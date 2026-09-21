# ADR-002 — Esquema de persistencia

- **Fase**: F2
- **Estado**: Accepted
- **Opened**: 2026-09-21
- **Closed**: 2026-09-21
- **Reason**: Bandera `isAnalyzed` explícita y nombres `Record` fijados en F2.1; esquema completo de las cuatro entidades cerrado con F2.1–F2.6; riesgo de reinstalación por cambio de esquema aceptado por Rubén

---

## Contexto

`F2_Persistencia.md` dejaba abierto dónde vive la marca de «analizado» que necesita DEC-16 (comprender más tarde desde el detalle): una bandera explícita en `Recuerdo`, o derivarla de la ausencia de apariciones propuestas por la comprensión. Ese hueco se cerró en F2.1, al abrir la fase — es la sección 2 de este ADR, entonces `Proposed`.

`F0_INDICE_Y_CONSTITUCION.md` asigna a este ADR el alcance «Esquema, identidad entre actores, almacenamiento de fotos» (tabla de fases y tabla de correspondencia fase↔spec↔ADR), más amplio que solo la bandera. Este cierre, con F2.1–F2.6 ya implementadas y 119 tests en verde, completa ese alcance: qué guarda cada una de las cuatro entidades, qué cruza la frontera del actor de modelo, cómo se borra la foto externa, y qué implica no tener historia de migraciones ahora que existe un esquema real con el que reinstalar de verdad tiene coste.

**Nota sobre el registro de decisiones.** `docs/specs/06_registro_decisiones.md` no existe en este repositorio, y no encontré ningún fichero equivalente: `DEC-37` y `DEC-38` no aparecen citadas en ninguna spec ni en ningún otro documento del repo. Dentro del repo solo pude verificar `DEC-27` con descripción («metadatos de la foto», en F2 y F4) y `DEC-08` citada sin descripción (F0.1, F1, F2). Asumo que el registro completo vive fuera de este repositorio (la Idea Especificada v2.3, que `CLAUDE.md` ya señala como referencia externa para conflictos de producto) y uso el número y el contenido de DEC-37 y DEC-38 tal como se me indicaron al pedir este cierre. Avisar si el número o el contenido no coinciden con el registro real.

---

## Decisión

### 1. Cuatro entidades, ninguna conexión almacenada

| Entidad | Propiedades | Identidad |
|---|---|---|
| `MemoryRecord` | `id: UUID` (única), `narrative: String`, `dateText: String?`, `deducedYear: Int?`, `photoData: Data?` (almacenamiento externo), `savedAt: Date`, `isAnalyzed: Bool`, `isExample: Bool` | `id` único, comparado con el `MemoryID` del dominio |
| `ElementRecord` | `id: UUID` (única), `displayName: String`, `canonicalName: String`, `type: ElementType`, `aliases: [String]` | `id` único, comparado con el `ElementID` del dominio |
| `AppearanceRecord` | `memory: MemoryRecord?`, `element: ElementRecord?`, `role: String?`, `status: RecognitionStatus` | Sin `id` propio: vive de su relación con un recuerdo y un elemento, ambos con cascade |
| `DiscardRecord` | `gapType: String`, `element: ElementRecord?` | Sin `id` propio: vive de su relación (opcional) con un elemento |

`AppearanceRecord` cuelga de `MemoryRecord.appearances` (`deleteRule: .cascade`, inversa de `AppearanceRecord.memory`) y de `ElementRecord.appearances` (mismo cascade, inversa de `AppearanceRecord.element`). `DiscardRecord` cuelga de `ElementRecord.discards` con el mismo cascade. Ninguna de las dos necesita `id` propio porque nunca se referencian por identificador suelto: se buscan siempre a través de su recuerdo o su elemento.

**Las conexiones no se almacenan.** `MemoryConnections.connected(to:appearances:)` (`Hilo/Domain/MemoryConnection.swift`, F1) las deduce en el momento de la lectura a partir de la lista de `Appearance` que expone `PersistenceActor.fetchAppearances()`. Guardar la conexión aparte crearía una segunda fuente de verdad que se desincroniza en cuanto se borra un recuerdo o se quita una aparición — el mismo argumento que ya cerró esta alternativa en `ADR-000`, confirmado ahora con el esquema real delante.

El nombre canónico se guarda (`ElementRecord.canonicalName`) porque es lo que se compara en cada resolución, pero lo calcula el dominio: `PersistenceActor.save(_:Element)` llama a `CanonicalName.of(element.displayName)` antes de insertar — la persistencia nunca deriva el canónico por su cuenta.

### 2. DEC-37 — `isAnalyzed` es una bandera explícita, no derivada

