import Synchronization

@testable import Hilo

/// Fails the first time and succeeds on the retry. Mutex, never nonisolated(unsafe).
nonisolated final class SequencedComprehender: MemoryComprehending, Sendable {
  private let scripts: [FakeMemoryComprehender.Script]
  private let callIndex = Mutex(0)

  init(scripts: [FakeMemoryComprehender.Script]) {
    self.scripts = scripts
  }

  func comprehend(narrative: String, interfaceLanguage: String) -> AsyncThrowingStream<
    ExtractedMemory, Error
  > {
    let index = callIndex.withLock { value -> Int in
      let current = value
      value += 1
      return current
    }
    let script = scripts[min(index, scripts.count - 1)]
    return FakeMemoryComprehender(script: script).comprehend(
      narrative: narrative, interfaceLanguage: interfaceLanguage)
  }
}
