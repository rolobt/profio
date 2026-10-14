# Profio — Reglas tributarias (documental, sin código)

Estado: BORRADOR v2. Los códigos de regla son provisionales. Ninguna regla se codifica hasta que su `source_reference` esté `VERIFICADO` en `sunat-sources.md`.

## 1. Diseño de reglas

Cada regla es un módulo tipado, puro y versionado. Campos obligatorios:

| Campo | Contenido |
|---|---|
| `rule_code` | Identificador estable, p. ej. `RCE_SPLIT_SUM_001` |
| `version` | Versión de la regla (por cambio de contenido) |
| `effective_from` / `effective_to` | Vigencia legal, no fecha de despliegue |
| `source_reference` | Norma y artículo/anexo/campo verificado |
| `applicability` | Predicado tipado: régimen, tipo de operación, tipo de documento, periodo; devuelve `APPLIES` o `NOT_APPLICABLE` con razón |
| `decision/output` | Decisión tipada para una ranura (`decision slot`) |
| `kind` | `VALIDATION` (verifica consistencia, no decide tributo), `DECISION` (determina un tratamiento), `ESTIMATE` (cálculo informativo) |

Reglas de selección:

1. Por cada ranura de decisión se evalúan las reglas vigentes en la fecha de la operación y aplicables al régimen de la empresa.
2. Cero reglas aplicables: `REQUIRES_REVIEW`.
3. Una regla: se aplica y queda registrada en `tax_result_rules`.
4. Más de una: error de configuración que se detecta en pruebas y falla en ejecución. No se desempata por prioridad.
5. Ninguna regla de tipo `DECISION` se activa sin pruebas "golden" cuyo valor esperado se justifique con la fuente.

Ranuras iniciales: `PERIOD`, `IGV_TREATMENT` (gravado / exonerado / inafecto / exportación), `CREDIT_DESTINATION` (DG / DGNG / DNG / sin crédito), `FX_RATE`, `NOTE_IMPACT`.

## 2. Reglas que se pueden implementar con seguridad (fuente verificada)

Se basan en texto oficial leído. "Seguridad" aquí significa que el comportamiento está escrito en la fuente; los parámetros marcados siguen pendientes.

