# F8 — Ajustes, español, accesibilidad y diseño

- **Fase**: F8 · Sesión S5 · **Con UI**
- **Estado**: Draft
- **Origen**: Idea v2.3 §10.2 (S7), §11.1, §11.2, §11.3, §13 (regla 25)
- **Capacidades**: 14 (borrado total), 13 (ejemplo, su superficie)
- **Decisiones**: DEC-03, DEC-07, DEC-58 · criterios 8 y 9 de terminado
- **Depende de**: F2, F5, y de todas las pantallas que existan cuando se abra

## Objetivo

Cerrar las cuatro cosas transversales: la hoja de ajustes con el borrado total, la traducción completa al español, la verificación de accesibilidad y la fidelidad visual, en toda la app. **No es donde se hace el trabajo, es donde se verifica**: cada pantalla nació con sus textos en el catálogo, sus etiquetas y sus tokens.

## Alcance

**Dentro**
- S7 Ajustes, como hoja: afirmación de privacidad, cargar y borrar la memoria de ejemplo, borrado total con doble confirmación, información del producto.
- Traducción completa al español, incluidas plurales y textos compuestos.
- Pasada de accesibilidad sobre todas las pantallas existentes: VoiceOver, Dynamic Type hasta AX5, Reducir movimiento y contraste.
- **Revisión de diseño** sobre todas las pantallas existentes, frente a `tokens.md` y `docs/design/reference/`, en las cuatro apariencias (DEC-58).

**Fuera, explícitamente**
- Cualquier capacidad nueva.
- Tejido (F9) y hebras sueltas (F10), que se auditan en su propia fase si llegan a construirse.
- Rediseño: si una pantalla no aguanta AX5, se arregla su disposición, no su concepto. La revisión de diseño corrige desviaciones del contrato existente, no propone uno nuevo.

## Trazabilidad

| Requisito | Cómo se cubre |
|---|---|
| regla 25 · todo es borrable desde la app | Contrato 1 |
| §11.3 · privacidad y sin conexión | Contrato 1 |
| §11.2 · inglés y español completos | Contrato 2 |
| §11.1 · accesibilidad completa | Contrato 3 |
| criterios 8 y 9 | Contratos 2 y 3 |
| DEC-58 · fidelidad visual | Contrato 4 |

## Contratos

### 1. S7 · Ajustes

- Es una **hoja**, no un destino.
- **Afirmación de privacidad**: todo se queda en el iPhone, sin cuenta y sin conexión. Es el segundo y último sitio donde se afirma, después del estado vacío.
- **Memoria de ejemplo**: cargar y borrar, usando lo de F2. Borrarla respeta los recuerdos reales.
- **Borrado total con doble confirmación**, y el texto dice exactamente qué desaparece.
- **Información del producto**: versión y poco más. Sin enlaces que requieran red.

### 2. Español

- El catálogo se completa: todas las claves con valor en los dos idiomas.
- **Plurales declarados** en ambos: el español y el inglés no coinciden en categorías.
- Los textos compuestos —motivo de la conexión, «en N recuerdos», aviso de lo que quedó fuera— se revisan **montados**, no clave a clave.
- El contenido del usuario no se traduce nunca.
- Formatos de fecha y número, del sistema.

### 3. Accesibilidad

Pasada completa, pantalla por pantalla, con la matriz: tamaño por defecto, el más pequeño, **AX5**, oscuro y Reducir movimiento.

- Etiquetas en todo lo interactivo, objetivos de 44 puntos, orden de lectura correcto y agrupación de tarjetas.
- **El relato nunca trunca** en un detalle, a ningún tamaño.
- Nada comunicado solo por color.
- Los anuncios compuestos se verifican **en los dos idiomas**.
- Contraste según `tokens.md`, comprobado también con Aumentar contraste activado.

### 4. Revisión de diseño (DEC-58)

- Pantalla por pantalla, en las cuatro apariencias, comparada con `docs/design/reference/` y con los valores exactos de `tokens.md`: color, tipografía, espaciado, radios y trazos.
- Las desviaciones ya aceptadas en `docs/design/README.md` (lote F4–F5) no se revisan otra vez.
- Toda desviación **nueva** que aparezca: si contradice `tokens.md`, se corrige en esta misma tarea; si es un matiz de la referencia que no tiene por qué seguirse (la referencia es solo referencia, `tokens.md` es el contrato), se añade a `docs/design/README.md`, nunca se deja sin anotar.
- Pase manual de Rubén junto a Claude Code — no es un juicio que delegue en ningún agente; los agentes de cierre verifican que lo corregido cumple la constitución, no la estética.

## Comportamiento

- **Dado** el idioma del sistema en español, **cuando** se recorre la app entera, **entonces** no aparece ningún texto en inglés salvo el contenido del usuario.
- **Dado** el borrado total, **cuando** se confirma dos veces, **entonces** no queda nada y la app vuelve al estado vacío de primera vez.
- **Dado** AX5, **cuando** se recorren todas las pantallas, **entonces** nada trunca, solapa ni se sale.
- **Dado** VoiceOver, **cuando** se recorre la app, **entonces** cada pantalla es navegable de principio a fin.
- **Dado** una pantalla existente, **cuando** se compara con `tokens.md` y la referencia, **entonces** toda diferencia encontrada queda corregida o documentada, ninguna sin decidir.

## Criterios de aceptación

**Por test**
- [ ] Toda clave del catálogo tiene valor en inglés y en español.
- [ ] Las cadenas con cantidad tienen variantes de plural en los dos idiomas.
- [ ] Los textos compuestos se generan correctamente en ambos idiomas, con cantidades de 0, 1 y N.
- [ ] El borrado total deja el almacén y el almacenamiento externo vacíos.

**En dispositivo**
- [ ] La app es navegable íntegramente con VoiceOver y en el tamaño de texto mayor (criterio 8).
- [ ] Funciona en inglés y en español (criterio 9).
- [ ] Borrado total con doble confirmación, y la app arranca después en el estado vacío.
- [ ] Todo en modo avión.
- [ ] Cada pantalla, en las cuatro apariencias, revisada contra `tokens.md` y `docs/design/reference/`; toda desviación nueva corregida o documentada en `docs/design/README.md`.

## Tareas atómicas

| Tarea | Objetivo |
|---|---|
| **F8.1** | S7 con privacidad, ejemplo y borrado total |
| **F8.2** | Catálogo completo en español, con plurales |
| **F8.3** | Pasada de accesibilidad sobre las pantallas existentes |
| **F8.4** | Correcciones derivadas de la pasada de accesibilidad |
| **F8.5** | Revisión de diseño frente a `tokens.md` y `docs/design/reference/`, con las correcciones que salgan en el mismo bloque |

## Verificación

- **Toca UI:** sí.
- **Datos íntimos del usuario:** sí, el borrado total.
- **Concurrencia nueva:** no.
- **Al cerrar:** `revisor-constitucion`, `auditor-accesibilidad`, `verificador-ui`.

## Huecos abiertos, a resolver al abrir la fase

- **Texto del borrado total.** Tiene que decir qué desaparece sin asustar ni banalizar, y es irreversible: lo aprueba Rubén.
- **Qué información del producto se muestra**, ahora que no hay enlaces posibles sin red.
- **Si la afirmación de privacidad de ajustes repite la del estado vacío o la amplía.** §9.2 pide que no sea un sello repetido.
- **Cuántas pantallas existen realmente al abrir esta fase**, que depende del punto de control B. La pasada cubre lo que haya, no lo previsto.
