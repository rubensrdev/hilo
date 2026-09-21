# Tokens de diseño — Hilo

> `docs/design/tokens.md` · **El contrato visual.** Los valores exactos salen de aquí y nunca de una imagen.
> Se deriva de la Idea v2.3 (§5, §7.6, §8.2, §9.4, §11.1, §11.2), de `F0` y de `ADR-000`.
> `docs/design/reference/` es referencia; si contradice este documento o una spec, ganan este documento y la spec.

**Prueba de suficiencia:** con este documento y la spec de fase, cualquier pantalla de Hilo se puede implementar sin abrir una imagen.

---

## 0. Dirección

Hilo guarda lo más íntimo que alguien puede contar. La interfaz se retira y deja el protagonismo al relato. Tres ideas gobiernan todos los tokens:

1. **Papel, no pantalla.** Fondos cálidos y poco saturados. El relato del usuario es lo más legible de cada vista.
2. **Un solo color con intención: el hilo.** El acento terracota se reserva para lo que conecta y para la acción principal. Si todo es acento, la conexión deja de verse.
3. **Lo que escribe el usuario y lo que redacta Hilo no se confunden nunca.** Tienen familia tipográfica distinta, fondo distinto y la etiqueta de fuentes siempre presente (§6.4).

**Prohibido en toda la app:** iconografía de IA (destellos, varitas, cerebros, chispas), burbujas de chat y avatares (§5). La inteligencia se nota porque funciona, no porque se anuncie.

---

## 1. Color

Nombres semánticos por rol. Cuatro apariencias: **C** claro · **O** oscuro · **C·AC** claro con más contraste · **O·AC** oscuro con más contraste.

Umbrales usados: **4,5:1** para texto en apariencia normal y **7:1** en alto contraste. Los elementos no textuales necesitan **3:1**. Los ratios están calculados con la fórmula de luminancia relativa de WCAG 2.2.

### 1.1 Superficies

| Token | Rol | C | O | C·AC | O·AC |
|---|---|---|---|---|---|
| `fondo` | Fondo de pantalla | `#F7F3EC` | `#15120F` | `#FFFFFF` | `#000000` |
| `superficie-tarjeta` | Tarjeta de recuerdo, bloques del detalle | `#FFFFFF` | `#221E1A` | `#FFFFFF` | `#121010` |
| `superficie-hundida` | Campo de captura, campo de pregunta, filas de revisión | `#EDE6DA` | `#2C2722` | `#F0EBE3` | `#1E1B18` |
| `superficie-generada` | Bloque de respuesta y de retrato | `#F1EADF` | `#26211C` | `#F3EEE6` | `#1A1714` |
| `chip-relleno` | Relleno de todo chip de elemento | = `superficie-hundida` | | | |

### 1.2 Texto e iconos

Cada token está medido contra las cuatro superficies. La tabla muestra el **peor par** de cada apariencia.

| Token | Rol | C | O | C·AC | O·AC | Peor ratio (C / O / C·AC / O·AC) |
|---|---|---|---|---|---|---|
| `texto-primario` | Relato, nombres, texto generado, títulos | `#1E1915` | `#F3EDE4` | `#000000` | `#FFFFFF` | 14,1 / 12,7 / 17,7 / 17,1 |
| `texto-secundario` | Fecha del usuario, metadatos, motivo de la conexión, aviso fuera del tope | `#5C5349` | `#B8AD9F` | `#3B342D` | `#E2DACF` | 6,1 / 6,7 / 10,3 / 12,4 |
| `texto-deshabilitado` | Controles inactivos (exentos de contraste en WCAG; se declaran igual) | `#8C8378` | `#7A7166` | `#6B6259` | `#A39A8F` | 3,0 / 3,1 / 5,0 / 6,2 |
| `acento-hilo` | Acción principal, conexión recién formada, vínculos del tejido, estado seleccionado | `#9E3D27` | `#E8927A` | `#7A2A17` | `#F7B5A2` | 5,4 / 6,2 / 8,2 / 9,9 |
| `texto-sobre-acento` | Etiqueta del botón principal | `#FFFFFF` | `#1E1915` | `#FFFFFF` | `#000000` | 6,7 / 7,3 / 9,7 / 12,1 |

