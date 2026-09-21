# F4 — Captura y revisión

- **Fase**: F4 · Sesión S2 · **Con UI**
- **Estado**: Draft
- **Origen**: Idea v2.3 §7.5, §8.3, §9.1, §9.2, §10.2 (S2 y S3), §13 (reglas 3, 5, 6, 7, 9, 10), §15
- **Capacidades**: 1, 2, 3, 4
- **Decisiones**: DEC-12, DEC-16, DEC-17, DEC-18, DEC-19, DEC-22, DEC-26, DEC-27, DEC-35, DEC-37, DEC-40, DEC-41, DEC-42, DEC-43, DEC-44, DEC-45, DEC-46
- **Depende de**: F1, F2, F3

## Objetivo

Las dos pantallas donde ocurre el producto: contar un recuerdo y validar lo entendido viendo nacer las conexiones. Al terminar se cumplen los criterios 1 y 2 de terminado, y el punto de control A decide si se sigue.

## Alcance

**Dentro**
- S2 Captura, con sus cinco estados.
- S3 Revisión, con sus cuatro estados más el aviso previo a renombrar.
- El momento de la conexión, justo después de guardar.
- Quitar, renombrar, rechazar un reconocimiento y resolver dudas de identidad.
- Editar el texto de la fecha.
- Guardar sin analizar y reintentar la comprensión.
- Los textos de interfaz de todos los estados de error de F3.

**Fuera, explícitamente**
- Dictado propio: el micrófono lo pone el teclado del sistema (§9.1).
- Selector de fotos: es superficie del sistema; aquí solo se integra.
- Listas y detalles (F5), preguntar (F6), retrato (F7), ajustes (F8).
- Unir dos elementos existentes: fuera del MVP.
- Añadir elementos a mano en la revisión: ampliación 7.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §9.1 · contar cuesta menos que no contarlo | Contrato 1 |
| §8.3 · el camino feliz es una sola confirmación | Contrato 2 |
| §9.2 · los cuatro bloques de la revisión | Contrato 2 |
| §7.5 · el año lo deduce solo la comprensión | Contrato 2 (DEC-44) |
| reglas 5, 6 y 7 · unir, rechazar y confirmar identidades | Contratos 3 y 4 |
| reglas 9 y 10 · alcance de quitar y de renombrar | Contrato 4 |
| regla 3 · nada entra sin confirmación | Contrato 4 (DEC-40) |
| §15 · el texto nunca se pierde | Contratos 1 y 5 |
| DEC-17 · deshacer al quitar | Contrato 4 |
| DEC-22 · «en N recuerdos» no cuenta el actual | Contratos 2, 4 y 5 |
| DEC-16 y DEC-18 · comprender más tarde y reintentar | Contrato 5 (DEC-45) |

## Contratos

### 1. Captura (S2)

- Campo de texto libre, amplio, con el teclado y el dictado del sistema. **Hilo no graba ni conserva audio.**
- Foto opcional, antes o después de escribir, a través del selector del sistema. Al guardarla se eliminan sus metadatos (DEC-27).
- Una acción principal: comprender y guardar. Y una salida secundaria **siempre visible**: guardar sin analizar.
- El texto de ayuda enseña con un recuerdo de ejemplo real, no con una instrucción.
- Estados: vacío, escribiendo, con foto, comprendiendo y error de comprensión.
- En el estado de error, el texto ya está a salvo, guardado sin analizar. Se muestra con `estado-aviso` y su símbolo, nunca con `estado-error` (DEC-43).
- **Solo el error genérico ofrece reintentar** (DEC-18, matizado por DEC-42). Desbordamiento de contexto e idioma no soportado cierran con un único botón: reintentar sin cambiar nada fallaría igual.

### 2. Revisión (S3)

Una sola superficie con cuatro bloques, y **cada bloque aparece solo si tiene contenido**:

1. **Lo que ha entendido**: elementos agrupados por tipo, con quitar y renombrar.
2. **Lo que ya conocía**: los elementos existentes con cuántos recuerdos conectan — sin contar el que se está guardando (DEC-22) — y cada reconocimiento rechazable con un toque.
3. **Lo que duda**: las identidades ambiguas, con pregunta clara y dos respuestas del mismo peso, ninguna preseleccionada.
4. **La fecha entendida**, editable como texto.