| Código provisional | Tipo | Regla | Fuente verificada | Observación |
|---|---|---|---|---|
| `RCE_SPLIT_SUM_001` | VALIDATION | La suma de bases en campos 15+17+19 debe igualar la base propuesta (tolerancia ±1); la suma de IGV en 16+18+20 debe igualar el IGV propuesto (±1) | R.S. 040-2022, Anexo 8 (complemento), campos 15–20 | Solo para el complemento. **El Anexo 11 no declara tolerancia** (ver `RCE_REPLACE_SUM_001`) |
| `RCE_IGV_RATE_001` | VALIDATION | IGV de cada grupo = base × tasa vigente (±1) | Anexo 8, campos 16, 18, 20 | La tasa es un parámetro versionado. Valor y vigencia pendientes de verificar en TUO art. 17 |
| `DOC_ZERO_AMOUNTS_001` | VALIDATION | Comprobante electrónico con CDR no aceptado, con baja comunicada, o físico anulado: importes `0.00` | Anexos 2, 3, 4 RVIE, notas | RCE: no anotar bajas, revertidos ni anulados con NC tipo 02 |
| `RVIE_NOTE_SIGN_001` | DECISION (de formato) | NC (07/87): importes negativos en campos de base/IGV si el documento modificado es del periodo informado; si es de periodo anterior, se usan campos de descuento (16 y 18) | Anexo 3, campos 15–18 | Requiere `original_period` en `document_relations` |
| `RCE_NOTE_SIGN_001` | DECISION (de formato) | NC/ND y ajustes: negativo cuando tipo 07, 87 o 25 según condiciones del campo 34 | Anexo 8, campos 15–25 | Detalle completo en Anexo 11 (pendiente) |
| `NOTE_REFERENCE_001` | VALIDATION | NC/ND (07, 08, 87, 88) exigen fecha, tipo, serie y número del documento que modifican; notas múltiples admiten varios valores separados por coma | Anexo 3, campos 29–32; Anexo 8, campos 28–32 | Soporta 1..N en `document_relations` |
| `FX_PROPOSAL_DATE_001` | ESTIMATE (para conciliar) | Predecir el tipo de cambio que SUNAT propone: RVIE = venta de la fecha de emisión (vencimiento en tipo 14; fecha de emisión del documento modificado en NC/ND). RCE = promedio ponderado venta de la fecha de emisión; fecha de pago del impuesto en tipos 50, 52, 53, 54; fecha del documento modificado en NC/ND | Anexo 2 nota 3; Anexo 8 nota 4 | Sirve para comparar contra la propuesta. **No** decide el tipo de cambio que corresponde tributariamente al contribuyente (ver sección 4) |
| `BOLETA_DETAIL_001` | VALIDATION | Boleta (03) y ticket (12) con total ≥ S/ 700 se registran de forma detallada con identificación del cliente | Anexo 3, campos 10–13 | Umbral literal del anexo |
| `RVIE_CONSOLIDATION_001` | VALIDATION | Consolidación diaria (rango inicial/final) solo para tipos 00, 03, 12, 13, 18, 87, 88 y documentos que no dan derecho a crédito | Anexo 3, campo 10 (modificado por 138-2023) | Uso en ventas; muy raro en V1 |
| `RCE_CONSOLIDATION_001` | VALIDATION | Los comprobantes sin derecho a crédito pueden anotarse consolidados por día en campos libres | Anexo 8 nota 9 | No usar en V1 (REQUIRES_REVIEW) |
| `UTILITY_PERIOD_001` | DECISION (PERIOD) | Recibos de servicios públicos (tipo 14) para crédito: se aplica al vencimiento del plazo de pago o en la fecha de pago, lo que ocurra primero | TUO IGV art. 21; Anexo 8 campo 6 | Dos fuentes coinciden. Texto del art. 21 leído |
| `CREDIT_LATE_REG_001` | VALIDATION/INFO | La anotación tardía o defectuosa en el Registro de Compras no implica pérdida del crédito, que se ejerce en el periodo al que corresponde la adquisición | TUO IGV art. 19 inc. c) | Solo informa; no decide por sí sola |
| `CREDIT_12M_001` | VALIDATION | Alerta cuando la fecha de emisión o pago está más de 12 meses antes del periodo de anotación (inconsistencia 301 de SUNAT) | Manual API RVIE v31, §5.25 (ejemplo de código 301) | Solo el código 301 está leído; catálogo de inconsistencias pendiente |
| `CREDIT_RETIRO_001` | DECISION | El impuesto que grava el retiro de bienes no se deduce como crédito fiscal | TUO IGV art. 20; Tabla 11 tipo 96 | Aplica a documento tipo 96 |
| `IGV_ESTIMATE_001` | ESTIMATE | IGV estimado del mes = IGV de ventas − crédito fiscal del mes − saldo a favor previo; si el crédito excede, el exceso es saldo a favor que se aplica a meses siguientes hasta agotarse | TUO IGV art. 25 | Solo para tablero. Debe rotularse "estimado" |
| `REF_VALIDATE_ID_001` | VALIDATION | Longitud y tipo por documento de identidad (RUC 11 numérico fijo con módulo 11; DNI 8 numérico fijo; etc.) | Tablas 5 y 12 | Algoritmo de módulo 11 debe documentarse con su fuente |

### 2B. Reglas añadidas tras leer el Anexo 11 (reemplazo RCE)

Fuente: R.S. 040-2022, Anexo F (Anexo 11), leído completo. Todas son `VALIDATION` salvo indicación; la primera columna es provisional.

