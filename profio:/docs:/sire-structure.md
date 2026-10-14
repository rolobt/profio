# Profio — Estructura SIRE verificada (solo documental)

Estado: **NO CODIFICAR**. Este documento resume lo leído directamente de fuentes oficiales (ver `sunat-sources.md`). No contiene posiciones definitivas para serializers. Nada de lo marcado PENDIENTE puede asumirse.

Convenciones: campos separados por `|` (palote). Importes: hasta 12 enteros y 2 decimales, sin separador de miles, negativos como `- #.##` según Tabla 5/12 (el formato literal con el espacio debe confirmarse en el anexo consolidado, ver sección 8).

## 1. Resumen de confianza

| Estructura | Fuente leída | Confianza |
|---|---|---|
| RVIE reemplazo (Anexo 3) | Original completo (`anexo-112-2021.pdf`, subido) + modificaciones R.S. 138-2023 (Anexos I y III) + Excel oficial consolidado | ALTA para orden, nombres, longitudes, tipos y reglas de los 50 campos. Pendientes menores: A15, A27 y la prueba con PVSIRE (ver 3A.c) |
| RVIE nombre de archivo (Tabla 6) | R.S. 112-2021 + ejemplos del manual API v31 | ALTA |
| RCE complemento (Anexo 8) | R.S. 040-2022 completo + modificación 138-2023 (campo 5) | ALTA (pero **no es** la estructura de reemplazo) |
| **RCE reemplazo (Anexo 11)** | **Texto completo del Anexo 11 (PDF R.S. 040-2022, Anexo F, págs. 33–38, subido por el usuario) + Excel oficial consolidado (7)** | **ALTA** para campos 1–37 y 42–80 (texto y Excel coinciden). Vigencia: el Anexo 11 NO fue modificado por la R.S. 138-2023 (verificado en su art. 4). No se puede descartar una modificación posterior no indexada (ver A21) |
| RCE nombre de archivo (Tabla 13) | R.S. 040-2022 | ALTA |
| Tablas paramétricas | Ver sección 5 | ALTA para versión original; modificaciones de 138-2023 parcialmente leídas |

## 2. Nombre de archivo

### RVIE (Tabla 6, Anexo 1 de R.S. 112-2021)

Plantilla para reemplazo: `LERRRRRRRRRRRAAAAMM0014040002OIM2.TXT` (código de libro `140400`).

| Posición | Nemotécnico | Significado |
|---|---|---|
| 01–02 | LE | Fijo |
| 03–13 | RRRRRRRRRRR | RUC |
| 14–17 | AAAA | Año |
| 18–19 | MM | Mes |
| 20–21 | DD | `00` para RVIE |
| 22–27 | LLLLLL | Identificador del libro (`140400`) |
| 28–29 | CC | Oportunidad: `01` acepta propuesta, `02` reemplaza propuesta, `03` ajustes posteriores, `04` y `05` ajustes de periodos anteriores al sistema (general / simplificado) |
| 30 | O | Indicador de operaciones: `0` cierre/baja RUC, `1` empresa operativa, `2` cierre del libro no obligado |
| 31 | I | Contenido: `1` con información, `0` sin información |
| 32 | M | Moneda: `1` soles, `2` US dólares |
| 33 | G | `2` fijo (generado por el sistema) |
| 34 | N | Correlativo de ajustes posteriores (solo para CC `03`, `04`, `05`) |

Observaciones verificadas en el manual API v31: la carga por API exige archivo `.zip` (≤ 6 GB), el nombre de importación se declara con la estructura anterior y el código de libro RVIE es `140000` en los parámetros de servicio (distinto del `140400` del nombre de archivo).

### RCE (Tabla 13, R.S. 040-2022)

Plantillas: aceptar `080400 ...0008040001OIM2.TXT`; reemplazar `...0008040002OIM2.TXT`; ajustes `...0008040003OIM2NN.TXT`; no domiciliados `...0008050000OIM2.TXT`.

Mismas posiciones 01–33 que RVIE con estas diferencias confirmadas: libro `080400` (RC) / `080500` (no domiciliados); `CC`: `00` RC no domiciliados informado, `01` acepta, `02` reemplaza, `03` ajustes, `04`/`05`/`06` ajustes de periodos anteriores; **el correlativo de ajustes es `NN` (posiciones 34–35)**, no un solo dígito.

Otros nombres de archivo RCE confirmados: `RUC-CP-AAAAMM-Correlativo.txt` (complemento con comprobantes), `RUC-RCECOM-AAAAMM-Correlativo.txt`, `RUC-RCEINEX-...`, `RUC-RCETCA-...`.

## 3. RVIE — Anexo 3 (reemplazo / comparación con propuesta)

Cantidad de campos: 1–33 informados por el generador, 34–40 los completa SUNAT (no hay columnas para ellos en el Excel oficial), 41–57 de libre utilización (CLU, hasta 200, texto). El Excel oficial tiene **50 columnas** (33 + 17); el texto original decía "51 campos" (ver A5, ahora resuelta a favor de 50 columnas, falta confirmar si el TXT lleva palotes para 34–40).

Notas del Excel oficial (versión (3), modificado 2023-12-13): el campo 4 (CAR) y la estructura van "vacío para el Reemplazo de la Propuesta"; los campos 34–40 "son completados automáticamente por la Administración"; separador `|`.

