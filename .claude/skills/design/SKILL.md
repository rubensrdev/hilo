---
name: design
description: >
  Cómo llevar el contrato visual de Hilo a una pantalla: tokens, referencia de diseño y su
  precedencia. Consultar al implementar o modificar cualquier superficie visible. Activar con:
  "tokens", "diseño", "color", "tipografía", "espaciado", "radio", "animación", "maqueta",
  "referencia de diseño", "se parece a la captura", "estilo", "DesignSystem".
---

# Applying Hilo's visual contract

## Precedence, in this order

1. **The phase spec** in `docs/specs/` — what the screen must do and say.
2. **`docs/design/tokens.md`** — every colour, type role, spacing, radius, stroke and motion value. Exact values come from here.
3. **`docs/design/README.md`** — design notes and the list of known deviations in the reference that must **not** be implemented.
4. **`docs/design/reference/`** — static images. Reference only, never a source of truth.

When an image and a spec disagree, the spec wins and you say so. When an image shows something that is not in `tokens.md`, it is the image that is wrong.

## Rules

- **Never read a value off an image.** No eyedropper, no measuring pixels, no guessing a font size.
- **Never invent a token.** If a surface needs a value that `tokens.md` does not define, stop and ask for the token. A number written inline is a defect, and `revisor-constitucion` will flag it.
- **Every value goes through `DesignSystem`**, which implements the tokens. Views never carry a hex, a point size or a raw number.
- **Text styles, never fixed sizes.** Each typographic role maps to a system text style; the roles for the user's own words use the serif family.
- **Colour is never the only signal.** An element's type shows colour, symbol and text together.
- **Four appearances.** Every colour exists in light, dark and both high-contrast variants. Check a surface in all four before calling it done.
- **Motion has its Reduce Motion branch**, and the information in the final state is identical with and without movement.
- **Liquid Glass only where the system puts it**: tab bar, navigation and toolbars. Never over cards, the memory text or photos.
- **No text on top of a photo.** Ever.

## When the reference suggests a product change

It happens: a handoff shows an action, a label or a behaviour that the spec does not have. Do not implement it and do not quietly drop it — report it as a question for Rubén. The same applies in reverse: if the spec asks for something the reference never drew, build it from the spec.
