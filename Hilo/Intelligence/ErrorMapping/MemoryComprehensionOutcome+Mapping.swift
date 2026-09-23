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
  // "comprender mas tarde" (DEC-16/DEC-18) es volver a llamar a comprehend con el
  // mismo relato, sin estado (contrato 3): no hace falta una operacion distinta.
  // Marcar isAnalyzed y actualizar el recuerdo existente es de F4.
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
