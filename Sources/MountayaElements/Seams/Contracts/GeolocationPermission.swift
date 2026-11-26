/// GeolocationPermission is what asking for a fix would do, when that can be known without asking.
public enum GeolocationPermission: String, Sendable, Hashable, CaseIterable {
  /// denied is a fix that would be refused: the reader refused it, the platform restricts it, or
  /// the reader allows only an approximate one.
  case denied
  /// granted is a fix that would be answered.
  case granted
  /// prompt is a permission never asked for, which the app asks the reader for in its own flow.
  case prompt
  /// unknown is a platform that does not say.
  case unknown
}
