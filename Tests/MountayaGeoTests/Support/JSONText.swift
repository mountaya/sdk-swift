import Foundation
import MountayaClient

/// json reads a JSON document into the client's `JSONValue`, so a test writes a style's label or
/// a bundle's words as the style or the bundle writes them.
func json(_ text: String) throws -> JSONValue {
  try JSONDecoder().decode(JSONValue.self, from: Data(text.utf8))
}

/// jsonObject reads a JSON document that is an object into its members.
func jsonObject(_ text: String) throws -> [String: JSONValue] {
  guard case .object(let members) = try json(text) else {
    throw JSONTextError(text: text)
  }
  return members
}

/// JSONTextError says a document a test wrote as an object is none.
struct JSONTextError: Error {
  let text: String
}
