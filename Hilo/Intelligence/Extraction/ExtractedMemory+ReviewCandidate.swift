/// The Intelligence-to-Domain bridge: the only file that knows both ExtractedMemory and ReviewState.
nonisolated extension ElementType {
  init(_ extracted: ExtractedElementType) {
    switch extracted {
    case .person: self = .person
    case .place: self = .place
    case .object: self = .object
    }
  }
}

nonisolated extension ReviewCandidate {
  init?(_ extracted: ExtractedElement) {
    self.init(
      name: extracted.name, type: ElementType(extracted.type),
      role: ElementRole(text: extracted.role))
  }
}

nonisolated extension ReviewState {
  init(
    extracted: ExtractedMemory, knownElements: [Element], appearances: [Appearance],
    excludingMemoryID: MemoryID? = nil
  ) {
    self.init(
      candidates: extracted.elements.compactMap(ReviewCandidate.init),
      extractedDateText: extracted.dateText, extractedDeducedYear: extracted.deducedYear,
      knownElements: knownElements, appearances: appearances,
      excludingMemoryID: excludingMemoryID)
  }
}
