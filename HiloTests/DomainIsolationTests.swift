import Testing

@testable import Hilo

// contrato 2 + F0.1.5: Domain es nonisolated y sus valores cruzan un limite Sendable
nonisolated struct DomainIsolationTests {
  @Test func nonisolatedFunctionRunsWithoutAwait() {
    let placeholder = DomainPlaceholder(value: 21)
    #expect(doublePlaceholderValue(placeholder) == 42)
  }

  @Test func sendableValueCrossesATaskBoundary() async {
    let placeholder = DomainPlaceholder(value: 21)
    let result = await Task.detached {
      doublePlaceholderValue(placeholder)
    }.value
    #expect(result == 42)
  }
}
