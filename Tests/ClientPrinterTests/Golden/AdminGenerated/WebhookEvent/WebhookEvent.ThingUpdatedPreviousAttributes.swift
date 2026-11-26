// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// ThingUpdatedPreviousAttributes is the former value of each field a `thing.updated` event's
  /// change moved, as its `data.previous_attributes` carries them, each typed as
  /// `AdminSchema.ThingEventObject` types it: a field the change did not move is nil.
  public struct ThingUpdatedPreviousAttributes: Sendable, Hashable, Codable {
    /// The contract's `count`.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var count: Int64?
    /// The contract's `updated_at`.
    ///
    /// The value it held before the change, `.some(nil)` where it held null, and nil where the
    /// change did not move it.
    public var updated_at: Date??
    /// The contract's `kind`.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var kind: RestSchema.ThingKind?
    /// The former name. Use `names` instead.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    @available(*, deprecated, message: "The former name.")
    public var old: String? {
      get { _old }
      set { _old = newValue }
    }

    var _old: String?

    /// Creates a `ThingUpdatedPreviousAttributes` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.count = nil
      self.updated_at = nil
      self.kind = nil
      self._old = nil
      configure(&self)
    }

    /// Reads a `ThingUpdatedPreviousAttributes` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.count = try container.decodeIfPresent(Int64.self, forKey: "count")
      self.updated_at = try container.decodeWiredMerge(Date.self, forKey: "updated_at")
      self.kind = try container.decodeIfPresent(RestSchema.ThingKind.self, forKey: "kind")
      self._old = try container.decodeIfPresent(String.self, forKey: "old")
    }

    /// Writes a `ThingUpdatedPreviousAttributes` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.count, forKey: "count")
      try container.encodeWiredMerge(self.updated_at, forKey: "updated_at")
      try container.encodeIfPresent(self.kind, forKey: "kind")
      try container.encodeIfPresent(self._old, forKey: "old")
    }
  }
}
