import Foundation

// contrato 6 + tokens.md §1.6: "N" es el numero de recuerdos en los que ya aparece el elemento
nonisolated enum ExploreCopy {
  static func elementMemoryCount(_ count: Int, locale: Locale) -> String {
    String(localized: LocalizedStringResource("in \(count) memories", locale: locale))
  }

  // contrato 2, DEC-14: encabezado de decada, nunca una fecha del usuario (regla 17)
  static func decadeHeader(_ decade: MemoryDecade, locale: Locale) -> String {
    switch decade {
    case .decade(let startingYear):
      // sin separador de millares: es un año, no una cantidad
      String(
        localized: LocalizedStringResource(
          "\(startingYear, format: .number.grouping(.never))s", locale: locale))
    case .noYear:
      String(localized: LocalizedStringResource("No date", locale: locale))
    }
  }
}
