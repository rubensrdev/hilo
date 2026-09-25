extension MemoryComprehending {
  /// One pass through the flow, for both capture and understanding later.
  func outcome(
    narrative: String, interfaceLanguage: String, onPartial: (ExtractedMemory) -> Void
  ) async -> MemoryComprehensionOutcome {
    var lastResult: Result<ExtractedMemory, MemoryComprehensionError>?
    do {
      for try await snapshot in comprehend(
        narrative: narrative, interfaceLanguage: interfaceLanguage)
      {
        guard !Task.isCancelled else { return .cancelled }
        onPartial(snapshot)
        lastResult = .success(snapshot)
      }
    } catch let error as MemoryComprehensionError {
      lastResult = .failure(error)
    } catch {
      return .cancelled  // cancelling is not a product state
    }
    guard !Task.isCancelled else { return .cancelled }
    return MemoryComprehensionOutcome(lastResult, narrative: narrative)
  }
}
