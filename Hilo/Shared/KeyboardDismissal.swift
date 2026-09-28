import SwiftUI

extension View {
  /// Una sola barra por pantalla: cada pantalla aporta su foco y lo aplica una vez.
  func hidesKeyboard(_ focus: FocusState<Bool>.Binding) -> some View {
    toolbar {
      ToolbarItemGroup(placement: .keyboard) {
        Spacer()
        Button {
          focus.wrappedValue = false
        } label: {
          Label("Hide keyboard", systemImage: "keyboard.chevron.compact.down")
        }
        .accessibilityIdentifier("keyboard.hide")
      }
    }
  }
}
