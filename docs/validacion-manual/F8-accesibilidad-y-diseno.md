# F8.3 — Pasada de accesibilidad y matriz de diseño

Resultado de la tarea F8.3 (spec `docs/specs/F8_Ajustes_Espanol_Accesibilidad.md`, contratos 3 y 4),
2026-09-25. Dos fuentes: la auditoría estática de `auditor-accesibilidad` sobre las 18 vistas y la
matriz de renders (tamaño mínimo, AX5 en español, oscuro, contraste aumentado claro y oscuro) hecha
con `RenderPreview`. Lo que no se puede juzgar sin iPhone queda al final, para Rubén.

## Accesibilidad — hallazgos (0 BLOCKER · 3 MAJOR · 13 MINOR)

Estado tras F8.4 en la columna final.

| # | Sev. | Dónde | Hallazgo | Corrección | F8.4 |
|---|---|---|---|---|---|
| 1 | MAJOR | `MemoryDetailScreen` chips de elemento | Chip como `NavigationLink` mide ~28 pt y va apilado a 4 pt: objetivo < 44 | `minHeight: objetivoToqueMinimo` + `contentShape`, separación `separacionChips` | hecha |
| 2 | MAJOR | `MemoryDetailScreen` comprender más tarde | Al pulsar no se anuncia «Reading your memory…» ni el aviso si falla | `onChange` de la fase: anunciar la cadena existente y el aviso de `ComprehensionNoticeCopy` | hecha |
| 3 | MAJOR | `ReviewScreen` quitar/deshacer, «Not the same», dudas | El foco de VoiceOver se pierde al sustituir la vista enfocada | `@AccessibilityFocusState` por `ReviewItemID`, reasignado tras cada acción; anuncio de quitado con `ReviewCopy.removedElementLabel` | hecha (foco); anuncio de duda respondida = texto nuevo, pendiente de Rubén |
| 4 | MINOR | `ElementRow` | P2: fila símbolo+nombre+recuento no pasa a columna en AX | `AnyLayout` como `ReviewScreen.rowLayout` | hecha |
| 5 | MINOR | `ElementDetailScreen` cabecera | P2: símbolo + nombre `largeTitle` en `HStack` a AX5 | `AnyLayout` a `VStack` en AX | hecha |
| 6 | MINOR | `ElementDetailScreen` cabecera | Sin `.isHeader`: el rotor no encuentra nada en S5 | `.accessibilityAddTraits(.isHeader)` | hecha |
| 7 | MINOR | `MemoryDetailScreen` «Saved without analyzing» | `tituloSeccion` sin `.isHeader` | `.accessibilityAddTraits(.isHeader)` | hecha |
| 8 | MINOR | `ReviewScreen` «Your words, as you wrote them» | No es encabezado | `.accessibilityAddTraits(.isHeader)` | hecha |
| 9 | MINOR | `ReviewScreen` cabecera de grupo | P1: color de tipo sobre el texto `metadato`, no solo sobre el símbolo | Color solo en `icon:`, texto en `textoSecundario` | hecha |
| 10 | MINOR | `ConnectionMomentScreen` «Memory saved» | Símbolo del `Label` no oculto a VoiceOver | `.accessibilityHidden(true)` en el icono | hecha |
| 11 | MINOR | `ElementChip` | `accessibilityLabel` sobre `Label` sin `children: .ignore` | Añadir `.accessibilityElement(children: .ignore)` | hecha |
| 12 | MINOR | `ElementRow` | `.combine` monta el anuncio desde los textos visibles, no desde la función pura probada | `.ignore` + `element.accessibilityLabel(memoryCount:locale:)` | hecha |
| 13 | MINOR | `ConnectionMomentScreen` anuncio | Publicado en `onAppear` de una hoja, puede competir con el anuncio de pantalla | Comprobar en dispositivo; si se corta, `@AccessibilityFocusState` sobre «Memory saved» | dispositivo |
| 14 | MINOR | `CaptureScreen` inicio de comprensión | «Reading your memory…» solo visual | Anunciar la cadena existente al entrar en `.comprehending` | hecha |
| 15 | MINOR | `MemoriesView` búsqueda | VoiceOver no sabe cuántos resultados hay | Anunciar en `onChange` de `memoriesDisplay`; «N recuerdos» es texto nuevo | pendiente de Rubén (texto) |
| 16 | MINOR | `ElementsView` filtro | Tocar el chip activo vuelve a «All» sin hint | Hint solo en el chip seleccionado; texto nuevo | pendiente de Rubén (texto) |

