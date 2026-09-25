import Foundation

// F8 contrato 1: informacion del producto = nombre y version, sin enlaces que requieran red
nonisolated enum ProductVersion {
  static func read(from info: [String: Any]? = Bundle.main.infoDictionary) -> String {
    info?["CFBundleShortVersionString"] as? String ?? ""
  }
}
