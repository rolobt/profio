# Profio — Plan de implementación

Estado: BORRADOR v2. No se inicia ninguna fase de código sin aprobación.
Regla transversal: cada fase termina con tests en verde, RLS verificada y `audit_logs` donde aplique.

---

## PHASE 0 — Verificación documental de fuentes (en curso, sin código)

**Objetivo:** dejar `VERIFICADO` todas las fuentes de las que dependen las Fases 2 a 8.

**Archivos:** `docs/sunat-sources.md`, `docs/sire-structure.md`, `docs/tax-rules.md`, `docs/profio-architecture.md`, `docs/implementation-plan.md`.

**Pendientes bloqueantes (ver `sunat-sources.md`):**
1. ~~Anexo 11~~ **Resuelto**: leído completo (texto del PDF y Excel coinciden). Falta solo probar con PVSIRE las ambigüedades A22 (tolerancia ±1) y A16 (campos 38–41).
2. ~~Anexo 3~~ **Resuelto en lo esencial**: original leído completo (`anexo-112-2021.pdf`, con hash) y contrastado con los Anexos I y III de la R.S. 138-2023 (ver `sire-structure.md` 3A). Quedan A15 y A27 por confirmar con PVSIRE y con el Excel campo a campo.
3. Leer el manual API de RCE (v28) y el resto del manual API de RVIE (secciones 5.29 en adelante, TUS, anexos).
4. Cronograma/obligados SIRE: texto de las R.S. 145-2024 y 293-2024 leído (incisos d, e, f, g del art. 3.1). Faltan R.S. 190-2022, 204-2023, 258-2023, 063-2024, 217-2025, 392-2025 y 0125-2026 completas, la R.S. 281-2022 (cronograma de atraso) y la norma que define quiénes están obligados a llevar el RV y el RC.
5. Leer y registrar normas de IGV (Reglamento), RER, RMT y tipo de cambio.
6. Hash SHA-256: calculado para los 2 Excel y los 2 PDF subidos (ver `sunat-sources.md` sección 2B). Faltan los demás PDF listados en la sección 2C.
7. Probar con PVSIRE un TXT de muestra para resolver A15, A16 y A22 (tipo del campo 30 de RVIE, palotes de campos 34–41 y tolerancia ±1 de RCE).
8. Leer las secciones 5.29 a 5.37 del manual RVIE v31 y 5.24 a 5.61 del manual RCE v28 (estados del ticket, descarga, inconsistencias).
9. Normas tributarias de la sección 7 de `tax-rules.md`, por prioridad.

**Acceptance criteria:** todas las filas de las secciones 1 y 2 de `sunat-sources.md` en `VERIFICADO` o `NO APLICABLE`, con hash y fecha; ambigüedades de `sire-structure.md` sección 8 resueltas por escrito.

---

## PHASE 1 — Fundaciones de datos

**Objetivo:** modelo de negocio base multiempresa, seguro y con idempotencia.

**Archivos:** `supabase/migrations/001_core.sql`, `src/domain/operations/*` (tipos, validaciones, decimales), `tests/unit/operations/*`, `tests/rls/*`.

**Database changes:** `companies`, `company_members`, `customers`, `suppliers`, `documents`, `document_lines`, `document_relations`, `operations`, `payments`, `cash_accounts`, `products`, `exchange_rates`, `audit_logs`. Funciones `is_company_member`, `has_role`. RLS en todas. Triggers `updated_at` y auditoría.

**Services:** `CompanyService`, `PartyService` (clientes/proveedores), `DocumentService`, `OperationService.createPurchase/createSale`, `PaymentService`.

**Tests:** CRUD por rol; aislamiento Company A vs B en cada tabla; unicidad de documentos; creación atómica operation+document+lines (una transacción/RPC); decimales.

**Acceptance criteria:**
- Se registra una compra y una venta con documento y líneas.
- Un usuario de otra empresa no puede leer ni escribir nada.
- Registrar dos veces el mismo comprobante falla con error claro.
- Fecha de operación y fecha de pago son independientes.

---

## PHASE 2 — Tax Engine

**Objetivo:** convertir operaciones en `TaxResult` determinista, versionado y trazable.