| Código provisional | Regla | Campo(s) | Observación |
|---|---|---|---|
| `RCE_REPLACE_SUM_001` | Σ campos 15, 17, 19 = base imponible total del comprobante o de la propuesta; Σ campos 16, 18, 20 = IGV total. Sin dato, 0.00 | 15–20 | **Sin tolerancia declarada** en el Anexo 11. No usar ±1 hasta probar con PVSIRE |
| `RCE_TYPE_EXCLUSION_001` | En el reemplazo no se permiten los tipos 91, 97 y 98; solo los tipos de la Tabla 11 | 7 | Tipos de no domiciliados: `REQUIRES_REVIEW` |
| `RCE_FX_REQUIRED_001` | Tipo de cambio obligatorio si la moneda ≠ PEN cuando la contabilidad es en soles, o si ≠ USD cuando es en dólares; formato `#.###` positivo | 26, 27 | Requiere atributo `companies.functional_currency` (PEN o USD) |
| `RCE_ICBPER_001` | Campo 23 obligatorio para tipos 01, 03, 07, 08, 12; 0.00 si no hay | 23 | |
| `RCE_DATE_001` | Fecha de emisión menor o igual al periodo; fecha de vencimiento o pago menor o igual al periodo, salvo tipo 14 (hasta el mes siguiente) | 5, 6 | Campo 6 obligatorio con tipos 14, 46, 50–54 |
| `RCE_NOTE_REFERENCE_001` | Tipos 07, 08, 87, 88 exigen fecha, tipo, serie y número del documento modificado; código de aduana si el tipo modificado es 50 o 52 | 28–32 | |
| `RCE_CLASSIF_33_001` | Campo 33 aplica solo si los ingresos del ejercicio anterior superaron 1,500 UIT | 33 | Requiere atributo de empresa (umbral); si no se conoce, `REQUIRES_REVIEW` |
| `RCE_NEG_SIGN_001` | Montos negativos (formato `- #.##`) cuando el tipo es 07, 87 o 25 (el 25 solo si campo 34 empieza con 1) | 15–25 | El anexo escribe `'7'` en lugar de `'07'` (A23) |
| `RCE_CONSOLIDATION_002` | Consolidación diaria de comprobantes sin derecho a crédito solo con sistema computarizado que mantenga el detalle; no usar en V1 | 10, 11 | `REQUIRES_REVIEW` |
| `RCE_TYPE14_PERIOD_001` | Servicios públicos (tipo 14): el crédito se aplica al vencimiento o al pago, lo que ocurra primero | 6 | Coincide con TUO art. 21 y con la nota 5 del Anexo 11 |

## 3. Reglas de crédito fiscal: marco y límites

Requisitos sustanciales (TUO art. 18, texto leído):
- (a) la adquisición debe ser permitida como gasto o costo según la legislación del Impuesto a la Renta, aun si el contribuyente no está afecto a ese impuesto;
- (b) debe destinarse a operaciones por las que se deba pagar el impuesto.

Requisitos formales (TUO art. 19, texto leído, con D.Leg. 1540):
- (a) impuesto consignado por separado en el comprobante o documento que sustenta el crédito;
- (b) nombre y RUC del emisor sin posibilidad de confusión y emisor habilitado a la fecha de emisión según medios públicos de SUNAT;
- (c) anotación en el Registro de Compras (la omisión o tardanza no hace perder el derecho, que se ejerce en el periodo de la adquisición);
- pagos con medios de pago del Reglamento permiten conservar el crédito aunque el comprobante incumpla requisitos, bajo condiciones del Reglamento.

Implicancias de diseño:
1. (a) del art. 18 exige un juicio sobre deducibilidad para Renta. **Profio no lo decide por sí solo.** Se captura una confirmación explícita del usuario ("uso empresarial") y el contador valida (`decision_source = USER` o `ACCOUNTANT`). Sin confirmación: `credit_status = REQUIRES_REVIEW`.
2. (b) del art. 18 y el art. 23 hacen que el destino (DG / DGNG / DNG) sea un dato declarado. Si la empresa solo realiza operaciones gravadas, el usuario/contador puede fijar un destino por defecto para la empresa (con auditoría); aun así cada operación puede ser sobrescrita.
3. El art. 19 (b) requiere consultar el estado del emisor a la fecha de emisión. Sin esa verificación, el resultado es `REQUIRES_REVIEW`.
4. El resultado `FULL` solo se produce si: IGV consignado por separado > 0, documento de tipo que sustenta crédito (según Reglamento de CP, pendiente), uso empresarial confirmado, destino declarado DG y emisor verificado. Hasta verificar el Reglamento de CP y el Reglamento del IGV, `FULL` automático queda desactivado (siempre exige confirmación humana).

## 4. Reglas que deben quedar en REQUIRES_REVIEW (V1)

