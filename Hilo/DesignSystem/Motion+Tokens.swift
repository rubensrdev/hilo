import SwiftUI

/// Only the motions some view already uses.
enum Motion {
  static let aparicionElemento = Animation.spring(response: 0.30, dampingFraction: 1)
  static let aparicionElementoReducida = Animation.easeInOut(duration: 0.15)
  static let conexion = Animation.easeInOut(duration: 0.60)
  /// With Reduce Motion: the final state, faded in.
  static let conexionReducida = Animation.easeInOut(duration: 0.20)
}
