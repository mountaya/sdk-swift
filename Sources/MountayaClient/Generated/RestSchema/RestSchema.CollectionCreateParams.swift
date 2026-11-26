// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for creating a new collection.
  public struct CollectionCreateParams: Sendable, Hashable, Codable {
    /// Free-text description of the collection, at most 100 characters as sent,
    /// stored with leading and trailing whitespace trimmed. Omit it, or send one
    /// that trims to nothing, to create the collection without one.
    public var description: String?
    /// Whether the collection is private. A private collection is reached only
    /// with the key of the organization that owns it, so a private personal
    /// collection, owned by no organization, is reached by no key. A public
    /// collection is readable by id, read-only, with any publishable key that
    /// knows its identifier, and it is listed only in its own organization's
    /// listings. A share token reaches only what its link names, and reaches the
    /// collection it names whatever this says. Public never grants editing,
    /// which takes a write role in the owning organization.
    public var is_private: Bool
    /// Display name of the collection, at most 30 characters as sent, and at
    /// least 2 once leading and trailing whitespace is trimmed. Refused with a
    /// `409` when another collection in the organization already carries it.
    /// Names are compared exactly after trimming, case included, so `Alps` and
    /// `alps` are two different names. A name is one line: a tab, a line break or
    /// a line separator between two of its characters is a `400`, and one at
    /// either end is trimmed with the whitespace there.
    public var name: String
    /// Identifier of the organization that will own the collection. It must be the key's
    /// organization; omitted, it is that organization.
    public var organization_id: String?

    /// Creates a `CollectionCreateParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      is_private: Bool,
      name: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.description = nil
      self.is_private = is_private
      self.name = name
      self.organization_id = nil
      configure(&self)
    }

    /// Reads a `CollectionCreateParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.description = try container.decodeIfPresent(String.self, forKey: "description")
      self.is_private = try container.decode(Bool.self, forKey: "is_private")
      self.name = try container.decode(String.self, forKey: "name")
      self.organization_id = try container.decodeIfPresent(String.self, forKey: "organization_id")
    }

    /// Writes a `CollectionCreateParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.description, forKey: "description")
      try container.encode(self.is_private, forKey: "is_private")
      try container.encode(self.name, forKey: "name")
      try container.encodeIfPresent(self.organization_id, forKey: "organization_id")
    }
  }
}