Motivo "sin fuente verificada" salvo indicación.

| Caso | Motivo |
|---|---|
| Clasificación gravado / exonerado / inafecto / exportación a partir de la descripción del bien o servicio | Requiere TUO IGV títulos I–II y apéndices I y II (no leídos) |
| Valor de la tasa del IGV/IPM y su vigencia | TUO art. 17 no leído (parámetro versionado, sin valor sembrado verificado) |
| Tipo de cambio que corresponde al contribuyente (no el que propone SUNAT) | Norma referida (Reglamento IGV art. 5 num. 17) no leída |
| Reglas específicas de RER y RMT (límites, obligaciones, qué registros llevan) | Normas de renta no leídas; cronograma SIRE para estos regímenes no leído |
| Crédito fiscal parcial y prorrata (operaciones gravadas y no gravadas con destino indeterminado) | TUO art. 23 leído, pero el procedimiento está en el Reglamento (no leído) |
| Reintegro de crédito fiscal | TUO art. 22 leído; Reglamento no leído |
| Sujetos no domiciliados (documentos 00, 91, 97, 98) y utilización de servicios | TUO art. 21 leído; resto de la mecánica y retención no leídos |
| Importaciones (documentos 50, 51, 52, 53, 54) | Fuera de V1 |
| Operaciones con retención, percepción o detracción | Fuera de V1 (el campo de detracción de la propuesta es solo informativo) |
| Operadores y partícipes de consorcios (tipo 25, campos 34–36) | Fuera de V1 |
| ISC, IVAP, ICBPER no estándar | Fuera de V1 |
| Documentos tipo 02, 10, 22 (honorarios, arrendamiento, operaciones no habituales) | Sin regla de crédito leída |
| Emisor no habilitado, de baja o no habido a la fecha de emisión | Requiere consulta pública de RUC; sin verificación = revisión |
| Medios de pago para conservar crédito pese a comprobante incompleto | Reglamento no leído |
| Tipos de nota (catálogos 09 y 10 de R.S. 097-2012) | No leídos; solo dato referencial |
| Regímenes GENERAL, NRUS, OTHER | No hay módulos de reglas; `ref_tax_regimes.status = REVIEW_ONLY` |
| Cualquier tipo de documento de Tabla 3 / Tabla 11 sin regla propia | Se siembra en la tabla de referencia pero sin regla de decisión |

## 5. Parámetros versionados (no son reglas)

| Parámetro | Fuente esperada | Estado |
|---|---|---|
| Tasa IGV + IPM | TUO IGV art. 17 | PENDIENTE de verificar |
| UIT del año | Decreto Supremo de UIT | PENDIENTE |
| Umbral boleta S/ 700 | Anexo 3, campos 10–13 | VERIFICADO (literal del anexo) |
| Tolerancia ±1 en validaciones de suma | Anexo 8, campos 15–20 | VERIFICADO |
| Umbral 1,500 UIT para clasificación de bienes y servicios (campo 33 RCE) | Anexo 8, campo 33 | VERIFICADO |
| Plazo de 12 meses para inconsistencia 301 | Manual API RVIE v31 §5.25 | PARCIAL |

## 6. Fixtures y golden tests

- Cada fixture cita la fuente que respalda el resultado esperado. Si no hay fuente, el resultado esperado es `REQUIRES_REVIEW`.
- La macro comercial de terceros solo sirve para comparar salidas, nunca como valor esperado único.
- Ejemplo con fuente verificada: compra con base 1,000 e IGV 180 con propuesta SUNAT de 1,000/180 → distribución en DG: base 1,000 / IGV 180; validación `RCE_SPLIT_SUM_001` y `RCE_IGV_RATE_001` pasan **si** la tasa parametrizada es 18 % (a verificar). El crédito fiscal efectivo depende de la confirmación humana descrita en la sección 3.

## 7. Inventario priorizado de normas pendientes

Orden = impacto en el motor tributario. Hasta que cada fila esté `VERIFICADO`, el tratamiento afectado queda en `REQUIRES_REVIEW`. "Tests" son casos que se escribirán solo después de leer la fuente.

