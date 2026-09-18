# F3 — Comprensión

- **Fase**: F3 · Sesión S2
- **Estado**: Draft
- **Origen**: Idea v2.3 §7.5, §8.1, §8.2.1, §11.2, §13 (reglas 1, 3, 17, 23, 24), §15
- **Capacidades**: 1 y 2 (base)
- **Decisiones**: DEC-32, DEC-33 · consume `ADR-001`
- **Depende de**: F1, F2 y **el resultado de la F0.2**

## Objetivo

Convertir un relato en lo que Hilo entiende de él, y hacerlo de forma que un fallo nunca cueste el texto del usuario. Al terminar existe el contrato de extracción, su consumo en streaming y los caminos de error, todos probados con dobles y ninguno con el modelo real.

## Alcance

**Dentro**
- Protocolo de comprensión y su implementación sobre Foundation Models.
- Estructura generable de la extracción: elementos con nombre, tipo y papel; texto de la fecha; año deducido opcional.
- Consumo del streaming con resultados parciales.
- Instrucciones fijas: idioma de la interfaz, y que los nombres del usuario no se traducen.
- Precalentamiento de la sesión.
- Los caminos de error, cada uno por separado.
- Guardar sin analizar, y comprender más tarde (DEC-16 y DEC-18).

**Fuera, explícitamente**
- Interfaz: la captura y la revisión son F4. Aquí no hay vistas.
- Interpretación de la pregunta (F6) y redacción (F6 y F7), aunque compartan framework.
- Resolución de elementos: la hace el dominio (F1) con lo que esta fase extrae.
- Cualquier análisis de la foto. La foto no participa (regla 23).

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §8.1 · la IA entiende, no decide | La extracción devuelve candidatos; quien resuelve es F1 y quien confirma es el usuario |
| §8.2.1 · elementos apareciendo uno a uno | Contrato 3 |
| §7.5 · el año se deduce en la misma pasada | Contrato 2 |
| regla 1 · el texto no se modifica | El relato entra y sale intacto; la extracción no lo reescribe |
| regla 3 · nada entra sin confirmación | Lo extraído es una propuesta hasta que F4 la confirma |
| regla 17 · la fecha se muestra con las palabras del usuario | El texto y el año viajan separados |
| regla 24 · no se conserva audio | El dictado es del teclado; aquí solo llega texto |
| §15 · el fallo no pierde el texto | Contrato 4 |

## Contratos

### 1. El protocolo

La comprensión se consume a través de un protocolo, de modo que todo test use un doble determinista. **Ningún test llama a Foundation Models.**

Entrada: el relato y el idioma de la interfaz. Salida: un flujo de resultados parciales y un resultado final, o un error de los del contrato 4.

### 2. Lo que se extrae

Una estructura generable, acotada por tipo y guías, nunca por instrucciones en el prompt:

| Campo | Contenido |
|---|---|
| Elementos | Nombre tal como aparece, tipo (persona, lugar u objeto) y papel, con las palabras del usuario |
| Texto de la fecha | Literal, tal como el usuario lo dijo. Puede no haberlo |
| Año deducido | Solo cuando puede deducirse. Puede faltar aunque haya texto de fecha |

- Se reconoce **lo nombrable y singular**, nunca lo genérico (§7.3).
- **Se valida después de generar:** una estructura bien formada puede traer un nombre que no está en el relato o un año que lo contradice. Lo que no pase la validación se descarta, y descartarlo no es un error de producto.
- El año **nunca se muestra**: viaja aparte y solo sirve para ordenar.

### 3. Streaming

- El flujo se consume en una tarea ligada a la vida de la vista y se cancela al salir de la pantalla.
- Cada resultado parcial es **incompleto por definición**: no se persiste ni se decide desde uno.
- El orden de aparición de los elementos es el de lectura, y es lo que sostiene §8.2.1.
- Una sesión por generación, sin historial.
- La sesión se precalienta al entrar en captura, con `prewarm(promptPrefix:)`.

### 4. Los caminos de error

Cada caso se trata por separado, con el nombre exacto que fije la F0.2 (observación O6). Todos los de la primera tabla acaban igual: **el recuerdo se guarda con las palabras del usuario, sin analizar, y se dice por qué**.

