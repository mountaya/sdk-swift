// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The contract's `ThingCreate`.
  ///
  /// It prints every property but its secrets, each printed as `<redacted>`, however it is printed
  /// (`sdk/SPEC.md` §1).
  public struct ThingCreate: Sendable, Hashable, Codable, CustomDebugStringConvertible,
    CustomReflectable
  {
    /// The contract's `name`.
    public var name: String
    /// The contract's `parent_id`.
    public var parent_id: String?
    /// The contract's `note`.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var note: String??
    /// The contract's `secret`.
    ///
    /// A request sends it, and the server never answers it.
    ///
    /// It is a secret: the type prints it as `<redacted>` wherever it is printed, in a log, a
    /// debugger's description or a dump, and a caller reads it as it is.
    public var secret: String?

    /// Creates a `ThingCreate` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      name: String,
      parent_id: String?,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = name
      self.parent_id = parent_id
      self.note = nil
      self.secret = nil
      configure(&self)
    }

    /// Reads a `ThingCreate` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decode(String.self, forKey: "name")
      self.parent_id = try container.decodeIfPresent(String.self, forKey: "parent_id")
      self.note = try container.decodeMerge(String.self, forKey: "note")
      self.secret = try container.decodeIfPresent(String.self, forKey: "secret")
    }

    /// Writes a `ThingCreate` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.name, forKey: "name")
      try container.encodeNullable(self.parent_id, forKey: "parent_id")
      try container.encodeMerge(self.note, forKey: "note")
      try container.encodeIfPresent(self.secret, forKey: "secret")
    }

    /// debugDescription is the value as a log may show it, which `print`, `String(describing:)` and
    /// `dump` all write: every property but its secrets, each printed as `<redacted>`.
    public var debugDescription: String {
      var fields: [String] = []
      fields.append("name: \(String(reflecting: self.name))")
      fields.append("parent_id: \(String(reflecting: self.parent_id))")
      fields.append("note: \(String(reflecting: self.note))")
      fields.append("secret: <redacted>")
      return "ThingCreate(\(fields.joined(separator: ", ")))"
    }

    /// customMirror has no children, so `dump` and a debugger's variable view print the redacted
    /// description rather than the secrets.
    public var customMirror: Mirror {
      Mirror(self, children: [], displayStyle: .struct)
    }
  }
}
