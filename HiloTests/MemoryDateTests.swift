import Testing

@testable import Hilo

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

  @Test func `keeps text and deduced year when the saved text matches the extracted text exactly`()
    throws
  {
    let resolved = try #require(
      MemoryDate.resolving(
        extractedText: "el verano del 87", deducedYear: 1987, textAtSave: "el verano del 87"))
    #expect(resolved.text == "el verano del 87")
    #expect(resolved.deducedYear == 1987)
  }

  @Test
  func
    `keeps the year even when the saved text only differs from the extracted one by surrounding whitespace`()
    throws
  {
    let resolved = try #require(
      MemoryDate.resolving(
        extractedText: "el verano del 87", deducedYear: 1987, textAtSave: "  el verano del 87  "))
    #expect(resolved.text == "el verano del 87")
    #expect(resolved.deducedYear == 1987)
  }

  @Test func `drops the deduced year when the saved text was edited or rewritten`() throws {
    let resolved = try #require(
      MemoryDate.resolving(
        extractedText: "el verano del 87", deducedYear: 1987, textAtSave: "el verano del 88"))
    #expect(resolved.text == "el verano del 88")
    #expect(resolved.deducedYear == nil)
  }

  @Test
  func `a date written by hand with nothing extracted keeps the text but never invents a year`()
    throws
  {
    // nil never equals the written text, so it always falls in the edited row, with no year.
    let resolved = try #require(
      MemoryDate.resolving(extractedText: nil, deducedYear: nil, textAtSave: "en Navidad del 92"))
    #expect(resolved.text == "en Navidad del 92")
    #expect(resolved.deducedYear == nil)
  }

  @Test
  func `deleting the date text at save time drops both text and year, whatever was extracted`() {
    #expect(
      MemoryDate.resolving(
        extractedText: "el verano del 87", deducedYear: 1987, textAtSave: "   ") == nil)
    #expect(MemoryDate.resolving(extractedText: nil, deducedYear: nil, textAtSave: "") == nil)
  }
}
