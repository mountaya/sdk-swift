// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// Parameters for converting a segment to the other way of defining its
  /// geometry, which `postItinerarySegmentConvert` takes.
  ///
  /// This is deliberately its own request shape rather than a field on
  /// SegmentUpdateParams: a conversion re-derives the geometry (and can fail
  /// routing) where a metadata update cannot, so the two have different failure
  /// semantics and belong on different operations.
  public struct SegmentConvertParams: Sendable, Hashable, Codable {
    /// How the segment's path is defined, which decides what `geojson` must
    /// carry: `directions` routes between the waypoints of a MultiPoint,
    /// `linestring` keeps the drawn line rather than routing it.
    public var mode: RestSchema.SegmentMode

    /// Creates a `SegmentConvertParams` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      mode: RestSchema.SegmentMode,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.mode = mode
      configure(&self)
    }

    /// Reads a `SegmentConvertParams` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.mode = try container.decode(RestSchema.SegmentMode.self, forKey: "mode")
    }

    /// Writes a `SegmentConvertParams` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.mode, forKey: "mode")
    }
  }
}
