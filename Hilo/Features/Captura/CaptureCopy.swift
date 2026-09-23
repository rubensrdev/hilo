import Foundation

// contrato 1 + DEC-43: el error de comprension es un aviso, el texto del usuario ya esta a salvo
nonisolated struct ComprehensionNoticeCopy: Sendable, Equatable {
  enum Actions: Sendable, Equatable {
    case retryOrLeave
    case done
  }

  let title: String
  let body: String
  let actions: Actions

  var announcement: String { "\(title). \(body)" }
}

// contrato 6: textos anunciables como funciones puras, probados en los dos idiomas
nonisolated enum CaptureCopy {
  static func comprehensionNotice(_ reason: MemoryComprehensionReason, locale: Locale)
    -> ComprehensionNoticeCopy
  {
    ComprehensionNoticeCopy(
      title: String(
        localized: LocalizedStringResource(
          "Your memory is saved just as you told it", locale: locale)),
      body: body(reason, locale: locale),
      actions: reason.allowsRetry ? .retryOrLeave : .done)
  }

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

  // anexo DEC-46: guardarrail y rechazo usan el texto generico, nunca insinuan nada del recuerdo
  private static func body(_ reason: MemoryComprehensionReason, locale: Locale) -> String {
    switch reason {
    case .generic, .guardrail:
      String(
        localized: LocalizedStringResource(
          "Hilo couldn't read it this time. It's saved without people, places or objects — you can try again now, or later from the memory.",
          locale: locale))
    case .contextOverflow:
      String(
        localized: LocalizedStringResource(
          "This memory is too long for Hilo to read in one go. It's saved without people, places or objects. If you shorten it, you can ask Hilo to read it from the memory.",
          locale: locale))
    case .unsupportedLanguage:
      String(
        localized: LocalizedStringResource(
          "Hilo can't read memories in this language. It's saved without people, places or objects.",
          locale: locale))
    }
  }
}

extension MemoryComprehensionReason {
  // DEC-42 + anexo DEC-46: desbordamiento e idioma fallarian igual al reintentar sin cambiar nada
  nonisolated var allowsRetry: Bool {
    switch self {
    case .generic, .guardrail: true
    case .contextOverflow, .unsupportedLanguage: false
    }
  }
}
