---
name: swiftdata
description: >
  Persistencia con SwiftData en Hilo. Consultar al tocar: "@Model", "ModelContainer",
  "ModelContext", "modelContext", "@Query", "ModelActor", "@ModelActor", "persistencia",
  "SwiftData", "esquema", "FetchDescriptor", "base de datos local", "borrado total",
  "memoria de ejemplo", "foto".
---

# SwiftData in Hilo

## Architecture

- SwiftData is the local source of truth for what is persisted, and `@Model` classes are the persisted model. There is no parallel entity layer for stored data.
- **The domain is not the schema.** Hilo's rules live in `Domain/` as pure value types. Persistence extracts `Sendable` values for the domain and writes back what the domain decides — the rules never live in a `@Model`.
- **Single write point**: a `@ModelActor` performs mutations off the main actor. Views read with `@Query` and never insert, delete or save directly; they hand the work to a view-model method.
- **Connections are derived, never stored** (`§12`). Storing them creates a second source of truth that goes stale on delete.

## Container

- The container is created once by the app and injected. **There is no initial load at launch**: the example memory is loaded on demand from settings, and loading it is an explicit, idempotent operation through the model actor.
- Previews and tests: in-memory container, always.
- No App Group, no widget target, no CloudKit, no sync. A single local store.

## Boundaries

- **`@Model` is not `Sendable`.** Across actors pass persistent identifiers or extracted values. A model that escapes its context is a defect, not a shortcut.
- Persisted property names are ASCII, with no diacritics.
- Fetches that can grow set an explicit `fetchLimit`.

## Integrity

- **Deletion is real.** Deleting a memory removes its photo and the photo's external storage; deleting everything leaves nothing behind. Both are verified by test.
- An element with no memories left ceases to exist (`§13` rule 11). That cleanup belongs to the write path, not to a view.
- The photo is stored as external data and is never analysed.
- There is no migration story for the MVP: a schema change during the hackathon means resetting the local store. Say so before changing the schema, and never migrate destructively without asking.
