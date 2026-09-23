// contrato 4: los 7 estados de producto — todos acaban en "guardado sin analizar, y se dice por qué"
nonisolated enum MemoryComprehensionError: Error, Sendable, Equatable {
  case guardrailViolation
  case contextOverflow
  case unsupportedLanguage
  case refusal
  case assetsUnavailable
  case decodingFailure
  case noResponse
}
