import Foundation
import SwiftData

@Model
final class AppearanceRecord {
  var memory: MemoryRecord?
  var element: ElementRecord?
  var role: String?
  var status: RecognitionStatus

  init(
    memory: MemoryRecord? = nil, element: ElementRecord? = nil, role: String? = nil,
    status: RecognitionStatus
  ) {
    self.memory = memory
    self.element = element
    self.role = role
    self.status = status
  }
}
