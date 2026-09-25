import Foundation

/// The user's text is already safe, so a comprehension error is a notice. Shared by capture and
/// by understanding later from the memory detail.
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

nonisolated enum ComprehensionCopy {
  /// The start of reading is announced, not only shown.
  static func readingAnnouncement(locale: Locale) -> String {
    String(localized: LocalizedStringResource("Reading your memory…", locale: locale))
  }

  static func notice(_ reason: MemoryComprehensionReason, locale: Locale) -> ComprehensionNoticeCopy
  {
    ComprehensionNoticeCopy(
      title: String(
        localized: LocalizedStringResource(
          "Your memory is saved just as you told it", locale: locale)),
      body: body(reason, locale: locale),
      actions: reason.allowsRetry ? .retryOrLeave : .done)
  }

  /// Guardrail and refusal use the generic text and never hint at anything about the memory.
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
  /// Overflow and language would fail the same way on a retry with nothing changed.
  nonisolated var allowsRetry: Bool {
    switch self {
    case .generic, .guardrail: true
    case .contextOverflow, .unsupportedLanguage: false
    }
  }
}
