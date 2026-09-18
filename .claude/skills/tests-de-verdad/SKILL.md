---
name: tests-de-verdad
description: >
  Doctrina obligatoria de testing en Swift (Swift Testing). Consultar SIEMPRE antes de crear un
  "@Test", "@Suite", fichero "*Tests.swift", o de hablar de "cobertura", "mock", "fake",
  "fixture", "TDD", "test unitario", "XCTest", "confirmation", "auditar tests",
  "tests tautológicos". Un test prueba comportamiento observable de producción contra un
  oráculo independiente.
---

# Tests That Actually Test

Full doctrine: `references/doctrina-completa.md`. XCTest → Swift Testing migration (Apple): `references/modernize-tests-apple.md`.

## The single principle

A test verifies **observable behaviour of production code** against an **oracle independent of that code** — fixture content, an external requirement, a separate calculation. If the assertion derives from the same line you wrote in production, it is not a test.

## Two Swift facts that kill most fake tests

1. Swift is **compiled**: the compiler already guarantees types, enum exhaustiveness, conformances and field existence. Never test what would not compile if it were wrong.
2. Swift's runtime is **static**: no swizzling. Mocks are **design seams in production code** — a protocol plus injection. No seam? Design it first.

**Mnemonic: if the test would pass whenever the code compiles, delete it.**

Blacklist, never write: counting cases of an enum · decoding a fixture and checking its fields · building a value and reading the property back · asserting an error description is not empty · a mapper round-trip that repeats the mapper.

## Gate — five questions before writing any test, all must be yes

1. Does it execute production code, not just build or read a value?
2. Is the oracle independent of the code under test?
3. Could it fail from a behaviour change that still compiles?
4. Does it assert observable behaviour — result or effect — rather than structure?
5. Does the mock seam exist in production by design?

## In this project

- **Never write a UI test of any kind.** No automation, no snapshots, no view-hierarchy assertions. UI is validated manually at phase close. If a rule cannot be tested without a view, the design is wrong.
- **The domain is the main target of the suite**: pure functions over `Sendable` values, no container and no model. **Call them from a non-isolated context**, without `await`: default isolation is `MainActor`, and that is how a missing `nonisolated` gets caught.
- **The language model is a double, always.** Never call Foundation Models from a test. Every failure path — context overflow, guardrail block, refusal, unsupported language, no answer — has its own test. Streaming is tested by feeding partial snapshots in order, including a cancelled stream.
- **Persistence uses an in-memory container.** Never the real store.
- **There is no network**, so there is no transport to mock.
- **Never write the retrieval cap as a literal.** Derive expectations from the named constant.
- **Fixtures are invented**, realistic but made up. No real person's memory enters the repository.

## Swift Testing usage (Apple)

`struct` suites; `init()` replaces `setUp`; `#expect` and `try #require`, never downgrading `#require` to `#expect`; `#expect(throws:)` for errors; `confirmation()` for asynchronous expectations; `@Test(arguments:)` for repeated logic; `@Suite(.serialized)` only with shared state; raw-identifier sentence names for multi-word tests. Never XCTest.

## Rules of engagement

- Tests derive from the acceptance criteria of the phase spec. A test that passes before the feature exists is wrong — fix it.
- Never modify a test to make something pass; fix the implementation. No regressions.
- Nothing is certified until the project builds with zero errors and zero warnings.
- Auditing an existing suite: apply the gate to each test, ask before deleting a committed one, keep the fixtures.