`MemoryRecord.isAnalyzed: Bool`, puesta explícitamente por quien llama a `PersistenceActor.save(_:Memory, photoData:, isAnalyzed:, isExample:)` — nunca calculada a partir de si el recuerdo tiene o no apariciones.

**Solo dos estados persistidos.** «Comprendiendo» nunca se guarda: no se persiste nada desde un resultado parcial de la comprensión. El motivo de un fallo de comprensión tampoco se guarda — se comunica al usuario en el momento de guardar (F3) y no se vuelve a usar después.

**Transiciones:**

| Momento | Valor |
|---|---|
| Se guarda sin analizar, o cualquier error de comprensión (guardarraíl, rechazo, desbordamiento, idioma no soportado, sin respuesta) | `false` |
| La comprensión termina, con o sin elementos encontrados | `true` |
| Se edita el texto del recuerdo (DEC-19: editar no reanaliza) | Sin cambio |
| Recuerdos de la memoria de ejemplo (F2, contrato 5) | Nacen en `true` |

**Por qué bandera y no derivación**: un recuerdo con cero apariciones puede no haberse analizado nunca, o haberse analizado y no encontrar nada — un relato sin personas, lugares ni objetos con nombre. Derivar la marca de la ausencia de apariciones propuestas ata dos preguntas distintas (¿se intentó comprender? / ¿qué encontró la comprensión?) a una sola señal que no basta para separarlas: el segundo caso volvería a ofrecer «comprender más tarde» (DEC-16) sobre algo ya resuelto, y el guardarraíl de comprensión (DEC-18, F3) quedaría indistinguible de una comprensión exitosa sin hallazgos. Solo la bandera explícita mantiene los dos estados observables por separado, sin lógica adicional en ningún sitio.

### 3. DEC-38 — sufijo `Record`, retrato diferido a F7, `gapType` como `String`

**Sufijo `Record`.** `Domain` ya usa `Memory`, `Element` y `Appearance` como nombres de struct, en el mismo target (una sola unidad de compilación, D1 de `ADR-000`). Las clases `@Model` de F2 necesitan un nombre distinto para no colisionar, y lo hacen visible en el propio nombre del tipo, no solo en la carpeta: `MemoryRecord`, `ElementRecord`, `AppearanceRecord`, `DiscardRecord`. El nombre de la clase es el nombre de la entidad en el almacén subyacente, y queda fijado desde F2.1: cambiarlo más adelante significa reinstalar, no migrar (regla general del punto 7).

**El retrato no entra en F2.** El contrato 1 de la spec asigna al elemento «el retrato con sus fuentes y su huella de vigencia (lo escribe F7; aquí solo existe el hueco)», pero `ElementRecord`, tal como quedó en F2.1–F2.6, no declara ninguna propiedad relacionada — ni siquiera un campo opcional vacío. Su forma exacta (qué cuenta como fuente, cómo se mide la huella de vigencia) es de F7 y no está decidida; añadir un campo ahora sin esa forma arriesga un `@Model` con una forma equivocada. **Condición para F7**: lo que añada al esquema de `ElementRecord` (o una entidad nueva, p. ej. `PortraitRecord`) debe ser **aditivo** — propiedades opcionales o una entidad nueva, nunca cambiar o quitar una columna existente — para que SwiftData lo cubra con una migración ligera (`MigrationStage.lightweight(fromVersion:toVersion:)`, disponible desde iOS 17.0, confirmado con Cupertino) sin necesitar un plan de migración a medida. F7 deja constancia de si SwiftData la infirió sola o hizo falta declarar la etapa ligera explícitamente — no se asume que funcione sin comprobarlo en el dispositivo (punto 7).

**`DiscardRecord` sí entra en F2.1**, porque su forma ya está cerrada en §12 (tipo de hueco + elemento) aunque el catálogo de tipos de hueco todavía no lo esté (F10, fuera de alcance explícito de F2). `gapType` se guarda como `String` ASCII, un contenedor libre: F2 no inventa valores de ejemplo, F10 define el catálogo real y lo mapea a este campo sin tocar el esquema. Al borrar el elemento (regla 11), sus descartes se borran con él — cascada declarada en `ElementRecord.discards`, verificada por test en F2.1.

### 4. Marca de ejemplo en el propio recuerdo (B11)

`MemoryRecord.isExample: Bool`. El contrato 1 lo dice explícito: «La memoria de ejemplo se distingue por una marca en el recuerdo, no por una entidad aparte (B11)». No hay una entidad `ExampleMemoryRecord` separada: son `MemoryRecord` normales, filtrados por `isExample` (`PersistenceActor.fetchExampleMemoryRecords()`). Al borrar el ejemplo (`deleteExampleMemory()`, F2.5), se borran esos recuerdos y se llama una sola vez a `cleanOrphanedElements()`, que aplica `OrphanElements.among(_:appearances:)` (F1, reglas 11+12): un elemento del ejemplo que todavía tenga una aparición real sobrevive, con solo esa aparición.

