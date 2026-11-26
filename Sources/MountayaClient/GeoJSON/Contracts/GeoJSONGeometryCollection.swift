/// GeoJSONGeometryCollection is a GeoJSON `GeometryCollection` (RFC 7946): several geometries
/// of any of the six coordinate-bearing types.
///
/// RFC 7946 does not let one collection nest inside another, and the Data API refuses one that
/// does, but a nested one decodes here as what it is rather than failing the response.
public struct GeoJSONGeometryCollection: Sendable, Hashable, Codable {
  /// geometries is the collection's members, in their order.
  public var geometries: [GeoJSONGeometry]
  /// bbox is the bounding box RFC 7946 lets any GeoJSON object carry, or nil where it has none.
  public var bbox: [Double]?

  /// Creates a collection from its members.
  public init(geometries: [GeoJSONGeometry], bbox: [Double]? = nil) {
    self.geometries = geometries
    self.bbox = bbox
  }

  /// Reads the collection, refusing one whose `type` is not `GeometryCollection`.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: WireKey.self)
    let type = try container.decode(String.self, forKey: "type")
    guard type == "GeometryCollection" else {
      throw DecodingError.dataCorruptedError(
        forKey: "type",
        in: container,
        debugDescription: "a `\(type)` where a `GeometryCollection` was expected"
      )
    }
    geometries = try container.decode([GeoJSONGeometry].self, forKey: "geometries")
    bbox = try container.decodeIfPresent([Double].self, forKey: "bbox")
  }

  /// encode writes the collection with its `type`.
  public func encode(to encoder: any Encoder) throws {
    var container = encoder.container(keyedBy: WireKey.self)
    try container.encode("GeometryCollection", forKey: "type")
    try container.encode(geometries, forKey: "geometries")
    try container.encodeIfPresent(bbox, forKey: "bbox")
  }
}
