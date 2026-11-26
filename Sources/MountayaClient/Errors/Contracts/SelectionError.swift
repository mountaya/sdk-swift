/// SelectionError is a field selection the operation's field tree does not allow, refused at
/// the call rather than by the server.
public struct SelectionError: Sendable, Hashable, CustomStringConvertible {
  /// path names the field the selection got wrong, from the operation's result down, or is
  /// empty where the selection as a whole is wrong.
  public let path: [String]
  /// message says what is wrong with it.
  public let message: String

  /// Creates a refusal.
  public init(path: [String], message: String) {
    self.path = path
    self.message = message
  }

  /// description is the failure as a developer reads it in a log.
  public var description: String {
    path.isEmpty ? message : "`\(path.joined(separator: "."))`: \(message)"
  }
}
