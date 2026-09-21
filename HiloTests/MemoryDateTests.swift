import Testing

@testable import Hilo

// contrato 7 + regla 17: el texto es lo unico que se muestra, el año solo ordena y agrupa
nonisolated struct MemoryDateTests {
  @Test(arguments: ["", "   ", "\n\t"])
  func `rejects a blank date text`(text: String) {
    #expect(MemoryDate(text: text) == nil)
  }

  @Test func `preserves the date text exactly as written, without trimming or reformatting`() throws
  {
    let original = "  no me acuerdo del año,   pero fue en otoño  "
    let date = try #require(MemoryDate(text: original))
    #expect(date.text == original)
  }
}
