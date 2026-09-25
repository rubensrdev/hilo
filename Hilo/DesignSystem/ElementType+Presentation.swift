import SwiftUI

/// The type's name follows the interface language, not the system's.
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
}
