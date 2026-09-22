import SwiftUI

// contrato 4 + tokens.md §4: simbolo, color y nombre de cada tipo, unico punto de verdad
// para Captura y Revision — el tipo nunca se comunica solo con color (regla del proyecto)
extension ElementType {
  var symbolName: String {
    switch self {
    case .person: "person.fill"
    case .place: "mappin.and.ellipse"
    case .object: "cube.fill"
    }
  }

  var color: Color {
    switch self {
    case .person: .tipoPersona
    case .place: .tipoLugar
    case .object: .tipoObjeto
    }
  }

  var displayName: String {
    switch self {
    case .person: String(localized: "Person")
    case .place: String(localized: "Place")
    case .object: String(localized: "Object")
    }
  }

  // encabezados de grupo en Revision (bloque "Lo que ha entendido")
  var pluralDisplayName: String {
    switch self {
    case .person: String(localized: "People")
    case .place: String(localized: "Places")
    case .object: String(localized: "Objects")
    }
  }
}