Comprobado sin hallazgo: el relato nunca lleva `lineLimit` en un detalle; sin tamaños fijos, sin
`minimumScaleFactor`, sin left/right; Reducir movimiento con el mismo estado final en los dos
movimientos; nada comunicado solo por color; compuestos en español montados y con plural.

## Diseño — matriz de apariencias (contrato 4, DEC-58)

Renders: Memoria (X Small; oscuro AC), Captura (claro AC), Revisión (claro AC; AX5 en español),
Detalle de recuerdo (claro AC), Detalle de elemento (oscuro AC), Momento de la conexión (claro AC),
Elementos (claro AC), Ajustes (claro AC, oscuro, AX5, español).

Contradicen `tokens.md` → corregidas en F8.5:

| # | Dónde | Desviación | Corrección |
|---|---|---|---|
| D1 | `Assets.xcassets/AccentColor.colorset` vacío | Todo control con tinte del sistema sale en azul (Deshacer, «No es el mismo», Añadir foto, Guardar sin analizar, Cancelar/Cerrar, Hecho, Renombrar, alertas). El azul no existe en la paleta; las referencias 09, 10 y 11 dibujan las acciones secundarias en `texto-primario` («Done no es acento: la acción ya ha ocurrido») | AccentColor = `texto-primario` en las cuatro apariencias. Los `.tint(acentoHilo)` explícitos (selector, contar, acción principal) se quedan |
| D2 | `MemoryCard`, `ElementChip` | `borde-tarjeta` y `borde-chip-nuevo` existen como colorset pero ninguna vista los usa: en alto contraste (ref. 15c/15d, tokens §1.5) tarjeta y chip nuevo van sin contorno | Trazo `borde-tarjeta` (1 pt) en la tarjeta; `borde-chip-nuevo` en el chip |
| D3 | `AjustesScreen` en claro AC | `superficie-tarjeta` y `fondo` son ambos `#FFFFFF`: las filas desaparecen | Mismo trazo `borde-tarjeta` sobre el fondo de fila |
| D4 | `MemoriaScreen` selector | «People, places & objects» trunca a tamaño por defecto; tokens §2.2 solo permite truncar a `titulo-pantalla`. La referencia 02a/07c pone el selector en el contenido, bajo la barra, a ancho completo | Mover el picker del toolbar al contenido |

Matices de la referencia que no se implementan (van a `docs/design/README-design.md`):

- Ref. 02a usa título grande «Memory»; la app usa título inline (DEC-12, F5.2). Reconsiderar cuando el
  selector baje al contenido es decisión de Rubén.
- Ref. 02b dibuja «Tell a second memory» como bloque sobre `superficie-hundida` con botón compacto con
  icono; la app usa el botón principal a ancho completo, que es lo que pide la spec de F5 (contrato 2).

## Para validar en el iPhone (no comprobable desde código ni simulador)

- Contraste real de las cuatro apariencias con Aumentar contraste activado.
- Orden real de lectura de VoiceOver en cada pantalla; si el símbolo de un `Label` se verbaliza.
- Si el anuncio del momento de la conexión se corta al abrirse la hoja (hallazgo 13).
- Pérdida de foco en Revisión tras quitar/deshacer/responder una duda (hallazgo 3) y objetivos de los chips de S4 con Switch Control (hallazgo 1).
- AX5: `ElementRow`, cabecera de S5, barra de Memoria, alertas de renombrar con `TextField`.
- Tamaño de texto más pequeño: legibilidad de `metadato` y `motivo-conexion`.
