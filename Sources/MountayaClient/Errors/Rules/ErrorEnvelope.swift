import Foundation

/// ErrorEnvelope reads what a failing answer's body carries: its entries, and its
/// `extensions.metadata`.
///
/// A body is read for what it holds and refused for nothing: an answer whose body is no JSON, or
/// whose `errors` are no list, carries no entry, and the error raised from it is still the one
/// its status names.
enum ErrorEnvelope {
  /// Read is what a body carries.
  struct Read: Sendable {
    /// errors is every member of `errors` that is an entry, an object with a string `message`,
    /// in order. A member that is not one is left out.
    let errors: [ErrorEntry]
    /// hasErrors is true where the body carries `errors` at all, which on the Data API makes a
    /// success an error even where none of them is an entry.
    let hasErrors: Bool
    /// metadata is `extensions.metadata` exactly as sent, or nil where the body carries none.
    let metadata: JSONValue?
  }

  /// read returns what `body` carries, or nothing where it is no JSON object.
  static func read(_ body: Data) -> Read {
    guard case .object(let members)? = try? JSONDecoder().decode(JSONValue.self, from: body) else {
      return Read(errors: [], hasErrors: false, metadata: nil)
    }
    return read(members)
  }

  /// read returns what a decoded body carries.
  static func read(_ members: [String: JSONValue]) -> Read {
    var errors: [ErrorEntry] = []
    var hasErrors = false
    if let listed = members["errors"], listed != .null {
      hasErrors = true
      if case .array(let entries) = listed {
        errors = entries.compactMap(entry)
      }
    }
    var metadata: JSONValue?
    if case .object(let extensions)? = members["extensions"], let found = extensions["metadata"],
      found != .null
    {
      metadata = found
    }
    return Read(errors: errors, hasErrors: hasErrors, metadata: metadata)
  }

  /// entry reads one member of `errors`, or nil where it is no object with a string `message`.
  /// A code is the entry's `extensions.code` where that is a string, kept as sent whether or not a
  /// surface declares it, and a path is kept only where every step of it is a key or a whole index.
  static func entry(_ value: JSONValue) -> ErrorEntry? {
    guard case .object(let members) = value, case .string(let message)? = members["message"] else {
      return nil
    }
    var code: APIErrorCode?
    if case .object(let extensions)? = members["extensions"],
      case .string(let text)? = extensions["code"]
    {
      code = APIErrorCode(rawValue: text)
    }
    var path: [ErrorEntry.PathComponent]?
    if case .array(let steps)? = members["path"] {
      path = []
      for step in steps {
        switch step {
        case .string(let key):
          path?.append(.key(key))
        case .number(let number):
          if let index = Int(exactly: number) {
            path?.append(.index(index))
          } else {
            path = nil
          }
        default:
          path = nil
        }
        if path == nil { break }
      }
    }
    return ErrorEntry(message: message, code: code, path: path)
  }
}
