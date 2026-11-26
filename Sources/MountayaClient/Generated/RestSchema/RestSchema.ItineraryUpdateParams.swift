// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for updating an existing itinerary. Every field is optional: this
  /// is a patch, so an omitted field keeps its current value rather than being
  /// cleared. Send null to clear the description; an itinerary always carries a
  /// name, so a name cannot be cleared.
  public struct ItineraryUpdateParams: Sendable, Hashable, Codable {
    /// Free-text description of the itinerary, at most 100 characters as sent,
    /// leading and trailing whitespace included; that whitespace is then
    /// trimmed. Omit to keep the current value; `null`, or a value that trims to
    /// nothing, clears it.
    ///
    /// Left `nil`, it is not sent, and a value already stored is left as it is. Set to a value, it
    /// is sent, and set to `.some(nil)`, it is sent as `null`, which clears a stored value:
    /// assigning `nil` is the absence of an instruction, never a clear.
    public var description: String??
    /// Whether the itinerary is private. A private itinerary is reached only with
    /// the key of the organization that owns it, so a private personal itinerary,
    /// owned by no organization, is reached by no key. A public itinerary is
    /// readable by id, read-only, by any publishable key, as last published, and
    /// it is listed only in its own organization's listings. A share token
    /// reaches only what its link names, the itinerary or a collection holding
    /// it, and reaches it whatever this says. Public never grants editing, which
    /// takes a write role in the owning organization. Privacy is read from the
    /// draft, so a change takes effect at once rather than at the next publish.
    /// Omit to keep the current value.
    public var is_private: Bool?
    /// Display name of the itinerary, 2 to 30 characters as sent. Leading and
    /// trailing whitespace is then trimmed, and what remains must still be at
    /// least 2 characters. Omit to keep the current value. Refused with a `409`
    /// when another itinerary in the organization already carries it, names
    /// compared exactly after trimming, case included; sending its current name
    /// again is not a conflict. A name is one line: a tab, a line break or a line
    /// separator between two of its characters is a `400`, and one at either end
    /// is trimmed with the whitespace there.
    public var name: String?

    /// Creates a `ItineraryUpdateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.description = nil
      self.is_private = nil
      self.name = nil
      configure(&self)
    }

    /// Reads a `ItineraryUpdateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.description = try container.decodeMerge(String.self, forKey: "description")
      self.is_private = try container.decodeIfPresent(Bool.self, forKey: "is_private")
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
    }

    /// Writes a `ItineraryUpdateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeMerge(self.description, forKey: "description")
      try container.encodeIfPresent(self.is_private, forKey: "is_private")
      try container.encodeIfPresent(self.name, forKey: "name")
    }
  }
}
