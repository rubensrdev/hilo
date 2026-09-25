import Foundation
import Testing

@testable import Hilo

/// One language rule for the empty state, the capture placeholder and Settings.
nonisolated struct ExampleMemoryLanguageTests {
  @Test func `A Spanish interface locale loads the Spanish example`() {
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "es")) == .spanish)
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "es_MX")) == .spanish)
  }

  @Test func `An English interface locale loads the English example`() {
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "en")) == .english)
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "en_GB")) == .english)
  }

  /// InterfaceLocale already resolved French to English; only a locale with no language code is left.
  @Test func `A locale without a recognisable language falls back to the English example`() {
    #expect(ExampleMemoryLanguage(interfaceLocale: Locale(identifier: "")) == .english)
  }
}
