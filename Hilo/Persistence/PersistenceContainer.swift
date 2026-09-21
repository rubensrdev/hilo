import Foundation
import SwiftData

enum PersistenceContainer {
  static let schema = Schema([
    MemoryRecord.self, ElementRecord.self, AppearanceRecord.self, DiscardRecord.self,
  ])

  static func make(inMemory: Bool) throws -> ModelContainer {
    let configuration = ModelConfiguration(isStoredInMemoryOnly: inMemory)
    return try ModelContainer(for: schema, configurations: [configuration])
  }
}
