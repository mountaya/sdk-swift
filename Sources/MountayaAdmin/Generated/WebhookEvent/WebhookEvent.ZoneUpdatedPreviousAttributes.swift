// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// ZoneUpdatedPreviousAttributes is the former value of each field a `zone.updated` event's
  /// change moved, as its `data.previous_attributes` carries them, each typed as
  /// `AdminSchema.ZoneEventObject` types it: a field the change did not move is nil.
  public struct ZoneUpdatedPreviousAttributes: Sendable, Hashable, Codable {
    /// The zone's name.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var name: String?
    /// The zone's description, null when it has none.
    ///
    /// The value it held before the change, `.some(nil)` where it held null, and nil where the
    /// change did not move it.
    public var description: String??
    /// The zone's severity level.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var level: RestSchema.ZoneLevel?
    /// How the zone's area was drawn.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var mode: RestSchema.ZoneMode?
    /// Whether the zone is private to the organization.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var is_private: Bool?
    /// When the zone's validity window opens, null when it has always been in force.
    ///
    /// The value it held before the change, `.some(nil)` where it held null, and nil where the
    /// change did not move it.
    public var start_at: Date??
    /// When the zone's validity window closes, null when it never lapses.
    ///
    /// The value it held before the change, `.some(nil)` where it held null, and nil where the
    /// change did not move it.
    public var end_at: Date??

    /// Creates a `ZoneUpdatedPreviousAttributes` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = nil
      self.description = nil
      self.level = nil
      self.mode = nil
      self.is_private = nil
      self.start_at = nil
      self.end_at = nil
      configure(&self)
    }

    /// Reads a `ZoneUpdatedPreviousAttributes` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.description = try container.decodeMerge(String.self, forKey: "description")
      self.level = try container.decodeIfPresent(RestSchema.ZoneLevel.self, forKey: "level")
      self.mode = try container.decodeIfPresent(RestSchema.ZoneMode.self, forKey: "mode")
      self.is_private = try container.decodeIfPresent(Bool.self, forKey: "is_private")
      self.start_at = try container.decodeWiredMerge(Date.self, forKey: "start_at")
      self.end_at = try container.decodeWiredMerge(Date.self, forKey: "end_at")
    }

    /// Writes a `ZoneUpdatedPreviousAttributes` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeMerge(self.description, forKey: "description")
      try container.encodeIfPresent(self.level, forKey: "level")
      try container.encodeIfPresent(self.mode, forKey: "mode")
      try container.encodeIfPresent(self.is_private, forKey: "is_private")
      try container.encodeWiredMerge(self.start_at, forKey: "start_at")
      try container.encodeWiredMerge(self.end_at, forKey: "end_at")
    }
  }
}
