protocol MemoryComprehending: Sendable {
  /// Each stream element is a partial ExtractedMemory in reading order; the last one is the final result.
  nonisolated func comprehend(
    narrative: String,
    interfaceLanguage: String
  ) -> AsyncThrowingStream<ExtractedMemory, Error>
}
