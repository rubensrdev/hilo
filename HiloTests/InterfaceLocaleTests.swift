import Foundation
import Testing

@testable import Hilo

// contrato 6: listas y anuncios van en el idioma de la interfaz, no en el del sistema
nonisolated struct InterfaceLocaleTests {
  private let localizations = ["en", "es", "Base"]

  @Test func `A Spanish system resolves to Spanish`() {
    let locale = InterfaceLocale.resolve(
      Locale(identifier: "es_ES"), localizations: localizations, development: "en")
    #expect(locale.language.languageCode == "es")
  }

  @Test func `English with a Spanish region resolves to English`() {
    let locale = InterfaceLocale.resolve(
      Locale(identifier: "en_ES"), localizations: localizations, development: "en")
    #expect(locale.language.languageCode == "en")
  }

  @Test func `A language the app does not ship falls back to the development language`() {
    let locale = InterfaceLocale.resolve(
      Locale(identifier: "fr_FR"), localizations: localizations, development: "en")
    #expect(locale.language.languageCode == "en")
  }
}
