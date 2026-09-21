# ADR-002 — Esquema de persistencia

- **Fase**: F2
- **Estado**: Proposed
- **Opened**: 2026-09-21
- **Closed**: —
- **Reason**: —

---

## Contexto

`F2_Persistencia.md` deja abierto dónde vive la marca de «analizado» que necesita DEC-16 (comprender más tarde desde el detalle): una bandera explícita en `Recuerdo`, o derivarla de la ausencia de apariciones propuestas por la comprensión.

La propia spec de F2 exige que un recuerdo pueda guardarse "sin foto, sin fecha y sin elementos" — y ese estado es alcanzable tanto por un recuerdo nunca analizado como por uno que sí se analizó y la comprensión no encontró ningún elemento real (un recuerdo abstracto, sin personas, lugares u objetos reconocibles). Derivar la marca de la ausencia de apariciones confunde esos dos estados: el segundo volvería a ofrecer «comprender más tarde» (DEC-16) sobre algo ya resuelto, y el guardarraíl de comprensión (DEC-18, F3) que guarda "sin analizar" quedaría indistinguible de una comprensión exitosa sin hallazgos.

---

## Decisión

### 1. Bandera explícita `isAnalyzed`

`Recuerdo` guarda `isAnalyzed: Bool`. Nombre en ASCII, coherente con el resto del esquema.

**Solo dos estados persistidos.** "Comprendiendo" nunca se guarda — no se persiste nada desde un resultado parcial de la comprensión. El motivo de un fallo de comprensión no se guarda: se comunica al usuario en el momento de guardar (F3) y no se vuelve a usar después.

**Transiciones:**

| Momento | Valor |
|---|---|
| Se guarda sin analizar, o cualquier error de comprensión (guardarraíl, rechazo, desbordamiento, idioma no soportado, sin respuesta) | `false` |
| La comprensión termina, con o sin elementos encontrados | `true` |
| Se edita el texto del recuerdo (DEC-19: editar no reanaliza) | Sin cambio |
| Recuerdos de la memoria de ejemplo (F2, contrato 5) | Nacen en `true` |

### 2. Por qué no la alternativa derivada

Derivar "analizado" de "sin apariciones propuestas" ata dos preguntas distintas — *¿se intentó comprender?* y *¿qué encontró la comprensión?* — a una sola señal, y las apariciones no bastan para separarlas: un recuerdo con cero apariciones puede no haberse analizado nunca, o haberse analizado y no encontrar nada. Solo la bandera explícita mantiene los dos estados observables por separado sin lógica adicional en ningún sitio.

### 3. Nombres de las clases `@Model`: sufijo `Record`

`Domain` ya usa `Memory`, `Element` y `Appearance` como nombres de struct, en el mismo target (una sola unidad de compilación, D1 de `ADR-000`). Las clases `@Model` de F2 necesitan un nombre distinto para no colisionar: `MemoryRecord`, `ElementRecord`, `AppearanceRecord`, `DiscardRecord`.

El nombre de la clase es el nombre de la entidad en el almacén subyacente, y el MVP no tiene historia de migraciones — así que este nombre queda **fijado** desde F2.1: cambiarlo más adelante significaría reinstalar, no migrar.

### 4. Qué entra ya en el esquema de F2 y qué espera a su fase

Contrato 1 de F2 lista, para `Elemento`, "el retrato con sus fuentes y su huella de vigencia (lo escribe F7; aquí solo existe el hueco)" y, para `Descarte`, el par (tipo de hueco, elemento). Ninguno de los dos está resuelto del mismo modo:

- **El retrato no entra en F2.** Su forma exacta (qué cuenta como fuente, cómo se mide la huella de vigencia) es de F7 y no está decidida. Añadir un campo ahora sin esa forma arriesga un `@Model` con un shape equivocado. **Condición para F7**: lo que añada al esquema de `ElementRecord` (o una entidad nueva, p. ej. `PortraitRecord`) debe ser **aditivo** — propiedades opcionales o una entidad nueva, nunca cambiar o quitar una columna existente — para que SwiftData lo cubra con una migración ligera (`MigrationStage.lightweight`, disponible desde iOS 17.0, confirmado con Cupertino) sin necesitar un plan de migración a medida. F7 deja constancia de si SwiftData la infirió sola o hizo falta declarar la etapa ligera explícitamente.
- **El descarte sí entra en F2.1**, como `DiscardRecord`, porque su forma ya está cerrada en `§12` (tipo de hueco + elemento) aunque el catálogo de tipos de hueco todavía no lo esté (hueco abierto A2 de F10). `gapType` se guarda como `String` ASCII, un contenedor libre: F2 no inventa valores de ejemplo, F10 define el catálogo real y lo mapea a este campo sin tocar el esquema. Al borrar el elemento (regla 11), sus descartes se borran con él — cascada declarada en `ElementRecord.discards`, verificada por test en F2.1.

---

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| Derivar de la ausencia de apariciones propuestas | Confunde "nunca analizado" con "analizado sin hallazgos" — ver Decisión §2 |
| Guardar el motivo del último fallo de comprensión | No tiene consumidor después del momento de guardar (F3 lo comunica una vez); guardarlo sería estado sin uso |
| Un tercer estado persistido para "comprendiendo" | Ninguna vista lee un recuerdo a mitad de una comprensión en curso — la comprensión vive en memoria de la sesión, no en el esquema |
| Añadir ya un placeholder del retrato en `ElementRecord` | Sin la forma exacta de F7, el placeholder tendría que adivinarse y probablemente se tira; sin historia de migraciones, esperar no cuesta nada — ver Decisión §4 |
| Esperar a F10 para crear `DiscardRecord` | Contrato 1 de F2 ya pide la entidad con su forma cerrada; solo el catálogo de valores de `gapType` espera a F10, no la entidad |

---

## Consecuencias

- F2.1 declara `isAnalyzed: Bool` en el esquema de `Recuerdo`, y fija `MemoryRecord`/`ElementRecord`/`AppearanceRecord`/`DiscardRecord` como nombres de las cuatro entidades.
- F2.5 (memoria de ejemplo) inicializa cada recuerdo cargado con `isAnalyzed = true`.
- F3 escribe `false` en el camino de guardar-sin-analizar y en cada caso de su contrato 4 (guardarraíl, rechazo, desbordamiento, idioma no soportado, sin respuesta), y `true` al terminar una comprensión con éxito, tenga o no elementos.
- F4/F5 leen la bandera para decidir si ofrecer «comprender más tarde» (DEC-16); no necesitan mirar las apariciones para eso.
- F7 añade el retrato de forma aditiva sobre `ElementRecord` o como entidad nueva, nunca modificando una columna existente.
- F10 define el catálogo de `gapType` y lo mapea al `String` ya persistido por `DiscardRecord`, sin tocar el esquema de F2.
- Tests de F2.1: un recuerdo analizado sin elementos es distinguible de uno no analizado; editar el texto no altera la bandera; cargar el ejemplo deja todo en `true`; borrar un elemento borra sus descartes.

---

## Coste de reversión

**Bajo.** Es una columna booleana más en el esquema, sin migración que perder porque el MVP no tiene historia de migraciones (reinstalar). Revertir a la derivación exigiría además auditar F3/F4/F5 para separar de otra forma los dos estados que hoy distingue la bandera. Renombrar las clases `Record` después de F2.1 tiene el mismo coste que cualquier cambio de esquema en este proyecto: reinstalar, no migrar.
