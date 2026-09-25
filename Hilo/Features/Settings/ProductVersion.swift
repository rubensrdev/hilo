import Foundation

/// Name and version only, with no links that would need the network.
nonisolated enum ProductVersion {
  static func read(from info: [String: Any]? = Bundle.main.infoDictionary) -> String {
    info?["CFBundleShortVersionString"] as? String ?? ""
  }
}
