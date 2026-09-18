# F1 — Núcleo de dominio

- **Fase**: F1 · Sesión S1
- **Estado**: Draft
- **Origen**: Idea v2.3 §7.3, §7.4, §7.5, §8.4, §12, §13 (reglas 1–12)
- **Capacidades**: 4 (resolución de elementos con pregunta), 5 (conexión automática con motivo)
- **Decisiones**: DEC-08, DEC-25 (B1), DEC-26 (B2)
- **Depende de**: F0.1. No depende del spike.

## Objetivo

Escribir la parte de Hilo que decide, y hacerlo sin persistencia, sin interfaz y sin modelo. Al terminar, el nombre canónico, el parecerse, la resolución de elementos, la conexión deducida y el ciclo de vida de un elemento existen como funciones puras con sus tests, y cualquier fase posterior las usa sin volver a pensarlas.

Esta fase es la que sostiene el criterio 2 de terminado: que el segundo recuerdo que comparte una persona con el primero se conecte solo.

## Alcance

**Dentro**
- Tipos valor del dominio: recuerdo, elemento, aparición, fecha, tipo de elemento, papel.
- Nombre canónico y sus reglas.
- Parecerse, y la resolución de un nombre contra lo que ya existe.
- Conexión deducida entre recuerdos, con su motivo.
- Validación de renombrar y de añadir alias.
- Ciclo de vida: cuándo un elemento deja de existir.

**Fuera, explícitamente**
- Persistencia de cualquier tipo: esquema, contenedor, consultas (F2).
- Cualquier llamada al modelo (F3).
- Recuperación, orden y tope (F6). Aquí no hay cascada ni material para generar.
- Vigencia del retrato (F7) y detección de huecos (F10).
- Interfaz.

## Trazabilidad

| Regla §13 | Cómo se cubre aquí |
|---|---|
| 1 · el texto original no se modifica | El relato es un valor inmutable; ninguna función del dominio lo devuelve alterado |
| 2 · un recuerdo puede no tener foto, fecha ni elementos | El tipo lo permite sin estados inválidos |
| 3 · ninguna comprensión entra sin confirmación | La aparición distingue confirmada por el usuario de propuesta |
| 4 · nombre canónico | Función pura, contrato 1 |
| 5 · unión automática solo con canónico o alias y mismo tipo | Resolución, contrato 3 |
| 6 · toda unión propuesta puede rechazarse | La resolución es una propuesta, nunca un efecto |
| 7 · al confirmar una duda, el nombre pasa a alias | Contrato 3 |
| 8 · varios alias, cualquiera vale como coincidencia exacta | Contrato 3 |
| 9 · quitar afecta solo a ese recuerdo | Se modela como quitar la aparición, no el elemento |
| 10 · renombrar cambia el nombre en toda la memoria | Contrato 5, con su aviso |
| 11 · un elemento sin recuerdos deja de existir | Contrato 6 |
| 12 · borrar un recuerdo no borra sus elementos, salvo la 11 | Contrato 6 |
| 17 · la fecha se muestra con las palabras del usuario | El año es un dato aparte que solo ordena |

Huecos de `05` resueltos aquí: **B1** y **B2**. Los demás no tocan esta fase.

## Contratos

### 1. Nombre canónico

De un nombre mostrado se obtiene su canónico. Es el único nombre que se compara, y **nunca se muestra**.

La transformación, en este orden:

1. Normalizar espacios: recortar los extremos y reducir cualquier secuencia interna a un espacio.
2. Plegar mayúsculas y acentos, de forma independiente del idioma del dispositivo.
3. Quitar el artículo o posesivo inicial, si lo hay.

La lista es **cerrada** y se aplica siempre, sea cual sea el idioma de la interfaz (DEC-25):

> el · la · los · las · lo · un · una · mi · mis · tu · tus · su · sus · nuestro · nuestra · nuestros · nuestras · the · a · an · my · our · your · his · her · their

Dos condiciones para quitarla: solo se mira **la primera palabra**, y solo se quita **si queda al menos otra palabra detrás**.

Consecuencia aceptada y documentada: en nombres cuyo artículo forma parte del nombre —«La Alhambra», «El Cairo», «Los Ángeles»— el artículo se quita en ambos lados de la comparación, así que siguen coincidiendo entre sí. Se pierde la distinción entre «el Cairo» y «Cairo», que es justo lo que queremos.

