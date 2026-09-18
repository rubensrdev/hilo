# ADR-000 — Stack tecnológico, aislamiento por defecto y reglas del kit

- **Fase**: F0
- **Estado**: Accepted
- **Opened**: 2026-09-17
- **Closed**: 2026-09-17
- **Reason**: Stack fijado; D1 = carpeta en target único, D4 = Xcode 26, D5 = iOS 26.0; reglas del kit resueltas

---

## Contexto

Hilo es la entrega de un hackathon de una semana a tiempo parcial. Es una app iOS nativa, sin App Store por ahora, construida con Spec-Driven Development y TDD en Claude Code.

Tres cosas condicionan el stack:

- **La inteligencia en el dispositivo es el producto** (Idea v2.3 §1.2). Sin Foundation Models no queda un Hilo peor, queda otra cosa.
- **Nada sale del teléfono** (§11.3). Sin red, sin cuentas, sin sincronización.
- **Una semana.** Toda capa o ceremonia que no pague su coste en ese plazo sobra.

Hay además tres motivos para fijar esto ahora. El agente necesita un documento al que acudir cuando dude qué tecnología usar. El aislamiento por defecto no se puede cambiar con el proyecto empezado sin revisar cada tipo. Y el kit Agentic trae reglas vinculantes que nadie ha contrastado para este proyecto.

---

## Decisión

### 1. Plataforma y toolchain

| Tema | Decisión |
|---|---|
| Dispositivo | iPhone. Sin iPad, Mac, Watch ni visionOS |
| Orientación | Solo vertical |
| Versión mínima | **iOS 26.0** (D5) |
| Generación de SDK | **Xcode 26 · SDK iOS 26** (D4) |
| Lenguaje | Swift 6.2 o superior, modo de lenguaje Swift 6 |
| Dependencias | Ninguna de terceros, ni en la app ni en los tests. Sin excepción |

**D4 · Generación de SDK: Xcode 26 con SDK iOS 26.** El SDK coincide con la versión mínima, así que el compilador impide usar una API de iOS 27 y la regla de §11.4 la vigila la herramienta, no la revisión. Descartado Xcode 27 (Swift 6.4, SDK iOS 27) para el hackathon: toolchain recién publicado en una semana crítica y APIs visibles por encima del mínimo. Si Hilo sigue después, se revisa antes de abril de 2027, cuando App Store exigirá el SDK de iOS 27.

**D5 · Versión mínima: iOS 26.0.** Según `02_stack`, `contextSize` y `tokenCount(for:)` llegan en iOS 26.4; se verifica con Cupertino MCP en F0.2. La consecuencia es menor de lo que parece: **el tope de recuperación es una constante medida en F0.2, no un cálculo en tiempo de ejecución**, así que el código de la app no necesita leer la ventana ni contar tokens. Si alguna medición en ejecución resultase imprescindible, va detrás de una comprobación de disponibilidad y se justifica en `ADR-001`.

### 2. Concurrencia

| Ajuste de build | Valor |
|---|---|
| Swift Language Version | Swift 6 |
| Strict Concurrency Checking | Complete |
| Default Actor Isolation | **MainActor** |
| Approachable Concurrency | YES |

**Por qué `MainActor` por defecto.** Casi toda la superficie de Hilo es interfaz, estado observable y contexto principal de SwiftData. Con `MainActor` por defecto, ese código no necesita anotaciones, y se evita el ruido de falsos positivos en código que en realidad es secuencial. El trabajo que no pertenece al actor principal existe, pero está acotado: dominio puro, escrituras de persistencia en segundo plano y consumo del modelo. Ese trabajo sale **de forma explícita**, y queda visible en revisión.

**Reglas que se derivan:**

- El trabajo pesado sale del actor principal con `@concurrent` o con actores dedicados.
- Los modelos persistentes no son `Sendable`. Entre actores viajan identificadores persistentes o valores `Sendable` extraídos, nunca modelos.
- Las escrituras fuera del actor principal van por un actor de modelo.
- El streaming del modelo se consume en una tarea ligada a la vista y se cancela al salir de la pantalla.
- Solo `async`/`await`. `@Observable` en lugar de `ObservableObject`.

**D1 · Salida del dominio puro: carpeta `Domain/` en el target único, con `nonisolated` explícito.** Con `MainActor` por defecto, un `struct` o `enum` queda aislado al actor principal salvo que se diga lo contrario. Por eso cada tipo y función de `Domain/` se declara `nonisolated` y sus tipos valor son `Sendable`. Es una sola unidad de compilación y encaja con la Skill `nonisolated`, que documenta este caso.

Lo que el compilador **no** protege con esta opción, y por tanto se protege de otra forma:

