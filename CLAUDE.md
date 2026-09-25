# CLAUDE.md

Contract for Claude Code in this repository. Rules here override defaults and habits.

`docs/specs/F0_INDICE_Y_CONSTITUCION.md` is the constitution — it prevails over any other technical practice in this repo, and is read, never implemented. Product-level conflicts fall back to the Idea Especificada v2.3 instead. This file is the short operational summary of that constitution, not a replacement for it.

Hilo is a private personal memory: the user tells a memory in their own words, the app recognises the people, places and objects in it, lets the user review what it understood, and connects that memory to earlier ones. Everything happens on the device.

## Stack

- Swift 6.2+, language mode 6, strict concurrency. Default actor isolation is **MainActor**, single target. Approachable Concurrency ON.
- SwiftUI only. iOS 26.4 minimum, iPhone, portrait. Built with Xcode 27 and the iOS 27 SDK.
- SwiftData, Swift Testing, Foundation Models.
- Third-party dependencies: none, in the app and in the tests. No exception.
- Typography: New York for user-authored content (the memory text and the date in the user's words), SF for everything else, including model-written text.

## Build & test

**Never** use `xcodebuild` or any Xcode CLI tool for building, testing, or reading errors. **Always** go through the Xcode MCP server — see the `xcode` skill for the exact tool calls.

- If the MCP server is unavailable, stop and ask. Never fall back silently.
- **Never** edit `project.pbxproj` directly. Project settings change through Xcode or the MCP.
- A phase is not done until the last build log shows zero errors **and** zero warnings.

## Architecture

Folders in a single target. The boundary is enforced by review and by a hook, not by the compiler — treat it as if it were.

| Folder | Responsibility | May import |
|---|---|---|
| `Domain` | Value types and pure rules | Standard library and `Foundation` only |
| `Persistence` | Schema and data access | `Domain`, SwiftData |
| `Intelligence` | Protocols for comprehension, question interpretation and writing, plus their implementation | `Domain`, FoundationModels |
| `Shared` | Types used by more than one screen — banners, locale helpers. `Shared/Previews/` holds DEBUG-only preview fixtures, never shipped code | `Domain`, SwiftUI |
| `Features` | One folder per screen | All of the above, SwiftUI |
| `DesignSystem` | Typed access to the tokens | SwiftUI |

- **Never** import SwiftUI, SwiftData, FoundationModels or PhotosUI from `Domain`.
- Every type and function in `Domain` is declared `nonisolated`, and its value types are `Sendable`.
- **Never** put a product rule inside a view. Views read state and emit intent; every rule lives in a testable type outside SwiftUI.
- The language model is injected through protocols so every test is deterministic.

### Folders inside a zone

- `Domain`, `Persistence` and `Intelligence` group their files into subfolders **by concept** — what the type represents in the product — never by technical nature ("protocols here, structs there").
- A `Features` screen folder stays flat until a role repeats inside it. Once two files share a role, split that role out: `Screen/`, `State/`, `Copy/`, `Coordinator/`. A role with a single file stays loose in the screen folder — **never** create a subfolder for one file.
- The vocabulary is `Screen` / `State` / `Copy` / `Coordinator`. **Never** `ViewModel`, **never** a generic `Components/`: this project has no MVVM layer (`ADR-000` §5, no ceremonial layers).
- A type shared by two or more screens moves to `Shared`; it does not live inside one screen's folder. DEBUG-only preview fixtures go to `Shared/Previews/`, wrapped in `#if DEBUG`, never mixed with shipped types.
- Groups in Xcode are folder-backed and mirror the file system exactly. **Never** a virtual group, and **never** move a file with `mv` or by editing `project.pbxproj` — use the Xcode MCP.

## Non-negotiable rules

### Testing

- **Never** write UI tests of any kind — no UI automation, no snapshot comparison, no view-hierarchy assertions. UI is validated manually at phase close.
- **Never** use XCTest. Swift Testing only.
- Test-first: red, green, refactor. If a rule cannot be tested without building a view, the design is wrong — say so instead of writing the view.
- Announceable strings (composed VoiceOver labels, the over-the-cap notice, the honest acknowledgement) are produced by pure functions and tested in both languages without opening the app.

### Previews

- Every SwiftUI view ships with at least one `#Preview` using representative state, written in the same atomic task that creates the view — never left for later, never for "the phase that needs it".
- One more `#Preview` per visually distinct state driven by the view's `State` — error, empty, loading. Distinct means the layout changes, not every possible combination of values.
- Preview data comes from the example memory or from fixtures that already exist; **never** invent new sample content to fill a preview.
- No hook can enforce this — a hook checks the destination path, never the content. `revisor-constitucion` checks it on every task that touches UI.

### Language & APIs

- `async`/`await` only. Never completion handlers, never `DispatchQueue`, never Combine.
- `@Observable`, never `ObservableObject`. `NavigationStack`, never `NavigationView`.
- `Codable` only. **Never** `JSONSerialization`.
- **Never** `AnyView`, force unwrap, or `print()`. Use `Logger`.
- Work that does not belong on the main actor leaves it explicitly, with `@concurrent` or a dedicated actor. `nonisolated` is written by hand on every `Domain` type — a missing annotation is a defect, not a detail.
- Verify every iOS API against Cupertino MCP before using it, targeting iOS 26.4. **Never** an API above the deployment target.
- The SDK is newer than the deployment target, so the compiler is not the only guard. **Never** add an availability check to reach an API newer than iOS 26.4: keep the 26.4 API and bring the decision to Rubén. An availability check written to use something newer is a BLOCKER.
- **One exception, and only one**: `if #available(iOS 27, *)` is allowed solely to catch and map an error the system throws at runtime that has no iOS 26.4 equivalent — today, only `FoundationModels.LanguageModelError` in the comprehension `catch` (`ADR-001` §3). On 26.4 that type does not exist and is never thrown, so the check is inert there. Never to call an API, store a type in a model, or enable new behavior. Any other availability check is still a BLOCKER.
- **Comments are written in English, doc-comment style (`///`) where the type or function needs one.** They explain a decision, never the code: write one only where the reason is not visible in the code itself — a trade-off, a non-obvious ordering, a rule from the spec the code alone does not reveal.
- One or two lines, plain natural language, the way Rubén would note something for his future self. **Never** a paragraph, **never** a file header comment, **never** a doc-comment on every symbol, and **never** a comment that restates the line below it.
- Clarity comes first from names, types, structure and small units. If a function needs a comment to be understood, try a better name or a smaller function first.
- Cite a phase or task number only when the comment is explaining a real constraint the code alone would not reveal — never as routine attribution. A product rule from the spec is usually worth citing in three or four words — `/// Rule 11: an element with no memories left disappears.` — a task ID rarely is.
- Soft-deprecated APIs already present in a file you edit: keep them, deliver the change, propose migration as a separate task. Apple's scoping rule wins over the modernity rule.

### Data

- SwiftData models are not `Sendable`. **Never** pass a model across actors: pass persistent identifiers or extracted `Sendable` values.
- Writes off the main actor go through a model actor. The container is created by the app and injected; there is no initial load at launch.
- The photo is stored as external data and is **never** analysed.
- Connections between memories are derived, never stored.
- Persisted property names are ASCII, no diacritics.
- No CloudKit, no sync, no migration story: a single local store.

### Localization & accessibility

- Interface strings are English literals in the view; the build generates the String Catalog entry. Translations are written **only** through the Xcode MCP's String Catalog tools — **never** by hand-editing the `.xcstrings` file. 2 languages declared: English base, Spanish complete.
- **Always** declare a string as plural if it contains a quantity.
- **Never** hardcode a date or number format. Use system format styles.
- **Always** use leading/trailing, never left/right.
- **Never** use a fixed font size. Every text style scales with Dynamic Type, up to AX5.
- Every interactive element has an accessibility label, ≥44pt touch target, and respects Reduce Motion.
- User content — the memory text, element names, the date in the user's words — **never** goes through the String Catalog and is **never** translated.

### Product

- **Never** rewrite, correct or reformat the user's words.
- **Never** display a date the user did not write. The deduced year only sorts and groups; it is never shown as a date.
- **Never** show generated text whose sources are missing or have changed. Sources shown are exactly the memories handed to the model — never the ones the model claims to have used.
- **Always** say how many memories were left outside the cap when material was dropped.
- With no material, there is no generation: the honest acknowledgement is interface text, not a model answer.
- **Never** show an element's type by colour alone: colour, symbol and text always travel together.
- **Never** put text on top of a photo.
- **Never** use the word "element" in the interface — the user sees people, places and objects.
- **Never** use AI iconography (sparkles, wands, brains), chat bubbles or avatars.
- **Never** add network code, analytics or telemetry. The app works end to end in airplane mode.
- **Never** log the text of a memory, an element name, a question or an answer. Use identifiers or the logging system's privacy controls.
- Deleting is real: it includes photos and their external storage.

### On-device AI

- Apple Intelligence is a premise of this product, not a state: there is **no** interface for its absence, and the app never tells the user their device cannot do something. But the code must not fail when the model does not answer — it falls into the same path as a comprehension error.
- Bound model output by generable type, not by prompt instruction. Validate before use.
- **A failed comprehension is a product state, not a silent fallback.** Context overflow, guardrail block, refusal, unsupported language, unavailable assets and a decoding failure all end in "saved without analyzing, and told why". The user's text is never lost.
- Two error cases are defects of ours, not product states, and are fixed rather than explained to the user: an unsupported generation guide, and two concurrent requests on one session.
- One session per generation. No history is kept between generations.
- Three uses, three closed contracts: extracting a memory, interpreting a question, writing an answer or a portrait.
- **Never** route to a server model, even if the system offers it.
- Whatever can be decided with certainty is decided with certainty: canonical names, element resolution, retrieval steps 1 and 3, ordering, the cap, portrait validity and gap detection are pure functions. The model never decides which memories answer a question.
- The retrieval cap is derived from the session's context size by a single pure function, with a floor and a ceiling, from the parameters in `ADR-001`. **Never** write a cap value as a literal, and **never** read the context size inside a test — inject it.
- `tokenCount(for:)` is spike instrumentation, not runtime code: **never** count tokens before a generation.

## Documentation

| Path | What it is |
|---|---|
| `docs/specs/` | One spec per phase, `F0` to `F10`. Technology-free functional requirements — the contract for what to build |
| `docs/decisions/` | ADRs, only for decisions that are expensive to reverse. `Estado: Proposed` means still open; `Accepted` ones are closed and must not be reverted |
| `MEMORY.md` | Cross-session memory: decisions, known errors, and patterns learned — the place to propose a new rule |
| `docs/design/tokens.md` | The visual contract. Every colour, type, spacing, radius and motion token with its role. Exact values come from here, never from an image |
| `docs/design/README.md` | Design notes, and the list of known deviations in `reference/` that must not be implemented |
| `docs/design/reference/` | Static design references. Reference only — **never** a source of product truth, and never a substitute for the phase spec |

When implementing a screen, cross-reference the phase spec, the design README section, and `tokens.md` — never eyeball a screenshot. If the design handoff and a phase spec disagree, the phase spec wins; flag the conflict instead of silently choosing.

**Language of written files:** `CLAUDE.md`, `MEMORY.md`, and every `.claude/skills/*/SKILL.md` and `.claude/agents/*.md` are always written in English, regardless of the conversation's language. Product vocabulary with no 1:1 translation (*hilo*, *recuerdo*, *elemento*) and literal quotes from the Spanish spec corpus (e.g. `Estado: Proposed`) are the only exceptions. This does **not** apply to `docs/`: that corpus is authored in Spanish on purpose.

## Session protocol

One phase at a time, one atomic task per turn — never start code before the plan is confirmed, and never open the next phase before the current one's closing conditions are met, in this order:

1. Build and tests green, with the phase's test criteria verified.
2. New strings in the String Catalog and accessibility labels declared.
3. The audits named in the phase's **Verificación** block, with no BLOCKER.
4. Manual on-device validation by Rubén, for any phase that touches UI.
5. `MEMORY.md` updated, and the commit `F<phase>-complete: <one-line summary>`.

A phase is opened by its spec, not by an ADR: ADRs exist only for decisions that are expensive to reverse.

### Opening a session

Before touching any code: read `MEMORY.md` in full, the current phase spec in `docs/specs/`, and any ADR still in `Estado: Proposed`. For a phase whose **Verificación** block says it touches UI, read `docs/design/README.md` and `tokens.md` too, and load the `accesibilidad-ios` skill — on a non-UI phase that skill only costs tokens.

Then say, in one paragraph: current state, next atomic task, and any known risk or blocker. **Write no code until Rubén confirms the plan.**

### During a phase

- One atomic task at a time: propose, wait for approval, implement, and stop so Rubén can read the diff.
- **A task touching three or more files, the schema, concurrency or navigation goes through Plan Mode, and the plan is written to disk** — a plan that only lives in the conversation does not survive a `/clear`.
- After any change that affects UI, run `verificador-ui` in a loop until it passes. **Its green is the exit condition**, not the diff and not your own opinion.
- On any concurrency or `Sendable` warning, run `auditor-concurrencia`.
- **Never modify a test so that it passes.** Fix the implementation. The test is the one source of truth in this project that does not degrade as the context fills up.

### Closing a phase

1. Run the audits named in the phase's **Verificación** block, starting with `revisor-constitucion` over the files changed in this phase. **One BLOCKER means the phase does not close**: fix and run it again until it comes back clean.
2. Clean build — the incremental one hides cached warnings — with zero errors and zero warnings.
3. Manual on-device validation by Rubén, for any phase that touches UI.
4. Update `MEMORY.md`: last session with date, task completed and next task; decisions taken in this phase; errors that cost time and how they were solved; and any rule worth keeping, in "Patrones aprendidos".
5. If this phase opened an ADR, close it: `Estado: Proposed` → `Accepted`, fill `Closed` and `Reason`, and add any decision taken during the phase that is not yet written down.
6. Commit `F<phase>-complete: <one-line summary>`, merge and push as described under Branching.
7. Say what the next atomic task is, reading `docs/specs/`. **Start no new code: closing is only closing.**

### `/compact` and `/clear`

- Same phase, still working: `/compact`, by hand and early — around 60% of the window, not 80%. Compacting loses detail, so the later you do it, the more you lose. A UI task with several preview iterations is a good moment.
- Back from a break, or changing phase: `/clear`, with the plan and the memory already written to disk.
- Close the session without discussion, compacted or not, when the agent repeats answered questions, contradicts a decision already taken, duplicates code it wrote itself, or ignores files it just created. That is not fixed by insisting: persist, clear, reopen.

At session start: read `MEMORY.md` and the current phase spec, plus any ADR still in `Estado: Proposed`.

When the work reveals a rule worth keeping — a repeating pattern, a mistake worth preventing, a convention we settled on — write it at phase close in the "Patrones aprendidos en este proyecto" section of `MEMORY.md`, one line, in Spanish like the rest of that file. **Never** edit `CLAUDE.md` itself: a hook blocks it, and promoting a pattern to a rule is Rubén's call. If a rule in this file is wrong or in your way, say so and stop.

## Branching

- **Never commit code to `main`.** Each phase runs on its own branch, created from `main` when the phase opens: `fase/F1-nucleo-de-dominio`, `fase/F4-captura-y-revision`.
- One commit per atomic task, prefixed with the task: `F1.2: nombre canónico`. The repo is green at every commit — build and tests pass.
- At phase close, once the five conditions above are met: commit `F<phase>-complete: <one-line summary>`, merge into `main` with `--no-ff`, and push both branches.
- **Never** merge a phase whose closing conditions are not met. **Never** rebase, and **never** force-push. If a branch gets tangled, stop and ask.
- **The F0.2 spike is the exception: it is throwaway.** Its code lives outside the app target and is **never** merged into `main`. What the spike delivers is a report and `ADR-001`.
- Documentation and governance — `docs/`, `CLAUDE.md`, agents, skills, hooks — are written by Rubén and land on `main` directly. They are never part of a phase branch.

## Skills

| Skill | Purpose | Status |
|---|---|---|
| `xcode` | Build, test and read errors through the Xcode MCP | Available |
| `cupertino` | Verify iOS 26.4 APIs before use | Available |
| `swiftui-moderno` | Views, navigation, previews | Available |
| `concurrencia-swift` | Streaming, model actor, cancellation tied to the view | Available |
| `nonisolated` | Explicit isolation under a MainActor default | Available |
| `apis-modernas` | Current iOS 26.4 APIs and the soft-deprecation rule | Available |
| `tests-de-verdad` | Test-first with real oracles | Available |
| `accesibilidad-ios` | VoiceOver, Dynamic Type, Reduce Motion | Available |
| `swiftdata` | Schema, identity across actors, external storage | Available |
| `foundation-models` | On-device generation: generable types, streaming, error paths | Available |
| `design` | Apply `tokens.md` to a surface | Available |
| `device-interaction` | Drive the simulator, including text entry — loaded by `verificador-ui` | Available |

Subagents live in `.claude/agents/`, one file per agent.