### 2. Parecerse

Dos nombres **se parecen** cuando son del mismo tipo y el canónico de uno contiene al del otro **como secuencia de palabras completas**.

- «José» y «José García» se parecen.
- «José» y «Josefa» no: no es una palabra completa.
- «Ana» y «mañana» no, por lo mismo.
- Mismo canónico y distinto tipo **no** es parecerse: son cosas distintas.

### 3. Resolución de un nombre

Dado un nombre y un tipo, y el conjunto de elementos existentes, la resolución devuelve exactamente uno de estos tres resultados, sin efectos:

| Resultado | Cuándo |
|---|---|
| **Coincidencia exacta** | El canónico coincide con el canónico o con cualquier alias de un elemento del mismo tipo (reglas 5 y 8). Se propone la unión y la interfaz muestra que ya se conocía |
| **Duda de identidad** | Se parecen, pero no coinciden (contrato 2). La interfaz pregunta |
| **Nuevo** | No hay ninguna de las dos |

Dos comportamientos que forman parte del contrato:

- **Una coincidencia exacta es una propuesta, no un hecho.** Al rechazarla se crea un elemento nuevo (regla 6).
- **Al confirmar una duda, el nombre usado en este recuerdo pasa a ser alias** del elemento existente (regla 7).

Si un mismo nombre resuelve contra **varios** elementos del mismo tipo, la resolución los devuelve todos: quien decide es el usuario, no el dominio. El caso y su presentación pertenecen a F4.

### 4. Conexión deducida

Dos recuerdos están conectados cuando comparten al menos un elemento. **La conexión no se almacena: se calcula** (§12).

Dado un recuerdo y el conjunto de apariciones, el dominio devuelve los recuerdos conectados, cada uno con **su motivo**: los elementos compartidos, en un orden estable y reproducible.

- Nunca se devuelve el propio recuerdo.
- Un recuerdo conectado por varios elementos aparece **una vez**, con todos sus motivos.
- Sin elementos compartidos, la lista es vacía. Vacío no es un error: es el comienzo.

### 5. Renombrar y alias

- **Renombrar** cambia el nombre mostrado del elemento, y por tanto su canónico, en toda la memoria (regla 10). El dominio expone cuántos recuerdos se ven afectados, para que la interfaz avise antes.
- **Renombrar hacia un nombre cuyo canónico ya pertenece a otro elemento del mismo tipo se rechaza** (DEC-26), y la validación dice contra qué elemento choca. Lo mismo al añadir un alias que colisiona. Unir dos elementos existentes está fuera del MVP (§14.3.2), y permitir esto sería unirlos por la puerta de atrás.
- Renombrar **no** toca las apariciones ni sus papeles.

### 6. Ciclo de vida de un elemento

- Un elemento **sin ninguna aparición deja de existir** (regla 11). El dominio dice, dado un conjunto de apariciones, qué elementos han quedado huérfanos; quien los borra es la persistencia (F2).
- Borrar un recuerdo no borra sus elementos, salvo los que queden huérfanos (regla 12).
- Quitar un elemento de un recuerdo afecta solo a ese recuerdo (regla 9), y puede dejarlo huérfano.

### 7. Fecha

Una fecha es **el texto del usuario** más, opcionalmente, un año deducido.

- El texto es lo único que se muestra.
- El año **solo ordena y agrupa**, y nunca se muestra (regla 17).
- Un recuerdo puede tener texto de fecha sin año — «no me acuerdo del año, pero fue en otoño» — y ese caso no es un error.
- El dominio no deduce años: el año llega de la comprensión (F3). Aquí solo se transporta y se usa para ordenar.

### 8. Forma de los tipos

- Todos los tipos de esta fase son **tipos valor `Sendable`**, y todo el módulo es `nonisolated` (`ADR-000`, D1).
- Sin dependencias de SwiftData, SwiftUI, FoundationModels ni PhotosUI. Lo garantiza un hook, además de la revisión.
- Ningún estado inválido representable: un recuerdo sin relato no existe, un elemento sin nombre tampoco.
- Las funciones son deterministas: mismos datos, mismo resultado y mismo orden, siempre.

## Comportamiento

