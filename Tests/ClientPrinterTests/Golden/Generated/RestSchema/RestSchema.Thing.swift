// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// A thing, as the API returns it.
  public struct Thing: Sendable, Hashable, Codable {
    /// Its identifier.
    ///
    /// The server writes it, and a request never sends it.
    public var id: String
    /// The contract's `created_at`.
    public var created_at: Date
    /// The contract's `updated_at`.
    public var updated_at: Date?
    /// The contract's `website`.
    public var website: URI?
    /// The contract's `count`.
    public var count: Int64
    /// The contract's `ratio`.
    public var ratio: Double?
    /// The contract's `tags`.
    public var tags: [String]
    /// The contract's `stamps`.
    public var stamps: [Date]?
    /// The contract's `names`.
    public var names: RestSchema.Names?
    /// The contract's `extras`.
    public var extras: JSONValue?
    /// The contract's `kind`.
    public var kind: RestSchema.ThingKind
    /// The contract's `size`.
    public var size: RestSchema.TileSize?
    /// The contract's `point`.
    public var point: RestSchema.GeoPoint?
    /// The contract's `meta`.
    public var meta: RestSchema.ThingMeta?
    /// The contract's `choice`.
    public var choice: RestSchema.ThingChoice?
    /// The contract's `level`.
    public var level: RestSchema.ThingLevel?
    /// The contract's `fixed`.
    ///
    /// It is always "thing", which this type writes itself.
    public var fixed: String {
      "thing"
    }
    /// The contract's `flags`.
    public var flags: [RestSchema.ThingKind: Bool]?
    /// The former name. Use `names` instead.
    @available(*, deprecated, message: "The former name.")
    public var old: String? {
      get { _old }
      set { _old = newValue }
    }
    /// The contract's `default`.
    public var `default`: Bool?

    var _old: String?

    /// Creates a `Thing` from the properties the contract requires, the optional ones being set in
    /// `configure`.
    public init(
      id: String,
      created_at: Date,
      count: Int64,
      tags: [String],
      kind: RestSchema.ThingKind,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.created_at = created_at
      self.updated_at = nil
      self.website = nil
      self.count = count
      self.ratio = nil
      self.tags = tags
      self.stamps = nil
      self.names = nil
      self.extras = nil
      self.kind = kind
      self.size = nil
      self.point = nil
      self.meta = nil
      self.choice = nil
      self.level = nil
      self.flags = nil
      self._old = nil
      self.`default` = nil
      configure(&self)
    }

    /// Reads a `Thing` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.created_at = try container.decodeWired(Date.self, forKey: "created_at")
      self.updated_at = try container.decodeWiredIfPresent(Date.self, forKey: "updated_at")
      self.website = try container.decodeIfPresent(URI.self, forKey: "website")
      self.count = try container.decode(Int64.self, forKey: "count")
      self.ratio = try container.decodeIfPresent(Double.self, forKey: "ratio")
      self.tags = try container.decode([String].self, forKey: "tags")
      self.stamps = try container.decodeWiredIfPresent([Date].self, forKey: "stamps")
      self.names = try container.decodeIfPresent(RestSchema.Names.self, forKey: "names")
      self.extras = try container.decodeIfPresent(JSONValue.self, forKey: "extras")
      self.kind = try container.decode(RestSchema.ThingKind.self, forKey: "kind")
      self.size = try container.decodeIfPresent(RestSchema.TileSize.self, forKey: "size")
      self.point = try container.decodeIfPresent(RestSchema.GeoPoint.self, forKey: "point")
      self.meta = try container.decodeIfPresent(RestSchema.ThingMeta.self, forKey: "meta")
      self.choice = try container.decodeIfPresent(RestSchema.ThingChoice.self, forKey: "choice")
      self.level = try container.decodeIfPresent(RestSchema.ThingLevel.self, forKey: "level")
      self.flags = try container.decodeIfPresent([RestSchema.ThingKind: Bool].self, forKey: "flags")
      self._old = try container.decodeIfPresent(String.self, forKey: "old")
      self.`default` = try container.decodeIfPresent(Bool.self, forKey: "default")
    }

    /// Writes a `Thing` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
      try container.encodeWired(self.created_at, forKey: "created_at")
      try container.encodeWiredIfPresent(self.updated_at, forKey: "updated_at")
      try container.encodeIfPresent(self.website, forKey: "website")
      try container.encode(self.count, forKey: "count")
      try container.encodeIfPresent(self.ratio, forKey: "ratio")
      try container.encode(self.tags, forKey: "tags")
      try container.encodeWiredIfPresent(self.stamps, forKey: "stamps")
      try container.encodeIfPresent(self.names, forKey: "names")
      try container.encodeIfPresent(self.extras, forKey: "extras")
      try container.encode(self.kind, forKey: "kind")
      try container.encodeIfPresent(self.size, forKey: "size")
      try container.encodeIfPresent(self.point, forKey: "point")
      try container.encodeIfPresent(self.meta, forKey: "meta")
      try container.encodeIfPresent(self.choice, forKey: "choice")
      try container.encodeIfPresent(self.level, forKey: "level")
      try container.encode(self.fixed, forKey: "fixed")
      try container.encodeIfPresent(self.flags, forKey: "flags")
      try container.encodeIfPresent(self._old, forKey: "old")
      try container.encodeIfPresent(self.`default`, forKey: "default")
    }
  }
}