### 1.3 Tipos de elemento

**El tipo nunca se comunica solo con color** (§11.1). Siempre llevan juntos token de color, símbolo (§5) y texto del tipo.

| Token | Tipo | C | O | C·AC | O·AC | Peor ratio |
|---|---|---|---|---|---|---|
| `tipo-persona` | Persona | `#2F5F82` | `#8DB9DB` | `#1E4866` | `#B7D6EE` | 5,5 / 7,1 / 8,1 / 11,3 |
| `tipo-lugar` | Lugar | `#3F6B2F` | `#9CC78A` | `#2B5020` | `#BFE0B0` | 5,0 / 7,7 / 7,8 / 11,8 |
| `tipo-objeto` | Objeto | `#7E5213` | `#E0B26E` | `#5E3C0A` | `#F0CE98` | 5,5 / 7,6 / 8,3 / 11,4 |

Los tres tipos también deben distinguirse en escala de grises. Lo garantizan el símbolo y el texto, no la luminancia.

### 1.4 Estados

| Token | Rol | C | O | C·AC | O·AC | Peor ratio | Además del color |
|---|---|---|---|---|---|---|---|
| `estado-exito` | Recuerdo guardado | `#2E6B3A` | `#86C995` | `#1F5229` | `#B0E2BB` | 5,2 / 7,6 / 7,7 / 11,8 | Símbolo + anuncio de VoiceOver |
| `estado-aviso` | Guardado sin analizar (también tras un error de comprensión), retrato sin vigencia | `#855400` | `#E9B45C` | `#633E00` | `#F5CE8A` | 5,2 / 7,8 / 8,0 / 11,5 | Símbolo + texto explicativo |
| `estado-error` | Base de `destructivo`. Ningún estado de la comprensión lo usa: si comprender falla, el recuerdo queda guardado sin analizar y es `estado-aviso` | `#B0261C` | `#FF8A80` | `#8A1810` | `#FFB3AC` | 5,4 / 6,5 / 8,0 / 10,0 | Solo a través de `destructivo` |
| `destructivo` | Borrar recuerdo, borrar memoria, borrar ejemplo | = `estado-error` | | | | | Rol `destructive` del sistema + confirmación |
| `seleccionado` | Selector Recuerdos/Elementos, filtro de tipo activo | = `acento-hilo` | | | | | Estado del control del sistema (marca, peso) |
| `seleccion-fila` | Pulsación en fila de lista | Color del sistema | | | | | No es el acento |

### 1.5 Trazos

| Token | Rol | C | O | C·AC | O·AC | Contra `superficie-tarjeta` |
|---|---|---|---|---|---|---|
| `separador` | Separadores de lista y de secciones | `#DDD4C7` | `#3A342E` | `#8C8378` | `#8A8178` | Decorativo en C/O · 3,7 / 5,0 en AC |
| `borde-tarjeta` | Contorno de tarjeta | ninguno | ninguno | = `separador` | = `separador` | Solo en alto contraste |
| `vinculo-tejido` | Vínculos del tejido | = `acento-hilo` | | | | ≥ 5,4 (no textual, requiere 3:1) |
| `borde-chip-conocido` | Chip de un elemento que ya existía en la memoria | = `acento-hilo` | | | | ≥ 5,4 contra `chip-relleno` |
| `borde-chip-nuevo` | Chip de un elemento nuevo | ninguno | ninguno | = `separador` | = `separador` | Solo en alto contraste |

### 1.6 Chips de elemento