- **Una anotación olvidada** deja el tipo en `MainActor` sin error inmediato. Los tests del dominio llaman a su API desde contexto no aislado, de modo que el olvido falla en test y no en producción.
- **Las importaciones prohibidas en `Domain/`** (SwiftData, SwiftUI, FoundationModels, PhotosUI) no las impide el compilador. Las vigila `revisor-constitucion` en cada cierre y un hook de comprobación de importaciones (Fase 4 de la guía).

Descartado el paquete local: garantiza la frontera por compilación, pero añade visibilidad `public`, un segundo sitio de tests y un límite de módulo que una semana no amortiza.

### 3. Reglas del kit Agentic no contrastadas

El kit trae estas tres reglas como vinculantes, pero vienen de un solo proyecto de origen. Ninguna se aplica por omisión: aquí queda qué se hace con cada una.

| Regla del kit | Decisión | Por qué |
|---|---|---|
| **Bifurcación iPad/iPhone por `userInterfaceIdiom` en la raíz** | **Se rechaza** | Hilo es solo iPhone. Bifurcar por idioma de interfaz añade una rama que nunca se ejecuta y que un agente acabará rellenando |
| **Colores con cuatro apariencias obligatorias en el catálogo** (claro, oscuro, claro con más contraste, oscuro con más contraste) | **Se adopta** | No es herencia del kit: la Fase 0.4 del método ya exige decidir las cuatro apariencias en `tokens.md` antes de diseñar, y `tokens.md` las declara todas con su ratio |
| **Carga inicial vía `modelContainer(_:onSetup:)` en lugar de `.task`** | **Se rechaza** | La firma que cita el kit no existe tal cual. La API real es `modelContainer(for:inMemory:isAutosaveEnabled:isUndoEnabled:onSetup:)`, que crea el contenedor por su cuenta. Hilo necesita el contenedor creado explícitamente por la app, para compartirlo con el actor de modelo de las escrituras en segundo plano, e inyectado con `modelContainer(_:)`. Y Hilo no tiene carga inicial: la memoria de ejemplo se carga a petición del usuario (§9.2, S7), no al arrancar |

### 4. Frameworks por responsabilidad

| Responsabilidad | Framework | Condición |
|---|---|---|
| Interfaz | SwiftUI + Observation | Nunca UIKit ni representables |
| Navegación | `NavigationStack` · `TabView` con dos destinos | §10.1 |
| Persistencia | SwiftData | Contenedor creado por la app. Fotos como datos externos |
| Comprensión, interpretación y redacción | Foundation Models | Salida estructurada con tipos generables. Streaming para la aparición progresiva. Una sesión por generación, sin historial |
| Foto | `PhotosPicker` + `Transferable` | La foto nunca se analiza. Metadatos según D3 (F0) |
| Localización | String Catalogs | Inglés base, español completo |
| Tests | Swift Testing | Sin tests de UI de ningún tipo |
| Serialización | `Codable` | `JSONSerialization` prohibido |
| Tejido | SwiftUI (`Canvas` o `Layout` propio) | Estático y determinista |
| Red | — | Ninguna. La app funciona entera en modo avión |

**Foundation Models, reglas fijas:**

- **No se codifica el tamaño de la ventana de contexto.** Se lee del sistema y se mide. El tope de recuperación sale de la medición de la F0.2 y queda en `ADR-001`.
- **Tres usos, tres contratos cerrados:**
  - extracción de un relato: elementos, tipo, papel, texto de la fecha y año deducido;
  - interpretación de la pregunta: nombres, tipo opcional e intervalo de años opcional;
  - redacción de la respuesta y del retrato.
- **Desbordamiento de contexto, guardarraíles, rechazo e idioma no soportado son estados de producto, no excepciones.** En la captura, todos acaban en «guardar sin analizar y decir por qué».
- **Sin interfaz para la ausencia del modelo** (§11.4). Aun así, el código no falla si el modelo no responde: cae al mismo camino que un error de comprensión.
- **Los servicios de inteligencia van detrás de protocolos**, con dobles deterministas en los tests.
- **Sin derivación a servidor**, aunque el sistema la ofrezca.

### 5. Arquitectura

Sin capas ceremoniales. Cuatro zonas con responsabilidades separadas:

| Zona | Contiene | No puede |
|---|---|---|
| **Domain** | Tipos valor, reglas de §13, nombre canónico, parecerse, resolución, recuperación (pasos 1 y 3), orden y tope, vigencia del retrato, detección de huecos | Importar SwiftData, SwiftUI o Foundation Models |
| **Persistence** | Esquema SwiftData, actor de modelo, extracción de valores `Sendable` para el dominio, borrado total, memoria de ejemplo | Contener reglas de producto |
| **Intelligence** | Protocolos y sus implementaciones sobre Foundation Models | Decidir qué recuerdos responden a una pregunta |
| **Features** | Una carpeta por pantalla de §10.2, más `DesignSystem` con los tokens | Decidir nada: leen estado y emiten intenciones |