### 5. Identidad entre actores

`PersistenceActor` es el único `@ModelActor` de la app (contrato 2: único punto de escritura). Lo que cruza su frontera nunca es un `@Model`:

- **Entrando**: los métodos `save` reciben tipos de dominio `Sendable` (`Memory`, `Element`, `Appearance`, con sus envoltorios `MemoryID`/`ElementID`) y `Data` simple para la foto — nunca un `MemoryRecord`/`ElementRecord`/`AppearanceRecord` construido fuera del actor.
- **Saliendo**: `fetchMemories()`, `fetchElements()` y `fetchAppearances()` traducen cada `@Model` a su tipo de dominio (`Self.memory(from:)`, `Self.element(from:)`, `Self.appearance(from:)`) antes de devolver el array — el `@Model` nunca sale del actor.

Esto es exactamente la regla no negociable de `CLAUDE.md` («los modelos SwiftData no son `Sendable`; nunca se pasa un modelo entre actores»), y la ejercitan tanto `DomainTypesIsolationTests` (F1, valores de dominio cruzando una tarea `detached`) como el conjunto de `PersistenceActorTests` (F2.2, ida y vuelta `Sendable` por el actor).

### 6. Foto como almacenamiento externo, sin metadatos (DEC-27)

`MemoryRecord.photoData: Data?` lleva `@Attribute(.externalStorage)`. `PhotoStripper.stripMetadata(from:)` (`Hilo/Persistence/PhotoStripper.swift`) elimina todos los metadatos — EXIF y ubicación incluidos — reconstruyendo la imagen sin ningún diccionario de propiedades, antes de que `PersistenceActor.save(_:Memory...)` inserte el registro. Solo se guardan los píxeles.

Al borrar (`deleteMemory(id:)` o `wipeAllData()`, F2.6), se borra el `MemoryRecord` propietario y se guarda el contexto; SwiftData libera el fichero externo asociado como parte de ese mismo guardado. Verificado en el test de F2.6 con un contenedor real en disco, midiendo el tamaño en bytes del directorio del store **excluyendo los ficheros del propio store SQLite** (`test.store`, `test.store-wal`, `test.store-shm`): el fichero SQLite no se encoge al borrar filas — sus páginas libres se reutilizan, no se truncan —, así que medir el directorio completo sin esa exclusión da una falsa alarma. Solo el resto del directorio, que es donde vive el dato externo, tiene que volver a su tamaño de línea base.

### 7. Sin migraciones — consecuencias

El alcance de F2 ya excluye migraciones («No hay historia de migración en el MVP»). `PersistenceContainer.make(inMemory:)` construye un único `Schema` sin versión, sin `VersionedSchema` ni `SchemaMigrationPlan`.

- **Los cambios aditivos** (una propiedad opcional nueva, una entidad nueva — el caso del retrato en el punto 3) dependen de la migración ligera que SwiftData infiere por su cuenta. Esto **no está verificado hoy**: quien la use primero (F7, para el retrato) tiene que comprobar en el dispositivo real, con un store que ya tenga datos guardados, que esa migración inferida abre la base antigua sin problema. No se da por hecha.
- **Los cambios no aditivos** (renombrar o quitar una propiedad, cambiar un tipo, cambiar la cardinalidad o la regla de borrado de una relación — el caso de renombrar cualquiera de las cuatro clases `Record`) obligan a reinstalar: el store antiguo no abre contra el esquema nuevo.
- **Comportamiento actual si el contenedor no abre**: `HiloApp.swift` lo trata como un error fatal de arranque —

  ```swift
  static let container: ModelContainer = {
    do {
      return try PersistenceContainer.make(inMemory: false)
    } catch {
      fatalError("No se pudo crear el ModelContainer: \(error)")
    }
  }()
  ```

  No hay pantalla de recuperación ni aviso al usuario: la app se cierra de golpe en el arranque. Este ADR documenta ese comportamiento tal como está implementado; no lo cambia.

**Decisión de Rubén (2026-09-21): se acepta el riesgo.** No hay `VersionedSchema` ni `SchemaMigrationPlan` en el MVP. Los datos del dispositivo de demo son desechables hasta el ensayo final de la semana; a partir del ensayo, el esquema se congela, y cualquier cambio posterior sigue las dos reglas de arriba tal cual.

