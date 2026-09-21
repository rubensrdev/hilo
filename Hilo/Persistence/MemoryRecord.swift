import Foundation
import SwiftData

@Model
final class MemoryRecord {
  @Attribute(.unique) var id: UUID
  var narrative: String
  var dateText: String?
  var deducedYear: Int?
  @Attribute(.externalStorage) var photoData: Data?
  var savedAt: Date
  var isAnalyzed: Bool
  var isExample: Bool
  @Relationship(deleteRule: .cascade, inverse: \AppearanceRecord.memory)
  var appearances: [AppearanceRecord] = []

  init(
    id: UUID = UUID(), narrative: String, dateText: String? = nil, deducedYear: Int? = nil,
    photoData: Data? = nil, savedAt: Date, isAnalyzed: Bool = false, isExample: Bool = false
  ) {
    self.id = id
    self.narrative = narrative
    self.dateText = dateText
    self.deducedYear = deducedYear
    self.photoData = photoData
    self.savedAt = savedAt
    self.isAnalyzed = isAnalyzed
    self.isExample = isExample
  }
}
