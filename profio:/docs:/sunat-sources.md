# Profio — Fuentes oficiales SUNAT (v2, verificación documental)

Fecha de consulta: 2026-10-08.
Método: lectura directa de los PDF/páginas oficiales con herramienta de descarga de texto. Solo se usó `sunat.gob.pe` y `cpe.sunat.gob.pe` como autoridad. Blogs, macros, videos y terceros NO se usaron como fuente normativa.

## Limitaciones de esta verificación (leer primero)

- **Hash SHA-256.** Calculado solo para los dos Excel que subió el usuario (ver filas 12 y 13). Son hashes de las copias subidas, no descargadas por mí desde SUNAT. Para los PDF sigue pendiente: hace falta subirlos o habilitar red.
- **Archivos Excel oficiales.** Ya leídos desde las copias subidas por el usuario el 2026-10-08. Dan estructura (orden, nombre, longitud y tipo de campo), no las reglas de validación de los anexos.
- **Lecturas parciales.** El manual API de RVIE v31 se leyó hasta la sección 5.28 y el de RCE v28 hasta la 5.23. No puedo descargar archivos binarios: leo el texto que devuelven las páginas y PDF. Los anexos de la R.S. 040-2022 y el Anexo III de la R.S. 138-2023 se leyeron además desde las copias que subió el usuario.
- **Hash no es vigencia.** Un SHA-256 solo identifica los bytes de la copia que se me entregó. No prueba autenticidad, origen oficial ni vigencia de la norma.

Estados: `VERIFICADO` (leído directamente y suficiente para su uso) | `PARCIAL` (leído en parte o falta confirmar vigencia) | `PENDIENTE` (identificado, no leído) | `NO APLICABLE`.

## 1. Estructuras SIRE y API

