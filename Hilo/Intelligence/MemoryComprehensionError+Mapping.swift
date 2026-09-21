import FoundationModels

// contrato 4: separa clasificar (puro, testable) de actuar (preconditionFailure, efecto unico,
// sin test — ver MemoryComprehensionError.init(mapping:)).
nonisolated enum MemoryComprehensionClassification: Sendable {
  case productState(MemoryComprehensionError)
  case ownDefect(String)
}

extension MemoryComprehensionClassification {
  nonisolated init(classifying error: LanguageModelSession.GenerationError) {
    switch error {
    case .guardrailViolation: self = .productState(.guardrailViolation)
    case .exceededContextWindowSize: self = .productState(.contextOverflow)
    case .unsupportedLanguageOrLocale: self = .productState(.unsupportedLanguage)
    case .refusal: self = .productState(.refusal)
    case .assetsUnavailable: self = .productState(.assetsUnavailable)
    case .decodingFailure: self = .productState(.decodingFailure)
    case .rateLimited: self = .productState(.noResponse)
    case .concurrentRequests:
      self = .ownDefect("dos peticiones concurrentes en la misma sesión")
    case .unsupportedGuide:
      self = .ownDefect("guía de generación no soportada")
    @unknown default: self = .productState(.noResponse)
    }
  }

  // decision de Ruben (F3, cierre): #available solo para clasificar el error de FoundationModels
  // que ya lanza el SO en iOS 27 (GenerationError se reparte en estos tipos), nunca para alcanzar
  // una capacidad nueva; CLAUDE.md y ADR-001 quedan pendientes de actualizar tras el merge de F3.
  @available(iOS 27, *)
  nonisolated init(classifying error: LanguageModelError) {
    switch error {
    case .guardrailViolation: self = .productState(.guardrailViolation)
    case .contextSizeExceeded: self = .productState(.contextOverflow)
    case .unsupportedLanguageOrLocale: self = .productState(.unsupportedLanguage)
    case .refusal: self = .productState(.refusal)
    case .rateLimited, .timeout, .unsupportedCapability, .unsupportedTranscriptContent:
      self = .productState(.noResponse)
    case .unsupportedGenerationGuide:
      self = .ownDefect("guía de generación no soportada")
    @unknown default: self = .productState(.noResponse)
    }
  }

  @available(iOS 27, *)
  nonisolated init(classifying error: SystemLanguageModel.Error) {
    switch error {
    case .assetsUnavailable: self = .productState(.assetsUnavailable)
    @unknown default: self = .productState(.noResponse)
    }
  }

  @available(iOS 27, *)
  nonisolated init(classifying error: GeneratedContent.ParsingError) {
    self = .productState(.decodingFailure)
  }

  @available(iOS 27, *)
  nonisolated init(classifying error: LanguageModelSession.Error) {
    switch error {
    case .concurrentRequests:
      self = .ownDefect("dos peticiones concurrentes en la misma sesión")
    case .transcriptMutationWhileResponding: self = .productState(.noResponse)
    @unknown default: self = .productState(.noResponse)
    }
  }
}

extension MemoryComprehensionError {
  nonisolated init(mapping error: Error) {
    let classification: MemoryComprehensionClassification
    if let generationError = error as? LanguageModelSession.GenerationError {
      classification = MemoryComprehensionClassification(classifying: generationError)
    } else if #available(iOS 27, *), let modelError = error as? LanguageModelError {
      classification = MemoryComprehensionClassification(classifying: modelError)
    } else if #available(iOS 27, *), let systemError = error as? SystemLanguageModel.Error {
      classification = MemoryComprehensionClassification(classifying: systemError)
    } else if #available(iOS 27, *), let parsingError = error as? GeneratedContent.ParsingError {
      classification = MemoryComprehensionClassification(classifying: parsingError)
    } else if #available(iOS 27, *), let sessionError = error as? LanguageModelSession.Error {
      classification = MemoryComprehensionClassification(classifying: sessionError)
    } else {
      classification = .productState(.noResponse)
    }

    switch classification {
    case .productState(let state): self = state
    case .ownDefect(let reason): preconditionFailure(reason)
    }
  }
}