| Campo | Descripción | Longitud / formato | Reglas clave verificadas |
|---|---|---|---|
| 1 | RUC del generador | 11 num | Obligatorio |
| 2 | Razón social del generador | hasta 1500 alfanum | Debe pertenecer al RUC |
| 3 | Periodo | 6 num `YYYYMM` | Periodo del RVIE; para tipo 14 ver regla (modificada por 138-2023: periodo según normativa del IGV) |
| 4 | CAR SUNAT | alfanum (27 o 29, ver A1) | Vacío; lo completa SUNAT |
| 5 | Fecha de emisión | 10 `DD/MM/AAAA` | Obligatorio; ≤ periodo |
| 6 | Fecha de vencimiento o pago | 10 `DD/MM/AAAA` | Obligatorio solo si tipo = 14 |
| 7 | Tipo de CP/documento | 2 alfanum | Validar con Tabla 3 |
| 8 | Serie | hasta 20 alfanum | Reglas por tipo (Tabla 3 y 5) |
| 9 | Número (o inicial de rango) | hasta 20 alfanum | idem |
| 10 | Número final de rango | hasta 20 alfanum | Solo tipos 00, 03, 12, 13, 18, 87, 88; consolidación diaria de boletas y tipo 18 (desde 01/10/2023) si no dan crédito fiscal; boleta ≥ S/ 700 va detallada |
| 11 | Tipo doc. identidad cliente | 1 alfanum | Obligatorio salvo excepciones (lista de tipos, notas sobre docs físicos, campo 14 > 0, boleta/ticket < S/ 700, campo 10 ≠ vacío); Tabla 1 |
| 12 | Número doc. identidad cliente | hasta 15 alfanum | Mismas excepciones; Tabla 5 |
| 13 | Razón social cliente | hasta 1500 alfanum | Mismas excepciones; apellido paterno, materno, nombres |
| 14 | Valor facturado de exportación | 12.2 num | Positivo; negativo en NC (07/87); anulado = 0.00 |
| 15 | Base imponible gravada | 12.2 num | En NC (07/87) negativo solo si el documento modificado es del periodo informado; ISC no incluido en base |
| 16 | Descuento de base imponible | 12.2 num | Solo NC (07/87) cuyo documento modificado es de periodo anterior |
| 17 | IGV / IPM | 12.2 num | Misma regla de signo que campo 15 |
| 18 | Descuento de IGV / IPM | 12.2 num | Misma regla que campo 16 |
| 19 | Importe operación exonerada | 12.2 num | Acepta negativo en NC |
| 20 | Importe operación inafecta | 12.2 num | Acepta negativo en NC |
| 21 | ISC | 12.2 num | — |
| 22 | Base imponible IVAP | 12.2 num | Obligatorio si tipo = 49 |
| 23 | IVAP | 12.2 num | Obligatorio si tipo = 49 |
| 24 | ICBPER | 12.2 num | Obligatorio si tipo ∈ {01, 03, 07, 08, 12}; `0.00` si no hay |
| 25 | Otros tributos, cargos y descuentos fuera de base | 12.2 num | Suma de otros conceptos |
| 26 | Importe total del CP | 12.2 num | Negativo en NC |
| 27 | Código de moneda | 3 alfanum | ISO 4217 según Tabla 2 |
| 28 | Tipo de cambio | 1 entero y 3 decimales (ver A6) | Obligatorio si moneda ≠ PEN |
| 29 | Fecha del documento que se modifica | 10, `DD/MM/AAAA` (versión 138-2023) | Solo tipos 07, 08, 87, 88; ≤ periodo; notas múltiples: valores separados por coma (long. 1500) |
| 30 | Tipo del CP que se modifica | 2 alfanum (138-2023) | idem |
| 31 | Serie del CP que se modifica (o dependencia aduanera) | hasta 20 | idem |
| 32 | Número del CP que se modifica (o DAM) | hasta 20 | idem |
| 33 | ID de contrato/proyecto (operadores y partícipes) | hasta 50 | Uso especial |
| 34–40 | Información que completa SUNAT | — | No se envían |
| 41–57 | Campos de libre utilización | hasta 200 texto | Si no se usan, no incluir ni los palotes |

Verificado con el PDF subido `anexoIII-000138-2023.pdf` (4 páginas, 5 marcas "(…)"; es una versión parcial, ver sección 9):

- Campos 11, 12 y 13: obligatorios, excepto cuando el campo 7 ∈ {00, 05, 06, 07, 08, 11, 12, 13, 14, 15, 16, 18, 19, 23, 28, 30, 34, 35, 36, 37, 55, 56, 64, 87, 88}; o campo 7 ∈ {07, 08, 87, 88} y campo 30 ∈ {03, 12, 13, 14, 36}; o campo 14 > 0.00; o campo 26 < 700.00 con campo 7 ∈ {03, 12} (si el documento trae identificación, es obligatorio consignarla); o campo 10 no vacío. En esos casos son opcionales y no se acepta el valor 0 en el campo 11.
- Campo 3, regla 5: si campo 7 = 14, el periodo es el que indique la normativa del IGV.
- Campo 10: consolidación diaria de boletas y de documentos tipo 18 sin derecho a crédito fiscal, desde el 01/10/2023; boleta (03) con total ≥ S/ 700.00 se registra detallada (desde el 01/07/2016).
- Campos 29–32: varios documentos modificados se consignan separados por coma, en orden correlativo, longitud 1500; campo 29 con formato DD/MM/AAAA y ≤ periodo; campo 30 se declara Alfanumérico.
- Nota 5: las excepciones de identificación solo aplican cuando los comprobantes y notas vinculadas son físicos.

Reglas transversales del Anexo 3 verificadas:

- Comprobantes electrónicos con CDR distinto a aceptado o con baja comunicada, y físicos anulados: se anotan con importe `0.00`.
- No se pueden aplicar excepciones de identificación del cliente a documentos electrónicos (solo físicos, nota 5).
- Las notas y comprobantes vinculados electrónicos siguen reglas de series (`E001`, `EB01`, `FXXX`, `BXXX`; serie `SXXX` si el documento modificado es tipo 14 o 36).
- Tipo de cambio: la propuesta usa tipo de cambio venta de la fecha de emisión (fecha de vencimiento para tipo 14); en NC/ND el de la fecha de emisión del documento modificado. En complementos o reemplazos, "conforme a las normas sobre la materia" (norma no leída, ver `sunat-sources.md` fila 27).

## 3A. Anexo 3 (RVIE reemplazo): original contra modificaciones

Fuentes contrastadas, todas leídas directamente:

| Fuente | Qué es | SHA-256 de la copia leída |
|---|---|---|
| `anexo-112-2021.pdf` (63 págs, creado 31/07/2021, 977,467 bytes) | Anexos 1 a 7 y A, B, C de la R.S. 112-2021: **texto original** del Anexo 3 | `9c9d484266a4eb261b7b22b5ea736dc477edd4c0827dfbc545ef81073ed6b987` |
| `anexoIII-000138-2023.pdf` | Modificaciones al Anexo 3 por R.S. 138-2023 (solo campos modificados) | `73366299cab1ef2824d23fc1fbfafadb3eb59b1c12727dbdcb849614ddfb7fd2` |
| `anexoI-000138-2023.pdf` (leído en línea, sin hash) | Modificaciones a Tablas 1, 3, 5 y 8 | — |
| Excel oficial Reemplazo RVIE (3) | Estructura consolidada (50 columnas) | `405dc7316e2b88763b14f6c688d1da2306d5c82e54c71dc285f2c39433e050ae` |