| # | URL oficial | Documento / anexo | Fecha / versión | Vigencia | Hash | Estado | Qué depende de Profio |
|---|---|---|---|---|---|---|---|
| 1 | https://cpe.sunat.gob.pe/node/141 | Índice oficial de normas SIRE (lista R.S. 112-2021, 040-2022, 138-2023, 190-2022, 204-2023, 258-2023, 063-2024, 293-2024, 217-2025, 392-2025, 0125-2026 y resoluciones de facultad discrecional hasta RSNATI 000041-2026) | Última modificación visible: 31/08/2026 | Vigente (índice) | — | VERIFICADO | Mapa de normas; detección de modificatorias |
| 2 | https://www.sunat.gob.pe/legislacion/superin/2021/anexo-112-2021.pdf | Anexo de R.S. 112-2021/SUNAT: Anexo 1 (Tablas 1–10), Anexos 2, 3, 4, 5, 6 (aspectos técnicos API), 7 (154 obligados de la primera etapa), A (Formatos 5.1 y 5.2), B (estructura del libro diario) y C (CAR) | PDF de 63 páginas, creado 31/07/2021; copia subida por el usuario | Texto original; modificado por R.S. 138-2023 (Tablas 1, 3, 5, 8 y Anexos 2, 3, 4, 5) | `9c9d484266a4eb261b7b22b5ea736dc477edd4c0827dfbc545ef81073ed6b987` (copia subida) | VERIFICADO como texto original (leído completo); vigencia: Anexo 3 vigente reconstruido con 138-2023 (ver `sire-structure.md` 3A) | Estructura RVIE, nombres de archivo RVIE, CAR, Tabla 3 de RVIE, reglas generales, hash/API (Anexo 6) |
| 3 | https://www.sunat.gob.pe/legislacion/superin/2023/000138-2023.pdf | R.S. N.º 000138-2023/SUNAT (modifica R.S. 112-2021 y 040-2022) | Firmada 27/06/2023; vigente desde el día siguiente a su publicación, salvo campo 3 y notas 3 y 5 del Anexo 2, nota 1 del Anexo 5 y otros ítems de los arts. 8, 9 y 11 desde el 01/10/2023, y su art. 4 desde el 01/07/2023 | Vigente salvo posteriores | — | VERIFICADO (texto de la resolución leído) | Alcance exacto: modifica Tablas 1, 3, 5 y 8 y Anexos 2, 3, 4, 5 de la R.S. 112-2021; y en la R.S. 040-2022 solo el texto de la Tabla 7 y de los Anexos 8, 12 y 13. **No modifica el Anexo 11** |
| 4 | https://www.sunat.gob.pe/legislacion/superin/2023/anexoI-000138-2023.pdf | Anexo I de 138-2023: modificaciones a Tablas 1, 3, 5, 8 | 2023 | Vigente | — | VERIFICADO (como lista de modificaciones, con "(…)" en lo no modificado) | Tabla 1 agrega tipo `G` Salvoconducto; Tabla 3 ajustes de series; Tabla 8 ajustes posteriores |
| 5 | https://www.sunat.gob.pe/legislacion/superin/2023/anexoIII-000138-2023.pdf | Anexo III de 138-2023: modificaciones al Anexo 3 (RVIE) | PDF de 4 páginas, creado 28/06/2023 | Vigente | `73366299cab1ef2824d23fc1fbfafadb3eb59b1c12727dbdcb849614ddfb7fd2` (copia subida) | PARCIAL: **solo modificaciones, 5 marcas "(…)"; no es el Anexo 3 completo** | Reglas de campos 2, 3, 7–13, 29–32 y notas del Anexo 3 |
| 6 | https://www.sunat.gob.pe/legislacion/superin/2023/anexoII-000138-2023.pdf, anexoIV, anexoV | Anexos II (Anexo 2), IV (Anexo 4), V (Anexo 5) de 138-2023 | 2023 | Vigente | — | PENDIENTE (II solo por fragmento de búsqueda; IV y V no leídos) | Complemento de propuesta RVIE; ajustes posteriores (fuera de V1) |
| 7 | https://www.sunat.gob.pe/legislacion/superin/2022/anexo-040-2022.pdf | Anexo de R.S. 040-2022/SUNAT: Anexos A (Tablas 4, 7, 10), B (Tablas 11–23), C (Anexo 8), D (Anexo 9), E (Anexo 10), F (Anexo 11), G (Anexo 12), H (Anexo 13), I (Formatos 5.1 y 5.2), J (Anexo 2 de R.S. 286-2009), K (Anexo 7 CAR) | PDF de 57 páginas, creado 21/03/2022 | Texto original de 2022; modificado por 138-2023 en Tabla 7, Anexos 8, 12 y 13 | `a84532acdf8af0ea8dbad56af6071ae21be922c5ba1f36e6f0234e9375d38c8a` (copia subida) | VERIFICADO como texto original (leído; sin páginas faltantes); vigencia PARCIAL (ver A21) | Tablas RCE, Anexo 8, **Anexo 11 (reemplazo RCE)**, CAR |
| 8 | https://www.sunat.gob.pe/legislacion/superin/2023/anexoVII-000138-2023.pdf | Anexo VII de 138-2023: modificación del Anexo 8 (campo 5) | 2023 | Vigente | — | VERIFICADO | Regla de fecha de emisión en complemento RCE |
| 9 | https://www.sunat.gob.pe/legislacion/superin/2023/anexoIX-000138-2023.pdf | Anexo IX de 138-2023: Anexo 13 (ajustes posteriores registros distintos al RCE) | 2023 | Vigente | — | VERIFICADO (sin contenido relevante: solo "(…)") | Ninguna en V1 |
| 10 | https://www.sunat.gob.pe/legislacion/superin/2023/anexoVI-000138-2023.pdf y anexoVIII-000138-2023.pdf | Anexo VI de 138-2023: texto de la Tabla 7 (CAR; el CAR de un ajuste posterior puede generar CAR nuevo). Anexo VIII: modificaciones al Anexo 12 (ajustes posteriores RCE) | 2023 | Vigente | — | VERIFICADO (solo modificaciones) | Ajustes posteriores (fuera de V1) |
| 11 | https://cpe.sunat.gob.pe/estructura-de-archivos | Página oficial "Estructura de archivos": Reemplazo RVIE (Anexo 3), Reemplazo RCE (Anexo 11), No domiciliados (Tabla 13 de R.S. 040-2022). Enlaza Excel consolidados | Última modificación 30/05/2025 | Vigente | — | VERIFICADO (página); Excel NO legibles | **Fuente vigente de Anexo 3 y Anexo 11 consolidados** |
| 12 | https://cpe.sunat.gob.pe/sites/default/files/inline-files/Estructura%20del%20Reemplazo%20RCE%20%287%29%20%281%29.xlsx | Excel oficial: Estructura del Reemplazo RCE, hoja "Reemplazo RCE", 80 columnas, "conforme al Anexo 11 de R.S. 00040-2022" | Versión (7); archivo subido por el usuario 2026-10-08 | Vigente según página de estructuras (30/05/2025) | `042a943bb13294cccc768d708dec0fd3adb87b1f8bb846622c42c817515b4b16` (copia subida) | PARCIAL (estructura VERIFICADA; reglas del Anexo 11 PENDIENTES) | Estructura de reemplazo RCE |
| 13 | https://cpe.sunat.gob.pe/sites/default/files/inline-files/Estructura%20del%20Reemplazo%20RVIE%20%283%29%20%281%29.xlsx | Excel oficial: Estructura del Reemplazo RVIE, hoja "Reemplazo RVIE", 50 columnas (campos 1–33 y 41–57), conforme al Anexo 3 de R.S. 112-2021 | Versión (3); propiedades del archivo: modificado 2023-12-13; subido por el usuario 2026-10-08 | Vigente según página de estructuras (30/05/2025) | `405dc7316e2b88763b14f6c688d1da2306d5c82e54c71dc285f2c39433e050ae` (copia subida) | PARCIAL (estructura VERIFICADA; reglas globales vigentes PENDIENTES de texto consolidado) | Estructura de reemplazo RVIE |
| 14 | https://cpe.sunat.gob.pe/sites/default/files/inline-files/Plantilla%20Estructura%20No%20Domiciliados%20%281%29%20%281%29.xlsx | Excel oficial: estructura de no domiciliados | — | — | — | NO APLICABLE en V1 | No domiciliados (REQUIRES_REVIEW) |
| 15 | https://cpe.sunat.gob.pe/node/158 | Formas de acceso al SIRE (SOL, aplicativo cliente, API SUNAT) y listado de servicios API | Última modificación 19/08/2025 | Vigente | — | VERIFICADO | Credenciales API, servicios disponibles |
| 16 | https://cpe.sunat.gob.pe/sites/default/files/2026-09/Manual%20del%20servicio%20API%20del%20Registro%20de%20Ventas%20e%20Informaci%C3%B3n%20Electr%C3%B3nica.%20v31.pdf | Manual API SIRE Ventas (RVIE) | v31, actualización 28/09/2026 | Vigente | — | PARCIAL (leído hasta §5.28 de §5.37; faltan 5.29–5.37, §6 TUS y anexos) | `SunatSireClient` para RVIE |
| 17 | https://cpe.sunat.gob.pe/sites/default/files/inline-files/Manual%20de%20servicios%20Web%20Api%20-%20SIRE_Compras%20v28_0.pdf | Manual API SIRE Compras (RCE) | Control de cambios: V28, 13/08/2025. La página `node/158` enlaza el archivo sin indicar versión | Vigente según la página oficial (a fecha 2026-10-08) | — | PARCIAL (leído hasta §5.23 de 5.61, más guía de uso, control de cambios y tabla de contenido) | `SunatSireClient` para RCE |
| 18 | https://cpe.sunat.gob.pe/programa-validador-sire-pvsire | Programa Validador SIRE (PVSIRE), Módulo N.º 72 | 10/07/2026 (fragmento de búsqueda) | Vigente | — | PARCIAL (no leído completo) | Segunda capa de validación externa, opcional |
| 19 | https://www.sunat.gob.pe/orientacion/cronogramas/cronoRegistroC-V-2026.html | Cronograma de atraso de los registros electrónicos 2026 (base legal citada: Anexo II de la R.S. 281-2022/SUNAT) | Año 2026 | Vigente (2026) | — | VERIFICADO (página); R.S. 281-2022 NO leída | Plazos máximos de atraso por último dígito de RUC (ver sección 2A) |
| 20 | https://www.sunat.gob.pe/legislacion/superin/2021/112-2021.pdf y https://www.sunat.gob.pe/legislacion/superin/2022/040-2022.pdf | Texto de las resoluciones R.S. 112-2021 y 040-2022 | 30/07/2021 y 2022 | Modificadas (112-2021 en arts. 3, 4, 8, 9 y 11; 040-2022 en su disposición complementaria final cuarta) | — | 112-2021: VERIFICADO (texto original leído completo, arts. 1 a 13). 040-2022: PENDIENTE (cuerpo no leído) | Definiciones, flujo propuesta → complemento o reemplazo → preliminar → generación, ajustes, cierre |
| 28 | https://www.sunat.gob.pe/legislacion/superin/2024/000145-2024.pdf | R.S. N.º 000145-2024/SUNAT (postergación y nueva redacción del art. 3, incisos b, d, e, f; art. 4 y disposición cuarta de 040-2022). **No figura en el índice oficial de la fila 1** | Lima, 18/07/2024; vigente desde el día siguiente a su publicación | Parcialmente reemplazada por 293-2024 en el inciso e | — | VERIFICADO (texto leído) | Obligación SIRE de RER y RMT (ver sección 2A) |
| 29 | https://www.sunat.gob.pe/legislacion/superin/2024/000293-2024.pdf | R.S. N.º 000293-2024/SUNAT (nueva redacción del inciso e y nuevo inciso g del art. 3.1; art. 4 y disposición cuarta) | Lima, 23/12/2024; vigente desde el día siguiente a su publicación | Vigente salvo posteriores (217-2025, 392-2025, 0125-2026 afectan solo a principales contribuyentes según el índice) | — | VERIFICADO (texto leído) | Obligación SIRE: no principales desde 01/2025; principales desde 07/2025 (luego postergado) |
| 30 | https://www.sunat.gob.pe/legislacion/superin/2023/000204-2023.pdf | R.S. N.º 000204-2023/SUNAT (inciso c: RER y RMT obligados en SLE-PLE/Portal al 30/09/2023, desde octubre de 2023) | Lima, 25/09/2023 | Sustituida en su alcance por 145-2024 | — | PARCIAL (fragmentos de búsqueda en el dominio oficial; PDF no leído completo) | Antecedente del inciso d) de la R.S. 145-2024 |
| 31 | https://www.sunat.gob.pe/legislacion/superin/2023/000258-2023.pdf | R.S. N.º 000258-2023/SUNAT (posterga enero de 2024 a abril de 2024 para los demás obligados) | Lima, 20/12/2023 | Superada por 063-2024 y 145-2024 | — | PARCIAL (fragmentos de búsqueda; no leído completo) | Antecedente histórico |
| 32 | (sin enlace oficial verificado) | R.S. N.º 000190-2022/SUNAT (incisos a, b, c, d del art. 3.1 en su primera versión) | 2022 | Modificada por 204-2023, 258-2023, 145-2024 | — | PARCIAL: solo resumen del índice oficial (fila 1) | Antecedente histórico |
| 33 | https://busquedas.elperuano.pe/dispositivo/NL/2548699-1/pdf | R.S. Nacional Adjunta de Tributos Internos N.º 000041-2026-SUNAT/700000 (facultad discrecional: no sanciona infracciones de los numerales 2 y 10 del art. 175 del Código Tributario en los periodos agosto de 2026 a enero de 2027; prórroga hasta el 28/02/2027 para subsanar) | Índice oficial modificado 31/08/2026 | Vigente según el índice | — | PARCIAL: solo resumen del índice (PDF no leído) | Mensajes al usuario sobre atrasos; no cambia plazos de obligación |

