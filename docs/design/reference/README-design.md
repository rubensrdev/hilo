# Diseño — Hilo

`reference/` es referencia visual; `tokens.md` es el contrato. Si una imagen contradice `tokens.md` o una spec de fase, ganan `tokens.md` y la spec.

| Fichero | Qué es |
|---|---|
| `tokens.md` | Contrato visual (1.2) |
| `brief-F4-F5.md` | Brief del lote F4–F5 y su criterio de aceptación |
| `reference/` | 15 PNG y README de Claude Design (F4 y F5) |

## Desviaciones conocidas de `reference/`

No se implementan a partir de la imagen:

- **`relato-detalle` (20 pt) en 12:** no es un token. El relato usa `relato` sobre el text style `body`.
- **Fecha en 12c:** un recuerdo guardado sin analizar no tiene fecha entendida; el detalle no la muestra.
- **Filas de 11 sin símbolo `link`:** cada fila conectada lleva `link` y motivo, como en 05 y 12a.
- **Nota de 12 «editar el recuerdo vuelve a Revisión»:** pendiente de decisión (B10). No se implementa.
- **Texto de 12d («José, Carmen and Granada stay»):** debe calcularse; un elemento que se queda sin recuerdos desaparece (regla 11).
- **Alias en 13:** falta en la imagen; la spec de F5 lo define.

El lienzo `#E4DFD6`, los marcos de iPhone y los sustitutos geométricos de SF Symbols son andamio de la entrega.
