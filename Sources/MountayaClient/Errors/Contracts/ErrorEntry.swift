/// ErrorEntry is one entry of a failure envelope: one failed validation of a REST request, or
/// one GraphQL error of a Data API response.
///
/// `message` is written for a person, in the language `Accept-Language` asked for, and free to
/// change. `code` is what a program branches on, in the one vocabulary every surface's codes share,
/// `APIErrorCode`.
public struct ErrorEntry: Sendable, Hashable {
  /// PathComponent is one step of the path to the field an entry is about.
  public enum PathComponent: Sendable, Hashable {
    /// key is a member of an object.
    case key(String)
    /// index is a position in an array, which stays a number.
    case index(Int)
  }

  /// message is the failure, described for a person.
  public let message: String
  /// code is the machine-readable code the entry carries under `extensions.code`, kept as sent
  /// where no surface declares it, or nil where it carries none.
  public let code: APIErrorCode?
  /// path is where the field the entry is about sits, from the root of the request or of the
  /// result, or nil where the entry is about no field in particular.
  public let path: [PathComponent]?

  /// Creates an entry.
  public init(message: String, code: APIErrorCode? = nil, path: [PathComponent]? = nil) {
    self.message = message
    self.code = code
    self.path = path
  }
}