Nota sobre numeración (corrige la solicitud): el **Anexo 2** es la propuesta/complemento RVIE y el **Anexo 8** es la propuesta/complemento RCE. El Anexo 3 es el reemplazo/comparación RVIE y el Anexo 11 es el reemplazo/comparación RCE.

## 2. Normativa tributaria base

| # | URL oficial | Norma | Fecha / versión | Vigencia | Hash | Estado | Dependencia en Profio |
|---|---|---|---|---|---|---|---|
| 21 | https://www.sunat.gob.pe/legislacion/igv/tuo.html | Índice del TUO Ley IGV e ISC (D.S. 055-99-EF) | — | — | — | VERIFICADO (índice) | Navegación a títulos |
| 22 | https://www.sunat.gob.pe/legislacion/igv/ley/capitul6.pdf | TUO Ley IGV, Capítulo VI "Del crédito fiscal" (arts. 18 a 25) | Texto incorpora D.Leg. 1540 (26/03/2022) | Falta confirmar modificaciones posteriores | — | VERIFICADO (texto leído); vigencia PARCIAL | Reglas de crédito fiscal, destino, mixtas, reintegro, saldo a favor |
| 23 | (por ubicar en sunat.gob.pe/legislacion/igv) | TUO Ley IGV: Títulos sobre ámbito, nacimiento de obligación, base imponible, tasa (art. 17), exoneraciones (apéndices I y II), inafectaciones | — | — | — | PENDIENTE | Clasificación gravado / exonerado / inafecto; tasa |
| 24 | (por ubicar) | Reglamento de la Ley del IGV (D.S. 029-94-EF), en especial art. 6 (crédito fiscal) y art. 5 num. 17 (tipo de cambio; referido por los anexos) | Art. 6.2.1 modificado por D.S. 008-2023-EF | — | — | PENDIENTE (solo fragmentos) | Documento que respalda crédito; tipo de cambio |
| 25 | (por ubicar en sunat.gob.pe/legislacion/renta) | Normas de RER y RMT (Impuesto a la Renta / D.Leg. 1269 y modificatorias) | — | — | — | PENDIENTE | `ref_tax_regimes`, límites y obligaciones por régimen |
| 26 | (por ubicar) | Reglamento de Comprobantes de Pago (R.S. 007-99/SUNAT) y R.S. 097-2012/SUNAT (catálogos 09 y 10 de tipos de nota) | — | — | — | PENDIENTE | NC/ND: tipos de nota, series |
| 27 | (por ubicar) | Norma de tipo de cambio aplicable (SBS) para operaciones en moneda extranjera | — | — | — | PENDIENTE | Regla `FX_RATE` |

