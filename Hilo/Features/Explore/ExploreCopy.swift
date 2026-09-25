import Foundation

/// "N" is the number of memories the element already appears in.
nonisolated enum ExploreCopy {
  static func elementMemoryCount(_ count: Int, locale: Locale) -> String {
    String(localized: LocalizedStringResource("in \(count) memories", locale: locale))
  }

  /// Rule 17: a decade header, never a date the user wrote.
  static func decadeHeader(_ decade: MemoryDecade, locale: Locale) -> String {
    switch decade {
    case .decade(let startingYear):
      // No grouping separator: it's a year, not a quantity.
      String(
        localized: LocalizedStringResource(
          "\(startingYear, format: .number.grouping(.never))s", locale: locale))
    case .noYear:
      String(localized: LocalizedStringResource("No date", locale: locale))
    }
  }

  /// Says what goes and what stays. No catalog plural: the number isn't shown, only the agreement
  /// changes, as in ConnectionCopy.
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

  /// An already localized String, like the plural type names on the other chips.
  static func allFilterLabel(locale: Locale) -> String {
    String(localized: LocalizedStringResource("All", locale: locale))
  }

  static func elementTypeAndCount(_ type: ElementType, count: Int, locale: Locale) -> String {
    "\(type.localizedName(locale: locale)) · \(elementMemoryCount(count, locale: locale))"
  }

  /// VoiceOver must not read the range's dash as text.
  static func dateRangeAccessibilityLabel(oldest: String, newest: String, locale: Locale) -> String
  {
    String(localized: LocalizedStringResource("From \(oldest) to \(newest)", locale: locale))
  }
}
