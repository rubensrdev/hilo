---
name: concurrencia-swift
description: >
  Concurrencia estricta Swift 6 con Approachable Concurrency (SE-0461, SE-0466). Consultar al
  escribir o revisar código con: "async", "await", "Task", "actor", "@MainActor", "Sendable",
  "@concurrent", "nonisolated", "aislamiento", "isolation", "data race", "concurrencia",
  "TaskGroup", "async let", "continuation", "AsyncStream", "DispatchQueue", "GCD",
  "strict concurrency", "Swift 6", "warning de concurrencia", "cancelación", "streaming".
---

# Swift 6 Strict Concurrency

Full reference with code patterns: `references/swift-62-reference.md`. Load it when applying any rule below in real code.

## This project's setting

**Default actor isolation is `MainActor`** (`ADR-000` §2, SE-0466). Consequences, and they run the opposite way to most projects:

- Views and view models need no annotation.
- **Everything in `Domain/` is declared `nonisolated` by hand**, and its value types are `Sendable`. A missing annotation silently ties the domain to the main actor; the domain tests catch it by calling without `await`.
- Work that does not belong on the main actor leaves it explicitly: `@concurrent` for genuinely background work, a dedicated actor for shared mutable state, `@ModelActor` for persistence writes.

## Non-negotiables

- `nonisolated(unsafe)` is **absolutely forbidden**. Never silence a data race with it, with `@unchecked Sendable` or with `@preconcurrency` — **there is no exception in this project**, not even for a reference type. Fix it with real isolation or with type constraints.
- Never bridge actors with `withCheckedContinuation` wrapping `Task { @MainActor in }` — extract a `@MainActor async` function and `await` it.
- `async`/`await` only: no GCD, no completion handlers, no Combine.

## Swift 6 model (know before writing)

- **SE-0461**: a `nonisolated async` function runs on the caller's actor by default. Opt out with `@concurrent` only when background execution is genuinely needed. `Task {}` inherits isolation from an isolated context and stays nonisolated in a nonisolated one.
- Value types whose properties are `Sendable` are `Sendable` automatically — no redundant conformances.
- Typed throws erase inside `Task {}`: a `throws(ConcreteError)` call needs a typed `catch` plus an unreachable generic `catch` for exhaustiveness.

## Patterns

- Shared mutable state → `actor`. Persistence writes off the main actor → `@ModelActor`, which is the single write point.
- **SwiftData models are not `Sendable`.** Across an isolation boundary, pass a persistent identifier or an extracted `Sendable` value, never the model.
- Fixed parallel set → `async let`; dynamic collection → `TaskGroup`. Never serial `await` in a parallelizable loop.
- Long loops → `try Task.checkCancellation()` each iteration.
- **Model streaming**: consume it in a task tied to the view's lifetime and cancel it when the screen goes away. Never in a detached task, never outliving its screen. Partial snapshots are incomplete by definition: never persist or decide from one.
- `Task.detached` inherits nothing; hop back with `await MainActor.run {}`. Use it only with a reason.

## Checklist before closing any concurrent change

- [ ] Zero concurrency warnings — one warning invalidates every later verification
- [ ] No `nonisolated(unsafe)`, `@unchecked Sendable` or `@preconcurrency` introduced
- [ ] Every type and function in `Domain/` is `nonisolated`
- [ ] Every `Task {}` has a clear isolation context
- [ ] No non-`Sendable` value, and no `@Model`, crosses an isolation boundary
- [ ] `@concurrent` used only where background execution is measured or needed