Método: el Anexo 3 vigente = texto original + Anexo III de R.S. 138-2023. No existe un texto consolidado oficial en PDF; el Excel consolidado solo trae estructura. Resultado de la reconstrucción:

### a) Reglas confirmadas sin cambios (original vigente)

Campos 1, 2 (salvo ajuste de redacción), 4, 5, 6, 7, 8, 14 al 28 y 33, y los campos libres 41 al 57. Detalle en la tabla de la sección 3. Puntos relevantes:

- Campo 4 (CAR): vacío, SUNAT lo completa. **El Anexo 3 no declara longitud** en su fila.
- Campos 5 y 6: `DD/MM/AAAA`; campo 6 solo obligatorio con tipo 14, fecha menor o igual al mes siguiente del periodo.
- Campo 8: serie hasta 20, reglas por tipo de la Tabla 3 y Tabla 5.
- Campos 14 a 26: hasta 12 enteros y 2 decimales; NC (07 y 87) en negativo con formato `- #.##`; comprobante anulado en `0.00`. Campos 16 y 18 (descuentos) solo para NC/87 cuyo documento modificado es de un periodo anterior; campos 15 y 17 negativos solo si el documento modificado es del periodo informado. ISC no incluido en la base (campo 15). IVAP obligatorio con tipo 49. ICBPER obligatorio con tipos 01, 03, 07, 08 y 12, `0.00` si no hay.
- Campo 27: moneda de emisión, ISO 4217 versión 2001, 3 caracteres.
- Campo 28: obligatorio si moneda distinta de PEN, positivo; el tipo de cambio es el de conversión a soles (contabilidad en soles) o a dólares (contabilidad en dólares); "conforme a las normas sobre la materia".
- Campos 29 al 32: solo con tipos 07, 08, 87, 88, y varios documentos separados por coma con longitud 1500. Campo 29 con formato `DD/MM/AAAA` y menor o igual al periodo.
- Notas originales vigentes: la nota 2 (tipo de cambio conforme a normas).

### b) Reglas modificadas por la R.S. 138-2023

| Campo o nota | Original (R.S. 112-2021) | Vigente (Anexo III de 138-2023) |
|---|---|---|
| Descripción del campo 3 | Incluía la frase sobre recibos de servicios públicos (SP, tipo 14) en el periodo de la fecha de vencimiento | La frase se elimina |
| Campo 3, regla 5 | Tipo 14: consigna fecha de vencimiento; puede informar con fecha de pago si corresponde a periodo anterior | Tipo 14: "el mes y año de acuerdo a lo señalado en la normativa del IGV correspondiente" |
| Campo 9 (descripción) | Tickets o cintas de máquinas registradoras sin derecho a crédito | Se amplía a "u otros comprobantes de pago o documentos" sin derecho a crédito |
| Campo 10 (descripción) | Complementar la propuesta; consolidación diaria de boletas de venta electrónicas | Comparar o reemplazar la propuesta; consolidación diaria de boletas **y de documentos tipo 18** sin derecho a crédito, desde el 01/10/2023 |
| Campos 11, 12, 13 | Obligatorio con excepciones; validar con "tabla 2 y 6" (referencia errónea) | Mismas excepciones, marcadas "(5)": solo aplican a documentos físicos; campo 11 valida con "tabla 1 y 5" (corregido). El campo 12 conserva "Reglas Generales, ver tabla 5" |
| Campo 30 | Numérico, longitud 2 | **Alfanumérico**, longitud 2 |
| Nota 1 | "En caso de reemplazar la propuesta" | "...o realizar la comparación entre la propuesta del RVIE y el archivo del generador" |
| Nota 3 | Anotar en cero los electrónicos con CDR distinto a aceptado, los de baja comunicada y los físicos anulados | Anotar en cero los electrónicos con baja comunicada y los físicos anulados; en campos 22 y 23 solo si el tipo no es 49. **Se elimina la mención al "CDR distinto a aceptado"** |
| Nota 4 | Campos 34–40 completados "a partir de la información que obra en la propuesta" | "...en los sistemas informáticos de la Administración" |
| Notas 5 y 6 | No existían | 5: las excepciones de identificación solo aplican a comprobantes y notas vinculadas físicos. 6: al validar con la Tabla 5 se evalúan sus "Reglas Generales" |

Cambios en las tablas por la R.S. 138-2023 (Anexo I) que afectan al Anexo 3:

- Tabla 1 y Tabla 5: se agrega el tipo `G` Salvoconducto (longitud 15, alfanumérico, variable).
- Tabla 5, nota 1 nueva: si en una factura tipo 01 se consignó guion (`-`) como tipo de documento del adquirente en los casos de R.S. 097-2012 art. 17.2 a) o R.S. 117-2017 art. 19.2 a), los campos 11 y 12 del RVIE llevan un guion (`-`).
- Tabla 3: descripciones ampliadas de varios tipos (11, 12 con ticket monedero, 13, 14, 16, 18 con EPS, 28, 29, 43, 45, 64); series de NC/ND (07 y 08) con `SXXX` si el documento modificado es tipo 14 o 36; tipo 48 con serie optativa y número hasta 20; tipos 48 y 89 solo para ajustes de periodos anteriores a agosto de 2021 (Ley 29972 derogada por Ley 31335); tipo 55 con tipos de boleto 1 manual, 2 automático, 5 anulado.
- Tabla 8: reescrita; el ajuste posterior RVIE se hace con el Anexo 4, con el CAR del comprobante a ajustar en el campo 41. Ajustes: fuera de V1.

### c) Dudas pendientes del Anexo 3

