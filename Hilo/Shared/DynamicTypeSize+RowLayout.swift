import SwiftUI

extension DynamicTypeSize {
  // P2 (tokens.md §2.2): en tamaños de accesibilidad lo que va en fila se apila
  func rowLayout(alignment: VerticalAlignment = .center, spacing: CGFloat) -> AnyLayout {
    isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
      : AnyLayout(HStackLayout(alignment: alignment, spacing: spacing))
  }
}
