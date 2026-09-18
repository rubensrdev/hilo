# F0 — Índice y constitución

> Spec de fase · Proyecto **Hilo** · `docs/specs/F0_INDICE_Y_CONSTITUCION.md`
> Origen: Documento de Idea Especificada v2.3 (fuente de verdad del producto)
> Este documento no se implementa: se lee. Es el mapa y el contrato.

---

## Parte 1 — Mapa de fases

## 1. De la idea a las fases

La v2.3 es un documento de **producto**: dice qué es Hilo, qué hace y qué no. Claude Code necesita otra cosa: unidades de trabajo ordenadas, verificables y autosuficientes.

La traducción es **1 fase = 1 fichero en `docs/specs/`**. Cada spec se basta sola para trabajar su fase. Los ADRs no son uno por fase: solo existen para decisiones caras de revertir (ver §7). El resto de decisiones van al registro de decisiones con una línea.

```
docs/
├── specs/
│   ├── F0_INDICE_Y_CONSTITUCION.md      ← este documento
│   ├── F0.1_Proyecto_y_Cimientos.md
│   ├── F0.2_Spike_Foundation_Models.md
│   ├── F1_Nucleo_de_Dominio.md
│   ├── …
│   └── F10_Hebras_Sueltas.md
├── decisions/                           ← ADR-000-stack y ADRs de decisiones caras
└── design/
    ├── tokens.md                        ← contrato visual, previo a F0.1
    ├── README.md
    └── reference/                       ← referencia, nunca fuente de verdad
```

Todo en minúsculas. En macOS el desajuste de mayúsculas no se nota; en git sí.

### Requisitos libres de tecnología

Cada spec escribe sus requisitos funcionales sin nombrar frameworks. Todo lo técnico va agrupado en una sección final de **notas de planificación**. Si una nota de planificación es cara de revertir, esa sección es el borrador de su ADR.

### Estructura común de cada spec de fase

Ficha · Objetivo · Alcance (dentro / fuera explícito) · Trazabilidad (§14.1, §13, §14.4, huecos de `05`) · Contratos · Comportamiento (Dado / Cuando / Entonces, un escenario por estado de §10.2) · Accesibilidad y localización · **Criterios de aceptación por test** · **Criterios de aceptación en dispositivo** · Tareas atómicas · **Verificación** · Riesgos y preguntas abiertas · Notas de planificación.

---

## 2. Régimen de ejecución

**Una fase cada vez.** Una fase se cierra cuando se cumplen estas condiciones, en este orden:

1. Build y suite de tests en verde, con sus criterios por test verificados.
2. Textos nuevos en el String Catalog y etiquetas de accesibilidad declaradas.
3. Auditorías que marque su bloque Verificación, sin ningún BLOCKER.
4. **Validación manual en dispositivo por Rubén**, si la fase toca UI.
5. `MEMORY.md` al día, registro de decisiones al día y commit `F<n>-complete: <resumen>`.

Hasta el punto 5 no se abre la siguiente.

**Cierre ligero por calendario.** El proyecto dura una semana a tiempo parcial. El protocolo de cierre no puede costar más que la fase. No se abre un ADR por fase, y la validación manual se limita a los criterios en dispositivo de esa fase, no a la app entera.

---

## 3. El principio de orden

Tres criterios, por prioridad:

1. **Lo que se paga con migración va primero.** El nombre canónico, la resolución de elementos y el esquema de persistencia van en F1 y F2. Un error ahí rompe la segunda conexión, que es la promesa entera del producto (§6.6).
2. **Los dos momentos de magia antes que todo lo demás** (§15): la conexión automática con motivo (F3–F4) y la respuesta con fuentes junto al reconocimiento honesto (F6). El punto de control A existe para no avanzar sin el primero.
3. **Lo recortable al final, en el orden de recorte.** Tejido (9) y hebras sueltas (12) son las dos últimas fases. Si el calendario obliga, se caen sin tocar nada anterior.

---

## 4. Las fases, en orden de ejecución

