/// The seven product states; every one ends in "saved without analyzing, and told why".
nonisolated enum MemoryComprehensionError: Error, Sendable, Equatable {
  case guardrailViolation
  case contextOverflow
  case unsupportedLanguage
  case refusal
  case assetsUnavailable
  case decodingFailure
  case noResponse
}
