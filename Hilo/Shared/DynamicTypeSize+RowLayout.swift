import SwiftUI

extension DynamicTypeSize {
  /// At accessibility sizes, whatever sits in a row stacks.
  func rowLayout(alignment: VerticalAlignment = .center, spacing: CGFloat) -> AnyLayout {
    isAccessibilitySize
      ? AnyLayout(VStackLayout(alignment: .leading, spacing: spacing))
      : AnyLayout(HStackLayout(alignment: alignment, spacing: spacing))
  }
}