| Prio | Norma a obtener (fuente oficial `sunat.gob.pe`) | Artículo o anexo | Vigencia | Qué decide en Profio | Casos de prueba | Dudas pendientes |
|---|---|---|---|---|---|---|
| 1 | TUO Ley del IGV, art. 17 | Tasa y componentes (IGV + IPM) | A confirmar | Parámetro `igv_rate` | Base 1,000 ⇒ IGV 180 si la tasa es 18 % | Valor y vigencia; redondeo |
| 1 | TUO Ley del IGV, Títulos de ámbito, operaciones, exoneraciones e inafectaciones; Apéndices I y II | Arts. 1, 2, 5, 7 a 12 y apéndices | A confirmar | `IGV_TREATMENT`: gravado / exonerado / inafecto / exportación | Venta gravada, venta exonerada del apéndice, venta inafecta; bien no listado ⇒ revisión | Qué descripciones pueden clasificarse sin juicio humano |
| 1 | Reglamento de la Ley del IGV (D.S. 029-94-EF): crédito fiscal, destino, prorrata, tipo de cambio | Art. 6 y siguientes; art. 5 num. 17 | Con modificatorias, p. ej. D.S. 008-2023-EF | `CREDIT_DESTINATION`, prorrata, `FX_RATE` | Compra con crédito total; compra mixta con prorrata ⇒ revisión; factura en USD con contabilidad en soles | Numeración exacta de artículos y numerales; sustento y bancarización |
| 1 | TUO Ley del IGV, Capítulo VI (ya leído) | Arts. 18 a 25 | Falta confirmar posteriores a D.Leg. 1540 | Marco del crédito fiscal | Ver sección 3 | Modificaciones posteriores al texto leído |
| 1 | D.Leg. 1269 y modificatorias, y normas de Renta de RER y RMT | Regímenes, límites de ingresos, registros obligatorios | A confirmar | `ref_tax_regimes`; quién debe llevar RV y RC | Empresa RER con registros obligatorios; RMT bajo y sobre el límite | Si cada régimen está obligado a llevar RV y RC y desde cuándo |
| 1 | Reglamento de Comprobantes de Pago (R.S. 007-99/SUNAT) y modificatorias | Tipos, series, notas, boletas | A confirmar | Qué comprobantes sustentan crédito; series de NC/ND | Factura electrónica; boleta con IGV; NC sobre factura de periodo anterior | Reglas por tipo (Tablas 3 y 11 solo traen series y longitudes) |
| 2 | R.S. 097-2012/SUNAT, catálogos 09 y 10 | Tipos de nota de crédito y débito | A confirmar | `reason_code` de `document_relations` | NC por anulación, por descuento, por devolución | Si el catálogo se usa como dato referencial únicamente |
| 2 | R.S. 281-2022/SUNAT y Anexo II | Cronograma de atraso | A confirmar | Plazos máximos de atraso (datos versionados) | Fecha por último dígito del RUC | Cómo se actualiza cada año |
| 2 | Anexo 7 de la R.S. 112-2021 | Lista de obligados de la primera etapa | 2021 | Excepción histórica | No relevante para nuevas empresas | Solo para empresas en esa lista |
| 2 | Norma que designa principales contribuyentes (PRICOS) | Directorio | A confirmar | Excluye a la empresa de los incisos d) y e) | Empresa con ingresos > 2,300 UIT | No aplica al segmento objetivo, pero el motor debe poder detectarlo |
| 2 | Consulta pública del estado del RUC del emisor (habilitado, de baja, no habido) | Art. 19 inc. b) de la Ley del IGV | Operativa | Verificación del emisor | Emisor de baja a la fecha de emisión ⇒ crédito `NONE` o revisión | Disponibilidad del servicio y su fuente oficial |
| 3 | Importaciones, no domiciliados, retención, percepción, detracción, IVAP, ISC, ICBPER | Varias | — | Fuera de V1 | Cualquier caso ⇒ `REQUIRES_REVIEW` | — |

Reglas de aceptación para cerrar cada fila: fuente descargada con hash, versión y vigencia anotadas; norma citada por artículo con su `source_reference`; casos de prueba con valores esperados trazados al texto; y dudas pendientes resueltas por escrito por el contador o por la propia norma.
