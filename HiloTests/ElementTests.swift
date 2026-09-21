import Testing

@testable import Hilo

// contrato 8: un elemento sin nombre no existe, y el nombre mostrado nunca se reescribe
nonisolated struct ElementTests {
  @Test(arguments: ["", "   ", "\n\t"])
  func `rejects a blank display name`(displayName: String) {
    #expect(Element(displayName: displayName, type: .object) == nil)
  }

  @Test func `preserves the display name exactly as written, without trimming or reformatting`()
    throws
  {
    let original = "  el   reloj  de mi abuelo "
    let element = try #require(Element(displayName: original, type: .object))
    #expect(element.displayName == original)
  }
}