| Caso | Qué se le dice al usuario |
|---|---|
| Guardarraíl | Que no ha podido leerlo esta vez, sin tono de fallo grave y sin insinuar que el recuerdo sea inapropiado |
| Desbordamiento de contexto | Que el relato es muy largo para leerlo de una vez |
| Idioma no soportado | Que no puede leerlo en ese idioma |
| Rechazo | Lo mismo que el guardarraíl |
| Assets no disponibles | Nada sobre el dispositivo: mismo mensaje genérico. **Es reintentable** |
| Fallo de decodificación | Mismo mensaje genérico |
| Sin respuesta o cancelado | Mismo mensaje genérico |

Y dos que **no** son estados de producto, sino defectos nuestros, que se corrigen en vez de explicarse: guía de generación no soportada, y dos peticiones concurrentes en la misma sesión.

- **Nunca se reintenta en silencio con un prompt suavizado.** Eso sería reescribir al usuario por la puerta de atrás.
- **Reintentar es una acción del usuario**, disponible en el error de captura (DEC-18) y en el detalle del recuerdo (DEC-16).

### 5. Idioma

- Las instrucciones fijan que se responde en el idioma de la interfaz y que **los nombres escritos por el usuario no se traducen** (§11.2).
- El papel es lenguaje del usuario, y por tanto de su idioma.

## Comportamiento

- **Dado** un relato con dos personas y un lugar, **cuando** se comprende, **entonces** llegan parciales en orden de lectura y un resultado final con los tres elementos, su tipo y su papel.
- **Dado** un relato sin ninguna fecha, **cuando** se comprende, **entonces** no hay texto de fecha ni año, y eso no es un error.
- **Dado** un relato con «el verano del 87», **cuando** se comprende, **entonces** el texto es literal y el año deducido es 1987.
- **Dado** un guardarraíl que salta, **cuando** se comprende, **entonces** el recuerdo se guarda sin analizar y se ofrece reintentar.
- **Dado** que la pantalla se cierra a mitad del streaming, **cuando** la tarea se cancela, **entonces** nada se persiste y no llega ningún error al usuario.

## Criterios de aceptación

**Por test**, todos con dobles:
- [ ] La extracción produce la estructura esperada para un relato típico en español y en inglés.
- [ ] Un relato sin fecha, uno con fecha sin año deducible y uno con fecha completa se comportan según el contrato 2.
- [ ] La validación descarta un elemento cuyo nombre no aparece en el relato.
- [ ] Cada caso de error del contrato 4 produce «guardado sin analizar» con su motivo, y el texto del usuario se conserva íntegro.
- [ ] El streaming entrega parciales en orden y nada se persiste desde un parcial.
- [ ] Una cancelación a mitad no persiste ni propaga error.
- [ ] Ningún test toca Foundation Models.

**En dispositivo**
- [ ] Con un relato real, los elementos aparecen progresivamente y el resultado coincide con lo que se ve.
- [ ] Con Apple Intelligence desactivada, la app no falla: guarda sin analizar y no menciona el dispositivo.
- [ ] En modo avión, todo lo anterior se comporta igual.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F3.1** | Protocolo, estructura generable y dobles de test |
| **F3.2** | Implementación sobre Foundation Models, con instrucciones e idioma |
| **F3.3** | Streaming, cancelación y precalentamiento |
| **F3.4** | Caminos de error, uno por uno |
| **F3.5** | Guardar sin analizar y comprender más tarde |

## Verificación

- **Toca UI:** no.
- **Datos íntimos del usuario:** sí.
- **Concurrencia nueva:** sí.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-concurrencia`.

## Huecos abiertos, a resolver al abrir la fase

Esta fase depende del spike más que ninguna otra. Al abrirla, leer primero `ADR-001` y resolver:

- **O6 · qué superficie de error es la vigente**: `LanguageModelSession.GenerationError` o `LanguageModelError`. Se comprueba en el SDK instalado, no solo en la documentación. Sin esto, el contrato 4 se escribe contra nombres que quizá no lleguen nunca.
- **O1 · si el contrato de extracción aguanta relatos reales**, y qué hay que ajustar en las guías si no.
- **O2 · frecuencia de guardarraíl con contenido íntimo.** Si es alta, es un problema de producto y se decide con Rubén, nunca se apaña aquí.
- **O4 · qué devuelve el modelo con fechas ambiguas** y si el año puede quedar vacío sin romper la estructura.
- **Precalentamiento:** si el spike midió que no aporta, no se implementa.
- **Texto exacto de cada mensaje de error.** Son textos de interfaz; se redactan en F4 con la pantalla delante, no aquí.
