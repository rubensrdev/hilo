import Foundation

// contrato 2: mismo tipo y el canonico de un nombre contiene al del otro como secuencia de palabras completas
nonisolated enum Resemblance {
  static func between(
    _ nameA: String, type typeA: ElementType,
    _ nameB: String, type typeB: ElementType
  ) -> Bool {
    guard typeA == typeB else { return false }

    let wordsA = CanonicalName.of(nameA).components(separatedBy: " ")
    let wordsB = CanonicalName.of(nameB).components(separatedBy: " ")

    return contains(sequence: wordsA, in: wordsB) || contains(sequence: wordsB, in: wordsA)
  }

  private static func contains(sequence needle: [String], in haystack: [String]) -> Bool {
    guard !needle.isEmpty, needle.count <= haystack.count else { return false }

    for start in 0...(haystack.count - needle.count) {
      if Array(haystack[start..<(start + needle.count)]) == needle {
        return true
      }
    }
    return false
  }
}