| Fase | Contenido | Sesión | Capacidades §14.1 | Reglas §13 | Criterios §14.4 |
|---|---|---|---|---|---|
| **F0.1** | Proyecto Xcode, build settings, estructura de carpetas, String Catalog, convenciones de accesibilidad | S0 | — | — | 8, 9 (base) |
| **F0.2** | Spike de Foundation Models: extracción ES/EN, contenido íntimo, medición de tokens para el tope | S0 | — | — | — |
| **F1** | Núcleo de dominio: tipos, nombre canónico, parecerse, resolución, conexión deducida, ciclo de vida de elementos | S1 | 4, 5 | 1–12 | 2, 3 (base) |
| **F2** | Persistencia: esquema, escrituras fuera del actor principal, borrado total con fotos, memoria de ejemplo | S1 | 13, 14 | 2, 11, 12, 25 | — |
| **F3** | Comprensión: contrato de extracción, streaming, errores como producto, guardar sin analizar | S2 | 1, 2 | 1, 3, 17, 23, 24 | 1 (base) |
| **F4** | Captura (S2) y Revisión (S3), con todos sus estados | S2 | 1, 2, 3, 4 | 3, 6, 7, 9, 10 | 1, 2 |
| ⛳ | **Punto de control A**: si los criterios 1 y 2 no pasan en dispositivo, no se abre F5 | — | — | — | — |
| **F5** | Explorar: Memoria (S1), detalle de recuerdo (S4), detalle de elemento (S5) sin retrato ni tejido, vecindad con motivo | S3 | 5, 6, 7 | 12, 17 | 3 |
| **F6** | Recuperación y Preguntar (S6): cascada, tope, orden, fuentes, reconocimiento honesto, sugerencias | S4 | 10, 11 | 13–16, 22 | 5, 6, 7 |
| **F7** | Retrato: generación, vigencia, umbral de tres recuerdos | S4 | 8 | 13, 14, 15, 18, 19 | 4, 7 |
| ⛳ | **Punto de control B**: decisión escrita sobre F9 y F10 según el orden de recorte | — | — | — | — |
| **F8** | Ajustes (S7), traducción completa al español y pasada de accesibilidad | S5 | 14 | 25 | 8, 9 |
| **F9** | Tejido estático y su sustitución en tamaños de accesibilidad | S6 | 9 | — | 8 |
| **F10** | Hebras sueltas: catálogo de huecos, plantillas, descartes | S6 | 12 | 20, 21 | — |

El criterio 10 («ninguna pantalla se ve provisional») no tiene fase propia. Se valida en cada cierre con UI y en la prueba final en modo avión.

**F8 va antes que F9 y F10, contra la numeración de §14.1.** Así lo exige §11.2: el español se completa antes de cualquier recortable.

### Verificación por fase

Los cinco campos de la guía se reducen a tres. Hilo no es un juego ni lleva Game Center, así que esas dos marcas no aparecen. La marca de datos se renombra: aquí no hay autenticación ni pagos, pero sí el contenido más íntimo que puede guardar un teléfono (ver principio VIII).

| Fase | Toca UI | Datos íntimos del usuario | Concurrencia nueva |
|---|---|---|---|
| F0.1 | no | no | no |
| F0.2 | no | sí | sí |
| F1 | no | no | no |
| F2 | no | sí | sí |
| F3 | no | sí | sí |
| F4 | sí | sí | sí |
| F5 | sí | no | no |
| F6 | sí | sí | sí |
| F7 | sí | sí | sí |
| F8 | sí | sí | no |
| F9 | sí | no | no |
| F10 | sí | no | no |

**Qué lanza cada marca al cerrar:**

- **UI: sí** → `auditor-accesibilidad`, y `verificador-ui` si mcpbridge expone interacción (se comprueba en la Fase 1.2 de la guía).
- **Datos íntimos: sí** → `revisor-constitucion` con el principio VIII como foco explícito.
- **Concurrencia: sí** → `auditor-concurrencia`.
- **Siempre** → `revisor-constitucion`.

---

## 5. Grafo de dependencias

```
F0.1 ── F0.2 ─────────────────────────┐
  │                                    │ (tope medido, contrato validado)
  └── F1 ── F2 ── F3 ── F4 ── ⛳A ── F5 ── F6 ── F7 ── ⛳B ── F8 ── F9 ── F10
                   ▲                        ▲
                   └──── F0.2 ─────────────┘
```

Lecturas útiles:

