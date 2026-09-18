---
name: cupertino
description: >
  Verificación de APIs de Apple contra documentación oficial antes de escribir código.
  Consultar SIEMPRE antes de usar una API que no hayas verificado en esta sesión, y ante
  cualquier duda de firma, disponibilidad o versión. Activar con: "¿existe esta API?",
  "firma", "disponibilidad", "iOS 26", "verifica la API", "documentación de Apple",
  "deprecada", "qué versión", "Foundation Models", "SwiftData", "SwiftUI 26".
---

# Verify before you write

The modernity target is **Swift 6.2 and iOS 26.0**, with the iOS 26 SDK. Model memory about Apple APIs is unreliable in exactly the places this project lives: Foundation Models, SwiftData, and everything added in iOS 26. Verify, then write.

## When verification is mandatory

- Any API you have not already verified in this session.
- Every Foundation Models symbol, without exception: generable types and guides, session creation, streaming, error cases, prewarming, context measurement.
- Anything to do with availability: does this exist in iOS 26.0, or only in a later minor or major version?
- Any symbol you are about to use because "it sounds right". That feeling is the signal, not the permission.

## What to check, in order

1. **Does the symbol exist**, with that exact name and spelling?
2. **What is its signature**, including argument labels and whether it is `async`, `throws` or typed-throws?
3. **From which version is it available?** If it arrived after 26.0, it does not exist for this project: find the 26.0 way or bring the problem back to Rubén. Never add an availability branch just to use something newer.
4. **Is it deprecated or soft-deprecated?** If so, what replaces it, and does the replacement exist in 26.0?

## If the documentation source is unavailable

Stop and tell Rubén. Then, and only then, you may fall back to Apple's published documentation, and every API taken from that fallback is reported in your summary as unverified so it can be checked at phase close.

**Never invent a signature, and never write "something like this" and let the compiler decide.** A compile error is the cheap outcome; a plausible wrong API that compiles is the expensive one.

## Hilo specifics

- Generation-27 material — a larger context window, image attachments, dynamic profiles, system tools, cloud-backed sessions — **does not exist at this deployment target**. If a document describes it, the document is ahead of this project.
- When you verify a Foundation Models symbol, record what you found in your summary: the F0.2 spike and `ADR-001` depend on knowing which APIs were actually available.