**Archivos:** `src/domain/tax-engine/{normalize,evaluate,rules,credit,credit-notes,fx,explain}.ts`, `tests/unit/tax-engine/*`, `tests/golden/tax/*`.

**Database changes:** `ref_tax_regimes`, `ref_document_types`, `tax_rules` (catálogo), `rule_sets`, `tax_results` (append-only, `is_current`, `trigger`, `supersedes_id`, `input_snapshot`), `tax_result_rules`, `tax_decisions`. Las reglas son módulos TS tipados con ranuras de decisión exclusivas (ver `profio-architecture.md` sección 4 y `tax-rules.md`). Seed de reglas **solo** con las que tengan fuente oficial verificada.

**Services:** `TaxEngineService.evaluateOperation` (Edge Function idempotente), `TaxReviewService` (confirmación por usuario/contador, override con auditoría).

**Tests:** gravado, exonerado, inafecto, crédito total, sin crédito, revisión, NC, ND, moneda extranjera, periodos; determinismo (misma entrada ⇒ misma salida); casos no soportados ⇒ `REQUIRES_REVIEW`.

**Acceptance criteria:**
- Cada `tax_result` indica `rule_code`, `rule_version`, `decision_source`, `explanation`.
- Re-evaluar no crea duplicados.
- Ningún caso fuera de reglas se resuelve en silencio.
- IGV del documento y crédito fiscal están separados.
- Depende de: fuentes tributarias (sección 2 de `sunat-sources.md`) en estado VERIFICADO.

---

## PHASE 3 — RCE

**Objetivo:** de compra con `TaxResult` a archivo RCE válido.

**Archivos:** `src/domain/sire-engine/rce/{mapper,record}.ts`, `.../serialization/rce-serializer.ts`, `.../validation/rce-rules.ts`, `tests/golden/rce/*`.

**Database changes:** `sire_structure_versions`, `sire_parametric_tables`, `rce_records`, `validation_results`.

**Services:** `RceService.buildRecord`, `RceService.generateFile` (TXT y ZIP, nombre según regla oficial).

**Tests:** mapeo por fixture; serialización contra casos construidos desde el Anexo 11; bloqueo ante errores; idempotencia.

**Acceptance criteria:**
- Flujo de compra completo (pasos 1–11 de la especificación).
- Si `REQUIRES_REVIEW`, no se genera `RCERecord`.
- El archivo generado pasa PVSIRE (prueba manual documentada).
- Depende de: Anexo 11 (texto verificado), Tablas 1 a 23 (verificadas en su versión original) y prueba con PVSIRE de A16, A22 y del tipo de cambio. Pendiente: confirmar vigencia (A21) y las normas tributarias de `tax-rules.md` sección 7 para las reglas de crédito.

---

## PHASE 4 — RVIE

**Objetivo:** de venta con `TaxResult` a archivo RVIE válido, incluyendo NC/ND.

**Archivos:** `.../sire-engine/rvie/*`, `serialization/rvie-serializer.ts`, `tests/golden/rvie/*`.

**Database changes:** `rvie_records`.

**Services:** `RvieService.buildRecord`, `RvieService.generateFile`.

**Tests:** venta gravada, exonerada, inafecta, boleta, NC, ND, moneda extranjera.

**Acceptance criteria:**
- Flujo de venta completo.
- NC/ND referencian su documento original.
- Archivo pasa PVSIRE (prueba manual).
- Depende de: prueba con PVSIRE de A15, A16 y A6 (tipo del campo 30, palotes de campos 34–40 y decimales del tipo de cambio) y de las normas tributarias de `tax-rules.md` para las reglas de decisión. La estructura y las reglas de formato del Anexo 3 ya están reconstruidas.

---

## PHASE 5 — Validator

**Objetivo:** validación propia consolidada (categorías A–S) y bloqueo de generación.

**Archivos:** `src/domain/validation-engine/*` (por categoría), catálogos cargados desde `sire_structure_versions`.

**Database changes:** ajustes a `validation_results` (estado, `suggested_fix`).

**Services:** `ValidationService.validateRecord/validatePeriod`.

**Tests:** una batería por categoría; consistencia matemática con tolerancia documentada; duplicados; relación NC/ND.

