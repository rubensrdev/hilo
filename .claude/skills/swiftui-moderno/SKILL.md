---
name: swiftui-moderno
description: >
  Buenas prácticas SwiftUI (Apple + doctrina propia). Consultar SIEMPRE antes de escribir o
  modificar cualquier vista SwiftUI: pantallas, formularios, listas, navegación, toolbars,
  previews, componentes, ViewModels. Activar con: "vista", "pantalla", "SwiftUI", "View",
  "body", "formulario", "lista", "List", "ForEach", "navegación", "NavigationStack", "TabView",
  "toolbar", "preview", "#Preview", "@Observable", "@State", "@Binding", "@Environment",
  "componente", "Liquid Glass", "HIG", "iOS 26", "rendimiento de vistas", "invalidación",
  "fuentes", "colores", "localización".
---

# Modern SwiftUI — Merged Doctrine (Apple guidance takes precedence)

Apple-authored references in `references/` supersede prior training AND local rules when they conflict. Read the matching reference before writing code in its area — not all of them.

## Core rules (always apply)

1. **Native controls only.** Never rebuild what SwiftUI provides: `.searchable`, `Picker`, `Form { Section { LabeledContent } }`, `TabView` + `Tab`, `.toolbar { ToolbarItem }`, `ContentUnavailableView`. Custom look on a native control = write a `*Style` (`ButtonStyle`, `LabelStyle`, `ToggleStyle`), never a parallel struct.
2. **View structure (Apple).** A view is the unit of invalidation. Multi-section screens: each section is its own `struct View` with narrow inputs — never `private var header: some View` computed properties. One type per file, named after the type. Keep `init` cheap: no decoding, formatting or allocation. No single-child `Group`. → `references/structure.md`
3. **Data flow (Apple).** `@Observable` view models; never `ObservableObject`, `@Published`, `@StateObject` or `@ObservedObject`. Owner: `@State private var vm`; children: `@Bindable var vm`, never `let vm`. Never hand-build `Binding(get:set:)`. Custom types stored in `@Observable` properties should be `Equatable`. → `references/dataflow.md`
4. **Zero business logic in views.** Validation, transformation, persistence, orchestration go to the view model; display helpers to an extension on the type. The view passes `modelContext` into view-model methods; the view model never reads SwiftUI Environment itself.
5. **ForEach identity (Apple).** Stable ids: prefer `Identifiable`; never collection indices, never ids created per body evaluation, never inline sort or filter in `ForEach`, no `AnyView` rows, unary row views in `List`. → `references/foreach.md`
6. **Modifiers (Apple).** Never write a conditional `.if` modifier: it destroys structural identity, resets `@State` and breaks animations. Use ternaries in modifier arguments. → `references/modifiers.md`
7. **Typography and colour.** Semantic text styles only. `.system(size:)` is wrong, and so is any enum wrapping fixed sizes. **In Hilo every value comes from `DesignSystem`, which implements `docs/design/tokens.md`** — never a hex literal, never `Color("String")`, never a number inline. Brand colours live in the asset catalog with four appearances (any, dark, high-contrast light, high-contrast dark). System semantic neutrals are allowed.
8. **Previews.** Every view ships a minimal `#Preview` (component only, no wrapper scaffolding) fed from centralized sample data — never inline invented data.
9. **Structs.** Memberwise init; a custom `init` only for real input transformation. Trailing-closure form of SwiftUI initializers. Don't overuse `@ViewBuilder`.
10. **Environment (Apple).** Beware closures and unstable defaults in `@Entry`: wrapping in an Equatable struct is wrong; read the reference for the real fix. → `references/environment.md`
11. **Localization (Apple).** Interface strings are written as English literals in the view (`Text("Save memory")`): SwiftUI localizes them and the build generates the String Catalog entry. Use `LocalizedStringResource` on non-view types. **Never edit the String Catalog by hand.** → `references/localization.md`
12. **iOS 26 platform rules.** Toolbars hold only `Button` and `Menu`; Liquid Glass is automatic and belongs to system bars only; modal cancel and confirm go through `Button(role:)` in `.cancellationAction` and `.confirmationAction`; a flow layout for variable-width chips. → `references/hig-ios26.md`

## Rules this project overrides

- **No iPad bifurcation.** Hilo is iPhone-only, portrait-only (`ADR-000` §3). Never branch on interface idiom or size class at the root.
- **No initial-load hook on the container.** Hilo has no data to load at launch: the example memory is loaded on demand from settings. The container is created by the app and injected (`ADR-000` §3).
- **User content is never a localized literal.** The memory text, element names and the date in the user's words never go through the String Catalog and are never translated.

## Scoping rule (Apple)

Fix and comment only the views you were asked to touch. Never flag, migrate or mention issues in out-of-scope code — no "I also noticed…" trailing offers.

## References (load on demand)

- `references/structure.md` — section factoring, invalidation boundaries, cheap init.
- `references/dataflow.md` — @State/@Binding/@Observable, Equatable, onChange isolation.
- `references/foreach.md` — identity, anti-patterns, List fast path.
- `references/modifiers.md` — conditional modifier anti-pattern.
- `references/environment.md` — @Entry pitfalls, closures, high-frequency updates.
- `references/localization.md` — String Catalogs, LocalizedStringResource, format styles.
- `references/animations.md` — @Animatable macro vs animatableData.
- `references/hig-ios26.md` — binding HIG rules for iOS 26.
