/// LocationAccuracy is how precisely the app may read the device's location.
public enum LocationAccuracy: Sendable, Hashable, CaseIterable {
  /// full is the platform's full accuracy, which a navigation reads.
  case full
  /// reduced is a location only approximately where the reader stands, kilometres away at times,
  /// which a navigation reads nothing of.
  case reduced
}
