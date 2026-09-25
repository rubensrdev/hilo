import Foundation

/// A notice on the first failure, without counting attempts; shared by capture and understanding later.
nonisolated enum ReviewNotice: Sendable, Equatable {
  case reviewUnavailable
  case reviewNotSaved
  case savedWithoutAnalyzing
}
