// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// ItinerarySegmentGroupUpdatedPreviousAttributes is the former value of each field a
  /// `itinerary.segment_group.updated` event's change moved, as its `data.previous_attributes`
  /// carries them, each typed as `AdminSchema.ItinerarySegmentGroupEventObject` types it: a field
  /// the change did not move is nil.
  public struct ItinerarySegmentGroupUpdatedPreviousAttributes: Sendable, Hashable, Codable {
    /// The segment group's name.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var name: String?
    /// The group's colour, six lowercase hexadecimal digits after `#`.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var color: String?

    /// Creates a `ItinerarySegmentGroupUpdatedPreviousAttributes` from the properties the contract
    /// requires, the optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.name = nil
      self.color = nil
      configure(&self)
    }

    /// Reads a `ItinerarySegmentGroupUpdatedPreviousAttributes` from the JSON object the contract
    /// describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.name = try container.decodeIfPresent(String.self, forKey: "name")
      self.color = try container.decodeIfPresent(String.self, forKey: "color")
    }

    /// Writes a `ItinerarySegmentGroupUpdatedPreviousAttributes` as the JSON object the contract
    /// describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.name, forKey: "name")
      try container.encodeIfPresent(self.color, forKey: "color")
    }
  }
}
