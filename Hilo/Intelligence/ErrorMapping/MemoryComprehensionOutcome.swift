/// The reason category behind "saved without analyzing"; the exact wording lives in the copy.
nonisolated enum MemoryComprehensionReason: Sendable, Equatable {
  case guardrail  // guardrail and refusal are treated the same
  case contextOverflow
  case unsupportedLanguage
  case generic  // unavailable assets, decoding failure, no response
}

nonisolated enum MemoryComprehensionOutcome: Sendable {
  case understood(ExtractedMemory)  // final, validated extraction, never a partial
  case notAnalyzed(narrative: String, reason: MemoryComprehensionReason)
  case cancelled  // no payload, and not an error
}
