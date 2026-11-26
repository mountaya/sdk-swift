// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Input for computing a time-distance matrix.
  public struct MatrixInput: Sendable, Hashable, Codable {
    /// Activity to use for routing. BACKCOUNTRY_SKIING has no routing, and
    /// GRAVEL_BIKE and MOUNTAIN_BIKE are unavailable: all three are
    /// VALIDATION_FAILED at ["input", "activity"].
    public var activity: DataSchema.ActivitySlug
    /// Locations as [longitude, latitude] coordinate pairs (WGS 84), 2 to 50 (fewer
    /// or more is VALIDATION_FAILED at ["input", "locations"]). Each is exactly two
    /// numbers, a longitude between -180 and 180 and a latitude between -90 and 90,
    /// and one that is not is VALIDATION_FAILED at ["input", "locations", i]. No two
    /// locations may lie more than 20 km apart in a straight line, and a matrix two
    /// of whose locations do is VALIDATION_FAILED at ["input", "locations"]: past
    /// that span the routing engine cannot search between them. A location the
    /// routing engine cannot place on the network answers its pairs null rather
    /// than failing, and so does a location on ways no other location connects to,
    /// an enclosed site for one: its pairs with the rest of the network are null, as
    /// no route joins them, and the pairs between two locations on the same enclosed
    /// site are answered. A matrix of many locations over a dense network, whose
    /// search the engine cannot hold at once, is computed one source at a time and
    /// answered exactly as the whole matrix would have been, recorded as one request
    /// with the elements asked for, null cells included; one holding such an
    /// enclosed location takes a few seconds more, and under load the engine is
    /// waited for within the request's time budget. Any failure of the engine within those
    /// bounds is INTERNAL_ERROR, never the caller's to fix: a ceiling of its own set
    /// below them, or a source whose own search it cannot hold either.
    /// Example: [[6.8694, 45.9237], [6.9271, 45.9822], [6.7997, 45.8906]] (Chamonix, Argentière,
    /// Les Houches).
    public var locations: [[Double]]
    /// Indices of locations to use as sources. When omitted, all locations are used.
    /// At most 50 (more is VALIDATION_FAILED at ["input", "sources"]). Each must be
    /// the index of one of the locations, and one that is not is VALIDATION_FAILED
    /// at ["input", "sources", i]. A repeated index is accepted.
    /// Example: [0] to compute only from the first location to all others.
    public var sources: [Int]?
    /// Indices of locations to use as destinations. When omitted, all locations are
    /// used. At most 50 (more is VALIDATION_FAILED at ["input", "destinations"]).
    /// Each must be the index of one of the locations, and one that is not is
    /// VALIDATION_FAILED at ["input", "destinations", i]. A repeated index is
    /// accepted.
    /// Example: [0] to compute only from all locations to the first one.
    public var destinations: [Int]?
    /// Metrics to compute. At least one metric is required (an empty list is
    /// VALIDATION_FAILED at ["input", "metrics"]).
    public var metrics: [DataSchema.MatrixMetric]

    /// Creates a `MatrixInput` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      activity: DataSchema.ActivitySlug,
      locations: [[Double]],
      metrics: [DataSchema.MatrixMetric],
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.activity = activity
      self.locations = locations
      self.sources = nil
      self.destinations = nil
      self.metrics = metrics
      configure(&self)
    }

    /// Reads a `MatrixInput` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.activity = try container.decode(DataSchema.ActivitySlug.self, forKey: "activity")
      self.locations = try container.decode([[Double]].self, forKey: "locations")
      self.sources = try container.decodeIfPresent([Int].self, forKey: "sources")
      self.destinations = try container.decodeIfPresent([Int].self, forKey: "destinations")
      self.metrics = try container.decode([DataSchema.MatrixMetric].self, forKey: "metrics")
    }

    /// Writes a `MatrixInput` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.activity, forKey: "activity")
      try container.encode(self.locations, forKey: "locations")
      try container.encodeIfPresent(self.sources, forKey: "sources")
      try container.encodeIfPresent(self.destinations, forKey: "destinations")
      try container.encode(self.metrics, forKey: "metrics")
    }
  }
}
