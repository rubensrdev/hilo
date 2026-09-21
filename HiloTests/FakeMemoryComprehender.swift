@testable import Hilo

// doble reutilizable por F3.3 (streaming/cancelacion) y F3.4 (caminos de error)
nonisolated struct FakeMemoryComprehender: MemoryComprehending {
  enum Script: Sendable {
    case succeeds(partials: [ExtractedMemory], final: ExtractedMemory)
    case fails(MemoryComprehensionError)
  }

  let script: Script

  func comprehend(narrative: String, interfaceLanguage: String) -> AsyncThrowingStream<
    ExtractedMemory, Error
  > {
    AsyncThrowingStream { continuation in
      switch script {
      case .succeeds(let partials, let final):
        for partial in partials {
          continuation.yield(partial)
        }
        continuation.yield(final)
        continuation.finish()
      case .fails(let error):
        continuation.finish(throwing: error)
      }
    }
  }
}