| Id | Duda | Estado |
|---|---|---|
| A1 (revisada) | El "29" de longitud del CAR está solo en el campo 4 del **Anexo 2** (complemento); el Anexo 3 no declara longitud y la Tabla 7 y el Anexo C dicen 27 | Se adopta 27; en el reemplazo el campo va vacío |
| A4 (resuelta) | `YYYY-MM-DD` aparece solo en los Anexos 2 y 4; el Anexo 3 original y el vigente dicen `DD/MM/AAAA` en el campo 29 | Resuelta para el Anexo 3 |
| A5 (precisada) | La frase "estructura de 51 campos" está en la nota 7 del **Anexo 2**, no en el Anexo 3. Las dos estructuras tienen 1–33 y 41–57 = 50 campos | Se usan 50; falta ver si el TXT lleva palotes para 34–40 |
| A6 | Campo 28: regla de formato `#.##` pero longitud "1 entero y 3 decimales" en la misma fila; el Anexo 5 y el Excel indican 3 decimales | Se parametriza en 3 decimales; confirmar con PVSIRE |
| A15 | Campo 30: la R.S. 138-2023 dice Alfanumérico; el Excel consolidado (modificado 13/12/2023) dice Numérico | Confirmar con PVSIRE |
| A24 | Campo 27 remite a "Tabla 3 Tipo de moneda" (la moneda es la Tabla 2); la parte leída de 138-2023 no lo corrige | Error de referencia en el texto; la lista válida es la Tabla 2 |
| A25 | Tabla 6: los nombres de ejemplo de ajustes RVIE usan `NN`, pero la tabla de posiciones solo define la posición 34 (`N`) | Fuera de V1; resolver antes de implementar ajustes |
| A26 | Anexos 2 y 4 de 138-2023 (II y IV) no se han leído, por lo que no se pudo confirmar si cambian reglas del complemento y de ajustes | Pendiente; no afecta al reemplazo |
| A27 | Campos 14 a 26, 28 y 33 aparecen como "(…)" en el Anexo III: se asumen sin cambios porque la R.S. 138-2023 no los menciona en el texto leído | Confirmar con el Excel consolidado campo a campo y con PVSIRE |

## 4. RCE

### 4.1 Anexo 8 (propuesta y complemento) — leído

Campos 1–37 informados, 38–41 informativos de SUNAT (no se envían), 42–80 libres. Total de estructura de complemento: 76 campos (consistente: 37 + 39).

| Campo | Descripción | Longitud / formato |
|---|---|---|
| 1 | RUC del generador | 11 num |
| 2 | Razón social del generador | hasta 1500 |
| 3 | Periodo `AAAAMM` | 6 num |
| 4 | CAR SUNAT | 27 alfanum |
| 5 | Fecha de emisión `DD/MM/AAAA` | 10 |
| 6 | Fecha de vencimiento o pago | 10 |
| 7 | Tipo de CP/documento (Tabla 11) | 2 |
| 8 | Serie (o código de dependencia aduanera en 50–54, o número de formulario) | hasta 20 |
| 9 | Año de emisión DAM/DSI/liquidación de cobranza | 4 num |
| 10 | Número de CP o documento / inicial de rango | hasta 20 |
| 11 | Número final de rango | hasta 20 |
| 12 | Tipo doc. identidad proveedor | 1 |
| 13 | Número doc. proveedor | hasta 15 |
| 14 | Razón social proveedor | hasta 1500 |
| 15 | BI adquisiciones gravadas con crédito, destinadas solo a operaciones gravadas y/o exportación (DG) | 12.2 |
| 16 | IGV/IPM de DG | 12.2 |
| 17 | BI adquisiciones gravadas destinadas a operaciones gravadas y no gravadas (DGNG) | 12.2 |
| 18 | IGV/IPM de DGNG | 12.2 |
| 19 | BI adquisiciones gravadas sin derecho a crédito (DNG) | 12.2 |
| 20 | IGV/IPM de DNG | 12.2 |
| 21 | Valor de adquisiciones no gravadas | 12.2 |
| 22 | ISC deducible | 12.2 |
| 23 | ICBPER | 12.2 |
| 24 | Otros conceptos, tributos y cargos | 12.2 |
| 25 | Importe total | 12.2 |
| 26 | Moneda (Tabla 2) | 3 |
| 27 | Tipo de cambio `#.###` | 1 entero y 3 decimales |
| 28 | Fecha de emisión del documento que se modifica | 10 |
| 29 | Tipo de CP que se modifica | 2 |
| 30 | Serie del CP que se modifica | hasta 20 |
| 31 | Código de dependencia aduanera DAM/DSI | 3 |
| 32 | Número del CP que se modifica | hasta 20 |
| 33 | Clasificación de bienes y servicios (solo si ingresos del ejercicio anterior > 1,500 UIT; Tabla 23, 1 a 5) | 1 num |
| 34 | ID de contrato/proyecto operadores y partícipes | hasta 50 |
| 35 | Porcentaje de participación | 2 enteros, 2 decimales |
| 36 | Impuesto materia de beneficio Ley 31053 | 12.2 |
| 37 | CAR del CP a modificar (ajustes) o indicador de exclusión (`1`) / inclusión (`2`) | 27 alfanum |
| 38–41 | Detracción, tipo de nota, estado del CP, inconsistencias | informativos (no se envían) |
| 42–80 | Libre utilización | hasta 200 texto |

Reglas verificadas que afectan el diseño:

- Los campos 15–20 dividen el IGV de cada comprobante entre DG / DGNG / DNG. Por defecto SUNAT propone todo en 15 y 16 (DG). El generador puede reubicar, con validación: Σ campos 15, 17, 19 = campo 15 de la propuesta y Σ campos 16, 18, 20 = campo 16 de la propuesta, ambos con **tolerancia ±1**. Cada IGV debe corresponder a la tasa vigente aplicada sobre su base, también con tolerancia ±1. **Esta tolerancia está escrita en el Anexo 8 (complemento). El Anexo 11 (reemplazo) NO menciona tolerancia**: solo dice que las sumatorias corresponden al total del comprobante o de la propuesta. Para el reemplazo no se debe asumir ±1 hasta probarlo con PVSIRE (A22).
- Tipo de cambio de la propuesta RCE: tipo de cambio promedio ponderado venta de la fecha de emisión (fecha de pago del impuesto para tipos 50, 52, 53, 54; fecha del documento modificado para NC/ND). Si SBS no publica para una moneda, el generador complementa (Anexo 10). Norma referencial citada: numeral 17 del artículo 5 del Reglamento del IGV.
- El generador no debe anotar comprobantes duplicados, dados de baja, revertidos ni anulados con NC tipo 02 por error en RUC. Documentos electrónicos deben tener CDR aceptado.
- Los comprobantes que no dan derecho a crédito se pueden anotar consolidados por día, con importes en los campos de libre utilización.
- Fecha de emisión (campo 5, versión 138-2023): permite periodo anterior para los tipos 01, 08, 23, 30, 34, 42, 50, 52, 53, 54.

### 4.2 Anexo 11 (reemplazo / comparación RCE) — texto leído

