extension MemoryComprehending {
  // un solo recorrido del flujo para la captura y para comprender mas tarde
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
      return .cancelled  // cancelacion: contrato 3 de F3, no es un estado de producto
    }
    guard !Task.isCancelled else { return .cancelled }
    return MemoryComprehensionOutcome(lastResult, narrative: narrative)
  }
}
