import Foundation
import Testing

@testable import Hilo

nonisolated struct ExploreCopyTests {
  private let english = Locale(identifier: "en")
  private let spanish = Locale(identifier: "es")

  @Test func `A single memory produces the singular form, in both languages`() {
    #expect(ExploreCopy.elementMemoryCount(1, locale: english) == "in 1 memory")
    #expect(ExploreCopy.elementMemoryCount(1, locale: spanish) == "en 1 recuerdo")
  }

  @Test func `Several memories produce the plural form, in both languages`() {
    #expect(ExploreCopy.elementMemoryCount(3, locale: english) == "in 3 memories")
    #expect(ExploreCopy.elementMemoryCount(3, locale: spanish) == "en 3 recuerdos")
  }

  @Test func `Zero memories produce the plural form, in both languages`() {
    #expect(ExploreCopy.elementMemoryCount(0, locale: english) == "in 0 memories")
    #expect(ExploreCopy.elementMemoryCount(0, locale: spanish) == "en 0 recuerdos")
  }

  @Test func `A decade header names its starting year, in both languages`() {
    #expect(ExploreCopy.decadeHeader(.decade(startingYear: 1980), locale: english) == "1980s")
    #expect(ExploreCopy.decadeHeader(.decade(startingYear: 1980), locale: spanish) == "Años 1980")
  }

  @Test func `The no-year group has its own header, distinct from any decade, in both languages`() {
    #expect(ExploreCopy.decadeHeader(.noYear, locale: english) == "No date")
    #expect(ExploreCopy.decadeHeader(.noYear, locale: spanish) == "Sin fecha")
  }

  // MARK: delete confirmation body (rule 11)

  @Test func `With nothing surviving or disappearing, only the fixed sentences remain`() {
    #expect(
      ExploreCopy.deleteConfirmationBody(surviving: [], disappearing: [], locale: english)
        == "Your words and your photo are deleted from this iPhone. This cannot be undone.")
  }

  @Test func `A single surviving element uses the singular verb`() {
    #expect(
      ExploreCopy.deleteConfirmationBody(surviving: ["José"], disappearing: [], locale: english)
        == "Your words and your photo are deleted from this iPhone. José stays, with their other memories. This cannot be undone."
    )
  }

  @Test func `Several surviving elements are joined and use the plural verb`() {
    #expect(
      ExploreCopy.deleteConfirmationBody(
        surviving: ["José", "Carmen"], disappearing: [], locale: english)
        == "Your words and your photo are deleted from this iPhone. José and Carmen stay, with their other memories. This cannot be undone."
    )
  }

  @Test func `A single disappearing element uses the singular verb`() {
    #expect(
      ExploreCopy.deleteConfirmationBody(surviving: [], disappearing: ["el reloj"], locale: english)
        == "Your words and your photo are deleted from this iPhone. el reloj disappears: it has no other memories. This cannot be undone."
    )
  }

  @Test func `Several disappearing elements are joined and use the plural verb`() {
    #expect(
      ExploreCopy.deleteConfirmationBody(
        surviving: [], disappearing: ["el reloj", "la casa del pueblo"], locale: english)
        == "Your words and your photo are deleted from this iPhone. el reloj and la casa del pueblo disappear: they have no other memories. This cannot be undone."
    )
  }

  @Test func `Surviving and disappearing elements both appear, surviving named first`() {
    #expect(
      ExploreCopy.deleteConfirmationBody(
        surviving: ["Carmen"], disappearing: ["el reloj"], locale: english)
        == "Your words and your photo are deleted from this iPhone. Carmen stays, with their other memories. el reloj disappears: it has no other memories. This cannot be undone."
    )
  }

  /// Spanish translations are added through the Xcode MCP; this only checks that it composes.
  @Test func `The delete confirmation body composes something non-empty in Spanish too`() {
    let empty = ExploreCopy.deleteConfirmationBody(surviving: [], disappearing: [], locale: spanish)
    let both = ExploreCopy.deleteConfirmationBody(
      surviving: ["José"], disappearing: ["el reloj"], locale: spanish)

    #expect(!empty.isEmpty)
    #expect(!both.isEmpty)
    #expect(both.contains("José"))
    #expect(both.contains("el reloj"))
  }

  // MARK: element detail header — type, separator and count

  @Test(arguments: [
    (ElementType.person, "Person", "Persona"),
    (ElementType.place, "Place", "Lugar"),
    (ElementType.object, "Object", "Objeto"),
  ])
  func `elementTypeAndCount composes the localized type and the memory count, in both languages`(
    type: ElementType, english: String, spanish: String
  ) {
    #expect(
      ExploreCopy.elementTypeAndCount(type, count: 1, locale: self.english)
        == "\(english) · in 1 memory")
    #expect(
      ExploreCopy.elementTypeAndCount(type, count: 1, locale: self.spanish)
        == "\(spanish) · en 1 recuerdo")
    #expect(
      ExploreCopy.elementTypeAndCount(type, count: 4, locale: self.english)
        == "\(english) · in 4 memories")
    #expect(
      ExploreCopy.elementTypeAndCount(type, count: 4, locale: self.spanish)
        == "\(spanish) · en 4 recuerdos")
  }

  @Test func `elementTypeAndCount uses the plural form for zero memories, in both languages`() {
    #expect(
      ExploreCopy.elementTypeAndCount(.person, count: 0, locale: english)
        == "Person · in 0 memories")
    #expect(
      ExploreCopy.elementTypeAndCount(.person, count: 0, locale: spanish)
        == "Persona · en 0 recuerdos")
  }

  // MARK: date range — announced as one sentence, not two texts joined

  @Test func `The date range accessibility label reads as a full sentence in English`() {
    #expect(
      ExploreCopy.dateRangeAccessibilityLabel(
        oldest: "cuando yo era niño", newest: "el verano pasado", locale: english)
        == "From cuando yo era niño to el verano pasado")
  }

  /// No «a» before the user's words, which often start with «el» («a el»). The user's text is
  /// never touched, so the template avoids the contraction.
  @Test func `The date range accessibility label reads as a full sentence in Spanish`() {
    #expect(
      ExploreCopy.dateRangeAccessibilityLabel(
        oldest: "1994", newest: "el verano de 2001", locale: spanish)
        == "Desde 1994 hasta el verano de 2001")
  }

  /// Regression: the «All» chip passed a pre-built String and came out untranslated.
  @Test func `The filter chip that clears the filter has its text in both languages`() {
    #expect(ExploreCopy.allFilterLabel(locale: english) == "All")
    #expect(ExploreCopy.allFilterLabel(locale: spanish) == "Todos")
  }
}
