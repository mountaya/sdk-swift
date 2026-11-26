// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Which itinerary to read.
  ///
  /// The identifier is the only input: the whole itinerary is returned with its ordered
  /// segments and waypoints, and there is no field selection or windowing to declare
  /// here. An id you may not read answers NOT_FOUND rather than FORBIDDEN, so an
  /// unknown id and an inaccessible one are indistinguishable by design.
  public struct ItineraryInput: Sendable, Hashable, Codable {
    /// Identifier of the itinerary to read, a UUID in its canonical form of 36
    /// characters with four hyphens. Any other value, the nil UUID included, is
    /// refused with VALIDATION_FAILED at ["input", "id"].
    /// Example: "0b6d1a4e-6d3f-4f7a-9c2e-1f0a5b8c3d21".
    public var id: String

    /// Creates a `ItineraryInput` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      id: String,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.id = id
      configure(&self)
    }

    /// Reads a `ItineraryInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.id = try container.decode(String.self, forKey: "id")
    }

    /// Writes a `ItineraryInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.id, forKey: "id")
    }
  }
}
