import SwiftUI

// F8.4: captura y comprender mas tarde anuncian lo mismo — empieza a leer, o fallo y por que
private struct ComprehensionAnnouncements: ViewModifier {
  let isReading: Bool
  let failure: MemoryComprehensionReason?
  @Environment(\.locale) private var environmentLocale

  private var interfaceLocale: Locale { InterfaceLocale.resolve(environmentLocale) }

  func body(content: Content) -> some View {
    content
      .onChange(of: isReading) { _, isReading in
        guard isReading else { return }
        AccessibilityNotification.Announcement(
          ComprehensionCopy.readingAnnouncement(locale: interfaceLocale)
        ).post()
      }
      .onChange(of: failure) { _, failure in
        guard let failure else { return }
        AccessibilityNotification.Announcement(
          ComprehensionCopy.notice(failure, locale: interfaceLocale).announcement
        ).post()
      }
  }
}

extension View {
  func announcesComprehension(isReading: Bool, failure: MemoryComprehensionReason?) -> some View {
    modifier(ComprehensionAnnouncements(isReading: isReading, failure: failure))
  }
}