**Acceptance criteria:**
- Ningún TXT/ZIP se emite con `ERROR` abierto.
- Mensajes entendibles para el usuario y código técnico para contador.
- Se documenta que PVSIRE es una segunda capa externa.

---

## PHASE 6 — Reconciliation

**Objetivo:** comparar registros esperados de Profio contra una propuesta (cargada de forma controlada).

**Archivos:** `src/domain/reconciliation/{normalize-key,match,diff,explain}.ts`, `tests/unit/reconciliation/*`, fixtures `exact_match`, `missing_in_sunat`, `missing_in_profio`, `amount_mismatch`, `igv_mismatch`.

**Database changes:** `reconciliation_results`.

**Services:** `ReconciliationService.run(period, registryType)` idempotente, `ResolveDifferenceService` (con auditoría).

**Tests:** los 7 niveles de matching; duplicados; resolución de diferencias.

**Acceptance criteria:**
- Resultados `MATCH/PARTIAL_MATCH/MISMATCH/UNMATCHED` con `difference_type`.
- Nunca se modifica una operación por lo que dice SUNAT.
- Mensajes en lenguaje de negocio.

---

## PHASE 7 — SUNAT Proposals (importación manual)

**Objetivo:** importar archivos de propuesta descargados por el usuario.

**Archivos:** `src/domain/sire-engine/sunat/proposal-parser-{rce,rvie}.ts`, UI de carga.

**Database changes:** `sire_proposals`, `sire_proposal_records` (con `raw_data`), bucket de Storage por empresa.

**Services:** `ProposalImportService` (hash del archivo para idempotencia, parseo según Anexos 2 y 8).

**Tests:** archivos de ejemplo oficiales o anonimizados; re-importar el mismo archivo no duplica; campos desconocidos se conservan en `raw_data`.

**Acceptance criteria:**
- Propuesta importada y visible en "Revisión SUNAT".
- Conserva la información original recibida.
- Depende de: Anexos 2 y 8 VERIFICADOS.

---

## PHASE 8 — SUNAT API

**Objetivo:** reemplazar el paso manual por `SunatSireClient` real, tras revisión.

**Archivos:** `src/domain/sire-engine/sunat/{client.ts,mock-client.ts,http-client.ts}`, Edge Functions `sunat-*`.

**Database changes:** `sire_submissions`; almacenamiento cifrado de credenciales de API.

**Services:** `SunatSireClient` completo; `SubmissionService` (estados PREPARED→…→ACCEPTED/REJECTED/ERROR, `file_hash` + `sunat_ticket`).

**Tests:** contra mock; contratos de respuesta; reintentos idempotentes; manejo de expiración de token; sin secretos en logs.

**Acceptance criteria:**
- Endpoints tomados del manual oficial vigente (VERIFICADO).
- Credenciales nunca llegan al navegador.
- Un envío repetido no duplica `sire_submissions`.
- Pruebas en ambiente real solo con empresa piloto y consentimiento del titular.

---

## PHASE 9 — UI refinement

**Objetivo:** experiencia de usuario final y vista técnica para contador.

**Archivos:** `src/ui/dashboard/*`, `src/ui/sunat-review/*`, `src/ui/technical-view/*`.

**Database changes:** vistas/RPC de agregados (ventas, compras, gastos, ganancia, IGV estimado, por revisar, estado SIRE).

**Services:** consultas agregadas; sin lógica tributaria en componentes.

**Tests:** componentes con datos de fixtures; accesibilidad básica; pruebas end-to-end de flujos compra → RCE y venta → RVIE → reconciliación.

**Acceptance criteria:**
- Dashboard según la especificación; "Revisión SUNAT" con 🟢 / 🟡 / 🔴.
- Usuario común no ve "campo 15 RCE"; contador sí, en vista técnica.
- Se cumplen los 15 criterios de aceptación de V1.

---

## Dependencias entre fases

```
1 → 2 → 3 ─┐
        └→ 4 → 5 → 6 → 7 → 8 → 9
```

Las fases 3, 4 y 7 están bloqueadas hasta que sus anexos pasen a `VERIFICADO`.
Una verificación de fuentes (descargar y leer Anexos 1, 3, 8, 11 y manuales API) es el primer paso de la Fase 2/3 y puede hacerse en paralelo a la Fase 1.
