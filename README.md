<div align="center">
  <img src="marketing/hilo-icon.png" width="128" alt="Hilo app icon">

[🇬🇧 English](#english) · [🇪🇸 Español](#español)

</div>

## English <a name="english"></a>

# Hilo

Hilo is a private personal memory: you tell a memory in your own words, and the app
recognises on its own the people, places and objects that appear in it, lets you review
what it understood before saving it, and connects it to earlier memories that share any
of those elements. Everything happens on the device — no account, no cloud, no internet
connection.

## What makes it different

- **It is your memory, not a diary.** There are no forms or tags: you tell the memory the
  way you would tell it out loud, and Hilo understands who, where and what. Your words are
  kept exactly as written, never corrected or rewritten.
- **The intelligence lives on the iPhone.** Comprehension uses the system's own language
  model (Apple Intelligence) through Foundation Models. A server is never consulted, not
  even when the system offers one.
- **Nothing leaves the phone.** There is no account, no sync, no analytics and no network
  code. The app works end to end in airplane mode, and deleting really deletes, photos
  included.
- **You decide what stays.** Before saving you see what Hilo understood and correct it.
  Connections always say why they exist, and the date you see is always the one you
  wrote: the deduced year is only used for sorting.

## What it does today

- Tell a memory by typing or dictating, with an optional photo.
- Progressive comprehension of people, places and objects, which appear while Hilo
  reads, with the date in your own words.
- Review before saving: remove, rename, resolve doubts («Is José Luis José?») or
  add the date.
- Automatic connection to earlier memories, with the reason always visible («By
  Lucía»).
- Browse the memory in chronological order or by element, with search.
- An example memory to try it without writing anything, and full deletion.
- If comprehension fails, the memory is saved anyway, unanalysed, and can be read
  later. The text is never lost.
- Interface in English and Spanish, with VoiceOver, Dynamic Type up to AX5, Reduce
  Motion and Increase Contrast.

## How it is built

- **Swift 6** in language mode 6, with strict concurrency and `MainActor` by default.
- **SwiftUI** for the whole interface, **SwiftData** for the local store and
  **Foundation Models** for on-device comprehension.
- **No third-party dependencies**, neither in the app nor in the tests.
- iOS 26.4 minimum, iPhone only, portrait. Built with Xcode 27.
- A single target organised in folders with strict boundaries: `Domain` (pure rules,
  no Apple frameworks beyond Foundation), `Persistence`, `Intelligence`, `Shared`,
  `DesignSystem` and `Features`, one folder per screen.
- Everything that can be decided with certainty (canonical names, element resolution,
  ordering, connections) is a pure, tested function. The model only extracts; it never decides.
- Tests with **Swift Testing**, written before the code, with the model replaced by
  deterministic doubles. The interface is validated by hand on the device.

## Try it

1. Open `Hilo.xcodeproj` in Xcode 27 and run the `Hilo` scheme on an iPhone with Apple
   Intelligence turned on.
2. In Memory, tap **Load an example memory** to see connections without writing
   anything, or **Tell your first memory** to start your own.

The full demo walkthrough is in
[`docs/manual-validation/hackathon-delivery/end-to-end-walkthrough.md`](docs/manual-validation/hackathon-delivery/end-to-end-walkthrough.md).

## Documentation

| Path | What it holds |
|---|---|
| [`docs/specs/`](docs/specs/) | One functional spec per phase; `F0_INDEX_AND_CONSTITUTION.md` is the constitution |
| [`docs/decisions/`](docs/decisions/) | ADRs: stack, model contracts and persistence schema |
| [`docs/design/`](docs/design/) | Design tokens and visual references |
| [`docs/manual-validation/`](docs/manual-validation/) | On-device validation batteries, one per phase |
| [`CLAUDE.md`](CLAUDE.md) | Working rules for the repo |

## Español <a name="español"></a>

# Hilo

Hilo es una memoria personal privada: cuentas un recuerdo con tus propias palabras, y la
app reconoce sola a las personas, los lugares y los objetos que aparecen en él, te deja
revisar lo que ha entendido antes de guardarlo, y lo conecta con los recuerdos anteriores
que comparten alguno de esos elementos. Todo pasa en el dispositivo — sin cuenta, sin nube,
sin conexión a internet.

## Qué la hace distinta

- **Es tu memoria, no un diario.** No hay formularios ni etiquetas: cuentas el recuerdo
  como lo contarías en voz alta, y Hilo entiende quién, dónde y qué. Tus palabras se
  guardan tal cual, sin corregirlas ni reescribirlas.
- **La inteligencia está en el iPhone.** La comprensión usa el modelo de lenguaje del
  propio sistema (Apple Intelligence) a través de Foundation Models. Nunca se consulta un
  servidor, ni siquiera cuando el sistema lo ofrece.
- **Nada sale del teléfono.** No hay cuenta, ni sincronización, ni analítica, ni código de
  red. La app funciona de principio a fin en modo avión, y borrar es borrar de verdad,
  fotos incluidas.
- **Tú decides lo que queda.** Antes de guardar ves lo que Hilo ha entendido y lo corriges.
  Las conexiones siempre dicen por qué existen, y la fecha que se ve es siempre la que
  escribiste tú: el año deducido solo sirve para ordenar.

## Lo que hace hoy

- Contar un recuerdo escribiendo o dictando, con foto opcional.
- Comprensión progresiva de personas, lugares y objetos, que van apareciendo mientras
  Hilo lee, con la fecha en tus propias palabras.
- Revisión antes de guardar: quitar, renombrar, resolver dudas («¿José Luis es José?») o
  añadir la fecha.
- Conexión automática con recuerdos anteriores, con el motivo siempre visible («Por
  Lucía»).
- Recorrer la memoria por orden cronológico o por elemento, con búsqueda.
- Memoria de ejemplo para probarla sin escribir nada, y borrado total.
- Si la comprensión falla, el recuerdo se guarda igual, sin analizar, y se puede leer más
  tarde. El texto nunca se pierde.
- Interfaz en inglés y en español, con VoiceOver, Tipografía Dinámica hasta AX5, Reducir
  movimiento y Aumentar contraste.

## Cómo está hecha

- **Swift 6** en modo de lenguaje 6, con concurrencia estricta y `MainActor` por defecto.
- **SwiftUI** para toda la interfaz, **SwiftData** para el almacén local y
  **Foundation Models** para la comprensión en el dispositivo.
- **Sin dependencias de terceros**, ni en la app ni en los tests.
- iOS 26.4 como mínimo, solo iPhone y en vertical. Se compila con Xcode 27.
- Un único target organizado por carpetas con fronteras estrictas: `Domain` (reglas puras,
  sin frameworks de Apple más allá de Foundation), `Persistence`, `Intelligence`, `Shared`,
  `DesignSystem` y `Features`, una carpeta por pantalla.
- Todo lo que se puede decidir con certeza (nombres canónicos, resolución de elementos,
  orden, conexiones) son funciones puras y testeadas. El modelo solo extrae; nunca decide.
- Tests con **Swift Testing**, escritos antes que el código y con el modelo sustituido por
  dobles deterministas. La interfaz se valida a mano en el dispositivo.

## Probarla

1. Abre `Hilo.xcodeproj` con Xcode 27 y ejecuta el esquema `Hilo` en un iPhone con Apple
   Intelligence activado.
2. En Memoria, pulsa **Cargar una memoria de ejemplo** para ver conexiones sin escribir
   nada, o **Cuenta tu primer recuerdo** para empezar la tuya.

El recorrido completo de la demo está en
[`docs/manual-validation/hackathon-delivery/end-to-end-walkthrough.md`](docs/manual-validation/hackathon-delivery/end-to-end-walkthrough.md).

## Documentación

| Ruta | Qué hay |
|---|---|
| [`docs/specs/`](docs/specs/) | Una spec funcional por fase; `F0_INDEX_AND_CONSTITUTION.md` es la constitución |
| [`docs/decisions/`](docs/decisions/) | ADRs: stack, contratos del modelo y esquema de persistencia |
| [`docs/design/`](docs/design/) | Tokens de diseño y referencias visuales |
| [`docs/manual-validation/`](docs/manual-validation/) | Baterías de validación en dispositivo, una por fase |
| [`CLAUDE.md`](CLAUDE.md) | Reglas de trabajo en el repo |
