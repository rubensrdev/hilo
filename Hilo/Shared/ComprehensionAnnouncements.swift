import SwiftUI

/// Capture and understanding later announce the same things: reading started, or it failed and why.
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