- **El camino feliz es una sola confirmación.** Guardar está siempre disponible: ninguna duda bloquea el guardado.
- **Sin conexiones, la pantalla se enmarca como el comienzo**, nunca como un fallo. El estado se recalcula en vivo: si el usuario rechaza todos los reconocimientos, la pantalla pasa a ser el comienzo.
- Sin nada reconocido, el recuerdo se guarda igual, y la pantalla no dice que ya está guardado antes de guardar.
- **La fecha y su año (DEC-44).** El año deducido solo se guarda si el texto de la fecha al guardar, sin espacios en los extremos, es idéntico al que devolvió la comprensión:

  | Texto de la fecha al guardar | Se guarda |
  |---|---|
  | Sin cambiar | Texto y año deducido |
  | Editado o reescrito | Texto, sin año |
  | Escrito a mano, sin fecha entendida (10d) | Texto, sin año |
  | Borrado | Sin fecha ni año |

  Sin año, el recuerdo ordena en el grupo «sin año» (DEC-21, DEC-35). **Nunca se deduce un año de texto escrito por el usuario**: §7.5 no admite un segundo análisis de la fecha.

### 3. Identidad

- Rechazar un reconocimiento crea un elemento nuevo (regla 6).
- Confirmar una duda convierte el nombre usado en este recuerdo en alias del elemento existente (regla 7).
- Guardar sin responder una duda deja los elementos separados, y se dice.

### 4. Quitar y renombrar

- **Quitar** afecta solo a este recuerdo (regla 9), y es reversible hasta guardar (DEC-17).
- **El renombrado es pendiente, no inmediato (DEC-40).** Queda en el estado de la revisión y se aplica al guardar, en la misma operación que el resto. Cancelar la captura o la revisión no deja nada renombrado (regla 3).
- **Un único alert del sistema con campo de texto** sirve para renombrar cualquier elemento (DEC-40):
  - Si el elemento **ya existía**, lleva el mensaje de alcance: lo renombra en toda la memoria (regla 10) y dice en cuántos **otros** recuerdos aparece (DEC-22).
  - Si el elemento **es nuevo**, no lleva mensaje: no afecta a nada más.
- **Colisiones de nombre**, siempre del mismo tipo y por canónico:
  - Un elemento **existente** renombrado hacia un canónico ya ocupado **se bloquea** (DEC-26) con un segundo alert que nombra el elemento en conflicto. Al cerrarlo se vuelve al alert de renombrar con el texto tal como estaba.
  - Un elemento **nuevo** renombrado hacia un canónico existente **no se bloquea** (DEC-41): pasa a «Lo que ya conocía» como reconocimiento de ese elemento, rechazable como cualquier otro (reglas 5 y 6).

### 5. Guardar y conectar

- Al confirmar, el usuario llega a su recuerdo **ya guardado** y ve formarse sus conexiones, con su motivo.
- Editar el texto de un recuerdo **no reanaliza** ni toca las apariciones confirmadas (DEC-19).
- **Comprender más tarde (DEC-16, DEC-45).** Tiene dos puntos de entrada que se comportan igual: el detalle de un recuerdo sin analizar y el reintento en captura tras un error genérico (DEC-18). Los dos reutilizan esta misma pantalla y:
  - **Parten de cero.** En el MVP, `isAnalyzed == false` implica cero apariciones, porque añadir elementos a mano es la ampliación 7. La invariante se fija con un test, que avisará el día que deje de cumplirse.
  - **Actualizan el mismo recuerdo**, nunca insertan uno nuevo.
  - Comprenden el relato **actual**, aunque se haya editado después de guardarlo.
  - Al guardar ponen `isAnalyzed = true` (DEC-37), añaden las apariciones confirmadas y aplican la regla de la fecha del contrato 2. **No tocan `savedAt`** (DEC-35) **ni la foto**.
  - Si se cancela la revisión, el recuerdo queda intacto y sin analizar.

