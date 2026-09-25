import Foundation

/// The interface language, not the system's: a French system gets an English interface.
nonisolated enum InterfaceLocale {
  static func resolve(
    _ environment: Locale, localizations: [String] = Bundle.main.localizations,
    development: String = Bundle.main.developmentLocalization ?? "en"
  ) -> Locale {
    let code = environment.language.languageCode?.identifier
    guard let code, localizations.contains(code) else { return Locale(identifier: development) }
    return Locale(identifier: code)
  }
}

extension ElementType {
  nonisolated func localizedName(locale: Locale) -> String {
    switch self {
    case .person: String(localized: LocalizedStringResource("Person", locale: locale))
    case .place: String(localized: LocalizedStringResource("Place", locale: locale))
    case .object: String(localized: LocalizedStringResource("Object", locale: locale))
    }
  }

  /// Group headers in the review's understood block.
  nonisolated func localizedPluralName(locale: Locale) -> String {
    switch self {
    case .person: String(localized: LocalizedStringResource("People", locale: locale))
    case .place: String(localized: LocalizedStringResource("Places", locale: locale))
    case .object: String(localized: LocalizedStringResource("Objects", locale: locale))
    }
  }
}

extension [String] {
  /// Names go as the user confirmed them; only the conjunction follows the language.
  nonisolated func joinedAsList(locale: Locale) -> String {
    formatted(.list(type: .and).locale(locale))
  }
}

extension Element {
  /// Reuses ReviewCopy.elementLabel's translated keys, so VoiceOver doesn't rely on the visual "·"
  /// to convey the type.
  nonisolated func accessibilityLabel(memoryCount: Int?, locale: Locale) -> String {
    let typeName = type.localizedName(locale: locale)
    guard let memoryCount else {
      return String(
        localized: LocalizedStringResource("\(displayName), \(typeName)", locale: locale))
    }
    return String(
      localized: LocalizedStringResource(
        "\(displayName), \(typeName), in \(memoryCount) memories", locale: locale))
  }
}