- **F1 no depende de F0.2.** El dominio es determinista y no toca el modelo. Si el spike se retrasa, F1 puede avanzar.
- **F3 depende de F0.2.** El contrato de extracción se escribe sobre lo que el spike demostró con relatos reales, no sobre lo que la documentación promete.
- **F6 y F7 dependen del tope medido en F0.2.** Hasta entonces el tope es un parámetro con valor provisional 6 (§17.2). Ningún test debe fijar ese número como literal.
- **F7 reutiliza entera la recuperación de F6** (§9.6). Si F7 necesita un camino propio, la fase está mal diseñada.
- **F10 depende de F5**, porque las hebras aparecen donde el usuario ya mira. No depende de F9.

---

## 6. Decisiones bloqueantes

Ninguna fase se abre con su decisión pendiente. El detalle de cada hueco vive en `05_huecos_y_ambiguedades.md`; aquí solo consta qué fase bloquea.

| # | Decisión | Estado | Bloquea |
|---|---|---|---|
| **D1** | Mecanismo para sacar el dominio del actor principal | **Resuelta** · carpeta `Domain/` en el target único con `nonisolated` explícito · ADR-000 | F0.1 |
| **D2** | Nivel de adopción de infraestructura | **Resuelta** · nivel 2 ampliado (Parte 2) · ADR-000 | F0.1 |
| **D4** | Generación de SDK | **Resuelta** · Xcode 26 · SDK iOS 26 · ADR-000 | F0.1 |
| **D5** | Versión mínima | **Resuelta** · iOS 26.0 · ADR-000 | F0.1 |
| **D3** | Metadatos de la foto: ¿se conservan tal cual (incluida la ubicación) o se eliminan al guardar? | Pendiente · Rubén | F2 |
| **B1** | Lista cerrada de artículos y posesivos del canónico | Pendiente | F1 |
| **B2** | Renombrar o añadir un alias que colisiona con otro elemento | Pendiente | F1 |
| **B3** | Semántica AND/OR del paso 1 con varios nombres y papeles | Pendiente | F6 |
| **B4** | Alias compartido por dos elementos distintos | Pendiente | F6 |
| **C2** | Valor del tope de recuperación (§17.2) | Pendiente · medición F0.2 | F6 |
| **C3** | Orden de recorte 12 → 9 → 4 (§17.3) | Pendiente | Punto de control B |
| **C1** | Nombre en la ficha (§17.1) | Pendiente | Entrega |

Los huecos 🟠 y 🟢 de `05` se ratifican al abrir la fase que los consume. Cada spec lista los suyos en su tabla de trazabilidad.

---

## 7. ADRs previstos

Solo decisiones caras de revertir:

| ADR | Decisión | Se abre en |
|---|---|---|
| `ADR-000-stack` | Stack, aislamiento por defecto y mecanismo de salida del dominio, reglas del kit no contrastadas | Antes de F0.1 |
| `ADR-001-contrato-modelo` | Contratos de los tres usos de Foundation Models y valor del tope | F0.2 |
| `ADR-002-esquema-persistencia` | Esquema, identidad entre actores, almacenamiento de fotos | F2 |
| `ADR-003-recuperacion` | Cascada y huella de vigencia del retrato (si se adopta la propuesta B8) | F6 |

Cualquier otro ADR requiere justificar por qué no basta una línea en el registro.

---

## 8. La restricción de no hacer tests de UI

Decidido y sin debate: **no se escriben tests de interfaz de ningún tipo**. La interfaz se valida a mano en dispositivo al cerrar cada fase con UI.

No es una renuncia a la cobertura. Es una restricción de arquitectura con tres consecuencias:

1. **Las vistas no deciden nada.** Qué estado de §10.2 se muestra, si el retrato tiene vigencia, si una hebra suelta se plantea o si hay que advertir un renombrado global: todo eso se calcula fuera de la vista y se prueba sin instanciarla.
2. **El modelo se inyecta.** Comprensión, interpretación y redacción entran por protocolo, con dobles deterministas en los tests. Eso permite probar el streaming, los rechazos, el desbordamiento de contexto y el guardado sin analizar sin tocar Foundation Models.
3. **Los textos anunciables son datos.** Las etiquetas de VoiceOver («José, persona, aparece en cuatro recuerdos»), el aviso de recuerdos fuera del tope y el reconocimiento honesto se producen como cadenas desde funciones puras. Se prueban en los dos idiomas sin abrir la app.

**La máquina verifica reglas; Rubén verifica sensación.**

---

## 9. Orden de arranque

