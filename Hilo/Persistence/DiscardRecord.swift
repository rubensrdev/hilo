import Foundation
import SwiftData

@Model
final class DiscardRecord {
  var gapType: String
  var element: ElementRecord?

  init(gapType: String, element: ElementRecord? = nil) {
    self.gapType = gapType
    self.element = element
  }
}
