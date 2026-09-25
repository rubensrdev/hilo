/// Raw String value, so persistence stores it as a column, not a serialized blob.
nonisolated enum RecognitionStatus: String, Sendable, Equatable, Codable {
  case confirmedByUser
  case proposed
}

/// Rule 3: comprehension the user has not confirmed does not count.
nonisolated struct Appearance: Sendable {
  let memoryID: MemoryID
  let elementID: ElementID
  let role: ElementRole?
  let status: RecognitionStatus

  init(memoryID: MemoryID, elementID: ElementID, role: ElementRole?, status: RecognitionStatus) {
    self.memoryID = memoryID
    self.elementID = elementID
    self.role = role
    self.status = status
  }
}
