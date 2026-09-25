import Foundation
import Testing

@testable import Hilo

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

/// Name, type and count: what the visual chip conveys through colour and symbol, for VoiceOver users.
nonisolated struct ElementAccessibilityLabelTests {
  private let english = Locale(identifier: "en")
  private let spanish = Locale(identifier: "es")

  @Test func `An element with a known count announces name, type and its memories in English`() throws {
    let element = try #require(Element(displayName: "Carmen", type: .person))
    #expect(
      element.accessibilityLabel(memoryCount: 3, locale: english) == "Carmen, Person, in 3 memories"
    )
    #expect(
      element.accessibilityLabel(memoryCount: 1, locale: english) == "Carmen, Person, in 1 memory")
  }

  @Test func `An element with a known count announces name, type and its memories in Spanish`() throws {
    let element = try #require(Element(displayName: "el pueblo", type: .place))
    #expect(
      element.accessibilityLabel(memoryCount: 3, locale: spanish)
        == "el pueblo, Lugar, en 3 recuerdos")
    #expect(
      element.accessibilityLabel(memoryCount: 1, locale: spanish)
        == "el pueblo, Lugar, en 1 recuerdo")
  }

  @Test func `An element with zero memories uses the plural, in both languages`() throws {
    let element = try #require(Element(displayName: "Carmen", type: .person))
    #expect(
      element.accessibilityLabel(memoryCount: 0, locale: english) == "Carmen, Person, in 0 memories"
    )
    #expect(
      element.accessibilityLabel(memoryCount: 0, locale: spanish)
        == "Carmen, Persona, en 0 recuerdos")
  }

  /// No count (nil): the row leaves it out while unknown, instead of saying "0 memories".
  @Test func `An element with no known count announces only name and type, in both languages`() throws {
    let clock = try #require(Element(displayName: "el reloj", type: .object))
    #expect(clock.accessibilityLabel(memoryCount: nil, locale: english) == "el reloj, Object")
    #expect(clock.accessibilityLabel(memoryCount: nil, locale: spanish) == "el reloj, Objeto")
  }
}
