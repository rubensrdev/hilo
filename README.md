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
[`docs/validacion-manual/entrega-hackathon/recorrido-de-principio-a-fin.md`](docs/validacion-manual/entrega-hackathon/recorrido-de-principio-a-fin.md).

## Documentación

| Ruta | Qué hay |
|---|---|
| [`docs/specs/`](docs/specs/) | Una spec funcional por fase; `F0_INDICE_Y_CONSTITUCION.md` es la constitución |
| [`docs/decisions/`](docs/decisions/) | ADRs: stack, contratos del modelo y esquema de persistencia |
| [`docs/design/`](docs/design/) | Tokens de diseño y referencias visuales |
| [`docs/validacion-manual/`](docs/validacion-manual/) | Baterías de validación en dispositivo, una por fase |
| [`CLAUDE.md`](CLAUDE.md) | Reglas de trabajo en el repo |
