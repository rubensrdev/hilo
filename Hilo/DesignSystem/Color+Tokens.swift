import SwiftUI

// contrato 3: los 18 colores reales (16 + borde-tarjeta/borde-chip-nuevo, con su propia
// variante de alto contraste) ya llegan de Xcode como simbolos generados del catalogo
// de assets (mismo nombre en camelCase); aqui solo van los alias que tokens.md define
// como iguales en las 4 apariencias
extension Color {
  static let chipRelleno = superficieHundida
  static let destructivo = estadoError
  static let seleccionado = acentoHilo
  static let vinculoTejido = acentoHilo
  static let bordeChipConocido = acentoHilo
}
