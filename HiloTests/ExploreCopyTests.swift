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
}