1. `ADR-000-stack` aceptado.
2. **Fase 0.4 de la guía**: escribir `docs/design/tokens.md` y, si da tiempo, la referencia de patrones de F4 y F5 en Claude Design. Sin tokens no se abre F0.1.
3. Crear el proyecto en Xcode (0.1 de la guía) con los ajustes del principio V.
4. Completar la inicialización de Claude Code, gobernanza, Skills y hooks (Fases 1 a 4 de la guía).
5. Ejecutar F0.1 y F0.2 en S0. Probar el dispositivo de demo: Apple Intelligence activo, idioma del modelo disponible y dictado preparado.
6. Ratificar B1 y B2. Abrir F1.
7. Continuar fase a fase, respetando los puntos de control A y B.

---

## Parte 2 — Encaje con la infraestructura agéntica

### Nivel de adopción

Hilo es una entrega de hackathon sin App Store. Eso lo sitúa en el **nivel 2**: constitución podada, tres Skills base, `revisor-constitucion` y los cinco hooks por defecto, **sin ADRs ni fases SDD**.

La propuesta **se sale de ese nivel en tres puntos**, porque el propio método del hackathon los exige:

1. **Ciclo SDD con fases y ADRs ligeros.** TDD y specs son requisitos del proyecto, no preferencia.
2. **Par de tests** (`tests-de-verdad` + `ingeniero-tests`). Sin él, los criterios TDD de las specs no tienen quien los ejecute con un oráculo independiente.
3. **Par de accesibilidad** (`accesibilidad-ios` + `auditor-accesibilidad`). La accesibilidad es el criterio 8 de terminado y un requisito transversal de §11.1, no un extra.

Si Hilo sigue después del hackathon, se sube al nivel 3 sin rehacer nada de lo que aquí se adopta.

### Skills

| Skill | Origen | Fases | Por qué |
|---|---|---|---|
| `swiftui-moderno` | Kit | F4–F10 | Vistas, navegación, previews |
| `concurrencia-swift` | Kit | F0.2, F2, F3, F4, F6, F7 | Streaming, actor de modelo, cancelación ligada a la vista |
| `apis-modernas` | Kit | Todas | APIs vigentes de iOS 26 (§11.4), con la precedencia de soft-deprecation escrita en `CLAUDE.md` |
| `tests-de-verdad` | Kit | F1, F2, F3, F6, F7, F10 | Criterios TDD con oráculo independiente |
| `accesibilidad-ios` | Kit | F4–F10 | §11.1 completo |
| `swiftdata` | Kit | F2 | Esquema, identidad entre actores, almacenamiento externo |
| `foundation-models` | **Propia, escrita desde cero** | F0.2, F3, F6, F7 | La del kit está desactualizada. Empieza por el mapa de decisión (API nativa antes que LLM) |
| `nonisolated` | Propia, recortada | F1, F2 | Miembros de `struct`/`enum` bajo `MainActor` por defecto y warnings en `#expect` |
| `xcode`, `cupertino`, `design` | Propias | Todas | Infraestructura que el kit no conoce |

**No entra ninguna Skill de dominio de la Parte B del catálogo.** No hay juego, ni compras, ni Game Center.

**No entra `seguridad-apple`.** Su contenido cubre secretos, JWT, Keychain, red y pagos, y Hilo no tiene ninguno de los cinco. El riesgo real de Hilo es de privacidad local y se cubre con el principio VIII y criterios concretos en F2, F3 y F8. Si Hilo pasa a App Store, se reevalúa.

**Repo nuevo.** Donde el veredicto de la guía es «sustituir», entra directamente la Skill del kit, sin copiar antes la propia. La regla «una cada vez, sin convivencia» se cumple por construcción.

### Subagentes

| Agente | Skill que carga | Cuándo |
|---|---|---|
| `revisor-constitucion` | — (lee `CLAUDE.md`) | Cierre de toda fase |
| `ingeniero-tests` | `tests-de-verdad` | Antes de implementar las fases con lógica |
| `auditor-accesibilidad` | `accesibilidad-ios` | Cierre de fases con UI |
| `auditor-concurrencia` | `concurrencia-swift` | Cierre de fases con concurrencia nueva |
| `verificador-ui` | — | Cierre de fases con UI, **solo si mcpbridge expone interacción** |

### Hooks

Los cinco por defecto, **parcheados antes de activarse** (Fase 4.2 de la guía). Sin los opt-in.

