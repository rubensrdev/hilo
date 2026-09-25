import Foundation

/// No gender agreement in any of these strings.
nonisolated enum ReviewCopy {
  /// nil means new: there are no memories to count.
  static func elementLabel(name: String, type: ElementType, otherMemories: Int?, locale: Locale)
    -> String
  {
    let typeName = type.localizedName(locale: locale)
    guard let otherMemories else {
      return String(
        localized: LocalizedStringResource("\(name), \(typeName), first time", locale: locale))
    }
    return String(
      localized: LocalizedStringResource(
        "\(name), \(typeName), in \(otherMemories) memories", locale: locale))
  }

  static func removedElementLabel(name: String, type: ElementType, locale: Locale) -> String {
    String(
      localized: LocalizedStringResource(
        "\(name), \(type.localizedName(locale: locale)), removed from this memory", locale: locale))
  }

  /// Rejecting the doubt says it is another one of the same type.
  static func doubtRejection(type: ElementType, locale: Locale) -> String {
    switch type {
    case .person: String(localized: LocalizedStringResource("Someone else", locale: locale))
    case .place: String(localized: LocalizedStringResource("Another place", locale: locale))
    case .object: String(localized: LocalizedStringResource("Another object", locale: locale))
    }
  }

  static func momentAnnouncement(connectedCount: Int, locale: Locale) -> String {
    let saved = String(localized: LocalizedStringResource("Memory saved", locale: locale))
    let connected = String(
      localized: LocalizedStringResource(
        "Connected with \(connectedCount) memories", locale: locale))
    return "\(saved). \(connected)"
  }
}
