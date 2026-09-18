---
name: foundation-models
description: >
  Generación on-device con Foundation Models en Hilo (iOS 26): tipos generables, streaming,
  ventana de contexto y caminos de error. Cargar ANTES de escribir o cambiar cualquier código
  que hable con el modelo. Activar con: "Foundation Models", "modelo on-device", "comprender
  el relato", "extracción", "streaming del modelo", "generable", "guardarraíles", "ventana de
  contexto", "tope de recuperación".
---

# Foundation Models in Hilo (iOS 26)

Hilo deploys to **iOS 26.0** and builds against the iOS 26 SDK. Only the generation-26 API surface exists here. Generation-27 features — a larger window, image attachments, dynamic profiles, system tools, PCC-backed sessions — **do not exist at this deployment target**. Never design against them, and never let a newer document talk you into an API the compiler will reject.

**Always verify a signature with the `cupertino` MCP before writing it.** This skill is doctrine, not an API reference.

## Before reaching for the model

Whatever can be decided with certainty is decided with certainty. In Hilo the model never touches: canonical names, resemblance, element resolution, derived connections, retrieval steps 1 and 3, ordering, the cap, portrait validity, gap detection.

Before adding a new model call, check whether a domain framework already answers it — Natural Language, Vision, Speech, Translation. A native API is free, offline and deterministic. The model is none of those.

## The three uses, and their contracts

Hilo talks to the model in exactly three places. Each has a closed contract; none of them share a session.

| Use | Input | Output |
|---|---|---|
| **Comprehension** | One memory, as the user wrote it | A generable structure: elements with name, type and role, the date text, and a deduced year that may be absent |
| **Question interpretation** | One question | A closed generable structure: names, optional type, optional year interval |
| **Writing** | The memories handed over as material | Free text, streamed: an answer or a portrait |

- **Bound the output by a generable type with guides, never by asking politely in the prompt.** Constrained decoding is what guarantees the shape; instructions are what guarantee the tone.
- **Validate after generating.** A well-shaped structure can still name an element that does not exist, or a year that contradicts the text.
- **The model never selects memories.** Retrieval hands it material; it writes about that material and nothing else.

## Sessions and the context window

- **One session per generation.** No history is carried between generations — neither a question nor a portrait remembers the previous one. This keeps the window from growing and makes isolation trivial.
- **Instructions are fixed and separate from the user's content.** They state the interface language, and that names written by the user are never translated.
- **The window is small and fixed.** Never hardcode its size. The retrieval cap is a single named constant, measured in F0.2 and recorded in `ADR-001`; never repeat its value anywhere else, tests included.
- **Prewarm** the session when entering capture, so progressive appearance does not start cold. Measure before assuming it helps.

## Streaming

Comprehension and writing stream. Consume the stream in a task tied to the view's lifetime and cancel it when the screen goes away — never in a detached task, never outliving its screen.

Partial results arrive as snapshots of the same generable type, with fields filling in. That is what drives elements appearing one by one during comprehension. Treat every partial as incomplete: never persist from a partial, never decide from a partial.

## Failure is product, not an exception

Context overflow, guardrail block, refusal, unsupported language and no answer at all are **states of the product**, not errors to swallow. In capture they all end the same way: **the memory is saved with the user's words, unanalyzed, and the app says why**. The user's text is never lost, and the tone is never one of catastrophe.

- Handle each error case explicitly. A generic catch that says "something went wrong" fails the spec.
- Apple Intelligence being unavailable is a premise of this product, not a state: there is no interface for it. But the code must not crash or hang — it falls into the same path as a comprehension error, and **never tells the user their device cannot do something**.
- **Never route to a server model**, even if the system offers one.
- Never log the prompt, the memory text, the names or the generated output.

## Guardrails and intimate content

Hilo's memories are about death, illness, war and loss. A guardrail block on a legitimate memory is the single most damaging failure this product can have, and it is measured in F0.2 before any of this is built. If it turns out to be frequent, that is a product decision for Rubén — never something to work around by rewriting the user's words or by retrying silently with a softened prompt.

## Testing

The model is injected through a protocol and is **never** called from a test. Doubles cover the happy path and every failure path above. Streaming is tested by feeding partial snapshots in order, including a stream cancelled halfway.
