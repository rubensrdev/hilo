import Foundation

// contrato 6: textos anunciables como funciones puras, probados en los dos idiomas
nonisolated enum CaptureCopy {
  static func notice(_ notice: ReviewNotice, locale: Locale) -> String {
    switch notice {
    case .reviewUnavailable:
      String(
        localized: LocalizedStringResource(
          "Hilo couldn't open the review. Your memory is still here — you can try again.",
          locale: locale))
    case .reviewNotSaved:
      String(
        localized: LocalizedStringResource(
          "Hilo couldn't save the review. Your memory is still here — you can try again.",
          locale: locale))
    case .savedWithoutAnalyzing:
      String(localized: LocalizedStringResource("Memory saved", locale: locale))
    }
  }

  static func elementAppeared(name: String, type: ElementType, locale: Locale) -> String {
    String(
      localized: LocalizedStringResource(
        "\(name), \(type.localizedName(locale: locale))", locale: locale))
  }

  // contrato 6: se anuncia cada elemento nuevo una vez, aunque lleguen varios en la misma tanda
  static func elementsAppeared(
    _ current: [ExtractedElement], after previousNames: [String], locale: Locale
  ) -> String? {
    let appeared = current.filter { !previousNames.contains($0.name) }
    guard !appeared.isEmpty else { return nil }
    return appeared.map {
      elementAppeared(name: $0.name, type: ElementType($0.type), locale: locale)
    }.joinedAsList(locale: locale)
  }

}
