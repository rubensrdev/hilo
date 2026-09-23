import Foundation
import SwiftData

@Model
final class ElementRecord {
  @Attribute(.unique) var id: UUID
  var displayName: String
  var canonicalName: String
  var type: ElementType
  var aliases: [String]
  @Relationship(deleteRule: .cascade, inverse: \AppearanceRecord.element)
  var appearances: [AppearanceRecord] = []
  @Relationship(deleteRule: .cascade, inverse: \DiscardRecord.element)
  var discards: [DiscardRecord] = []

  init(
    id: UUID = UUID(), displayName: String, canonicalName: String, type: ElementType,
    aliases: [String] = []
  ) {
    self.id = id
    self.displayName = displayName
    self.canonicalName = canonicalName
    self.type = type
    self.aliases = aliases
  }
}
