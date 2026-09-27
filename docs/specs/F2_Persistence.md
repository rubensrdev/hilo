# F2 — Persistencia

- **Fase**: F2 · Sesión S1
- **Estado**: Draft
- **Origen**: Idea v2.3 §7.6, §9.2 (arranque en frío), §12, §13 (reglas 2, 11, 12, 23, 25)
- **Capacidades**: 13 (memoria de ejemplo), 14 (borrado total)
- **Decisiones**: DEC-08, DEC-27 (metadatos de la foto) · produce `ADR-002`
- **Depende de**: F1

## Objetivo

Guardar lo que el dominio decide, sin que la persistencia decida nada. Al terminar, existe el esquema, un único punto de escritura fuera del actor principal, la carga y el borrado de la memoria de ejemplo, y el borrado total verificable.

## Alcance

**Dentro**
- Esquema: recuerdo, elemento, aparición, descarte.
- Contenedor creado por la app e inyectado; contenedor en memoria para tests.
- Actor de modelo: único punto de escritura.
- Extracción de valores `Sendable` para el dominio.
- Foto como dato externo, sin metadatos.
- Memoria de ejemplo: cargar y borrar.
- Borrado total.
- Limpieza de elementos huérfanos según la regla 11.

**Fuera, explícitamente**
- Interfaz de cualquier tipo, incluidos los ajustes que disparan carga y borrado (F8).
- Cualquier llamada al modelo (F3).
- Recuperación y orden de la cascada (F6).
- Vigencia del retrato (F7) y descartes de hebras (F10 escribe su uso; aquí solo existe el tipo).
- Migraciones. No hay historia de migración en el MVP.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| §12 · el modelo conceptual | Contrato 1 |
| regla 2 · recuerdo sin foto, fecha ni elementos | El esquema lo permite sin estados inválidos |
| regla 11 y 12 · ciclo de vida del elemento | Contrato 4, aplicando la función pura de F1 |
| regla 23 · la foto se muestra pero no se interpreta | Contrato 3 |
| regla 25 · todo es borrable | Contrato 6 |
| §9.2 · arranque en frío | Contrato 5 |
| DEC-27 · metadatos de la foto | Contrato 3 |

Hueco de `05` que se resuelve aquí: **B11**, la memoria de ejemplo mezclada con la real.

## Contratos

### 1. Esquema

Cuatro entidades, derivadas de §12. Nombres de propiedad en ASCII, sin tildes.

| Entidad | Contenido |
|---|---|
| **Recuerdo** | Relato, texto de fecha opcional, año deducido opcional, foto opcional, instante de guardado, si llegó a analizarse, y si pertenece a la memoria de ejemplo |
| **Elemento** | Nombre mostrado, nombre canónico, tipo, alias, y el retrato con sus fuentes y su huella de vigencia (lo escribe F7; aquí solo existe el hueco) |
| **Aparición** | Qué elemento aparece en qué recuerdo, con qué papel, y si la confirmó el usuario o la propuso la comprensión |
| **Descarte** | Que una hebra suelta concreta —tipo de hueco y elemento— ya no se plantea |

- **Las conexiones no se almacenan.** Se deducen de las apariciones (F1, contrato 4).
- El nombre canónico se guarda porque es lo que se compara, pero **lo calcula el dominio**: la persistencia nunca lo deriva por su cuenta.
- La memoria de ejemplo se distingue por una marca en el recuerdo, no por una entidad aparte (B11).

### 2. Aislamiento y escritura

- El contenedor lo crea la app una vez y se inyecta. **No hay carga inicial al arrancar.**
- **Todas las escrituras pasan por un actor de modelo.** Las vistas leen; nunca insertan, borran ni guardan.
- Los modelos no cruzan actores: fuera del actor viajan identificadores persistentes o valores `Sendable`.
- Las consultas que pueden crecer declaran su límite.

### 3. Fotografía

- Se guarda como **dato externo**, una por recuerdo.
- **Los metadatos se eliminan al guardar**, incluida la ubicación (DEC-27). Lo que se guarda son los píxeles.
- Nunca se analiza su contenido.
- Borrar el recuerdo borra la foto y su almacenamiento externo.

