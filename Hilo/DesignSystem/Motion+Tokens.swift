import SwiftUI

// tokens.md §5: solo los movimientos que ya usa alguna vista
enum Motion {
  // spring suave, sin rebote
  static let aparicionElemento = Animation.spring(response: 0.30, dampingFraction: 1)
  static let aparicionElementoReducida = Animation.easeInOut(duration: 0.15)
  static let conexion = Animation.easeInOut(duration: 0.60)
  // con Reducir movimiento: el estado final, con fundido
  static let conexionReducida = Animation.easeInOut(duration: 0.20)
}