## 2A. Obligación de usar SIRE y cronogramas (RER y RMT)

Tres cosas distintas, con fuentes distintas. No deben mezclarse.

### a) Cronograma de incorporación (desde qué periodo está obligado un sujeto)

Norma base: art. 3 de la R.S. 112-2021 (original: leído; texto original hoy reemplazado) con la redacción dada por R.S. 190-2022, 204-2023, 258-2023, 063-2024, 145-2024 y 293-2024. Las redacciones de 145-2024 y 293-2024 se leyeron; el resto se conoce por fragmentos.

| Supuesto (art. 3.1) | Desde el periodo | Fuente leída | A quién aplica |
|---|---|---|---|
| a) Sujetos del Anexo 7 de la R.S. 112-2021 | Julio de 2023 | Índice oficial (resumen de 190-2022) y considerandos de 145-2024 | Lista del Anexo 7 (no leída) |
| b) Quienes adquieren la obligación en el SLE-PLE o SLE-Portal entre julio de 2023 y diciembre de 2024 | El periodo en que la adquieren | R.S. 145-2024, texto del inciso b) | Obligados por R.S. 286-2009 y 379-2013 |
| c) RER o RMT obligados al SLE-PLE/Portal al 30/09/2023 | Octubre de 2023 | Fragmentos oficiales de R.S. 204-2023 | RER y RMT con esa obligación |
| **d) RER o RMT obligados a llevar el RV y el RC al 31/07/2024, no comprendidos en a, b, c** | **Agosto de 2024** | **R.S. 145-2024, texto del inciso d)** | **Régimen RER o RMT (D.Leg. 1269)** |
| e) Otros obligados al 31/12/2024, no designados principales contribuyentes, no comprendidos en a a d | Enero de 2025 | R.S. 293-2024, texto del inciso e) | Régimen general y otros no principales |
| f) Quienes adquieran la obligación desde el 01/01/2025 | Primer día del tercer mes siguiente a aquel en que adquieren la obligación, o desde el periodo en que adquieran por elección la calidad de emisor electrónico del SEE (R.S. 300-2014), lo que ocurra primero | R.S. 145-2024, texto del inciso f) | Nuevos obligados |
| g) Principales contribuyentes obligados al 31/12/2024 | Julio de 2025 (luego postergado por 217-2025, 392-2025 y 0125-2026 hasta fechas posteriores, solo resúmenes del índice) | R.S. 293-2024, texto del inciso g) | Solo principales contribuyentes (PRICOS) |
| h) Existe: R.S. Nacional Adjunta 32-2026 cita el "inciso h) del párrafo 3.1" | — | Solo cita indirecta | Texto no leído |

