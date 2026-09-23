import SwiftUI

// tokens.md §5: solo los movimientos que ya usa alguna vista
enum Motion {
  static let conexion = Animation.easeInOut(duration: 0.60)
  // con Reducir movimiento: el estado final, con fundido
  static let conexionReducida = Animation.easeInOut(duration: 0.20)
}
