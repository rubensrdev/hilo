import FoundationModels

/// Shape validated by the F0.2 spike on twelve Spanish and English narratives (ADR-001 §2);
/// the contract does not change.
@Generable(
  description:
    "Lo que se entiende de un recuerdo: sus elementos y la fecha tal como la contó quien lo recuerda"
)
nonisolated struct ExtractedMemory {
  @Guide(
    description:
      "Personas, lugares u objetos nombrables y singulares mencionados en el relato, en el orden en que aparecen"
  )
  let elements: [ExtractedElement]

  @Guide(
    description:
      "El texto de la fecha, literal, tal como lo escribió quien cuenta el recuerdo. Ausente si no se menciona ninguna fecha"
  )
  let dateText: String?

  @Guide(
    description:
      "El año que se puede deducir del texto de la fecha, solo cuando es posible deducirlo con certeza"
  )
  let deducedYear: Int?
}

@Generable(description: "Un elemento nombrable extraído de un recuerdo")
nonisolated struct ExtractedElement {
  @Guide(description: "El nombre tal como aparece en el relato")
  let name: String
  @Guide(description: "El tipo de elemento")
  let type: ExtractedElementType
  @Guide(description: "El papel del elemento en el recuerdo, con las palabras de quien lo cuenta")
  let role: String
}

@Generable
nonisolated enum ExtractedElementType {
  case person
  case place
  case object
}

extension ExtractedMemory {
  /// An element only appears once all three of its fields are complete.
  init(partial: ExtractedMemory.PartiallyGenerated) {
    self.init(
      elements: (partial.elements ?? []).compactMap { element in
        guard let name = element.name, let type = element.type, let role = element.role else {
          return nil
        }
        return ExtractedElement(name: name, type: type, role: role)
      },
      dateText: partial.dateText,
      deducedYear: partial.deducedYear)
  }
}