Fuente: `anexo-040-2022.pdf` (57 páginas, subido por el usuario; SHA-256 `a84532acdf8af0ea8dbad56af6071ae21be922c5ba1f36e6f0234e9375d38c8a`). El Anexo 11 es el "Anexo F", páginas 33 a 38, con campos 1–37, 42–80 y 10 notas, sin páginas faltantes. Contraste con el Excel oficial "Reemplazo RCE (7)" (SHA-256 `042a943bb13294cccc768d708dec0fd3adb87b1f8bb846622c42c817515b4b16`, 80 columnas): coinciden orden, nombres, longitudes y tipos de los campos revisados. El texto no define filas para los campos 38–41 (la nota 6 dice que SUNAT los completa a partir de la propuesta) y el Excel sí tiene sus columnas (ver A16).

| Campo | Regla global verificada (resumen) |
|---|---|
| 1 | RUC del generador, 11 numérico, obligatorio |
| 2 | Razón social, hasta 1500, debe pertenecer al RUC, obligatorio |
| 3 | Periodo `AAAAMM`, 6 numérico, obligatorio; corresponde al periodo de la propuesta que se reemplaza |
| 4 | CAR, 27 alfanumérico, **vacío** (SUNAT lo completa) |
| 5 | Fecha de emisión `DD/MM/AAAA`, obligatoria, menor o igual al periodo, validar con Tabla 12 |
| 6 | Fecha de vencimiento o pago. Obligatoria si campo 7 ∈ {14, 46, 50, 51, 52, 53, 54}. Menor o igual al periodo, salvo tipo 14: menor o igual al mes siguiente. Debe ser fecha de pago, salvo tipo 14 (vencimiento o pago, lo que ocurra primero) |
| 7 | Tipo de CP, Tabla 11, obligatorio. **No permite 91, 97 ni 98.** Para el reemplazo solo se permiten los tipos de la Tabla 11 |
| 8 | Serie, hasta 20. Obligatoria u opcional según Tabla 11. Si tipo 50–54: código de aduana (Tabla 4) |
| 9 | Año de DAM/DSI/liquidación de cobranza, 4 numérico, obligatorio; si tipo 50–54: mayor a 1981 y menor o igual al año del periodo |
| 10 | Número o inicial de rango, hasta 20, obligatorio salvo tipo 00. Permite consolidar el total diario de operaciones sin derecho a crédito para tipos 00, 03, 05, 06, 07, 08, 11, 12, 13, 14, 15, 16, 18, 19, 23, 28, 30, 34, 35, 36, 37, 44, 45, 55, 56, 87, 88 |
| 11 | Número final de rango. Solo si tipo 00, o tipos 03, 05, 06, 07, 08, 11, 12, 13, 14, 15, 16, 18, 19, 23, 28, 30, 34, 35, 36, 37, 55, 56, 87, 88 con campo 10 no vacío y campos 15–20 = 0.00 (los tipos 44 y 45 no figuran aquí, ver A20) |
| 12–14 | Tipo y número de documento y razón social del proveedor (o del operador/partícipe): obligatorios salvo tipo 00 o tipos 03, 05, 06, 07, 08, 11, 12, 13, 14, 15, 16, 18, 19, 23, 28, 30, 34, 35, 36, 37, 55, 56, 87, 88 con campo 11 no vacío. Tablas 1 y 12 |
| 15, 17, 19 | Bases DG / DGNG / DNG. Positivo o negativo; negativo cuando tipo 07, 87 o 25 (este último solo si campo 34 empieza con 1), formato `- #.##`. Tipo 46: base = IGV del campo respectivo ÷ tasa vigente. Si campo 11 no vacío: 0.00. El ISC de operaciones gravadas forma parte de la base. Obligatorio |
| 16, 18, 20 | IGV/IPM de cada grupo: mismo signo que su base, corresponde a la adquisición registrada en el campo de base. Obligatorio |
| 21 | Valor de adquisiciones no gravadas (exoneradas + inafectas); el ISC de operaciones no gravadas se suma aquí |
| 22 | Solo el ISC deducible; no afecta las bases del IGV |
| 23 | ICBPER, obligatorio si tipo ∈ {01, 03, 07, 08, 12}; 0.00 si no hay |
| 24 | Suma de otros conceptos, tributos, cargos y descuentos fuera de la base |
| 25 | Total del comprobante, acepta negativos (07, 87, 25 con condición) |
| 26 | Moneda en que se emitió el comprobante, 3, Tabla 2, obligatorio |
| 27 | Tipo de cambio `#.###`, positivo, 1 entero y 3 decimales. Obligatorio si campo 26 ≠ PEN cuando la contabilidad es en soles, o si campo 26 ≠ USD cuando la contabilidad es en dólares. "Conforme a las normas sobre la materia" |
| 28–32 | Documento que se modifica (solo tipos 07, 08, 87, 88): fecha (menor o igual al periodo), tipo (Tabla 11), serie, código de dependencia aduanera (obligatorio si campo 29 = 50 o 52) y número |
| 33 | Clasificación de bienes y servicios (1 a 5, Tabla 23); aplica solo si los ingresos del ejercicio anterior superaron 1,500 UIT |
| 34 | ID de contrato o proyecto de operadores/partícipes; obligatorio con tipo 25; formato `#-Identificador` (1 operador, 2 partícipe) |
| 35 | Porcentaje de participación, opcional |
| 36 | Impuesto materia de beneficio Ley 31053 |
| 37 | CAR original, **vacío**; aplica a ajustes posteriores |
| 42–80 | Libre utilización, hasta 200; si no se usan, no incluir información ni palotes |

Notas verificadas del Anexo 11:

- Solo se anotan comprobantes autorizados (electrónicos con CDR, CDR aceptado o estado aceptado), sin duplicados; no se anotan los dados de baja, revertidos o anulados con nota de crédito tipo 02 por error en RUC.
- IVAP: las facturas, DAM o DSI afectas a IVAP van en los campos 21 y 24; si tienen operaciones afectas a IGV, estas van en 15–20.
- ISC por ítem: si el ítem está afecto a IGV, el ISC integra la base (15, 17 o 19); si no lo está, integra el campo 21.
- Σ campos 15, 17, 19 = base imponible total del comprobante o de la propuesta; Σ campos 16, 18, 20 = IGV total. Sin dato, consignar 0.00.
- Tipo de cambio: "norma referencial: numeral 17 del artículo 5 del Reglamento del IGV" (norma no leída).
- Tipo 14: el crédito fiscal puede aplicarse al vencimiento del plazo de pago o en la fecha de pago, lo que ocurra primero (art. 21 de la Ley del IGV, citado en el anexo).
- Los campos 38–41 no informados se completan automáticamente a partir de la propuesta.
- Operadores de consorcios: el partícipe anota los datos del operador y viceversa, según opción de exceptuarse del registro auxiliar de la R.S. 022-98/SUNAT.
- La consolidación diaria exige un sistema de control computarizado que mantenga el detalle y permita verificación individual.

