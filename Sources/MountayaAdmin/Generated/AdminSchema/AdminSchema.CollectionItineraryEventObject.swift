// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// An itinerary's place in a collection: which collection, which itinerary, and where it
  /// sits. `getCollection` reads the order of the whole.
  ///
  /// Every string it carries is bounded, and it carries no geometry, no file and no
  /// credential, so a payload stays small whatever the resource holds.
  public struct CollectionItineraryEventObject: Sendable, Hashable, Codable {
    /// The kind of object this is, always `collection.itinerary`: the family of the event
    /// types that carry it, and what tells the members of `WebhookEventObject` apart.
    ///
    /// It is always `collection.itinerary`, the discriminator value naming this member of its
    /// union.
    public var object: String {
      "collection.itinerary"
    }
    /// Identifier of the collection.
    public var collection_id: String
    /// Identifier of the itinerary.
    public var itinerary_id: String
    /// Where the itinerary sits in the collection once this change was made, counted from
    /// 0. Absent on `collection.itinerary.removed`. A move shifts the itineraries between
    /// its two positions, which record no event of their own.
    public var position: Int?
    /// The collection's `version` once this change was made, which every change to what
    /// it holds moves. Of two events about one collection, the one carrying the higher
    /// figure is the later state.
    public var collection_version: Int64

    /// Creates a `CollectionItineraryEventObject` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      collection_id: String,
      itinerary_id: String,
      collection_version: Int64,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.collection_id = collection_id
      self.itinerary_id = itinerary_id
      self.position = nil
      self.collection_version = collection_version
      configure(&self)
    }

    /// Reads a `CollectionItineraryEventObject` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.collection_id = try container.decode(String.self, forKey: "collection_id")
      self.itinerary_id = try container.decode(String.self, forKey: "itinerary_id")
      self.position = try container.decodeIfPresent(Int.self, forKey: "position")
      self.collection_version = try container.decode(Int64.self, forKey: "collection_version")
    }

    /// Writes a `CollectionItineraryEventObject` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.object, forKey: "object")
      try container.encode(self.collection_id, forKey: "collection_id")
      try container.encode(self.itinerary_id, forKey: "itinerary_id")
      try container.encodeIfPresent(self.position, forKey: "position")
      try container.encode(self.collection_version, forKey: "collection_version")
    }
  }
}
