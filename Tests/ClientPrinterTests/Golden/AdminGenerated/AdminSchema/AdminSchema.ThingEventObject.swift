// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A thing as a webhook event carries it.
  public struct ThingEventObject: Sendable, Hashable, Codable {
    /// Always `thing`.
    ///
    /// It is always `thing`, the discriminator value naming this member of its union.
    public var object: String {
      "thing"
    }
    /// Its identifier.
    public var id: String
    /// The contract's `count`.
    public var count: Int64
    /// The contract's `updated_at`.
    public var updated_at: Date?
    /// The contract's `kind`.
    public var kind: RestSchema.ThingKind
    /// The former name. Use `names` instead.
    @available(*, deprecated, message: "The former name.")
    public var old: String? {
      get { _old }
      set { _old = newValue }
    }

    var _old: String?

    /// Creates a `ThingEventObject` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      count: Int64,
      updated_at: Date?,
      kind: RestSchema.ThingKind,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      self.count = count
      self.updated_at = updated_at
      self.kind = kind
      self._old = nil
      configure(&self)
    }

    /// Reads a `ThingEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
      self.count = try container.decode(Int64.self, forKey: "count")
      self.updated_at = try container.decodeWiredIfPresent(Date.self, forKey: "updated_at")
      self.kind = try container.decode(RestSchema.ThingKind.self, forKey: "kind")
      self._old = try container.decodeIfPresent(String.self, forKey: "old")
    }

    /// Writes a `ThingEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.id, forKey: "id")
      try container.encode(self.count, forKey: "count")
      try container.encodeWiredNullable(self.updated_at, forKey: "updated_at")
      try container.encode(self.kind, forKey: "kind")
      try container.encodeIfPresent(self._old, forKey: "old")
    }
  }
}
