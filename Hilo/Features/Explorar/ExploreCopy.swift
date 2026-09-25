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

  // DEC-24 + regla 11: el texto de borrado dice que se va y que se queda, sin plural de catalogo
  // porque el numero no se muestra, solo cambia la concordancia (mismo patron que ConnectionCopy)
  static func deleteConfirmationBody(surviving: [String], disappearing: [String], locale: Locale)
    -> String
  {
    var sentences = [
      String(
        localized: LocalizedStringResource(
          "Your words and your photo are deleted from this iPhone.", locale: locale))
    ]
    if surviving.count == 1 {
      sentences.append(
        String(
          localized: LocalizedStringResource(
            "\(surviving[0]) stays, with their other memories.", locale: locale)))
    } else if surviving.count > 1 {
      sentences.append(
        String(
          localized: LocalizedStringResource(
            "\(surviving.joinedAsList(locale: locale)) stay, with their other memories.",
            locale: locale)))
    }
    if disappearing.count == 1 {
      sentences.append(
        String(
          localized: LocalizedStringResource(
            "\(disappearing[0]) disappears: it has no other memories.", locale: locale)))
    } else if disappearing.count > 1 {
      sentences.append(
        String(
          localized: LocalizedStringResource(
            "\(disappearing.joinedAsList(locale: locale)) disappear: they have no other memories.",
            locale: locale)))
    }
    sentences.append(
      String(localized: LocalizedStringResource("This cannot be undone.", locale: locale)))
    return sentences.joined(separator: " ")
  }

  // DEC-13: el chip que quita el filtro; como String ya localizado porque el resto de chips
  // reciben el nombre plural del tipo por el mismo parametro (F8.2: «All» salia sin traducir)
  static func allFilterLabel(locale: Locale) -> String {
    String(localized: LocalizedStringResource("All", locale: locale))
  }

  // contrato 4 (S5): cabecera del detalle de elemento, tipo mas recuento en una sola linea
  static func elementTypeAndCount(_ type: ElementType, count: Int, locale: Locale) -> String {
    "\(type.localizedName(locale: locale)) · \(elementMemoryCount(count, locale: locale))"
  }

  // DEC-57 (A1): VoiceOver no debe leer el guion medio del rango como si fuera texto
  static func dateRangeAccessibilityLabel(oldest: String, newest: String, locale: Locale) -> String
  {
    String(localized: LocalizedStringResource("From \(oldest) to \(newest)", locale: locale))
  }
}
