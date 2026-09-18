# F4 — Captura y revisión

- **Fase**: F4 · Sesión S2 · **Con UI**
- **Estado**: Draft
- **Origen**: Idea v2.3 §8.3, §9.1, §9.2, §10.2 (S2 y S3), §13 (reglas 3, 6, 7, 9, 10), §15
- **Capacidades**: 1, 2, 3, 4
- **Decisiones**: DEC-12, DEC-16, DEC-17, DEC-18, DEC-19, DEC-22, DEC-26, DEC-27
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

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §9.1 · contar cuesta menos que no contarlo | Contrato 1 |
| §8.3 · el camino feliz es una sola confirmación | Contrato 2 |
| §9.2 · los cuatro bloques de la revisión | Contrato 2 |
| reglas 6 y 7 · rechazar y confirmar identidades | Contrato 3 |
| reglas 9 y 10 · alcance de quitar y de renombrar | Contrato 4 |
| §15 · el texto nunca se pierde | Contrato 5 |
| DEC-17 · deshacer al quitar | Contrato 4 |
| DEC-22 · «en N recuerdos» no cuenta el actual | Contrato 2 |

## Contratos

### 1. Captura (S2)

- Campo de texto libre, amplio, con el teclado y el dictado del sistema. **Hilo no graba ni conserva audio.**
- Foto opcional, antes o después de escribir, a través del selector del sistema. Al guardarla se eliminan sus metadatos (DEC-27).
- Una acción principal: comprender y guardar. Y una salida secundaria **siempre visible**: guardar sin analizar.
- El texto de ayuda enseña con un recuerdo de ejemplo real, no con una instrucción.
- Estados: vacío, escribiendo, con foto, comprendiendo y error de comprensión.
- En el estado de error, el texto ya está a salvo y se ofrece reintentar (DEC-18).

### 2. Revisión (S3)

Una sola superficie con cuatro bloques, y **cada bloque aparece solo si tiene contenido**:

1. **Lo que ha entendido**: elementos agrupados por tipo, con quitar y renombrar.
2. **Lo que ya conocía**: los elementos existentes con cuántos recuerdos conectan — sin contar el que se está guardando (DEC-22) — y cada reconocimiento rechazable con un toque.
3. **Lo que duda**: las identidades ambiguas, con pregunta clara y dos respuestas del mismo peso, ninguna preseleccionada.
4. **La fecha entendida**, editable como texto.

- **El camino feliz es una sola confirmación.** Guardar está siempre disponible: ninguna duda bloquea el guardado.
- **Sin conexiones, la pantalla se enmarca como el comienzo**, nunca como un fallo.
- Sin nada reconocido, el recuerdo se guarda igual.

### 3. Identidad

- Rechazar un reconocimiento crea un elemento nuevo (regla 6).
- Confirmar una duda convierte el nombre usado en este recuerdo en alias del elemento existente (regla 7).
- Guardar sin responder una duda deja los elementos separados, y se dice.

### 4. Quitar y renombrar

- **Quitar** afecta solo a este recuerdo (regla 9), y es reversible hasta guardar (DEC-17).
- **Renombrar un elemento que ya existía** lo renombra en toda la memoria, y la interfaz avisa antes diciendo en cuántos recuerdos aparece (regla 10).
- Renombrar hacia un canónico ya ocupado del mismo tipo **se bloquea**, nombrando el elemento con el que choca (DEC-26).
- Renombrar un elemento nuevo no afecta a nada más.

### 5. Guardar y conectar

- Al confirmar, el usuario llega a su recuerdo **ya guardado** y ve formarse sus conexiones, con su motivo.
- Editar el texto de un recuerdo **no reanaliza** ni toca las apariciones confirmadas (DEC-19).
- Un recuerdo guardado sin analizar puede comprenderse más tarde desde su detalle (DEC-16), reutilizando esta misma pantalla.