### Correspondencia fase ↔ spec ↔ ADR

| Fase | Spec | ADR | Tipo |
|---|---|---|---|
| F0 | `F0_INDICE_Y_CONSTITUCION.md` | `ADR-000-stack` | — |
| F0.1 | `F0.1_Proyecto_y_Cimientos.md` | — | Sin UI |
| F0.2 | `F0.2_Spike_Foundation_Models.md` | `ADR-001-contrato-modelo` | Sin UI |
| F1 | `F1_Nucleo_de_Dominio.md` | — | Sin UI |
| F2 | `F2_Persistencia.md` | `ADR-002-esquema-persistencia` | Sin UI |
| F3 | `F3_Comprension.md` | — (consume ADR-001) | Sin UI |
| F4 | `F4_Captura_y_Revision.md` | — | **Con UI** |
| F5 | `F5_Explorar.md` | — | **Con UI** |
| F6 | `F6_Recuperacion_y_Preguntar.md` | `ADR-003-recuperacion` | **Con UI** |
| F7 | `F7_Retrato.md` | — (consume ADR-003) | **Con UI** |
| F8 | `F8_Ajustes_Espanol_Accesibilidad.md` | — | **Con UI** |
| F9 | `F9_Tejido.md` | — | **Con UI** |
| F10 | `F10_Hebras_Sueltas.md` | — | **Con UI** |

**F0.2 se sale de la guía.** La guía no contempla fases de spike. Aquí existe porque tres decisiones dependen de una medición y no de un criterio: el tope (§17.2), el contrato de extracción y el comportamiento ante contenido íntimo (riesgo de §15). Su código es desechable, vive fuera del target de la app y no se fusiona. Lo que entrega es un informe y el ADR-001.

---

## Parte 3 — Constitución

### I. La especificación precede al código

Ninguna fase se implementa sin su spec revisada y sus decisiones bloqueantes ratificadas. Las preguntas abiertas de una fase se resuelven **antes** de la primera línea de código.

Por encima de la spec está §0 de la v2.3: **si algo no está en §14.1, no se construye**, aunque sea buena idea, barato o bonito. Una propuesta de ampliación durante una fase se anota como pregunta y no se implementa.

### II. Test primero, y nunca contra la interfaz

El ciclo es rojo → verde → refactor con **Swift Testing**. Prohibidos los tests de UI de cualquier tipo.

Si una regla de producto no se puede verificar sin construir una vista, la fase está mal diseñada. El modelo de lenguaje, el reloj y cualquier fuente no determinista entran por protocolo.

### III. Cero dependencias de terceros

Solo APIs de Apple, en la app y en los tests. Sin excepción. Cualquier propuesta de dependencia es enmienda constitucional.

### IV. Componentes nativos, vestidos

SwiftUI exclusivamente. No se reimplementan listas, formularios, pestañas, hojas, selectores ni campos de texto. El diseño se aplica encima del componente del sistema con los valores de `docs/design/tokens.md`, nunca con valores escritos en la vista.

### V. Concurrencia estricta y moderna

- Swift 6.2 o superior, modo de lenguaje 6, comprobación de concurrencia completa.
- **Aislamiento por defecto: `MainActor`**, con Approachable Concurrency activada.
- El trabajo que no pertenece al actor principal sale **de forma explícita**. El dominio puro vive en la carpeta `Domain/` del único target, con cada tipo y función `nonisolated` y sus valores `Sendable` (`ADR-000`, D1). `Domain/` no importa SwiftData, SwiftUI, FoundationModels ni PhotosUI.
- Los modelos persistentes no cruzan actores: entre actores viajan identificadores persistentes o valores `Sendable`.
- Solo `async`/`await`. `@Observable` en lugar de `ObservableObject`. `Codable` para toda serialización; `JSONSerialization` prohibido.

### VI. Lo determinista primero, el modelo después

Cuando una tarea puede resolverse con certeza, se resuelve con certeza (§6.8). Son funciones puras, sin persistencia ni modelo:

- nombre canónico y parecerse;
- resolución de elementos y conexión deducida;
- pasos 1 y 3 de la cascada, orden y tope;
- vigencia del retrato;
- detección de huecos.

El modelo entra solo en tres sitios, cada uno con su contrato cerrado: **comprensión** de un relato, **interpretación estructurada** de una pregunta en el paso 2 y **redacción** de respuesta y retrato.

