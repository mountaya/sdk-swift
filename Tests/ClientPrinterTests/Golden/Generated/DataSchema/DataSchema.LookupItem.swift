// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// The contract's `LookupItem`.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct LookupItem: Sendable, Hashable, Codable {
    /// The contract's `name`.
    public var name: String?
    /// The contract's `when`.
    public var when: Date?
    /// The contract's `where`.
    public var `where`: GeoJSONGeometry?
    /// The contract's `link`.
    public var link: URI?
    /// The contract's `id`.
    public var id: String?
    /// The contract's `score`.
    public var score: Double?
    /// The contract's `ok`.
    public var ok: Bool?
    /// The contract's `kind`.
    @available(*, deprecated, message: "The contract marks this deprecated.")
    public var kind: DataSchema.LookupKind? {
      get { _kind }
      set { _kind = newValue }
    }

    var _kind: DataSchema.LookupKind?

    /// Creates a `LookupItem` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = nil
      self.when = nil
      self.`where` = nil
      self.link = nil
      self.id = nil
      self.score = nil
      self.ok = nil
      self._kind = nil
      configure(&self)
    }

    /// Reads a `LookupItem` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.when = try container.decodeWiredIfPresent(Date.self, forKey: "when")
      self.`where` = try container.decodeIfPresent(GeoJSONGeometry.self, forKey: "where")
      self.link = try container.decodeIfPresent(URI.self, forKey: "link")
      self.id = try container.decodeIfPresent(String.self, forKey: "id")
      self.score = try container.decodeIfPresent(Double.self, forKey: "score")
      self.ok = try container.decodeIfPresent(Bool.self, forKey: "ok")
      self._kind = try container.decodeIfPresent(DataSchema.LookupKind.self, forKey: "kind")
    }

    /// Writes a `LookupItem` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeWiredIfPresent(self.when, forKey: "when")
      try container.encodeIfPresent(self.`where`, forKey: "where")
      try container.encodeIfPresent(self.link, forKey: "link")
      try container.encodeIfPresent(self.id, forKey: "id")
      try container.encodeIfPresent(self.score, forKey: "score")
      try container.encodeIfPresent(self.ok, forKey: "ok")
      try container.encodeIfPresent(self._kind, forKey: "kind")
    }
  }
}