### 4.3 RC Información de operaciones con sujetos no domiciliados (Anexo 9)

Estructura de 35 campos más libres 36–45 leída (campos 1–35). Fuera de V1: toda operación con no domiciliados es `REQUIRES_REVIEW`.

## 5. Tablas paramétricas confirmadas (versión leída)

| Tabla | Contenido | Fuente / versión | Estado |
|---|---|---|---|
| 1 | Tipo de documento de identidad: `0` Doc. trib. no dom. sin RUC, `1` DNI, `4` Carnet de extranjería, `6` RUC, `7` Pasaporte, `A` Cédula diplomática, `B` Doc. identidad país residencia no domiciliado, `C` TIN persona natural, `D` IN persona jurídica, `E` TAM, `F` PTP, `G` Salvoconducto (agregado por 138-2023) | R.S. 112-2021 + 138-2023 | Confirmada |
| 2 | Tipo de moneda (ISO 4217; incluye PEN, USD, EUR, etc.) | R.S. 112-2021 (2021) | Confirmada como snapshot 2021. Hay códigos que pueden haber cambiado desde 2021; ver A8 |
| 3 | Tipo de CP/documento RVIE: 00, 01, 03, 04, 05, 06, 07, 08, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 23, 24, 27, 28, 29, 30, 32, 34, 35, 36, 37, 42, 43, 44, 45, 48, 49, 55, 56, 64, 87, 88, 89 (con longitudes y validaciones de serie/número por tipo) | R.S. 112-2021 + 138-2023 (parcial) | Confirmada; falta contrastar consolidado |
| 4 | Código de la aduana | RVIE 2021 (33 códigos) y RCE 2022 (más códigos, p. ej. 000, 037, 064, 073, 109, 136, 253, 901, 974) | Dos versiones distintas; usar la de RCE para RCE (A7) |
| 5 | Reglas generales RVIE y longitudes por tipo de doc. de identidad (RUC 11 numérico fijo con módulo 11; DNI 8 numérico fijo; carnet 12; pasaporte 12; otros 15) | R.S. 112-2021 + 138-2023 | Confirmada |
| 6 | Estructuras y nombres RVIE | R.S. 112-2021 | Confirmada |
| 7 | CAR SUNAT: RUC emisor (11) + tipo CP (2) + serie (4) + número (10) = 27; reglas de relleno con ceros y de truncado por la derecha; en RCE para tipos 46, 50–54 el RUC es del importador/usuario/retenedor | R.S. 040-2022 (versión más completa) | Confirmada; ver A1 |
| 8 | Procedimiento de ajustes posteriores RVIE | 138-2023 | Confirmada (fuera de V1) |
| 9 | Estado de validez RVIE (Activo, Baja, Rechazado, Autorizado) | R.S. 112-2021 | Confirmada |
| 10 | Tipo de medio de pago (001–013, 101–108, 999) | R.S. 112-2021 y 040-2022 | Confirmada |
| 11 | Tipo de CP/documento RCE: 00, 01, 02, 03, 04, 05, 06, 07, 08, 10, 11, 12, 13, 14, 15, 16, 17, 18, 19, 21, 22, 23, 24, 25, 27, 28, 29, 30, 32, 34, 35, 36, 37, 42, 43, 44, 45, 46, 48, 50, 51, 52, 53, 54, 55, 56, 64, 87, 88, 89, 91, 96, 97, 98 | R.S. 040-2022 | Confirmada |
| 12 | Reglas generales RCE (alfanumérico admite guion; fecha ≤ periodo; longitudes de documentos de identidad) | R.S. 040-2022 | Confirmada |
| 13 | Nombres de archivo RCE | R.S. 040-2022 | Confirmada |
| 14 | Estado de validez RCE (Activo, Baja, Revertido, Anulado, Autorizado, No autorizado) | R.S. 040-2022 | Confirmada |
| 15 | Ajustes posteriores RCE | R.S. 040-2022 | Confirmada (fuera de V1) |
| 16–21 | Países, vinculación económica, convenios, tipo de renta, modalidad de servicio, exoneraciones | R.S. 040-2022 | Confirmadas; solo no domiciliados (fuera de V1) |
| 22 | Inclusiones y exclusiones de la propuesta RCE | R.S. 040-2022 | Confirmada |
| 23 | Clasificación de bienes y servicios adquiridos (1–5) | R.S. 040-2022 | Confirmada |

## 6. Reglas generales de formato (resumen)

| Aspecto | RVIE (Tabla 5) | RCE (Tabla 12) |
|---|---|---|
| Separador | `|` | `|` |
| Texto | Sin `|`, `/`, `\` | Sin `|`, `/`, `\` |
| Alfanumérico | Letras y `( ) , .` | Letras, números y `( ) , . -` |
| Fecha | Igual al periodo (regla general); campos con `DD/MM/AAAA` | Igual o menor al periodo |
| Monto negativo | `- #.##` | `- #.##` |

## 7. API SIRE verificada

### 7.1 Manual RVIE (v31, leído hasta la sección 5.28)

- Credenciales: se generan en SUNAT Operaciones en Línea ("Credenciales de API SUNAT"), registrando aplicación y URI "MIGE RCE y RVIE - SIRE". Entrega `client_id` y `client_secret`.
- Token: POST a `https://api-seguridad.sunat.gob.pe/v1/clientessol/{client_id}/oauth2/token/` con `grant_type=password`, `scope=https://api-sire.sunat.gob.pe`, `client_id`, `client_secret`, `username={RUC}{USUARIO}`, `password={CLAVE SOL}`. Esto implica que Profio necesitaría la clave SOL del cliente. Riesgo de seguridad y de producto, ver sección 8.
- Servicios principales: descargar propuesta, aceptar propuesta, reemplazar propuesta, registrar preliminar, consultar ticket, descargar archivo, inconsistencias, tipo de cambio.
- Importante: los servicios no deben consumirse desde un cliente web (error CORS). La carga de archivos usa protocolo TUS y el manual indica desarrollarla en Java.
- Anexo 6 de R.S. 112-2021: envío por REST con ZIP + hash SHA-256 y ticket; seguridad OAuth 2.0 (JWT) con credenciales y clave SOL.

