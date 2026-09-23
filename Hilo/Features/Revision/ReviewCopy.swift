import Foundation

// contrato 6: textos anunciables de la revision, sin concordancia de genero
nonisolated enum ReviewCopy {
  static func beginningBody(names: [String], locale: Locale) -> String {
    let joined = names.joinedAsList(locale: locale)
    if names.count == 1 {
      return String(
        localized: LocalizedStringResource(
          "This is the first time \(joined) appears. The next memory that mentions \(joined) will connect to this one.",
          locale: locale))
    }
    return String(
      localized: LocalizedStringResource(
        "This is the first time \(joined) appear. The next memory that shares any of them will connect to this one.",
        locale: locale))
  }

  // contrato 6: nombre, tipo y en cuantos recuerdos; nil = nuevo, sin recuerdos que contar
  static func elementLabel(name: String, type: ElementType, otherMemories: Int?, locale: Locale)
    -> String
  {
    let typeName = type.localizedName(locale: locale)
    guard let otherMemories else {
      return String(
        localized: LocalizedStringResource("\(name), \(typeName), first time", locale: locale))
    }
    return String(
      localized: LocalizedStringResource(
        "\(name), \(typeName), in \(otherMemories) memories", locale: locale))
  }

  static func removedElementLabel(name: String, type: ElementType, locale: Locale) -> String {
    String(
      localized: LocalizedStringResource(
        "\(name), \(type.localizedName(locale: locale)), removed from this memory", locale: locale))
  }

  // DEC-49: la respuesta de la duda dice que es otro de su mismo tipo
  static func doubtRejection(type: ElementType, locale: Locale) -> String {
    switch type {
    case .person: String(localized: LocalizedStringResource("Someone else", locale: locale))
    case .place: String(localized: LocalizedStringResource("Another place", locale: locale))
    case .object: String(localized: LocalizedStringResource("Another object", locale: locale))
    }
  }

  // regla 4 del diseño: una conexion siempre enseña su motivo
  static func connectionMotive(names: [String], locale: Locale) -> String {
    String(
      localized: LocalizedStringResource(
        "By \(names.joinedAsList(locale: locale))", locale: locale,
        comment:
          "Why two memories are connected: the people, places or objects they share, as a list of names."
      ))
  }

  // el extracto se corta en pantalla, pero VoiceOver lee el recuerdo entero tras el motivo
  static func connectionRowLabel(names: [String], narrative: String, locale: Locale) -> String {
    "\(connectionMotive(names: names, locale: locale)). \(narrative)"
  }

  static func momentAnnouncement(connectedCount: Int, locale: Locale) -> String {
    let saved = String(localized: LocalizedStringResource("Memory saved", locale: locale))
    let connected = String(
      localized: LocalizedStringResource(
        "Connected with \(connectedCount) memories", locale: locale))
    return "\(saved). \(connected)"
  }
}
