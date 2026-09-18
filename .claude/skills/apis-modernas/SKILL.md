---
name: apis-modernas
description: >
  APIs modernas de Swift/iOS frente a legacy. Consultar cuando el código contenga o se pida
  escribir: "@objc", "#selector", "DispatchQueue", "DispatchGroup", "DispatchSemaphore",
  "String(format:)", "DateFormatter", "NumberFormatter", "NSRegularExpression",
  "UIView.animate", "UIAlertController", "ObservableObject", "@Published", "KVO",
  "NavigationView", "API deprecada", "deprecated", "soft-deprecated", "legacy",
  "modernizar", "migrar API", "JSONSerialization".
---

# Modern APIs — Forbidden → Replacement

LLMs are biased toward outdated APIs, because there is more training data for them. The modernity target here is **Swift 6.2 and iOS 26.0**, and every API is verified against the `cupertino` MCP before being written — never from memory.

| Forbidden | Modern |
|---|---|
| `@objc func`, `#selector()` | Closures, `async` methods, SwiftUI actions |
| `DispatchQueue.main.async` | `await MainActor.run {}` or `@MainActor` |
| `DispatchQueue.global().async` | `Task {}` |
| `DispatchGroup` | `async let` (fixed) / `TaskGroup` (dynamic) |
| `DispatchSemaphore` | `actor` |
| `UIView.animate`, `CAAnimation` | `withAnimation {}` / `.animation()` |
| `viewDidLoad`, `viewWillAppear` | `.task {}`, `.onAppear {}` |
| `UIAlertController` | `.alert()` modifier |
| `String(format:)` | Format styles: `.formatted(...)` |
| `DateFormatter` / `NumberFormatter` | Format styles |
| `NSRegularExpression` | Regex literal or `Regex {}` builder |
| `UIAccessibility.post(.announcement)` | `AccessibilityNotification.Announcement(...).post()` |
| `ObservableObject` + `@Published` | `@Observable` |
| KVO | `@Observable`, `.onChange()` |
| `JSONSerialization` | `Codable` |
| `NavigationView` | `NavigationStack` |

**In Hilo there are no allowed exceptions.** The usual carve-outs — a monitor's required queue, a transitional Combine pipeline, an AVFoundation callback, an `@objc` demanded by a system delegate — all belong to frameworks this app does not use. If you are about to write `@objc`, stop and ask.

## Soft-deprecated APIs (Apple policy)

These compile without warnings but must not appear in new code. Searchable list: `references/soft-deprecated-apis.md`. Policy: `references/soft-deprecation.md`.

- Never generate a soft-deprecated API in new code. Verify against the list, not memory.
- **Editing a view that already uses one: keep it**, deliver the change, and offer migration as a separate task. Apple's scoping rule wins over the modernity rule, and over any auditor that flags it — say so in the report instead of migrating on the spot.
- Never flag or offer to migrate code you were not asked to touch.
- **If the modern replacement requires iOS 27, keep the current API.** The deployment target is 26.0 and the SDK is 26: a replacement that does not exist here is not a replacement.
