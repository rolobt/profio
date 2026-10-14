# Profio, Fase 1: datos de negocio

Primera parte funcional de Profio: empresas multiusuario, terceros, comprobantes, operaciones y pagos, con RLS, auditoría y registro atómico e idempotente de operaciones. **No contiene lógica tributaria** (eso es la Fase 2) ni estructuras SIRE.

## Qué hay

| Ruta | Contenido |
|---|---|
| `supabase/migrations/20261012000001_phase1_core.sql` | Esquema, tablas de referencia, RLS, auditoría, RPC `create_company` y `register_operation` |
| `supabase/tests/rls_isolation.test.sql` | Pruebas pgTAP de aislamiento y permisos |
| `src/domain/shared/` | Decimales exactos (bigint) y validación de documentos de identidad (Tabla 5) |
| `src/domain/operations/` | Tipos, catálogos, validación, servicio y pasarela hacia Supabase |
| `tests/` | 41 pruebas con el runner de Node |

## Cómo probar

```bash
npm test                 # pruebas del dominio y comprobaciones estáticas de la migración
npx supabase db reset    # aplica la migración en local (requiere Supabase CLI y Docker)
npx supabase test db     # ejecuta supabase/tests/rls_isolation.test.sql
```

## Estado de verificación

- Pasan 41 de 41 pruebas de TypeScript (`npm test`).
- La migración SQL y la prueba pgTAP **no se ejecutaron**: el entorno de trabajo no tiene PostgreSQL. La migración tiene comprobaciones estáticas (RLS en cada tabla, claves foráneas compuestas, seeds sincronizados con los catálogos TS), pero puede tener errores de sintaxis o de comportamiento que solo `supabase db reset` detectará.
- `tsc` no se ejecutó (sin acceso a npm). Las pruebas corren con el soporte nativo de TypeScript de Node 22.

## Decisiones y adiciones respecto a la especificación (para revisión)

1. `tax_regime` y `document_type` son tablas de referencia, no enums. `ref_document_types` se siembra con los códigos de las Tablas 3 y 11; las descripciones de tipos que solo aparecen en la Tabla 11 quedan en `NULL` hasta leer esa fuente.
2. `documents.direction` (`ISSUED` / `RECEIVED`): distingue ventas (RVIE, Tabla 3) de compras (RCE, Tabla 11) y define la unicidad del comprobante.
3. `operations.idempotency_key` y `payload_hash`: la misma clave con el mismo contenido devuelve la misma operación; con distinto contenido se rechaza.
4. Atributos de empresa que las reglas SIRE leídas exigen: `functional_currency`, `prior_year_income_over_1500_uit`, `is_principal_taxpayer`, `sire_obligation_start_period`. Desconocido = `NULL`.
5. Las notas de crédito y débito (tipos 07, 08, 87, 88) exigen `document_relations` con periodo original; una venta o compra con documento de nota se rechaza. Los montos se guardan en positivo; el signo lo decide la representación SIRE (Fases 3 y 4).
6. Los tipos 48 y 89 se rechazan: solo valen para ajustes de periodos anteriores a agosto de 2021.
7. Sin políticas de borrado en tablas de negocio: se anula con `status = 'VOIDED'`.
8. El dígito verificador del RUC solo genera una advertencia: el algoritmo no está en las fuentes leídas.
9. Tolerancia de redondeo en `total = subtotal + igv + otros`: ninguna (igualdad exacta a 2 decimales). Es decisión de producto, no una regla de SUNAT.

## Pendiente de esta fase

- Ejecutar la migración y la prueba RLS en un Supabase real.
- Conectar el servicio a Lovable (formularios y llamadas a `register_operation`); no hay UI en este paquete.
- Alta de usuarios invitados a una empresa (hoy `company_members` se administra con SQL o por rol OWNER/ADMIN).
- Documentos de compras de proveedores sin identificar (tickets): hoy una compra exige proveedor.
