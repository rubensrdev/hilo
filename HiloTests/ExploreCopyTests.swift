import Foundation
import Testing

@testable import Hilo

// tokens.md §1.6: "«N» es el número de recuerdos en los que ya aparece ese elemento", plural correcto
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

  // contrato 2, DEC-14: encabezado de decada, texto de interfaz — nunca una fecha del usuario
  @Test func `A decade header names its starting year, in both languages`() {
    #expect(ExploreCopy.decadeHeader(.decade(startingYear: 1980), locale: english) == "1980s")
    #expect(ExploreCopy.decadeHeader(.decade(startingYear: 1980), locale: spanish) == "Años 1980")
  }

  @Test func `The no-year group has its own header, distinct from any decade, in both languages`() {
    #expect(ExploreCopy.decadeHeader(.noYear, locale: english) == "No date")
    #expect(ExploreCopy.decadeHeader(.noYear, locale: spanish) == "Sin fecha")
  }

  // MARK: contrato 4, DEC-24, regla 11 — el texto de la confirmacion de borrado se calcula

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

  // las traducciones al español se añaden despues via Xcode MCP; aqui solo se comprueba que compone
  @Test func `The delete confirmation body composes something non-empty in Spanish too`() {
    let empty = ExploreCopy.deleteConfirmationBody(surviving: [], disappearing: [], locale: spanish)
    let both = ExploreCopy.deleteConfirmationBody(
      surviving: ["José"], disappearing: ["el reloj"], locale: spanish)

    #expect(!empty.isEmpty)
    #expect(!both.isEmpty)
    #expect(both.contains("José"))
    #expect(both.contains("el reloj"))
  }

  // MARK: contrato 4 (S5): cabecera del detalle de elemento — tipo, separador y recuento

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

  // MARK: contrato 4 (S5), DEC-57 (A1): el rango temporal se anuncia como una frase, no dos textos pegados

  @Test func `The date range accessibility label reads as a full sentence in English`() {
    #expect(
      ExploreCopy.dateRangeAccessibilityLabel(
        oldest: "cuando yo era niño", newest: "el verano pasado", locale: english)
        == "From cuando yo era niño to el verano pasado")
  }

  // la traduccion al español se añade despues via Xcode MCP; aqui solo se comprueba que compone
  @Test func `The date range accessibility label composes something non-empty in Spanish too`() {
    let label = ExploreCopy.dateRangeAccessibilityLabel(
      oldest: "cuando yo era niño", newest: "el verano pasado", locale: spanish)

    #expect(!label.isEmpty)
    #expect(label.contains("cuando yo era niño"))
    #expect(label.contains("el verano pasado"))
  }
}
