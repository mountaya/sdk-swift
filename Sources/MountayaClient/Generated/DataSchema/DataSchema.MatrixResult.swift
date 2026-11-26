// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataSchema {
  /// Result of a matrix computation.
  ///
  /// These two grids are the only sparse lists in this schema. Everywhere else a
  /// list of non-null elements is exactly that; here an inner value may be null,
  /// because a pair with no route between it has no number to report. A client
  /// that has generalized "lists here are never sparse" will get these wrong, so
  /// check each cell before using it.
  ///
  /// Every property is optional, since a field the caller did not select is absent from the
  /// response, and Swift cannot compute a result type from a selection.
  public struct MatrixResult: Sendable, Hashable, Codable {
    /// Duration grid in seconds, one row per source and one column per destination.
    /// These are the routing engine's own estimates: they take no `speed` and do not
    /// use the terrain-aware model behind `duration` on `directions`, `suggestions`
    /// and `analyzeGeometry`, so they are not comparable with it. Null inner values
    /// indicate unreachable pairs. Only present when DURATION metric is requested.
    public var durations: [[Double?]]?
    /// Distance grid in meters, one row per source and one column per destination:
    /// the routing engine's own figures, with no geometry returned to measure them
    /// against. Null inner values indicate unreachable pairs. Only present when
    /// DISTANCE metric is requested.
    public var distances: [[Double?]]?

    /// Creates a `MatrixResult` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.durations = nil
      self.distances = nil
      configure(&self)
    }

    /// Reads a `MatrixResult` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.durations = try container.decodeIfPresent([[Double?]].self, forKey: "durations")
      self.distances = try container.decodeIfPresent([[Double?]].self, forKey: "distances")
    }

    /// Writes a `MatrixResult` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.durations, forKey: "durations")
      try container.encodeIfPresent(self.distances, forKey: "distances")
    }
  }
}
