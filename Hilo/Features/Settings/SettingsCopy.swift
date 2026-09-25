import Foundation

// F8 contrato 1: version del producto y los dos pasos del borrado total, testables en EN/ES
nonisolated enum SettingsCopy {
  static func versionLine(_ version: String, locale: Locale) -> String {
    String(localized: LocalizedStringResource("Version \(version)", locale: locale))
  }

  // el texto dice exactamente que desaparece, sin asustar ni banalizar
  static func wipeFirstStepBody(locale: Locale) -> String {
    String(
      localized: LocalizedStringResource(
        "Every memory, every person, place and object, and every photo will be deleted from this iPhone. Hilo will start again as on the first day.",
        locale: locale))
  }

  static func wipeSecondStepBody(locale: Locale) -> String {
    String(
      localized: LocalizedStringResource(
        "This cannot be undone. There is no copy anywhere else.", locale: locale))
  }
}
