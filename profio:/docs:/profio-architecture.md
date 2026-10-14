# Profio — Arquitectura (greenfield)

Estado: BORRADOR v2 (post verificación documental de fuentes). Ninguna fase de código ha comenzado.
Fecha: 2026-10-08
Cambios respecto a v1: ver sección 14.

## 1. Architecture

Cinco bloques estrictamente separados. Cada bloque solo conoce la salida del anterior.

```
A. BUSINESS OPERATIONS  (operations, documents, payments, customers, suppliers)
        ↓ normalización
B. TAX ENGINE           (operation → tax_result, determinista, reglas versionadas)
        ↓
C. SIRE ENGINE          (tax_result → RCERecord/RVIERecord → validator → serializer → TXT/ZIP)
        ↓
E. VALIDATION ENGINE    (Profio Validator → [PVSIRE opcional externo] → SUNAT)

D. RECONCILIATION       (expected record Profio ↕ sire_proposal_records → diferencias)
```

Reglas de dependencia (se verifican con lint de imports):

| Módulo | Puede importar | NO puede importar |
|---|---|---|
| `domain/operations` | nada del resto | tax, sire, reconciliation |
| `tax-engine` | `domain/operations` (tipos) | `sire-engine`, UI, HTTP |
| `sire-engine` | tipos de `tax-engine` (TaxResult) | lógica tributaria, UI |
| `validation-engine` | tipos de records | UI |
| `reconciliation` | tipos de records y proposals | tax-engine (no recalcula) |
| `sire-engine/sunat` | solo interfaces | UI directa |

Capas de ejecución:

```
React UI → Application/API layer (Edge Functions + RPC) → Domain services (TS puro) → PostgreSQL
```

- Todo el dominio vive en un paquete TS puro (`packages/domain`), sin dependencias de React ni de Supabase. Se ejecuta en Edge Functions y en tests.
- React solo llama a la capa de aplicación y muestra resultados.
- Lovable: las carpetas y los límites de import deben pedirse explícitamente en cada prompt; la lógica tributaria nunca va en componentes.

Estructura de carpetas propuesta:

```
/docs
/supabase/migrations
/supabase/functions            # capa application/API
/src/domain/operations
/src/domain/tax-engine
/src/domain/sire-engine/{rce,rvie,serialization,validation,sunat}
/src/domain/reconciliation
/src/domain/validation-engine
/src/ui                        # solo presentación
/tests/{unit,golden,fixtures}
```

## 2. Domain model

Principio: se guarda el hecho de negocio ("compré una factura por S/1,180"), luego se determina su significado tributario, luego su representación SIRE.

```
OPERATION → TAX_RESULT → RCE_RECORD / RVIE_RECORD → (serializer) → archivo
```

Entidades:

- **Company**, **CompanyMember** (rol).
- **Customer**, **Supplier**.
- **Document** (comprobante): independiente de la operación. Una operación puede no tener documento.
- **DocumentLine**.
- **DocumentRelation** (NC/ND → documento afectado). Ver sección 4.
- **Operation**: entidad central (SALE, PURCHASE, EXPENSE, CREDIT_NOTE, DEBIT_NOTE, OTHER).
- **Payment**: fecha de pago separada de fecha de operación.
- **TaxResult**: resultado tributario con rule_code + rule_version + decision_source + explanation.
- **RCERecord / RVIERecord**: representación intermedia, desacoplada del TXT.
- **SireProposal / SireProposalRecord**: copia fiel de lo que propone SUNAT (con `raw_data`).
- **ReconciliationResult**, **ValidationResult**, **SireSubmission**, **AuditLog**.

Decisiones de modelado (supuestos a confirmar):

1. Dinero en `numeric(14,2)`; tipo de cambio en `numeric(10,6)`; nunca float. En TS se usa una librería decimal (p. ej. `decimal.js`) o enteros en céntimos.
2. Se conserva el monto en moneda original y los valores calculados en PEN en columnas separadas.
3. `tax_period` como `char(6)` `YYYYMM` más constraint de formato.
4. `tax_results` es **append-only**: cada evaluación es una fila nueva; exactamente una está marcada `is_current` por operación (índice único parcial). Nunca se sobrescribe. Ver sección 4 (historial).
5. `operations` y `documents` duplican totales a propósito (la operación puede no tener documento); el validador verifica consistencia entre ambos cuando existe documento.
6. Se agregan tablas auxiliares no listadas en la especificación pero necesarias: `document_relations`, `exchange_rates`, `cash_accounts`, `products`, `rule_sets` (para versionar paquetes de reglas), `sire_structure_versions`.

