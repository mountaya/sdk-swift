// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// CollectionItineraryMovedPreviousAttributes is the former value of each field a
  /// `collection.itinerary.moved` event's change moved, as its `data.previous_attributes` carries
  /// them, each typed as `AdminSchema.CollectionItineraryEventObject` types it: a field the change
  /// did not move is nil.
  public struct CollectionItineraryMovedPreviousAttributes: Sendable, Hashable, Codable {
    /// Where the itinerary sits in the collection once this change was made, counted from
    /// 0. Absent on `collection.itinerary.removed`. A move shifts the itineraries between
    /// its two positions, which record no event of their own.
    ///
    /// The value it held before the change, and nil where the change did not move it.
    public var position: Int?

    /// Creates a `CollectionItineraryMovedPreviousAttributes` from the properties the contract
    /// requires, the optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.position = nil
      configure(&self)
    }

    /// Reads a `CollectionItineraryMovedPreviousAttributes` from the JSON object the contract
    /// describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.position = try container.decodeIfPresent(Int.self, forKey: "position")
    }

    /// Writes a `CollectionItineraryMovedPreviousAttributes` as the JSON object the contract
    /// describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.position, forKey: "position")
    }
  }
}
