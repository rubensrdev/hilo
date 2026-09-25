import Foundation

/// The only name that is compared; it is never shown.
nonisolated enum CanonicalName {
  private static let leadingWords: Set<String> = [
    "el", "la", "los", "las", "lo", "un", "una", "mi", "mis", "tu", "tus", "su", "sus",
    "nuestro", "nuestra", "nuestros", "nuestras",
    "the", "a", "an", "my", "our", "your", "his", "her", "their",
  ]

  static func of(_ displayName: String) -> String {
    let normalized =
      displayName
      .trimmingCharacters(in: .whitespacesAndNewlines)
      .components(separatedBy: .whitespacesAndNewlines)
      .filter { !$0.isEmpty }
      .joined(separator: " ")

    // POSIX, so folding never depends on the device's language.
    let folded = normalized.folding(
      options: [.diacriticInsensitive, .caseInsensitive],
      locale: Locale(identifier: "en_US_POSIX")
    )

    var words = folded.components(separatedBy: " ")
    if let first = words.first, words.count > 1, leadingWords.contains(first) {
      words.removeFirst()
    }
    return words.joined(separator: " ")
  }
}
