import Foundation

// punto 3 de F4.6: aviso al primer fallo, sin contar intentos; lo comparten captura y comprender mas tarde
nonisolated enum ReviewNotice: Sendable, Equatable {
  case reviewUnavailable
  case reviewNotSaved
  case savedWithoutAnalyzing
}
