import SwiftUI

/// trazo-vinculo is not here: it is a function of the memory count, which is domain logic, not a value.
enum Spacing {
  static let espacio1: CGFloat = 4
  static let espacio2: CGFloat = 8
  static let espacio3: CGFloat = 12
  static let espacio4: CGFloat = 16
  static let espacio5: CGFloat = 24
  static let espacio6: CGFloat = 32
  static let espacio7: CGFloat = 48

  static let margenPantalla = espacio4
  static let rellenoTarjeta = espacio4
  static let separacionTarjetas = espacio3
  static let separacionSecciones = espacio5
  static let separacionChips = espacio2
  static let altoFilaMinimo: CGFloat = 44
  static let objetivoToqueMinimo: CGFloat = 44
  /// The field grows with its text, so its minimum does not scale with Dynamic Type.
  static let altoMinimoCampoCaptura: CGFloat = 160

  /// radio-tarjeta, radio-campo and radio-foto are continuous: the view applies `.continuous`, the value can't say so.
  static let radioTarjeta: CGFloat = 16
  static let radioCampo: CGFloat = 12
  static let radioFoto: CGFloat = 12
  static let radioChip = Capsule()

  /// Width over height.
  static let proporcionFotoTarjeta: CGFloat = 3 / 2
  static let altoFotoCaptura: CGFloat = 120

  static let trazoBordeTarjeta: CGFloat = 1
  static let trazoChipConocido: CGFloat = 1.5
  static let trazoConexion: CGFloat = 2.5
}

/// One physical pixel, not one point: it depends on the display scale.
private struct TrazoSeparador: ViewModifier {
  @Environment(\.displayScale) private var displayScale

  func body(content: Content) -> some View {
    content.frame(height: 1 / displayScale)
  }
}

extension View {
  func trazoSeparador() -> some View {
    modifier(TrazoSeparador())
  }

  /// Always drawn; the colorset is clear except in high contrast. Not named bordeTarjeta(),
  /// because Color is a View and it would shadow Color.bordeTarjeta.
  func contornoTarjeta() -> some View {
    overlay {
      RoundedRectangle(cornerRadius: Spacing.radioTarjeta, style: .continuous)
        .strokeBorder(Color.bordeTarjeta, lineWidth: Spacing.trazoBordeTarjeta)
    }
  }
}