| Variante | Relleno | Borde | Texto | Además del color |
|---|---|---|---|---|
| Nuevo | `chip-relleno` | `borde-chip-nuevo` | `texto-primario` + símbolo del tipo | Texto del tipo en VoiceOver |
| Ya conocido | `chip-relleno` | `borde-chip-conocido`, `trazo-chip-conocido` | `texto-primario` + «en N recuerdos» en `texto-secundario` | El número va en texto; VoiceOver lo anuncia |
| Quitado | `chip-relleno` | ninguno | `texto-secundario` **con tachado** | VoiceOver lo anuncia como quitado. El tachado nunca es la única señal |

«N» es el número de recuerdos en los que ya aparece ese elemento.

### 1.7 Resalte de búsqueda

El término encontrado en un extracto se marca con **peso semibold**, sin color ni fondo. Si la coincidencia cae fuera de las primeras líneas del relato, el extracto se centra en ella en lugar de empezar por el principio. Si el recuerdo aparece porque coincide el nombre o un alias de uno de sus elementos y no el relato, la tarjeta muestra ese elemento como chip con su símbolo, para que se entienda por qué está en los resultados.

### 1.8 Liquid Glass

- **Se usa solo donde el sistema lo pone:** barra de pestañas, barras de navegación y de herramientas, y controles del sistema.
- **Nunca sobre el relato, las tarjetas, el bloque generado ni las fotos.** Debajo de una barra de vidrio siempre queda `fondo`.
- No sustituye a ningún token de color.

### 1.9 Fotografías

**No se pone texto encima de una foto. Nunca.** La foto se muestra encima o al lado del texto, no debajo. Así, «texto legible sobre fotografías en todos los casos» (§11.1) se cumple por construcción y no hace falta ningún token de velo.

| Token | Valor |
|---|---|
| `foto-tarjeta` | Proporción 3:2, recorte para rellenar, dentro de `relleno-tarjeta` (no a sangre), encima del extracto, `radio-foto` |
| `foto-detalle` | Proporción original, **sin recorte**, ancho completo menos `margen-pantalla`, `radio-foto` |

Los valores de translucidez y desenfoque del vidrio los pone el sistema: no son tokens y no se juzgan sobre una imagen de referencia.

---

## 2. Tipografía

Todos los tokens se mapean a un **text style del sistema**. No hay tamaños fijos en puntos.

### 2.1 Familias

| Familia | Uso | Por qué |
|---|---|---|
| **New York** (serif del sistema) | **Solo** las palabras del usuario: el relato y el texto de la fecha | Separa visualmente lo que es suyo de lo que redacta Hilo (§6.1, §6.4). La fecha va en serif porque son sus palabras literales (§7.5) |
| **SF Pro** (sistema) | Todo lo demás: interfaz, nombres de elementos, texto generado, reconocimiento honesto, fuentes | El texto generado **no** va en serif. Si fuera igual que el relato, parecería escrito por el usuario |

Los nombres de elementos van en SF aunque los escriba el usuario. Son estructura, no relato.

### 2.2 Roles

| Token | Text style | Familia · peso | AX1–AX5 | Crecimiento EN → ES |
|---|---|---|---|---|
| `titulo-pantalla` | `largeTitle` | SF · sistema | Lo gestiona la barra de navegación | Puede truncar (título de sistema) |
| `titulo-seccion` | `title3` | SF · semibold | Envuelve | Envuelve |
| `encabezado-epoca` | `headline` | SF · semibold | Envuelve | Envuelve |
| `relato` | `body` | New York · regular · interlineado amplio | Envuelve. **Nunca trunca** en el detalle | Contenido del usuario: no se traduce |
| `relato-extracto` | `body` | New York · regular | Envuelve. Mantiene su número de líneas de extracto; la tarjeta se reorganiza en vertical | — |
| `fecha-usuario` | `subheadline` | New York · italic | Envuelve | No se traduce |
| `nombre-elemento` | `headline` | SF · semibold | Envuelve | No se traduce |
| `chip-elemento` | `subheadline` | SF · medium | El chip crece y los chips pasan a una columna | No se traduce (el nombre); el tipo sí envuelve |
| `metadato` | `footnote` | SF · regular | Envuelve | Envuelve |
| `motivo-conexion` | `footnote` | SF · regular | Envuelve | Envuelve (plantilla con nombres) |
| `texto-generado` | `body` | SF · regular | Envuelve. Nunca trunca | — |
| `etiqueta-fuentes` | `footnote` | SF · semibold | Envuelve | Envuelve |
| `aviso-fuera-tope` | `footnote` | SF · regular | Envuelve | Envuelve |
| `reconocimiento-honesto` | `title3` | SF · regular | Envuelve | Envuelve. No es texto gris pequeño (§9.7) |
| `pregunta-identidad` | `headline` | SF · regular | Envuelve. Las dos respuestas pasan a apilarse | Envuelve |
| `hebra-suelta` | `callout` | SF · regular | Envuelve | Envuelve |
| `boton-principal` | `headline` | SF · semibold | El botón crece en alto, nunca trunca | Envuelve |
| `boton-secundario` | `body` | SF · regular | Crece en alto | Envuelve |