### 6. Accesibilidad y textos

- Todos los textos en el catálogo, desde el primer día. Los mensajes de error de F3 se redactan aquí; los provisionales están en el anexo (DEC-46).
- **Los textos con nombres no llevan concordancia de género ni pronombres**: solo varía el número del verbo, con variaciones de plural del catálogo y la lista formateada en el idioma de la interfaz.
- La aparición progresiva se anuncia; con Reducir movimiento, el mismo anuncio sin movimiento.
- Un elemento anuncia nombre, tipo y en cuántos recuerdos aparece. Una conexión anuncia su motivo.
- AX5: las tarjetas se reorganizan y el relato no se trunca.

## Comportamiento

- **Dado** un campo vacío, **cuando** se abre la captura, **entonces** la acción principal está desactivada y guardar sin analizar disponible.
- **Dado** un relato comprendido con José ya conocido, **cuando** se abre la revisión, **entonces** José aparece en «ya conocía» con su número de recuerdos, sin contar este.
- **Dado** un reconocimiento rechazado, **cuando** se guarda, **entonces** existe un elemento nuevo y el anterior queda intacto.
- **Dado** un elemento quitado, **cuando** se deshace, **entonces** vuelve con su papel.
- **Dado** que «Carmen» y «la tía Carmen» ya existen como personas, **cuando** se renombra «la tía Carmen» a «Carmen», **entonces** se bloquea nombrando a Carmen.
- **Dado** que «Carmen» ya existe y la revisión trae una persona nueva «la tía», **cuando** se renombra a «Carmen», **entonces** pasa a «ya conocía» como reconocimiento de Carmen, rechazable.
- **Dado** un elemento existente renombrado en la revisión, **cuando** se cancela, **entonces** conserva su nombre en toda la memoria.
- **Dado** «el verano del 87» con año deducido, **cuando** se edita a «el verano del 88» y se guarda, **entonces** el recuerdo no tiene año.
- **Dado** un error genérico de comprensión, **cuando** ocurre, **entonces** el relato está guardado sin analizar y se ofrece reintentar.
- **Dado** un desbordamiento de contexto o un idioma no soportado, **cuando** ocurre, **entonces** el relato está guardado sin analizar y no se ofrece reintentar.
- **Dado** un recuerdo guardado sin analizar, **cuando** se comprende más tarde y se guarda, **entonces** es el mismo recuerdo, con el mismo `savedAt` y la misma foto, y analizado.

## Criterios de aceptación

**Por test** (lógica fuera de la vista)
- [ ] El estado de la revisión se calcula a partir de lo extraído y lo existente: qué bloques aparecen y con qué contenido, y cuándo es el comienzo.
- [ ] Rechazar, confirmar, quitar, deshacer y renombrar producen el conjunto de apariciones esperado.
- [ ] El renombrado solo se aplica al guardar; cancelar no deja rastro.
- [ ] La colisión de un elemento existente se bloquea y nombra el elemento en conflicto; la de un elemento nuevo lo convierte en reconocimiento.
- [ ] La regla de la fecha: sin cambiar, editado, escrito a mano y borrado.
- [ ] La invariante: un recuerdo sin analizar no tiene apariciones.
- [ ] Comprender más tarde actualiza el mismo recuerdo, sin tocar `savedAt` ni la foto, y DEC-22 se cumple también en este camino.
- [ ] Cada error de F3 produce el texto y el estado que le corresponde, y solo el genérico ofrece reintentar.
- [ ] Los textos anunciables se generan en los dos idiomas.

