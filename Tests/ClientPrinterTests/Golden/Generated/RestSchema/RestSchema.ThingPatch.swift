// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The contract's `ThingPatch`.
  public struct ThingPatch: Sendable, Hashable, Codable {
    /// The contract's `name`.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var name: String??
    /// The contract's `when`.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var when: Date??
    /// The contract's `note`.
    public var note: String?

    /// Creates a `ThingPatch` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = nil
      self.when = nil
      self.note = nil
      configure(&self)
    }

    /// Reads a `ThingPatch` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decodeMerge(String.self, forKey: "name")
      self.when = try container.decodeWiredMerge(Date.self, forKey: "when")
      self.note = try container.decodeIfPresent(String.self, forKey: "note")
    }

    /// Writes a `ThingPatch` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.name, forKey: "name")
      try container.encodeWiredMerge(self.when, forKey: "when")
      try container.encodeIfPresent(self.note, forKey: "note")
    }
  }
}