`Domain`, `Persistence`, `Intelligence` y `Features` son carpetas del único target de la app (D1).

### 6. Nivel de adopción de infraestructura

Ratificado (D2 de F0):

- **Base del nivel 2:** constitución podada, `swiftui-moderno`, `concurrencia-swift`, `apis-modernas`, `revisor-constitucion` y los cinco hooks por defecto, parcheados.
- **Añadidos a ese nivel:**
  - ciclo SDD con ADRs solo para decisiones caras de revertir;
  - `tests-de-verdad` con `ingeniero-tests`;
  - `accesibilidad-ios` con `auditor-accesibilidad`.
- **Resto de Skills:** `swiftdata` y `foundation-models`, esta escrita desde cero.
- **Infraestructura propia:** `nonisolated` recortada, `xcode`, `cupertino` y `design`.
- **Fuera:** `seguridad-apple` y `auditor-seguridad`. Cubren secretos, autenticación, red y pagos, y Hilo no tiene ninguno. La privacidad local se protege con el principio VIII de la constitución.
- **Fuera:** las Skills de dominio de la Parte B del catálogo.

---

## Alternativas descartadas

| Alternativa | Por qué no |
|---|---|
| **`nonisolated` como aislamiento por defecto** | Invierte la carga: la mayor parte del código, que es interfaz y estado observable, necesitaría anotarse, para ahorrar anotaciones en la parte más pequeña. El stack de Rubén lo fija en `MainActor` |
| **Core Data** | SwiftData cubre el esquema de §12 sin ceremonia. Core Data solo aportaría control que una semana no puede aprovechar |
| **Transcripción propia del dictado** | Es la ampliación 1 de §14.3. En el MVP el dictado es del sistema (§9.1) |
| **Framework NaturalLanguage para extraer entidades** | Reconoce nombres de persona, lugar y organización, pero no objetos con carga narrativa, ni papeles, ni el año deducido de una fecha contada en palabras. El contrato de extracción necesita las tres cosas en una sola pasada (§7.5). Se revisa en la F0.2 si el modelo resulta insuficiente en algo concreto |
| **Guardar las conexiones entre recuerdos** | §12: la conexión se deduce, no se almacena. Guardarla crea una segunda fuente de verdad que se desincroniza al borrar o quitar elementos |
| **Una sesión del modelo con historial para preguntas encadenadas** | La regla 22 prohíbe conservar preguntas. Además, el contexto crecería justo en la ventana más pequeña del stack |
| **`seguridad-apple` + `auditor-seguridad`** | Ver §6 |

---

## Consecuencias

- **F0.1** crea el proyecto con Xcode 26, versión mínima iOS 26.0, los ajustes de §2 y las carpetas de §5 en un único target.
- **`tokens.md`** define cada color semántico en sus cuatro apariencias, con su ratio de contraste declarado.
- **F0.2** mide la ventana real y el consumo de tokens en ES y EN, y verifica la disponibilidad de las APIs de medición. Su resultado fija el tope como constante en `ADR-001`; ningún test lo repite como literal.
- **F1** escribe el dominio `nonisolated` y `Sendable`, sin importar SwiftData, SwiftUI ni Foundation Models. Sus tests invocan la API desde contexto no aislado para detectar anotaciones olvidadas.
- **Fase 4 de la guía** añade un hook que rechaza importaciones prohibidas dentro de `Domain/`.
- **F2** crea el contenedor de forma explícita y lo comparte con el actor de modelo. No hay carga inicial al arrancar.
- **F3, F6 y F7** consumen el modelo a través de protocolos y se prueban con dobles deterministas.
- **Toda API nueva** se verifica con Cupertino MCP antes de usarse, contra iOS 26.0.
- **Si Hilo sigue tras el hackathon**, este ADR se revisa en tres puntos: generación de SDK (obligatoria para App Store desde abril de 2027), nivel de adopción y la exclusión de `seguridad-apple`.

---

## Coste de reversión

| Decisión | Coste |
|---|---|
| Aislamiento por defecto | **Alto.** Obliga a revisar cada tipo escrito. No se toca después de F0.1 |
| D1 → paquete local | **Medio.** Mover `Domain/` a un paquete y hacer `public` lo que se consume. Barato antes de F2, caro después de F6 |
| D4 → Xcode 27 | **Bajo**: el SDK de iOS 26 no permite haber usado APIs de iOS 27 |
| D5 → iOS 26.4 | **Bajo.** Solo quita comprobaciones de disponibilidad, si llegara a haberlas |
| Reglas del kit | **Bajo.** Ninguna tiene código escrito todavía |
| SwiftData | **Alto** una vez hay esquema y memoria de ejemplo |
| Foundation Models | **No reversible.** Es el producto |
