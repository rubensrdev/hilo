import Foundation

// contrato 6: idioma de la interfaz, no del sistema (sistema en frances → interfaz en ingles)
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

  // encabezados de grupo en Revision (bloque "Lo que ha entendido")
  nonisolated func localizedPluralName(locale: Locale) -> String {
    switch self {
    case .person: String(localized: LocalizedStringResource("People", locale: locale))
    case .place: String(localized: LocalizedStringResource("Places", locale: locale))
    case .object: String(localized: LocalizedStringResource("Objects", locale: locale))
    }
  }
}

extension [String] {
  // los nombres van tal como el usuario los confirmo; solo la union sigue el idioma (anexo DEC-46)
  nonisolated func joinedAsList(locale: Locale) -> String {
    formatted(.list(type: .and).locale(locale))
  }
}