### 7.2 Manual RCE (v28, leído hasta la sección 5.23 de 5.61)

Identificación: archivo `Manual de servicios Web Api - SIRE_Compras v28_0.pdf` en `cpe.sunat.gob.pe/sites/default/files/inline-files/`, enlazado desde `cpe.sunat.gob.pe/node/158`. El control de cambios del documento termina en "V28, 13/08/2025" (última entrada: actualización del servicio 5.61). La página enlaza el archivo sin indicar versión; la versión sale del nombre y del control de cambios. El manual de Ventas (RVIE) es otro archivo distinto (v31, 28/09/2026).

Autenticación (sección 5.1, igual que RVIE):

- Credenciales: SUNAT Operaciones en Línea, "Empresas / Credenciales de API SUNAT", registrar nombre (50) y URL (260) de la aplicación, elegir la URI "MIGE RCE y RVIE – SIRE" y alcance Desktop o Web. Entrega `client_id` y `client_secret`.
- Token: `POST https://api-seguridad.sunat.gob.pe/v1/clientessol/{client_id}/oauth2/token/`, `application/x-www-form-urlencoded`, cuerpo `grant_type=password`, `scope=https://api-sire.sunat.gob.pe`, `client_id`, `client_secret`, `username={RUC}{USUARIO}`, `password={CLAVE SOL}`. Duración del token y formato de respuesta: están en imágenes del manual, no capturados.
- Llamadas de datos: cabeceras `Content-Type: application/json`, `Accept: application/json`, `Authorization: Bearer {token}`.

Servicios leídos (host `https://apisire.sunat.gob.pe/v1/contribuyente/migeigv/libros/`):

| Sección | Servicio | Método y ruta | Notas |
|---|---|---|---|
| 5.2 | Aceptar propuesta | `POST rce/propuesta/web/registroslibros/{perTributario}/aceptarpropuesta` | Devuelve `numTicket` (`AAAA99999999`). Con no domiciliados el tipo de registro es 2 y exige cargar no domiciliados |
| 5.3 | Reemplazar propuesta | Carga TUS a `rvierce/receptorpropuesta/web/propuesta/upload` | Metadatos: `filename`, `filetype`, `numRuc`, `perTributario`, `codOrigenEnvio=2`, `codProceso=61`, `codTipoCorrelativo=01`, `nomArchivoImportacion`, `codLibro=080000`. Archivo `.zip`, hasta 6 GB. Devuelve `numTicket` |
| 5.4 | Registrar preliminar | `POST rce/preliminar/web/registroslibros/{perTributario}/registrapreliminares` | Errores 1008 (ya en preliminar) y 1009 (ya generado) |
| 5.5 | Cargar no domiciliados | TUS a `rvierce/receptorpreliminar/web/preliminar/upload` | `codProceso=56` |
| 5.6, 5.8, 5.9 | Complementar, incluir/excluir, importar comprobantes a la propuesta | TUS a `receptorpropuesta/.../upload` | `codProceso` 54, 55 y 1 |
| 5.7 | Importar comprobantes al preliminar | TUS a `receptorpreliminar/.../upload` | `codProceso=4` |
| 5.10 | Tipo de cambio masivo | `GET rce/propuesta/web/{perTributario}/{codLibro}/resumenfechatipocambio` | Para comprobantes sin tipo de cambio propuesto |
| 5.11–5.14 | Reintegro de crédito fiscal, crédito fiscal especial, coeficiente de prorrata, consultar FV0621 | `PUT rce/propuesta/web/{perTributario}/grabacreditofiscal` y variantes | Datos del formulario 621; manual inconsistente (ver A19) |
| 5.15, 5.16, 5.17 | Eliminar comprobante de propuesta, de preliminar, o el preliminar completo | `DELETE .../propuestarce/{perTributario}`; `POST .../eliminacomprobante`; `PUT .../{perTributario}/{indEliminar}/eliminapreliminar` | `indEliminar` 1 = todo, 2 = solo no domiciliados. Errores 2301, 2302, 2297, 2009 |
| 5.18–5.29 | Ajustes posteriores (normales, no domiciliados, periodos anteriores) | Cargas TUS a `receptorajustesposteriores/.../upload` y envíos/eliminaciones en `rce/ajustesposteriores/...` | Fuera de V1 |

Servicios no leídos (secciones 5.31 a 5.61): consultar estado del ticket, descargar archivo (la versión V24 cambió la URL y agregó `perTributario`, `codProceso`, `numTicket`; la V25–V26 cambiaron parámetros y salida binaria), consultar año y mes, descargar propuesta, resumen, excluidos, reportes, constancia de recepción, inconsistencias, consultar y eliminar preliminares registrados. Por eso los **estados posibles de un ticket y el detalle de descarga no están documentados aquí**.

Formato de errores: HTTP 500 `{cod, msg, exc}` y HTTP 422 `{cod, msg, errors:[{cod, msg}]}`. Códigos comunes de carga leídos: 1001 RUC vacío, 1002 RUC no numérico de 11 dígitos, 1003 RUC inexistente, 1005–1007, 1014 y 1064 de periodo, 1022 nombre de archivo vacío, 1024 archivo ya enviado, 1044 error de posición en el nombre del archivo, 1348 extensión distinta de `.zip`, 1346 tamaño mayor a 6 GB, 1350 archivo vacío, 1351 error de envío.

Restricciones declaradas por SUNAT: los servicios no deben consumirse desde un cliente web (error CORS) y los servicios que usan TUS deben desarrollarse en Java (el anexo 7.4 trae ejemplo de cliente TUS en Java). Seguridad de datos: toda llamada usa la clave SOL del generador.

Operaciones de reemplazo (ambos registros): flujo mínimo = token → (opcional) descargar propuesta → importar reemplazo (TUS) → consultar ticket hasta "Terminado" → (opcional) descargar inconsistencias → registrar preliminar → generación del registro en el portal web de SUNAT. La generación final del registro solo se hace desde SUNAT Operaciones en Línea, no por API (art. 8.3 de la R.S. 112-2021: "se accede únicamente mediante SUNAT Operaciones en Línea").

## 8. Ambigüedades y contradicciones detectadas (sin resolver)

