import SwiftUI

// tokens.md §4: simbolo y color de cada tipo; el nombre, en el idioma de la interfaz (InterfaceLocale)
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
