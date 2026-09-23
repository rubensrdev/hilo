// contrato 4: categoria de motivo para "guardado sin analizar"; el texto exacto es de F4
nonisolated enum MemoryComprehensionReason: Sendable, Equatable {
  case guardrail  // guardarraíl y rechazo: mismo trato (contrato 4)
  case contextOverflow
  case unsupportedLanguage
  case generic  // assets no disponibles, decodificación, sin respuesta
}

// contrato 4 + DEC-16/DEC-18: el desenlace de un intento de comprensión
nonisolated enum MemoryComprehensionOutcome: Sendable {
  case understood(ExtractedMemory)  // extracción final ya validada, nunca un parcial
  case notAnalyzed(narrative: String, reason: MemoryComprehensionReason)
  case cancelled  // sin carga, no es error (contrato 3, F3.3)
}