Condiciones y vacíos:

- El texto leído dice "obligados a llevar el Registro de Ventas e Ingresos y el Registro de Compras". **Qué RER/RMT están obligados a llevarlos** depende de normas del IGV y de Renta que no se han leído (ver sección 2, filas 24 y 25). No se debe asumir que todo RER/RMT está obligado.
- La afiliación voluntaria al SIRE existe (art. 4) y es definitiva (art. 4 de la R.S. 112-2021).
- Para una empresa, Profio debe guardar `sire_obligation_start_period` con su `source_reference`; mientras no esté confirmado por el contador, el estado es `REQUIRES_REVIEW`.

### b) Plazos máximos de atraso mensuales

- Fuente: página oficial "Cronograma de atraso de los registros electrónicos" (2026), base legal Anexo II de la R.S. 281-2022/SUNAT (no leída).
- Aplica a RVIE y RCE (la nota (*) indica que se refiere al mes al que corresponde el registro de operaciones).
- Fechas máximas por último dígito del RUC (2026, la columna 0 va primero, las demás en orden 1, 2-3, 4-5, 6-7, 8-9, Buenos Contribuyentes y UESP). Ejemplo, periodo agosto de 2026: 14-set, 15-set, 16-set, 17-set, 18-set, 21-set, 22-set. Periodo setiembre de 2026: 15-oct, 16-oct, 19-oct, 20-oct, 21-oct, 22-oct, 23-oct. Periodo octubre de 2026: 13-nov, 16-nov, 17-nov, 18-nov, 19-nov, 20-nov, 23-nov. La tabla completa de 2026 está en la página oficial; Profio debe cargarla como datos versionados, no como constantes.
- No es la fecha de pago del IGV ni de presentación del PDT 621.