## 3. Database model

Tablas (ver detalle de campos en la especificación, se respetan tal cual y se agregan los campos indicados):

| Grupo | Tablas |
|---|---|
| Identidad | `companies`, `company_members` |
| Terceros | `customers`, `suppliers` |
| Comprobantes | `documents`, `document_lines`, `document_relations` |
| Negocio | `operations`, `payments`, `cash_accounts`, `products` |
| Tributario | `tax_rules` (catálogo de reglas), `rule_sets`, `tax_results` (append-only), `tax_result_rules`, `tax_decisions` |
| SIRE | `sire_structure_versions`, `rce_records`, `rvie_records`, `sire_proposals`, `sire_proposal_records`, `sire_submissions` |
| Control | `reconciliation_results`, `validation_results`, `audit_logs`, `exchange_rates` |

Constraints clave (idempotencia):

- `documents`: UNIQUE (`company_id`, `document_type`, `series`, `number`, `supplier_id`/`customer_id` según tipo de operación). El campo de tercero se normaliza en un índice único parcial por tipo.
- `tax_results`: UNIQUE (`operation_id`, `input_hash`, `rule_set_version`) para que re-evaluar con la misma entrada y las mismas reglas no cree filas nuevas; UNIQUE parcial (`operation_id`) WHERE `is_current`. Un cambio de datos, de reglas o una decisión humana sí crea una evaluación nueva.
- `rce_records` / `rvie_records`: UNIQUE (`operation_id`, `tax_result_id`, `structure_version`).
- `sire_submissions`: UNIQUE (`company_id`, `registry_type`, `period`, `file_hash`).
- `reconciliation_results`: UNIQUE (`proposal_record_id`, `profio_record_id`, `difference_type`) por corrida.
- `sire_proposal_records`: UNIQUE (`proposal_id`, hash de llave del documento).

**Decisión:** `tax_regime` y `document_type` NO son enums nativos. Son tablas de referencia (`ref_tax_regimes`, `ref_document_types`) con FK. Valores iniciales de `ref_tax_regimes`: RER, RMT, GENERAL, NRUS, OTHER, cada uno con `status` (`SUPPORTED` | `REVIEW_ONLY`) y vigencia. Los códigos de `ref_document_types` se siembran desde las tablas oficiales (Tabla 3 RVIE y Tabla 11 RCE, ver `sire-structure.md`), conservando el código SUNAT de 2 caracteres como clave. Las tablas paramétricas SIRE se versionan en `sire_structure_versions` / `sire_parametric_tables`; no se escriben a mano en código.

## 4. Tax Engine

Responsabilidad: `evaluateOperation(operation, ruleSet) → TaxResult`. No genera TXT.

Propiedades:

- Función pura y determinista: misma operación + mismo `rule_set` + misma versión ⇒ mismo resultado.
- Entrada normalizada (`NormalizedOperation`): montos decimales, periodo, moneda, tipo de cambio, régimen de la empresa, tipo y relación del documento.
- **Reglas como módulos de código tipados, no como JSON genérico.** Cada regla es un módulo TS puro con: `rule_code`, `version`, `effective_from`, `effective_to`, `source_reference` (norma + artículo/anexo verificado en `sunat-sources.md`), `applicability(operation, context)` (predicado tipado que devuelve `APPLIES | NOT_APPLICABLE` con razón) y `decide(operation, context)` que devuelve una decisión tipada (`decision/output`). `tax_rules` es el **catálogo** de esos módulos (metadatos, estado, hash del módulo), no el lugar donde vive la lógica.
- **Ranuras de decisión exclusivas** (`decision slots`): p. ej. `IGV_TREATMENT`, `CREDIT_DESTINATION`, `FX_RATE`, `PERIOD`. Para cada ranura y cada operación, el motor selecciona las reglas aplicables vigentes en la fecha de la operación y para el régimen de la empresa. Resultado: 0 reglas ⇒ `REQUIRES_REVIEW`; 1 regla ⇒ su decisión; más de 1 ⇒ error de configuración (falla de forma explícita, no se resuelve por `priority`). Así no se acumula un if/else gigante disfrazado de configuración.
- El `TaxResult` registra, por cada ranura, exactamente qué `rule_code` + `version` produjo la decisión (`tax_result_rules`).
- Si ninguna regla aplica con seguridad: `tax_status = REVIEW_REQUIRED`, `credit_status = REVIEW_REQUIRED`, `review_status = REQUIRES_REVIEW`.

