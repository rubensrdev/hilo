import Foundation

// contrato 1: unico nombre que se compara, nunca se muestra
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

    // locale: nil usaria el idioma del sistema (ver doc NSString); fijamos POSIX para que el plegado no dependa del dispositivo
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