### c) Fechas de otras obligaciones tributarias

- Vencimiento de declaraciones y pagos mensuales (IGV-Renta, PLAME, etc.): cronograma de obligaciones mensuales de SUNAT, **no leído**. Es un documento distinto al cronograma de atraso.
- Facultad discrecional de no sancionar (R.S. Nacional Adjunta 39-2023 y sucesivas, hasta 41-2026): evita sanciones por infracciones de los numerales 2 y 10 del art. 175 del Código Tributario bajo condiciones; no es una prórroga de la obligación ni del cronograma de atraso. Solo se leyó el resumen del índice oficial.

## 2B. Manifiesto de archivos y hashes

No hay repositorio de código en esta etapa; "archivos disponibles" son los cuatro subidos por el usuario. Los hashes identifican bytes; **no prueban autenticidad ni vigencia**.

| Archivo | Tamaño (bytes) | Fecha de subida | Origen que indica el nombre | SHA-256 |
|---|---|---|---|---|
| `Estructura_del_Reemplazo_RCE__7___1_.xlsx` | 20,067 | 2026-10-08 | Probablemente `cpe.sunat.gob.pe/estructura-de-archivos` (fila 12); no verificado | `042a943bb13294cccc768d708dec0fd3adb87b1f8bb846622c42c817515b4b16` |
| `Estructura_del_Reemplazo_RVIE__3___1___1_.xlsx` | 17,717 | 2026-10-08 | Idem (fila 13); propiedades internas: modificado 2023-12-13 | `405dc7316e2b88763b14f6c688d1da2306d5c82e54c71dc285f2c39433e050ae` |
| `anexoIII-000138-2023.pdf` | 119,040 | 2026-10-09 | `sunat.gob.pe/legislacion/superin/2023/` (fila 5) | `73366299cab1ef2824d23fc1fbfafadb3eb59b1c12727dbdcb849614ddfb7fd2` |
| `anexo-040-2022.pdf` | 1,011,418 | 2026-10-09 | `sunat.gob.pe/legislacion/superin/2022/` (fila 7) | `a84532acdf8af0ea8dbad56af6071ae21be922c5ba1f36e6f0234e9375d38c8a` |
| `anexo-112-2021.pdf` | 977,467 | 2026-10-09 | `sunat.gob.pe/legislacion/superin/2021/` (fila 2) | `9c9d484266a4eb261b7b22b5ea736dc477edd4c0827dfbc545ef81073ed6b987` |

