import Testing

@testable import Hilo

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

  /// The rebuild init keeps the validated id; the failable init always creates a new one.
  @Test
  func
    `The reconstruction init keeps the exact id it is given, unlike the failable init which always creates a new one`()
    throws
  {
    let elementID = ElementID()
    let reconstructed = Element(id: elementID, displayName: "El Abuelo", type: .person)
    #expect(reconstructed.id == elementID)

    let freshlyCreated = try #require(Element(displayName: "El Abuelo", type: .person))
    #expect(freshlyCreated.id != elementID)
  }
}
