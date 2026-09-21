import Testing

@testable import Hilo

// F3.3: streaming con puntos de suspension reales y garantias al cancelar a mitad
nonisolated struct MemoryComprehensionCancellationTests {
  struct CollectedResult: Sendable {
    var received: [ExtractedMemory]
    var thrownError: Error?
  }

  @Test
  func
    `Cancelling mid-stream stops delivery before the second partial and never throws a comprehension error`()
    async throws
  {
    let firstPartial = ExtractedMemory(
      elements: [ExtractedElement(name: "Marta", type: .person, role: "mi tía")],
      dateText: nil, deducedYear: nil)
    let secondPartial = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Marta", type: .person, role: "mi tía"),
        ExtractedElement(name: "la cocina", type: .place, role: "donde hablamos"),
      ], dateText: nil, deducedYear: nil)
    let final = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Marta", type: .person, role: "mi tía"),
        ExtractedElement(name: "la cocina", type: .place, role: "donde hablamos"),
      ], dateText: "una tarde de invierno", deducedYear: nil)
    // margen generoso: primer parcial llega en t=0, segundo en t=50ms; cancelamos en t=10ms
    let fake = FakeMemoryComprehender(
      script: .succeeds(
        partials: [firstPartial, secondPartial], final: final,
        delayBetweenPartials: .milliseconds(50)))

    let task = Task<CollectedResult, Never> {
      var received: [ExtractedMemory] = []
      do {
        for try await snapshot in fake.comprehend(narrative: "no importa", interfaceLanguage: "es")
        {
          received.append(snapshot)
        }
        return CollectedResult(received: received, thrownError: nil)
      } catch {
        return CollectedResult(received: received, thrownError: error)
      }
    }

    try await Task.sleep(for: .milliseconds(10))
    task.cancel()
    let result = await task.value

    // como mucho el primer parcial llego antes de la cancelacion, nunca el segundo ni el final
    #expect(result.received.count <= 1)
    if let onlyReceived = result.received.first {
      #expect(onlyReceived.elements.count == firstPartial.elements.count)
      #expect(onlyReceived.dateText == nil)
    }
    #expect(!result.received.contains { $0.dateText != nil })

    // la cancelacion no es un camino del contrato 4 (eso es F3.4)
    if let error = result.thrownError {
      #expect((error as? MemoryComprehensionError) == nil)
    }
  }

  @Test
  func
    `Streams every partial in order through real suspension points and keeps the final result intact`()
    async throws
  {
    let firstPartial = ExtractedMemory(
      elements: [ExtractedElement(name: "Ibrahim", type: .person, role: "mi compañero de piso")],
      dateText: nil, deducedYear: nil)
    let secondPartial = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Ibrahim", type: .person, role: "mi compañero de piso"),
        ExtractedElement(name: "la terraza", type: .place, role: "donde cenamos"),
      ], dateText: nil, deducedYear: nil)
    let final = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Ibrahim", type: .person, role: "mi compañero de piso"),
        ExtractedElement(name: "la terraza", type: .place, role: "donde cenamos"),
      ], dateText: "la noche de mi cumpleaños", deducedYear: nil)
    let fake = FakeMemoryComprehender(
      script: .succeeds(
        partials: [firstPartial, secondPartial], final: final,
        delayBetweenPartials: .milliseconds(5)))

    var received: [ExtractedMemory] = []
    for try await snapshot in fake.comprehend(narrative: "no importa", interfaceLanguage: "es") {
      received.append(snapshot)
    }

    #expect(received.map { $0.elements.count } == [1, 2, 2])
    let lastResult = try #require(received.last)
    #expect(lastResult.elements.map(\.name) == ["Ibrahim", "la terraza"])
    #expect(lastResult.dateText == "la noche de mi cumpleaños")
  }
}
