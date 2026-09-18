---
name: accesibilidad-ios
description: >
  Accesibilidad iOS/SwiftUI con criterios WCAG 2.2 AA. Consultar al escribir cualquier vista y
  OBLIGATORIO al cerrar una pantalla. Activar con: "accesibilidad", "accessibility", "a11y",
  "VoiceOver", "Dynamic Type", "AX5", "WCAG", "contraste", "hit target", "rotor",
  "reduce motion", "reduce transparency", "accessibilityLabel", "accessibilityHint",
  "ScaledMetric", "imagen decorativa", "auditoría de pantalla".
---

# iOS Accessibility (WCAG 2.2 AA)

Quick per-view rules: `references/quick-reference.md`. Full WCAG 2.2 AA mapping with crystallized patterns: `references/wcag-22-aa.md`. Load the full mapping when auditing a finished screen; the quick reference is enough while writing.

**Precedence:** where a reference contradicts Apple's own guidance, Apple wins. In particular, interface strings are English literals in the view — the build generates the String Catalog entry — and `String(localized:)` is not required inside views.

## While writing any view

- Every interactive element has an `accessibilityLabel`, plus a hint when the action is not obvious, plus `.accessibilityAddTraits(.isButton)` on tappable non-buttons. An SF Symbol inside a `Button`: the label goes on the button, not the symbol.
- Images: decorative → hidden from accessibility; informative → descriptive label.
- Group related elements so a card reads as one unit, not five fragments.
- Dynamic Type: semantic text styles, and a scaled metric for chrome that must grow. A placeholder is not a label.
- Announcements go through `AccessibilityNotification.Announcement`.

## Crystallized patterns (apply preventively)

- **P1**: a semantic colour goes on the symbol (needs 3:1), never on small text (needs 4.5:1). Split the styling inside `Label { } icon: { }`.
- **P2**: an `HStack` of image plus title switches to a `VStack` when the size is an accessibility size.
- **P3**: any custom material overlay ships a reduce-transparency fallback.

## Hilo specifics

- **The user's memory never truncates in a detail view**, at any text size. A card extract keeps its line count while the card reflows vertically.
- The memory text is read as one block, in the user's words, with no interface text interjecting.
- An element announces name, type and how many memories it appears in. A connection announces its reason. Generated text announces its sources and how many memories were left outside the cap.
- Type is never carried by colour alone: colour, symbol and text always travel together, and the pair stays distinguishable in greyscale.
- Progressive appearance during comprehension is announced; with Reduce Motion the announcement is identical and the movement is gone.
- Contrast ratios are already decided in `docs/design/tokens.md` §1 — implement the token, don't re-derive a colour.
- Audit the Spanish interface too: composed labels order differently.

## Screen close-out gate (mandatory)

Before declaring a screen done, render and check: default size, small, **AX5**, dark mode, and Reduce Motion if it animates. Verify hit targets of at least 44 pt, no horizontal text scrolling, visible focus with modals, and that nothing clips or overlaps. Report findings with `file:line`.

Deep VoiceOver verification on a real device belongs to Rubén at phase close. Say what you could not check.