Sin Apple Intelligence no hay producto (§1.2, §11.4). Por eso no hay interfaz para su ausencia. Pero el código nunca falla porque el modelo no responda: cae al mismo camino que un error de comprensión.

### VII. La fuente es un hecho

- Las fuentes mostradas son exactamente los recuerdos entregados al modelo. Nunca los que el modelo diga haber usado.
- Si quedó material fuera del tope, se dice cuántos.
- Sin material no hay generación, y el reconocimiento honesto es un texto de la interfaz.
- **Ningún texto generado se muestra si alguna de sus fuentes ya no existe o ha cambiado.**

Este principio es el que separa a Hilo de un asistente conversacional. Una violación es BLOCKER siempre.

### VIII. Nada sale del dispositivo, y lo que se borra desaparece

- Sin código de red, sin analítica, sin telemetría, sin identificadores. La app funciona íntegra en modo avión.
- **Ningún registro de diagnóstico contiene texto de recuerdos, nombres de elementos, preguntas ni respuestas.** Si un registro necesita referenciarlos, usa identificadores o la privacidad del sistema de logging.
- Hilo no graba ni conserva audio.
- El borrado total es real e incluye las fotografías y su almacenamiento externo. Es verificable por test.
- La foto se muestra y nunca se analiza. El tratamiento de sus metadatos lo fija D3.

### IX. El texto del usuario es intocable

- El relato nunca se reescribe ni se modifica automáticamente.
- El contenido del usuario (relato, nombres, texto de la fecha) nunca se traduce.
- La fecha se muestra siempre con las palabras del usuario; el año deducido solo ordena.
- Un recuerdo no entendido sigue siendo un recuerdo válido, y el texto nunca se pierde por un fallo del modelo.

### X. Accesibilidad y localización nacen con la pantalla

- Cada pantalla nace con sus textos en el String Catalog (inglés base, español declarado) y sus etiquetas de accesibilidad. F8 es la pasada de verificación y la traducción, no el trabajo desde cero.
- Dynamic Type hasta AX5 sin truncar el relato. VoiceOver en todas las superficies. Reducir movimiento sin pérdida de información.
- El tipo de elemento nunca se distingue solo por color: color, icono y texto.
- El vocabulario interno («elemento», «nombre canónico») nunca aparece en la interfaz.

### XI. Una fase cada vez, y el alcance se protege

- Ejecución estrictamente secuencial, con las condiciones de cierre de la Parte 1 §2.
- Los puntos de control A y B son obligatorios y su resultado se escribe en el registro.
- Si hay que recortar, se recorta de §14.1 en el orden ratificado (C3). **Nunca 13, nunca 14 y nunca calidad.**

---

## Restricciones tecnológicas

| Restricción | Valor |
|---|---|
| Plataforma | iPhone, vertical, iOS 26.0 mínimo |
| Toolchain | Xcode 26 · SDK iOS 26 |
| Lenguaje | Swift 6.2+, modo 6, concurrencia completa |
| Aislamiento por defecto | `MainActor`, Approachable Concurrency: YES |
| Interfaz | SwiftUI + Observation. Nunca UIKit |
| Persistencia | SwiftData, fotos como datos externos |
| IA | Foundation Models en dispositivo. Sin derivación a servidor |
| Localización | String Catalogs · inglés base · español completo |
| Pruebas | Swift Testing. Sin tests de UI |
| Serialización | `Codable` |
| Red | Ninguna |
| Dependencias | Ninguna |

---

## Gobernanza

Esta constitución prevalece sobre cualquier otra práctica del proyecto **en materia técnica**. En materia de **producto** manda la Idea especificada v2.3. Cuando una spec y el diseño de referencia se contradicen, gana la spec. Si un diseño sugiere un cambio de producto, es una pregunta para Rubén.

Las enmiendas requieren justificación escrita, actualización de las fases afectadas y entrada en el histórico. Versionado semántico: mayor para redefinir o eliminar un principio, menor para añadir, parche para aclarar.

**Histórico**

- **1.0.0** — Redacción inicial.
- **1.0.1** — Aclaración (parche): se incorporan D1, D2, D4 y D5 resueltas en `ADR-000`; el principio V concreta el mecanismo de salida del dominio. Pendientes: D3, B1–B4, C1–C3.