### 6. Accesibilidad y textos

- Todos los textos en el catálogo, desde el primer día. Los mensajes de error de F3 se redactan aquí.
- La aparición progresiva se anuncia; con Reducir movimiento, el mismo anuncio sin movimiento.
- Un elemento anuncia nombre, tipo y en cuántos recuerdos aparece. Una conexión anuncia su motivo.
- AX5: las tarjetas se reorganizan y el relato no se trunca.

## Comportamiento

- **Dado** un campo vacío, **cuando** se abre la captura, **entonces** la acción principal está desactivada y guardar sin analizar disponible.
- **Dado** un relato comprendido con José ya conocido, **cuando** se abre la revisión, **entonces** José aparece en «ya conocía» con su número de recuerdos, sin contar este.
- **Dado** un reconocimiento rechazado, **cuando** se guarda, **entonces** existe un elemento nuevo y el anterior queda intacto.
- **Dado** un elemento quitado, **cuando** se deshace, **entonces** vuelve con su papel.
- **Dado** «Carmen» ya existente, **cuando** se renombra «la tía Carmen» a «Carmen», **entonces** se bloquea con el motivo.
- **Dado** un error de comprensión, **cuando** ocurre, **entonces** el relato está guardado y se ofrece reintentar.

## Criterios de aceptación

**Por test** (lógica fuera de la vista)
- [ ] El estado de la revisión se calcula a partir de lo extraído y lo existente: qué bloques aparecen y con qué contenido.
- [ ] Rechazar, confirmar, quitar, deshacer y renombrar producen el conjunto de apariciones esperado.
- [ ] El bloqueo por colisión de nombre se produce y nombra el elemento en conflicto.
- [ ] Los textos anunciables se generan en los dos idiomas.
- [ ] Cada error de F3 produce el texto y el estado que le corresponde.

**En dispositivo**
- [ ] Contar, revisar y guardar un recuerdo lleva menos de un minuto, y se puede hacer dictando (criterio 1).
- [ ] El segundo recuerdo que comparte una persona con el primero se conecta solo y se ve por qué (criterio 2).
- [ ] Los cinco estados de captura y los cuatro de revisión se ven correctos, en claro y oscuro.
- [ ] AX5 y VoiceOver en ambas pantallas.
- [ ] Todo lo anterior en modo avión.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F4.1** | Estado de la revisión como lógica pura, con sus tests |
| **F4.2** | S2 Captura con sus cinco estados |
| **F4.3** | S3 Revisión: los cuatro bloques y sus acciones |
| **F4.4** | Identidad: rechazar, confirmar, avisar al renombrar |
| **F4.5** | Guardado y momento de la conexión |
| **F4.6** | Textos de error, accesibilidad y AX5 |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** sí.
- **Concurrencia nueva:** sí.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`, `auditor-concurrencia`.
- **Después:** ⛳ **punto de control A**. Si los criterios 1 y 2 no pasan en dispositivo, no se abre F5.

## Huecos abiertos, a resolver al abrir la fase

- **Textos de interfaz definitivos** de los dos bloques delicados: el error de comprensión y la revisión sin conexiones. El primero no puede sonar a fallo grave; el segundo no puede sonar a fracaso. Son de producto: los aprueba Rubén.
- **Qué pasa al añadir una fecha en un recuerdo sin nada reconocido** (visible en `reference/10d`): el año solo lo deduce la comprensión, así que un texto de fecha escrito a mano se queda sin año y ordena al final. Confirmar que es aceptable.
- **Si el aviso previo a renombrar es un diálogo del sistema o un bloque en la pantalla.** La referencia lo dibuja como bloque porque el diálogo quedaba fuera de su alcance.
- **Alcance exacto de «comprender más tarde»** (DEC-16): reutiliza esta pantalla entera, y hay que decidir qué ocurre con las apariciones que ya existían si el recuerdo tenía alguna confirmada a mano.