**Regla de expansión:** el español alarga alrededor de un 25 % respecto al inglés. Solo `titulo-pantalla` puede truncar, y solo porque lo hace el sistema. Ningún otro rol trunca.

---

## 3. Espaciado, radios y densidad

### 3.1 Escala (unidad base: 4 pt)

| Token | Valor |
|---|---|
| `espacio-1` | 4 |
| `espacio-2` | 8 |
| `espacio-3` | 12 |
| `espacio-4` | 16 |
| `espacio-5` | 24 |
| `espacio-6` | 32 |
| `espacio-7` | 48 |

Un número suelto en una vista es un token que falta.

### 3.2 Densidad

| Token | Valor |
|---|---|
| `margen-pantalla` | `espacio-4` (en horizontal: leading/trailing) |
| `relleno-tarjeta` | `espacio-4` |
| `separacion-tarjetas` | `espacio-3` |
| `separacion-secciones` | `espacio-5` |
| `separacion-chips` | `espacio-2` |
| `alto-fila-minimo` | 44 |
| `objetivo-toque-minimo` | 44 × 44 |

### 3.3 Radios

| Token | Valor | Rol |
|---|---|---|
| `radio-tarjeta` | 16, continuo | Tarjetas y bloque generado |
| `radio-campo` | 12, continuo | Campo de captura y de pregunta |
| `radio-foto` | 12, continuo | Foto en tarjeta y en detalle |
| `radio-chip` | cápsula | Chips de elemento |

### 3.4 Grosores

| Token | Valor |
|---|---|
| `trazo-separador` | 1 píxel físico |
| `trazo-borde-tarjeta` | 1 pt (solo alto contraste) |
| `trazo-chip-conocido` | 1,5 pt |
| `trazo-vinculo` | **Solo en el tejido (F9).** Grosor de un vínculo entre dos elementos según cuántos recuerdos comparten: 1 → 1,5 pt · 2 → 2,5 pt · 3 → 3,5 pt · 4 o más → 4,5 pt |
| `trazo-conexion` | **Solo en el momento de la conexión (§8.2.2).** Trazo único de 2,5 pt, sin variar con el número de recuerdos: el motivo lo da el texto, no el grosor |

Fuera del tejido y del momento de la conexión no se dibujan trazos de unión. En el detalle de un recuerdo, la conexión es una fila con el símbolo `link` y su motivo.

El grosor del vínculo tiene un máximo para que un elemento con muchos recuerdos no tape el tejido. El número exacto de recuerdos compartidos se da siempre en la lista contigua (§9.4).

---

## 4. Iconografía

Solo SF Symbols. Escala `medium`. El peso acompaña al texto contiguo.

