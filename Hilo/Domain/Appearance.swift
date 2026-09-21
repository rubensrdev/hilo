nonisolated enum RecognitionStatus: Sendable, Equatable {
  case confirmedByUser
  case proposed
}

// contrato 3 + regla 3: comprension sin confirmar no entra
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