Pipeline (12 pasos de la especificación):

1. Validar operación. 2. Tipo de operación. 3. Documento. 4. Periodo tributario. 5. Tratamiento tributario. 6. Bases. 7. IGV. 8. Crédito fiscal. 9. ¿Requiere revisión? 10. rule_id + rule_version. 11. Crear TaxResult. 12. Explicación + decision_source.

Separación crítica: **IGV del documento** ≠ **IGV con derecho a crédito**. Ambos viven en `tax_results` (`igv_amount` vs `creditable_igv` / `non_creditable_igv`).

Historial de evaluaciones (`tax_results` append-only):

- Campos de control: `sequence`, `trigger` (`INITIAL | REEVALUATION | DATA_CHANGE | RULES_CHANGE | USER_DECISION | ACCOUNTANT_OVERRIDE`), `supersedes_id`, `is_current`, `input_snapshot`, `input_hash`, `rule_set_version`, `decision_source`, `decided_by`, `created_at`.
- `tax_decisions`: decisiones humanas (usuario/contador): campo afectado, valor anterior, valor nuevo, motivo, autor, fecha. Un override produce una evaluación nueva con `trigger = ACCOUNTANT_OVERRIDE` que referencia la decisión.
- Se puede responder: resultado original, reevaluaciones, qué datos cambiaron (diff de `input_snapshot`), decisión del usuario, override del contador y regla/versión usada.
- Un trigger de base de datos impide UPDATE/DELETE sobre `tax_results`, salvo la función que cambia `is_current`.

Decisión de diseño derivada de las fuentes verificadas: el **destino** de una adquisición (campos 15–20 del RCE: solo operaciones gravadas / gravadas y no gravadas / no gravadas) es una decisión del generador del registro. Profio no lo infiere en silencio: se captura como dato declarado (`decision_source = USER` o `ACCOUNTANT`) y las reglas solo validan consistencia y bloqueos. Detalle en `tax-rules.md`.

Notas de crédito y débito:

- Nunca se modelan como venta negativa.
- `document_relations` es una relación 1..N (una nota puede modificar varios comprobantes; las estructuras SIRE lo admiten con valores separados por coma). Cada fila guarda: `document_id` (la nota), `related_document_id` (nullable), `related_document_type`, `related_document_series`, `related_document_number`, `related_issue_date`, `original_period` (`YYYYMM`), `affected_base`, `affected_igv`, `affected_total`, `reason_code` y `reason_text` (el tipo de nota es dato referencial en SIRE, no va en el archivo de reemplazo), `original_operation_id`.
- `original_period` es obligatorio para el tratamiento: en RVIE los importes de una NC se informan en negativo en los campos de base/IGV solo si el documento modificado corresponde al periodo informado; si corresponde a un periodo anterior se usan los campos de descuento (16 y 18). El tipo de cambio de una nota sigue la fecha del documento que modifica. Fuente: Anexos 2/3 (RVIE) y Anexo 8 (RCE), ver `sire-structure.md`.
- Si el documento afectado no existe en Profio, se registra la referencia textual y el resultado queda en `REQUIRES_REVIEW` hasta confirmación.

Moneda extranjera:

- Se guarda `currency`, `exchange_rate` y el monto original.
- La regla de qué tipo de cambio aplica (fecha de emisión, fecha de pago, etc., y su fuente: SBS) se implementa como regla versionada con `source_reference`. Hasta tener la fuente verificada, el motor marca `REQUIRES_REVIEW` cuando falta tipo de cambio o la regla no está confirmada.
- Dato ya identificado en documentación SUNAT: la propuesta RVIE usa el tipo de cambio venta de la fecha de emisión (a verificar en el anexo vigente antes de codificarlo).

IA: puede extraer, sugerir, explicar y detectar anomalías. No decide tratamiento tributario sin regla determinística o confirmación humana (`decision_source = USER/ACCOUNTANT`).

## 5. RCE Engine

```
TaxResult → RCE Mapper → RCERecord → RCE Validator → RCE Serializer → TXT/ZIP
```

- Mapper: traduce resultado tributario a campos del registro. No recalcula impuestos.
- `RCERecord` lleva: `registry_type`, `structure_version`, `source_rule_version`, `period`, `operation_id`, `payload` estructurado.
- `structure_version` proviene de la documentación oficial descargada (no se escribe "2026" como sustituto). Se registra en `sire_structure_versions` junto con la resolución y fecha de la fuente.
- Serializer: único lugar que conoce posiciones, separadores, longitudes y nombre de archivo. Se parametriza por `structure_version`.
- No se genera archivo si hay errores bloqueantes.

