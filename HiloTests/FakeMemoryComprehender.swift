@testable import Hilo

// doble reutilizable por F3.3 (streaming/cancelacion) y F3.4 (caminos de error)
nonisolated struct FakeMemoryComprehender: MemoryComprehending {
  enum Script: Sendable {
    // delayBetweenPartials en .zero preserva la entrega sincrona de siempre (F3.1);
    // un valor mayor abre un hueco real donde cancelar (F3.3)
    case succeeds(
      partials: [ExtractedMemory], final: ExtractedMemory, delayBetweenPartials: Duration = .zero)
    case fails(MemoryComprehensionError)
  }

  let script: Script

  func comprehend(narrative: String, interfaceLanguage: String) -> AsyncThrowingStream<
    ExtractedMemory, Error
  > {
    AsyncThrowingStream { continuation in
      switch script {
      case .succeeds(let partials, let final, let delay):
        let task = Task {
          for partial in partials + [final] {
            guard !Task.isCancelled else { return }
            continuation.yield(partial)
            if delay > .zero {
              try? await Task.sleep(for: delay)
            }
          }
          continuation.finish()
        }
        continuation.onTermination = { _ in task.cancel() }
      case .fails(let error):
        continuation.finish(throwing: error)
      }
    }
  }
}