Fecha de descarga original: desconocida (la fecha de subida es la única registrada). Versión: la del nombre del archivo y la de las propiedades internas, sin más garantía.

## 2C. Archivos que faltan y dónde están (para subirlos y calcular hash)

| Prioridad | Archivo | URL oficial (aparece en `cpe.sunat.gob.pe/node/141` o en resultados de `sunat.gob.pe`) |
|---|---|---|
| Alta | Anexo de la R.S. 112-2021 (Anexos 1 a 7 originales) | https://www.sunat.gob.pe/legislacion/superin/2021/anexo-112-2021.pdf |
| Alta | Anexos I, II, IV y V de la R.S. 138-2023 | https://www.sunat.gob.pe/legislacion/superin/2023/anexoI-000138-2023.pdf (y `anexoII`, `anexoIV`, `anexoV`) |
| Alta | Manual API RVIE v31 | https://cpe.sunat.gob.pe/sites/default/files/2026-09/Manual%20del%20servicio%20API%20del%20Registro%20de%20Ventas%20e%20Informaci%C3%B3n%20Electr%C3%B3nica.%20v31.pdf |
| Alta | Manual API RCE v28 | https://cpe.sunat.gob.pe/sites/default/files/inline-files/Manual%20de%20servicios%20Web%20Api%20-%20SIRE_Compras%20v28_0.pdf |
| Alta | R.S. 190-2022, 204-2023, 258-2023, 063-2024, 217-2025, 392-2025, 0125-2026 | `sunat.gob.pe/legislacion/superin/<año>/...` (204-2023: `.../2023/000204-2023.pdf`; 258-2023: `.../2023/000258-2023.pdf`) y enlaces del índice `node/141` |
| Media | R.S. 281-2022 y su Anexo II (cronograma de atraso) | https://www.sunat.gob.pe/legislacion/superin/2022/281-2022.pdf y https://www.sunat.gob.pe/legislacion/superin/2022/anexo2-281-2022.pdf |
| Media | R.S. 040-2022 (cuerpo) | https://www.sunat.gob.pe/legislacion/superin/2022/040-2022.pdf |
| Media | Página y manual de PVSIRE | https://cpe.sunat.gob.pe/programa-validador-sire-pvsire |

## 3. Fuentes NO autoritativas (no usadas como base)

Los resultados de búsqueda de portales de contadores, blogs, copias en Scribd/Academia y librerías de facturación de terceros se descartaron como fuente. La macro comercial de SIRE sigue siendo únicamente fixture/oráculo auxiliar.

## 4. Procedimiento para pasar una fuente a VERIFICADO

1. Descargar el archivo oficial desde `sunat.gob.pe` o `cpe.sunat.gob.pe`.
2. Guardarlo en `/docs/sources/` con nombre `<norma>_<fecha>.<ext>` y calcular SHA-256.
3. Registrar versión, vigencia y resoluciones modificatorias.
4. Resolver las ambigüedades listadas en `sire-structure.md` sección 8.
5. Cargar la versión en `sire_structure_versions` y sus tablas en `sire_parametric_tables`.
6. Cambiar el estado aquí. Solo entonces se puede escribir código que dependa de ella.
7. Revisión mensual de la página de estructuras y del índice de normas (filas 1 y 11).