| Rol | Símbolo | Nota |
|---|---|---|
| Persona | `person.fill` | Con `tipo-persona` |
| Lugar | `mappin.and.ellipse` | Con `tipo-lugar` |
| Objeto | `cube.fill` | Con `tipo-objeto` |
| Pestaña Memoria | `square.stack` | |
| Pestaña Preguntar | `text.magnifyingglass` | No es burbuja: no es un chat (§5) |
| Contar un recuerdo | `square.and.pencil` | Botón de la barra de herramientas de Memoria en todos los tamaños de texto, con el estilo prominente de vidrio del sistema teñido con `acento-hilo`; nunca flotante, a ancho completo ni con un círculo dibujado a mano. Solo los estados vacío y de un recuerdo añaden además un `boton-principal` dentro del contenido |
| Foto | `photo` | |
| Fuentes | `text.quote` | |
| Conexión | `link` | Junto al motivo |
| Hebra suelta | `questionmark.circle` | |
| Estado aviso | `exclamationmark.triangle.fill` | Con `estado-aviso` |
| Estado éxito | `checkmark.circle.fill` | Con `estado-exito` |
| Estado error | `exclamationmark.octagon.fill` | Con `estado-error`. Sin uso en el MVP desde la 1.4: el error de comprensión usa el símbolo de aviso |
| Filtro de tipo activo | Símbolo del tipo | Chip de filtro con `seleccionado` y marca de estado del control |
| Descartar | `xmark` | |
| Ajustes | `gearshape` | |

Todos los nombres de símbolo se verifican en SF Symbols contra la versión mínima de `ADR-000` antes de F4.

Direcciones: **leading / trailing**, nunca izquierda / derecha.

---

## 5. Movimiento

| Token | Duración | Curva | Uso | Con Reducir movimiento |
|---|---|---|---|---|
| `mov-aparicion-elemento` | 0,30 s | spring suave, sin rebote | Cada elemento que aparece mientras el modelo lee (§8.2.1) | Fundido de 0,15 s |
| `mov-conexion` | 0,60 s | ease-in-out | El hilo que une con lo ya conocido al guardar (§8.2.2) | Aparece el estado final con fundido de 0,20 s. El anuncio de VoiceOver no cambia |
| `mov-cambio-estado` | 0,20 s | ease-out | Paso entre estados de §10.2 | Sin animación |
| `mov-llegada-generado` | 0,20 s | ease-out | Aparición del bloque de respuesta o retrato | Sin animación |
| `mov-streaming` | — | — | El texto generado entra según llega, sin animación propia | Igual |

**Ningún movimiento transmite información que no esté también en el estado final.**

---

## 6. Icono de app

| Variante | Contenido | Token que sobrevive |
|---|---|---|
| Por defecto | Trazo de hilo continuo en `acento-hilo` (C) sobre `fondo` (C) | `acento-hilo` |
| Oscura | Trazo en `acento-hilo` (O) sobre `fondo` (O) | `acento-hilo` |
| Teñida | Solo el trazo, monocromo | **La forma**: el icono no puede depender del color |
| Clara | Trazo en `texto-primario` (C) sobre `fondo` (C) | Forma |

---

## 7. Fuera de este documento

- **Superficies del sistema:** teclado y dictado, `PhotosPicker`, alertas, diálogos de confirmación y la hoja de Ajustes como contenedor.
- **Widgets:** fuera del MVP (§14.2).
- **Orden y etiquetas de VoiceOver, AX5 real y alto contraste sobre la implementación:** se comprueban en dispositivo al cerrar cada fase con UI, no aquí.

---

## Histórico

- **1.0** — Redacción inicial.
- **1.4** — Apertura de F4 (DEC-43): el error de comprensión pasa a `estado-aviso` con su símbolo; `estado-error` queda solo como base de `destructivo`.
- **1.3** — Cierre de la 0.4: foto de tarjeta dentro del relleno, estilo del botón de contar, extracto centrado en la coincidencia.
- **1.2** — Tras el segundo handoff: `trazo-conexion` separado de `trazo-vinculo`; ubicación única de la acción de contar en todos los tamaños.
- **1.1** — Tras el primer handoff de Claude Design: chips de elemento (relleno, bordes, variante quitada), resalte de búsqueda sin color, proporciones de foto, símbolos de estado y del filtro de tipo, acción de contar en la barra de herramientas.
