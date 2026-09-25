import FoundationModels

/// Classifying is pure and tested; acting on one of our defects is a preconditionFailure with
/// no test (see MemoryComprehensionError.init(mapping:)).
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
      self = .ownDefect("two concurrent requests on the same session")
    case .unsupportedGuide:
      self = .ownDefect("unsupported generation guide")
    @unknown default: self = .productState(.noResponse)
    }
  }

  /// Only to classify the FoundationModels errors the OS already throws on iOS 27, never to reach
  /// a new capability.
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
      self = .ownDefect("unsupported generation guide")
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
      self = .ownDefect("two concurrent requests on the same session")
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
