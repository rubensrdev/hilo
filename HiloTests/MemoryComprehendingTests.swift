import Testing

@testable import Hilo

// contrato 1 + contrato 3: el doble entrega el guion tal cual, en orden de lectura
nonisolated struct MemoryComprehendingTests {
  @Test func `Delivers partials in reading order and the final result matches the script`()
    async throws
  {
    let firstPartial = ExtractedMemory(
      elements: [ExtractedElement(name: "Elena", type: .person, role: "mi vecina")],
      dateText: nil, deducedYear: nil)
    let secondPartial = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Elena", type: .person, role: "mi vecina"),
        ExtractedElement(name: "el parque", type: .place, role: "donde nos vimos"),
      ], dateText: nil, deducedYear: nil)
    let final = ExtractedMemory(
      elements: [
        ExtractedElement(name: "Elena", type: .person, role: "mi vecina"),
        ExtractedElement(name: "el parque", type: .place, role: "donde nos vimos"),
      ], dateText: "un domingo por la mañana", deducedYear: nil)
    let fake = FakeMemoryComprehender(
      script: .succeeds(partials: [firstPartial, secondPartial], final: final))

    var received: [ExtractedMemory] = []
    for try await snapshot in fake.comprehend(narrative: "no importa", interfaceLanguage: "es") {
      received.append(snapshot)
    }

    #expect(received.map { $0.elements.count } == [1, 2, 2])
    let lastResult = try #require(received.last)
    #expect(lastResult.elements.map(\.name) == ["Elena", "el parque"])
    #expect(lastResult.dateText == "un domingo por la mañana")
  }

  @Test func `Propagates the scripted error instead of yielding any snapshot`() async throws {
    let fake = FakeMemoryComprehender(script: .fails(.guardrailViolation))

    await #expect(throws: MemoryComprehensionError.guardrailViolation) {
      for try await _ in fake.comprehend(narrative: "no importa", interfaceLanguage: "es") {}
    }
  }
}
