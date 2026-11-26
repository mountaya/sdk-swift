/// GeoJSONMultiPolygon is a GeoJSON `MultiPolygon` (RFC 7946): several areas.
///
/// Declared once here rather than per surface, since RFC 7946 rather than a bundle is its
/// definition, so a geometry read from REST and one read from the Data API are one type.
public struct GeoJSONMultiPolygon: Sendable, Hashable, Codable {
  /// coordinates is the geometry's positions: each polygon is an array of linear rings.
  public var coordinates: [[[[Double]]]]
  /// bbox is the bounding box RFC 7946 lets any GeoJSON object carry, or nil where it has none.
  public var bbox: [Double]?

  /// Creates a geometry from its positions.
  public init(coordinates: [[[[Double]]]], bbox: [Double]? = nil) {
    self.coordinates = coordinates
    self.bbox = bbox
  }

  /// Reads the geometry, refusing one whose `type` is not `MultiPolygon`.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: WireKey.self)
    let type = try container.decode(String.self, forKey: "type")
    guard type == "MultiPolygon" else {
      throw DecodingError.dataCorruptedError(
        forKey: "type",
        in: container,
        debugDescription: "a `\(type)` where a `MultiPolygon` was expected"
      )
    }
    coordinates = try container.decode([[[[Double]]]].self, forKey: "coordinates")
    bbox = try container.decodeIfPresent([Double].self, forKey: "bbox")
  }

  /// encode writes the geometry with its `type`.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: WireKey.self)
    try container.encode("MultiPolygon", forKey: "type")
    try container.encode(coordinates, forKey: "coordinates")
    try container.encodeIfPresent(bbox, forKey: "bbox")
  }
}
