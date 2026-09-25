extension MemoryComprehensionReason {
  nonisolated init(mapping error: MemoryComprehensionError) {
    switch error {
    case .guardrailViolation, .refusal: self = .guardrail
    case .contextOverflow: self = .contextOverflow
    case .unsupportedLanguage: self = .unsupportedLanguage
    case .assetsUnavailable, .decodingFailure, .noResponse: self = .generic
    }
  }
}

extension MemoryComprehensionOutcome {
  /// Understanding later is calling comprehend again with the same narrative and no state, so no
  /// separate operation is needed.
  nonisolated init(_ result: Result<ExtractedMemory, MemoryComprehensionError>?, narrative: String)
  {
    switch result {
    case nil: self = .cancelled
    case .success(let extracted): self = .understood(extracted)
    case .failure(let error):
      self = .notAnalyzed(narrative: narrative, reason: MemoryComprehensionReason(mapping: error))
    }
  }
}
