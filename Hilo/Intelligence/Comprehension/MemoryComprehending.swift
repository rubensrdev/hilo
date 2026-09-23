// contrato 1: costura de test — la implementacion real sobre LanguageModelSession llega en F3.2
protocol MemoryComprehending: Sendable {
  // cada elemento del flujo es un ExtractedMemory incompleto en orden de lectura; el ultimo es el resultado final
  nonisolated func comprehend(
    narrative: String,
    interfaceLanguage: String
  ) -> AsyncThrowingStream<ExtractedMemory, Error>
}
