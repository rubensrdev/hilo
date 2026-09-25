import Foundation
import Testing

@testable import Hilo

// F2 contrato 5: una sola regla de idioma para el vacio, el placeholder de captura y Ajustes
nonisolated struct ExampleMemoryLanguageTests {
  @Test func `A Spanish interface locale loads the Spanish example`() {
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "es")) == .spanish)
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "es_MX")) == .spanish)
  }

  @Test func `An English interface locale loads the English example`() {
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "en")) == .english)
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "en_GB")) == .english)
  }

  // InterfaceLocale ya resolvio frances → ingles; solo queda el locale sin codigo de idioma
  @Test func `A locale without a recognisable language falls back to the English example`() {
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "")) == .english)
  }
}
