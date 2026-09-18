---
name: nonisolated
description: >
  Cómo anotar aislamiento explícito en un proyecto cuyo aislamiento por defecto es MainActor.
  Consultar al escribir o revisar tipos de Domain, funciones puras, extensiones de tipos valor
  y tests que llaman al dominio. Activar con: "nonisolated", "aislamiento por defecto",
  "MainActor por defecto", "función pura", "dominio", "no compila desde el test",
  "warning en #expect", "SE-0466".
---

# Explicit `nonisolated` under a MainActor default

This project sets **default actor isolation to `MainActor`** (`ADR-000` §2). Every type, function and property is main-actor isolated unless it says otherwise. That is convenient for the 80% that is UI, and a trap for the 20% that is not.

## The rule

**Everything in `Domain/` is `nonisolated`, written by hand.** Its value types are `Sendable`. There is no exception and no "the compiler will infer it": under a `MainActor` default, nothing is inferred in your favour.

## Where the annotation actually goes

- **On the type**, when the whole type is pure: `nonisolated struct ElementName { … }`. Every member inherits it, which is what you want for a domain type.
- **On an extension**, when you are adding pure behaviour to an existing type: `nonisolated extension Memory { … }`. Annotating each function one by one is noise, and one forgotten function is a defect.
- **On a single member**, only when a type is genuinely mixed. In `Domain/` that should not happen: if a type needs the main actor, it does not belong in `Domain/`.
- **Stored properties of a `nonisolated` value type need nothing extra** — their isolation follows the type.

## The failure mode, and how it is caught

A missing annotation does not produce an error where it was forgotten. The type simply stays on the main actor, and the call site is forced to `await`. The code compiles, the tests pass, and the problem surfaces later — in a model actor, in a stream, in a background task.

That is why **the domain tests call the domain from a non-isolated context, without `await`**. If the annotation disappears, the test stops compiling. That test is the compiler check we gave up when we chose a folder over a package (`ADR-000`, D1).

Never "fix" such a failure by adding `await` in the test. The `await` is the symptom; the missing `nonisolated` is the cause.

## Tests and warnings

- A `@Test` function is main-actor isolated by default here too. Mark the suite or the test `nonisolated` when it exercises the domain: that is the point.
- Inside `#expect(…)`, an expression that crosses isolation produces a warning rather than a clear error, and warnings are not allowed to survive a phase close. If `#expect` warns about isolation, the type under test is missing its annotation — fix the type, not the expectation.
- Never reach for `nonisolated(unsafe)`, `@unchecked Sendable` or `@preconcurrency`. Forbidden without exception in this project.

## What `nonisolated` is not

- It is not "runs in the background". A `nonisolated async` function runs on the caller's actor (SE-0461). To actually leave the main actor you need `@concurrent` or a dedicated actor.
- It is not a performance optimisation. It is a statement about where the code is allowed to be called from.
