import FoundationModels

// contrato 4 + O6 (ADR-001 §3, enmendado F3.4): ambas superficies se capturan, ninguna basta sola.
// LanguageModelError es iOS 27+ en el SDK instalado; el #available de abajo es la excepción
// acotada de CLAUDE.md — solo reconoce un error que lanza el sistema, nunca activa nada nuevo.
extension MemoryComprehensionError {
  nonisolated init(mapping error: Error) {
    if let generationError = error as? LanguageModelSession.GenerationError {
      self = MemoryComprehensionError(mappingGenerationError: generationError)
      return
    }
    if #available(iOS 27, *), let modelError = error as? LanguageModelError {
      self = MemoryComprehensionError(mappingLanguageModelError: modelError)
      return
    }
    self = .noResponse
  }

  private nonisolated init(mappingGenerationError error: LanguageModelSession.GenerationError) {
    switch error {
    case .guardrailViolation: self = .guardrailViolation
    case .exceededContextWindowSize: self = .contextOverflow
    case .unsupportedLanguageOrLocale: self = .unsupportedLanguage
    case .refusal: self = .refusal
    case .assetsUnavailable: self = .assetsUnavailable
    case .decodingFailure: self = .decodingFailure
    case .rateLimited: self = .noResponse
    case .concurrentRequests:
      // contrato 4: defecto nuestro, no estado de producto — una sesión por generación (contrato 3) ya debería impedirlo
      preconditionFailure("dos peticiones concurrentes en la misma sesión")
    case .unsupportedGuide:
      // contrato 4: defecto nuestro — la guía la fija el tipo @Generable, nunca el usuario
      preconditionFailure("guía de generación no soportada")
    @unknown default: self = .noResponse
    }
  }

  @available(iOS 27, *)
  private nonisolated init(mappingLanguageModelError error: LanguageModelError) {
    switch error {
    case .guardrailViolation: self = .guardrailViolation
    case .contextSizeExceeded: self = .contextOverflow
    case .unsupportedLanguageOrLocale: self = .unsupportedLanguage
    case .refusal: self = .refusal
    case .rateLimited, .timeout, .unsupportedCapability, .unsupportedTranscriptContent:
      self = .noResponse
    case .unsupportedGenerationGuide:
      // contrato 4: defecto nuestro — la guía la fija el tipo @Generable, nunca el usuario
      preconditionFailure("guía de generación no soportada")
    @unknown default: self = .noResponse
    }
  }
}