### 4. Ciclo de vida

- Tras cualquier borrado o quitado de aparición, la persistencia pide al dominio qué elementos han quedado huérfanos y los elimina (reglas 11 y 12).
- La limpieza ocurre **en el camino de escritura**, nunca en una vista ni en un proceso aparte.

### 5. Memoria de ejemplo

- Se carga **a petición del usuario**, desde ajustes, y la operación es idempotente: cargarla dos veces no duplica nada.
- Sus recuerdos quedan marcados como de ejemplo.
- **Borrar el ejemplo borra sus recuerdos**, y a continuación se aplica la regla 11: un elemento sobrevive si le quedan recuerdos reales (B11).
- El idioma del contenido de ejemplo es el de la interfaz en el momento de cargarlo, y no cambia después: es contenido del usuario y no se traduce.

### 6. Borrado total

- Borra recuerdos, elementos, apariciones, descartes y **todas las fotos con su almacenamiento externo**.
- Deja la app en el estado vacío de primera vez, sin restos.
- Es verificable por test: tras borrar, ninguna consulta devuelve nada y el directorio de datos externos queda vacío.

## Comportamiento

- **Dado** un recuerdo con foto, **cuando** se borra, **entonces** desaparecen el recuerdo y el fichero de la foto.
- **Dado** un elemento que solo aparecía en el recuerdo borrado, **cuando** termina la escritura, **entonces** el elemento ya no existe.
- **Dado** el ejemplo cargado y un recuerdo real que menciona a un elemento del ejemplo, **cuando** se borra el ejemplo, **entonces** el elemento sobrevive con sus recuerdos reales.
- **Dado** el ejemplo ya cargado, **cuando** se carga otra vez, **entonces** nada se duplica.
- **Dado** un borrado total, **cuando** termina, **entonces** no queda ningún dato ni fichero.

## Criterios de aceptación

**Por test**
- [ ] Un recuerdo puede guardarse sin foto, sin fecha y sin elementos.
- [ ] Guardar una foto con metadatos de ubicación produce un fichero sin esos metadatos.
- [ ] Borrar un recuerdo elimina su foto y su fichero externo.
- [ ] Los huérfanos se eliminan según las reglas 11 y 12, usando la función de F1.
- [ ] Cargar el ejemplo dos veces no duplica; borrarlo respeta los recuerdos reales.
- [ ] El borrado total deja el almacén y el almacenamiento externo vacíos.
- [ ] Ninguna escritura ocurre fuera del actor de modelo.
- [ ] Ningún modelo cruza un límite de aislamiento.

**En dispositivo**
- [ ] Con la app cerrada y reabierta, lo guardado sigue ahí.
- [ ] Tras un borrado total, la app arranca en el estado vacío de primera vez.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F2.1** | Esquema y contenedor, con contenedor en memoria para tests |
| **F2.2** | Actor de modelo y extracción de valores `Sendable` |
| **F2.3** | Foto como dato externo, sin metadatos |
| **F2.4** | Ciclo de vida de elementos en el camino de escritura |
| **F2.5** | Memoria de ejemplo: cargar, borrar, idempotencia |
| **F2.6** | Borrado total verificable |

## Verificación

- **Toca UI:** no.
- **Datos íntimos del usuario:** sí.
- **Concurrencia nueva:** sí, el actor de modelo.
- **Antes de implementar:** `ingeniero-tests`.
- **Al cerrar:** `revisor-constitucion`, `auditor-concurrencia`.

## Huecos abiertos, a resolver al abrir la fase

- **Contenido de la memoria de ejemplo.** No está escrito en ninguna parte: hacen falta entre cuatro y seis recuerdos inventados que demuestren al menos una conexión por persona y una por lugar, en español y en inglés. Es contenido de producto: lo escribe Rubén, no el modelo ni el agente.
- **Estrategia ante un cambio de esquema durante la semana.** No hay migraciones: cambiar el esquema significa reinstalar. Confirmar que se acepta antes de la primera escritura real en el dispositivo de demo.
- **Dónde vive la marca de «analizado».** El esquema la necesita para la DEC-16 (comprender más tarde); decidir si es una bandera o se deriva de la ausencia de apariciones propuestas.