- **Dado** un elemento «el reloj» y un recuerdo nuevo que menciona «mi reloj», **cuando** se resuelve el nombre, **entonces** hay coincidencia exacta.
- **Dado** un elemento «José» y un nombre nuevo «José García» del mismo tipo, **cuando** se resuelve, **entonces** hay duda de identidad.
- **Dado** un lugar «Granada» y una persona «Granada», **cuando** se resuelve la persona, **entonces** el resultado es nuevo: coincidir en canónico sin coincidir en tipo no une.
- **Dado** un recuerdo que comparte José y Granada con otro, **cuando** se calculan sus conexiones, **entonces** el otro aparece una sola vez, con ambos motivos.
- **Dado** un elemento que aparece en cuatro recuerdos, **cuando** se pide renombrarlo, **entonces** el dominio informa de que afecta a cuatro.
- **Dado** un elemento «Carmen» y otro «la tía Carmen», **cuando** se intenta renombrar el segundo a «Carmen», **entonces** la validación lo rechaza nombrando el elemento con el que choca.
- **Dado** un recuerdo que se borra y un elemento que solo aparecía en él, **cuando** se calculan los huérfanos, **entonces** ese elemento está en la lista y los demás no.

## Criterios de aceptación

**Por test**
- [ ] El canónico se comporta según el contrato 1, incluidos los casos límite: «La Alhambra», «El Cairo», «Los Ángeles», un nombre de una sola palabra que es un artículo, espacios múltiples, mayúsculas y acentos mezclados, y nombres en inglés.
- [ ] Parecerse acepta «José» / «José García» y rechaza «José» / «Josefa» y «Ana» / «mañana».
- [ ] Mismo canónico con distinto tipo no resuelve como coincidencia.
- [ ] Un alias cuenta como coincidencia exacta igual que el canónico.
- [ ] Rechazar una coincidencia produce un elemento nuevo; confirmar una duda añade el alias.
- [ ] Las conexiones devuelven cada recuerdo una vez con todos sus motivos, en orden estable, y nunca el propio recuerdo.
- [ ] Renombrar hacia un canónico ocupado del mismo tipo se rechaza; hacia uno libre, o hacia el mismo nombre que ya tiene, se permite.
- [ ] Añadir un alias que colisiona se rechaza.
- [ ] Los huérfanos se calculan según las reglas 11 y 12.
- [ ] Un recuerdo con texto de fecha y sin año es válido y ordena después de los fechados.
- [ ] Las funciones del dominio se invocan **desde un contexto no aislado, sin `await`**. Si una anotación `nonisolated` desaparece, el test deja de compilar.

**En dispositivo**

Ninguno. Esta fase no tiene superficie.

## Tareas atómicas

| Tarea | Objetivo | Termina cuando |
|---|---|---|
| **F1.1** | Tipos valor del dominio, sin estados inválidos | Compilan, son `Sendable` y `nonisolated`, y los tests del andamiaje pasan |
| **F1.2** | Nombre canónico | Todos los casos límite del contrato 1 en verde |
| **F1.3** | Parecerse y resolución | Los tres resultados y sus casos límite en verde |
| **F1.4** | Conexión deducida con motivo | Orden estable y sin duplicados |
| **F1.5** | Renombrar, alias y huérfanos | Validaciones y ciclo de vida en verde |

Cada tarea empieza por sus tests (`ingeniero-tests`) y termina con la suite completa en verde.

## Verificación

- **Toca UI:** no.
- **Datos íntimos del usuario:** no. Las fixtures son inventadas.
- **Concurrencia nueva:** no. Pero el dominio es `nonisolated` y eso se verifica por test.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`.

## Riesgos y preguntas abiertas

- **Un canónico demasiado agresivo une cosas distintas; uno demasiado tímido rompe la promesa del producto.** La lista cerrada es una apuesta consciente; si el spike o el uso real muestran fallos, se ajusta aquí y en un solo sitio.
- **El orden estable de los motivos no es un detalle estético:** es lo que hace que los tests y la interfaz sean reproducibles. Definirlo explícitamente, no dejarlo al azar del conjunto.
- **La resolución contra varios elementos del mismo tipo** (hueco B4) se decide en F6 para la recuperación. Aquí solo se garantiza que el dominio los devuelve todos y no elige por su cuenta.
- **Esta fase es la más barata de probar y la más cara de equivocar.** Todo lo que se descubra tarde aquí se paga con migración de datos en F2 o con conexiones incorrectas en toda la memoria.