**En dispositivo**
- [ ] Contar, revisar y guardar un recuerdo lleva menos de un minuto, y se puede hacer dictando (criterio 1).
- [ ] El segundo recuerdo que comparte una persona con el primero se conecta solo y se ve por qué (criterio 2).
- [ ] Los cinco estados de captura y los cuatro de revisión se ven correctos, en claro y oscuro.
- [ ] AX5 y VoiceOver en ambas pantallas.
- [ ] Todo lo anterior en modo avión.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F4.1** | Estado de la revisión como lógica pura, con sus tests: bloques, renombrado pendiente, colisiones y regla de la fecha |
| **F4.2** | S2 Captura con sus cinco estados |
| **F4.3** | S3 Revisión: los cuatro bloques y sus acciones |
| **F4.4** | Identidad: rechazar, confirmar, avisar al renombrar |
| **F4.5** | Guardado, momento de la conexión y comprender más tarde |
| **F4.6** | Textos de error, accesibilidad y AX5 |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** sí.
- **Concurrencia nueva:** sí. Incluye la cancelación del streaming atada al ciclo de vida de la pantalla, que F3 dejó sin auditar.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`, `auditor-concurrencia`.
- **Después:** ⛳ **punto de control A**. Si los criterios 1 y 2 no pasan en dispositivo, no se abre F5.

## Huecos resueltos al abrir la fase

| Hueco | Resolución |
|---|---|
| Textos de los bloques delicados | Provisionales en el anexo; se aprueban en pantalla (DEC-46). Estilo del error: DEC-43. Reintentar: DEC-42 |
| Fecha añadida a mano sin nada reconocido | Aceptado, dentro de una regla única para toda fecha editada (DEC-44) |
| Aviso previo a renombrar: diálogo o bloque | Alert del sistema, con renombrado pendiente hasta guardar (DEC-40). Colisiones: DEC-26 y DEC-41 |
| Alcance de «comprender más tarde» | Parte siempre de cero por invariante; actualiza el mismo recuerdo (DEC-45) |

## Anexo · Textos provisionales (DEC-46)

Son la base del catálogo. Los aprueba Rubén al verlos en pantalla; hasta entonces no son definitivos.

### Error de comprensión

Con `estado-aviso` y su símbolo (DEC-43). El título es común a todos los casos.

| Caso | ES | EN |
|---|---|---|
| Título | Tu recuerdo está guardado tal como lo contaste | Your memory is saved just as you told it |
| Genérico: guardarraíl, rechazo, assets, decodificación, sin respuesta | Hilo no ha podido leerlo esta vez. Queda guardado sin personas, lugares ni objetos; puedes volver a intentarlo ahora o más tarde desde el recuerdo. | Hilo couldn't read it this time. It's saved without people, places or objects — you can try again now, or later from the memory. |
| Botones del genérico | Volver a leerlo · Dejarlo así | Try reading it again · Leave it as it is |
| Desbordamiento | Este recuerdo es demasiado largo para que Hilo lo lea de una vez. Queda guardado sin personas, lugares ni objetos. Si lo acortas, puedes pedirle que lo lea desde el propio recuerdo. | This memory is too long for Hilo to read in one go. It's saved without people, places or objects. If you shorten it, you can ask Hilo to read it from the memory. |
| Idioma no soportado | Hilo no puede leer recuerdos en este idioma. Queda guardado sin personas, lugares ni objetos. | Hilo can't read memories in this language. It's saved without people, places or objects. |
| Botón de desbordamiento e idioma | Hecho | Done |

El guardarraíl y el rechazo usan el mismo texto que el resto del caso genérico, a propósito: nunca se insinúa que el recuerdo sea inapropiado.

### Revisión sin conexiones: el comienzo

| Caso | ES | EN |
|---|---|---|
| Título | Aquí empiezan los hilos | These are the first threads |
| Un elemento | Es la primera vez que aparece {José}. El próximo recuerdo en el que vuelva a aparecer se conectará con este. | This is the first time {José} appears. The next memory that mentions {José} will connect to this one. |
| Varios | Es la primera vez que aparecen {José y el reloj}. El próximo recuerdo que comparta cualquiera de ellos se conectará con este. | This is the first time {José and el reloj} appear. The next memory that shares any of them will connect to this one. |

Los nombres van tal como el usuario los confirmó, sin traducir.

### Revisión sin nada reconocido

| Caso | ES | EN |
|---|---|---|
| Título | Esta vez, sin nombres | No names this time |
| Cuerpo | Hilo no ha encontrado personas, lugares ni objetos con nombre. Sigue siendo un recuerdo, y se guardará con tus palabras. | Hilo didn't find named people, places or objects. It's still a memory, and it will be saved in your words. |
