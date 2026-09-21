import FoundationModels

// forma validada por el spike F0.2 en doce relatos ES/EN, ver ADR-001 §2 — no se cambia el contrato
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