## 6. RVIE Engine

Mismo pipeline que RCE con `RVIERecord` y serializer propio (Anexo 3 vigente). Mismas reglas de versionado y de bloqueo.

## 7. Reconciliation

- Entrada: registros esperados de Profio (RCERecord/RVIERecord) vs `sire_proposal_records`.
- Matching progresivo (niveles 1–7): llave (tipo+serie+número+contraparte) → fecha → base → IGV → total → moneda → tipo de cambio.
- Resultados: `MATCH`, `PARTIAL_MATCH`, `MISMATCH`, `UNMATCHED`, con `difference_type` según la especificación.
- Nunca modifica una operación de Profio por lo que proponga SUNAT. Solo genera diferencia + `suggested_action`; la resolución la hace una persona y queda en `audit_logs`.
- Mensajes al usuario en lenguaje de negocio ("Compra F001-456 está en Profio por S/1,180 y SUNAT propone S/1,000"), con vista técnica separada para contador.
- Normalización previa de llave: serie/número en mayúsculas, ceros a la izquierda según regla del anexo, documento de contraparte por tipo.

## 8. Validator

`validation-engine` ejecuta las categorías A–S de la especificación, por severidad `ERROR | WARNING | INFO`.

- Reglas estructurales (longitudes, formatos, catálogos) se cargan desde la versión de estructura vigente, no se hardcodean.
- Reglas matemáticas: `base + igv + otros = total` con tolerancia explícita y documentada.
- Reglas de duplicado: por llave de documento.
- Resultados persistidos en `validation_results`.
- Un `ERROR` bloquea generación de TXT/ZIP.
- PVSIRE: capa externa, opcional y posterior. El validador propio no lo reemplaza ni lo sustituye en la comunicación al usuario.

## 9. SUNAT integration

- Abstracción `SunatSireClient` (interfaz) con implementaciones `MockSunatSireClient` y, más adelante, `HttpSunatSireClient`.
- Métodos: `authenticate`, `getRceProposal`, `getRvieProposal`, `getInconsistencies`, `downloadFile`, `uploadReplacement`, `submitAction`, `getTicketStatus`, `getRegistryStatus`.
- Los endpoints reales se toman del manual oficial vigente del servicio API SIRE, no de librerías o blogs de terceros.
- Credenciales API SUNAT: se generan por el contribuyente desde SUNAT Operaciones en Línea. Se guardan cifradas (Supabase Vault o equivalente), solo accesibles desde Edge Functions, nunca en el cliente. Nunca se almacena la clave SOL en texto plano.
- V1 puede operar 100 % manual: el usuario sube el archivo de propuesta descargado de SUNAT y Profio lo importa a `sire_proposals`. La integración API es la Fase 8.

## 10. Security

- RLS en todas las tablas con `company_id` (o vía join a tabla con `company_id`): operations, documents, document_lines, customers, suppliers, payments, tax_results, rce/rvie_records, proposals, reconciliation, submissions, validation_results, audit_logs.
- Función `is_company_member(company_id)` y `has_role(company_id, roles[])` (SECURITY DEFINER, con `search_path` fijo).
- Políticas por rol: VIEWER solo lectura; OPERATOR crea operaciones; ACCOUNTANT confirma tratamientos y resuelve diferencias; ADMIN/OWNER administran.
- Tests de aislamiento: usuario de Company A no lee ni escribe en Company B (por cada tabla).
- Archivos (Storage): buckets por empresa con políticas por prefijo `company_id/`.
- Audit log inmutable (sin UPDATE/DELETE para roles de aplicación).
- Secretos solo en Edge Functions.

## 11. Testing

- Unitarios: cálculos, clasificación, crédito fiscal, NC, ND, moneda extranjera, mapeo RCE, mapeo RVIE, validación, conciliación, duplicados.
- Golden tests: cada fixture con `INPUT`, `EXPECTED_TAX_RESULT`, `EXPECTED_RECORD`, `EXPECTED_VALIDATION`.
- Fixtures: purchase_full_credit, purchase_no_credit, purchase_review, sale_taxable, sale_exempt, sale_unaffected, credit_note, debit_note, foreign_currency, missing_in_sunat, missing_in_profio, amount_mismatch, igv_mismatch, exact_match.
- Los valores esperados se derivan de las normas y anexos oficiales. La macro comercial de terceros se usa solo como oráculo de comparación (REFERENCE / TEST ORACLE), no como autoridad.
- Tests de RLS (pgTAP o scripts con distintos JWT).
- Tests de idempotencia: ejecutar dos veces el mismo proceso no duplica filas.
- Archivo TXT final: se valida contra PVSIRE manualmente en la fase de aceptación (no es automatizable en CI).