| Id | Detalle | Impacto |
|---|---|---|
| A1 | Longitud del CAR: el "29" figura solo en el campo 4 del Anexo 2; el Anexo 3 no declara longitud; Tabla 7, Anexo C (R.S. 112-2021) y Anexos 8 y 11 (RCE) dicen 27 | Se adopta 27. Resuelta en la práctica; el campo va vacío en reemplazo |
| A2 | El Anexo III de R.S. 138-2023 no es el Anexo 3 completo: solo muestra campos modificados | Parcialmente resuelta: el Excel oficial confirma columnas, longitudes y tipos. Las reglas globales vigentes siguen siendo original + modificaciones |
| A3 | Texto del Anexo 11 | **Resuelta**: leído completo (sección 4.2) |
| A4 | `YYYY-MM-DD` solo en Anexos 2 y 4; el Anexo 3 (original y vigente) usa `DD/MM/AAAA` | **Resuelta** para el Anexo 3 (ver 3A.c) |
| A5 | "Estructura de 51 campos" está en la nota 7 del Anexo 2; las estructuras de los Anexos 2 y 3 tienen 50 campos (1–33 y 41–57); el Excel RVIE tiene 50 columnas | Resuelta a 50. Falta confirmar con PVSIRE si el TXT lleva campos vacíos para 34–40 |
| A6 | Tipo de cambio RVIE: regla textual `#.##`, pero el Excel oficial dice "1 entero y 3 decimales" (igual que RCE `#.###`) | Probable: 3 decimales en ambos. Confirmar con PVSIRE |
| A7 | Dos versiones de la Tabla 4 (aduanas) | Catálogos |
| A8 | Tabla 2 es un snapshot ISO de 2021 (incluye HRK, VES, etc.) | Catálogo de monedas; ver si SUNAT lo actualizó |
| A9 | Código de libro `140000` (API) vs `140400` (nombre de archivo) para RVIE | Mapeo de códigos |
| A10 | El manual API usa dos hosts: `apisire.sunat.gob.pe` y `api-sire.sunat.gob.pe` | Configuración del cliente HTTP |
| A11 | La autenticación requiere clave SOL del contribuyente (grant `password`) | Seguridad, custodia de secretos, consentimiento y términos de servicio |
| A12 | Requisito de cliente TUS en Java | Arquitectura de Fase 8 (Edge Functions es TS) |
| A13 | No se pudo calcular hash SHA-256 de ningún archivo | Trazabilidad de fuentes |
| A14 | El formato exacto del monto negativo ("- #.##") puede incluir un espacio literal; confirmar | Serializer |
| A15 | Campo 30 RVIE (tipo del CP que se modifica): el Excel oficial dice "Numérico"; la modificación de R.S. 138-2023 dice "Alfanumérico" | Tipo de dato en el serializer; probar con PVSIRE |
| A16 | Asimetría: el Excel RVIE no tiene columnas para 34–40, el Excel RCE sí las tiene para 38–41, y el texto del Anexo 11 no define filas 38–41 (nota 6: SUNAT los completa) | Nº de palotes de cada TXT; probar con PVSIRE |
| A17 | La longitud del campo 4 (CAR) no figura en ninguno de los dos Excel (van vacíos en el reemplazo) | En reemplazo el campo va vacío, el conflicto 27/29 (A1) solo afecta ajustes y descargas |
| A18 | El Excel RVIE tiene una celda de longitud inconsistente en un campo CLU (campo 47 con "Hasta 20" frente a "Hasta 200") | Tomar 200; error tipográfico probable |
| A19 | El manual RCE v28 tiene ejemplos copiados de RVIE: en 5.3 y varios otros los metadatos de ejemplo usan `codLibro` 140000 y `codProceso` 87 en base64, pero la tabla dice 080000 y 61; 5.13 repite la ruta de 5.11 (`grabacreditofiscal`); 5.14 dice PUT pero el ejemplo es una consulta; la numeración salta de 5.29 a 5.31 | No usar los ejemplos; usar la tabla de parámetros y probar en ambiente real |
| A20 | Anexo 11: la lista de tipos permitidos para consolidar (campo 10) incluye 44 y 45, la del campo 11 no | Regla de rangos |
| A21 | El índice oficial de normas SIRE no es exhaustivo: la R.S. 145-2024 (que modifica el art. 3) no figura en él | No se puede certificar "sin modificaciones posteriores" solo con el índice |
| A22 | El Anexo 11 no menciona la tolerancia de ±1 que sí escribe el Anexo 8 | No aplicar tolerancia en el reemplazo hasta probar con PVSIRE |
| A23 | Anexo 11, campos 15, 17, 19: la regla de signo dice `'7'` (sin cero) además de `'87'` y `'25'`; se interpreta como tipo 07 | Validar el tipo con dos caracteres |
| A24–A27 | Ambigüedades del Anexo 3 (referencia de tabla en campo 27, nombres de ajustes, Anexos II y IV sin leer, campos "(…)"): ver sección 3A.c | Ver 3A.c |

## 9. Estado de los PDF subidos

| Archivo | Contenido | ¿Completo? |
|---|---|---|
| `anexo-112-2021.pdf` (63 págs, SHA-256 `9c9d484266a4eb261b7b22b5ea736dc477edd4c0827dfbc545ef81073ed6b987`) | Anexos 1 (Tablas 1–10), 2, 3, 4, 5, 6, 7 y A, B, C de la R.S. 112-2021, texto original de julio de 2021 | Sí, como anexo de la resolución (sin el cuerpo). **Sin las modificaciones posteriores** de 138-2023 y de las normas de obligación |
| `anexoIII-000138-2023.pdf` (4 págs, SHA-256 `73366299cab1ef2824d23fc1fbfafadb3eb59b1c12727dbdcb849614ddfb7fd2`) | Anexo III de la R.S. 138-2023: solo modificaciones al Anexo 3 (RVIE). Las filas "(…)" son campos no modificados | **No.** Solo los campos 2, 3, 7–13, 29–32 y las notas 1 y 3–6 |
| `anexo-040-2022.pdf` (57 págs, SHA-256 `a84532acdf8af0ea8dbad56af6071ae21be922c5ba1f36e6f0234e9375d38c8a`) | Anexos A a K de la R.S. 040-2022: tablas, Anexos 8, 9, 10, 11, 12, 13, formatos del libro diario y Anexo 7 (CAR) | Sí, como anexo de la resolución (texto de marzo de 2022). **Sin las modificaciones de la R.S. 138-2023** a Tabla 7 y Anexos 8, 12 y 13 |
