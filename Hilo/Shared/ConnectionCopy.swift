import Foundation

/// A connection always shows its motive, with the same text right after saving and later in the detail.
nonisolated enum ConnectionCopy {
  static func firstAppearanceBody(names: [String], locale: Locale) -> String {
    let joined = names.joinedAsList(locale: locale)
    if names.count == 1 {
      return String(
        localized: LocalizedStringResource(
          "This is the first time \(joined) appears. The next memory that mentions \(joined) will connect to this one.",
          locale: locale))
    }
    return String(
      localized: LocalizedStringResource(
        "This is the first time \(joined) appear. The next memory that shares any of them will connect to this one.",
        locale: locale))
  }

  static func connectionMotive(names: [String], locale: Locale) -> String {
    String(
      localized: LocalizedStringResource(
        "By \(names.joinedAsList(locale: locale))", locale: locale,
        comment:
          "Why two memories are connected: the people, places or objects they share, as a list of names."
      ))
  }

  /// The extract is cut on screen, but VoiceOver reads the whole memory after the motive.
  static func connectionRowLabel(names: [String], narrative: String, locale: Locale) -> String {
    "\(connectionMotive(names: names, locale: locale)). \(narrative)"
  }
}