## 12. V1 scope

Operaciones: ventas, compras, facturas, boletas, NC, ND, clientes, proveedores, pagos.
Tributario: IGV, gravado, exonerado, inafecto, crédito fiscal total/ninguno, revisión manual, moneda extranjera, periodos, NC/ND, versionado de reglas.
SIRE: RCE, RVIE, importación de propuesta, comparación, diferencias, validador, TXT, ZIP.
Regímenes con reglas implementadas en V1: RER y RMT (sujeto a verificación de normas, ver `sunat-sources.md`). El dominio NO está excluyendo otros regímenes: GENERAL, NRUS y OTHER existen en `ref_tax_regimes` con `status = REVIEW_ONLY`; el motor devuelve `REQUIRES_REVIEW` hasta que se cargue un módulo de reglas para ellos. Agregar un régimen = agregar fila de referencia + módulos de reglas + fixtures, sin migrar el esquema.

## 13. Unsupported cases (siempre `REQUIRES_REVIEW`, nunca silencioso)

- Operaciones con sujetos no domiciliados.
- Importaciones complejas.
- ISC avanzado e IVAP.
- Prorrata de crédito fiscal.
- Crédito fiscal parcial sin regla formal implementada.
- Operaciones de exportación con particularidades no modeladas.
- Estructuras o tipos de documento poco frecuentes no cargados.
- Regímenes distintos de RER/RMT.
- Ajustes posteriores (Anexos 4, 5, 12, 13) — fuera de V1.
- Complemento de propuesta (Anexos 2 y 8) — V1 trabaja con reemplazo/comparación.

## 14. Cambios de la revisión v2 (post verificación de fuentes)

1. `tax_regime` y `document_type`: de enum a tablas de referencia (`ref_tax_regimes`, `ref_document_types`). Regímenes no implementados quedan en `REVIEW_ONLY`, no excluidos.
2. Reglas tributarias: de "condiciones/acciones JSON" a módulos de código tipados con ranuras de decisión exclusivas. `tax_rules` pasa a ser catálogo.
3. `tax_results` pasa a ser append-only con `is_current`, `trigger`, `supersedes_id`, `input_snapshot`; nuevas tablas `tax_result_rules` y `tax_decisions`.
4. `document_relations` pasa a 1..N y con `original_period`, fechas y datos del documento afectado (las estructuras oficiales lo exigen).
5. Nuevas tablas de referencia versionadas: `sire_parametric_tables` (tablas 1–23 oficiales con versión y fuente).
6. Nuevo riesgo de arquitectura: el manual API SIRE indica que los servicios no deben consumirse desde cliente web (CORS) y que la carga de archivos usa el protocolo TUS con cliente desarrollado en Java. Las Edge Functions de Supabase corren TypeScript/Deno. Hay que decidir y probar: (a) cliente TUS en TypeScript contra el ambiente real, o (b) un microservicio Java pequeño solo para `SunatSireClient.uploadReplacement`. Hasta decidir, la Fase 8 queda bloqueada y V1 trabaja con carga manual en el portal SUNAT.
7. El destino de adquisiciones (DG / DGNG / DNG) se modela como dato declarado por usuario/contador, no inferido por el motor.
8. Estados de fuentes: ningún serializer RCE/RVIE se diseña hasta tener `VERIFICADO` el Anexo 11 y la versión consolidada del Anexo 3.
9. Atributos de empresa requeridos por las reglas leídas: `functional_currency` (PEN o USD, determina cuándo es obligatorio el tipo de cambio en RCE campo 27), `prior_year_income_over_1500_uit` (campo 33 RCE), `sire_obligation_start_period` con `source_reference` y `is_principal_taxpayer` (la obligación SIRE depende del supuesto del art. 3.1 de la R.S. 112-2021, modificado). Mientras no estén confirmados por el contador, los tratamientos que dependen de ellos van a `REQUIRES_REVIEW`.
10. La generación final del registro (paso posterior a cargar el reemplazo y registrar el preliminar) solo existe en SUNAT Operaciones en Línea. Profio no puede "presentar" el registro; puede preparar el archivo de reemplazo y registrar el preliminar vía API. Esto limita el alcance de la Fase 8.