---

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| `isAnalyzed` derivado de la ausencia de apariciones propuestas | Confunde «nunca analizado» con «analizado sin hallazgos» — ver Decisión §2 |
| Guardar el motivo del último fallo de comprensión | No tiene consumidor después del momento de guardar (F3 lo comunica una vez); guardarlo sería estado sin uso |
| Un tercer estado persistido para «comprendiendo» | Ninguna vista lee un recuerdo a mitad de una comprensión en curso — la comprensión vive en memoria de la sesión, no en el esquema |
| Reservar ya en F2 un campo vacío para el retrato en `ElementRecord` | Sin la forma exacta de F7, el placeholder tendría que adivinarse y probablemente se tira; sin historia de migraciones antes del ensayo, esperar no cuesta nada — ver Decisión §3 |
| Esperar a F10 para crear `DiscardRecord` | Contrato 1 de F2 ya pide la entidad con su forma cerrada; solo el catálogo de valores de `gapType` espera a F10, no la entidad |
| `gapType` como `enum` en `Domain` ya en F2 | Congelaría una taxonomía que F10 todavía no ha diseñado |
| Una entidad `ExampleMemoryRecord` separada | B11 exige que un elemento del ejemplo sobreviva mezclado con recuerdos reales del usuario; una entidad aparte duplicaría la deducción de conexiones (F1, contrato 4) para dos tipos de recuerdo, cuando una sola marca (`isExample`) sobre el mismo `MemoryRecord` basta |
| `VersionedSchema` + `SchemaMigrationPlan` desde ya | Nadie tiene datos reales de usuario todavía. Escribir un plan de migración que no se ejercita antes del ensayo final no se amortiza en una semana; se revisa si el proyecto sigue tras el hackathon |

---

## Consecuencias

- F2.1 declaró `isAnalyzed: Bool` en el esquema de `MemoryRecord`, y fijó `MemoryRecord`/`ElementRecord`/`AppearanceRecord`/`DiscardRecord` como nombres de las cuatro entidades.
- F2.5 (memoria de ejemplo) inicializa cada recuerdo cargado con `isAnalyzed = true` e `isExample = true`.
- F3 escribe `false` en el camino de guardar-sin-analizar y en cada caso de su contrato 4 (guardarraíl, rechazo, desbordamiento, idioma no soportado, sin respuesta), y `true` al terminar una comprensión con éxito, tenga o no elementos.
- F4/F5 leen la bandera para decidir si ofrecer «comprender más tarde» (DEC-16); no necesitan mirar las apariciones para eso.
- **F7** añade los campos del retrato a `ElementRecord` (o a una entidad nueva) de forma aditiva, y verifica en el dispositivo real, con datos ya guardados, que la migración ligera inferida por SwiftData abre el store existente.
- **F10** define el catálogo cerrado de tipos de hueco y construye los `gapType: String` de `DiscardRecord`; nada del esquema de F2 restringe ese catálogo por adelantado.
- **Cualquier cambio no aditivo de esquema antes del ensayo final** obliga a reinstalar el dispositivo de demo — riesgo aceptado, punto 7.
- Los tests de persistencia usan `PersistenceContainer.make(inMemory: true)` en toda la suite salvo una excepción: el test de borrado total de F2.6 necesita un contenedor real en disco para observar el tamaño del almacenamiento externo, y limpia su directorio temporal al terminar.
- Tests de F2.1: un recuerdo analizado sin elementos es distinguible de uno no analizado; editar el texto no altera la bandera; cargar el ejemplo deja todo en `true`; borrar un elemento borra sus descartes.
- Si el proyecto sigue tras el hackathon, este ADR se revisa junto con `ADR-000` al decidir si se adopta `VersionedSchema`.

---

## Coste de reversión

| Decisión | Coste |
|---|---|
| `isAnalyzed` como bandera explícita (DEC-37) | **Bajo.** Una columna booleana más; revertir a la derivación exigiría auditar F3/F4/F5 para separar de otra forma los dos estados que hoy distingue la bandera, pero no toca la firma pública del actor |
| Sufijo `Record` (DEC-38) | **Bajo mecánicamente hasta el ensayo final** (renombrar toca `Persistence/` y sus tests, pero sin datos reales que perder). **Alto después**: es un cambio no aditivo, obliga a reinstalar y perder lo guardado |
| Retrato diferido a F7 (DEC-38) | **Bajo ahora.** Se vuelve alto en cuanto F7 escriba datos de retrato reales sobre el esquema |
| `gapType` como `String` (DEC-38) | **Bajo mientras F10 no exista.** Pasar a `enum` después de que F10 escriba datos reales exige migrar datos, no solo esquema |
| Las cuatro entidades y sus relaciones (§1) | **Bajo hasta el ensayo final** (datos desechables). **Alto después**: cambiarlas exige reinstalar y perder lo guardado |
| Sin migraciones (`VersionedSchema`) | **Medio.** Adoptarlo más adelante no exige rehacer las cuatro entidades, solo empezar a versionarlas desde ese punto |
