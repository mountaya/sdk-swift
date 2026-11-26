/// GeoJSONGeometry is any GeoJSON geometry (RFC 7946), told apart by its `type`.
///
/// It is closed, unlike the contract's own enums and unions: RFC 7946 fixes the seven
/// geometries, and the Data API's `GeoJSON` scalar refuses every other `type`, so a value
/// outside them is a broken response rather than one a newer contract added.
public enum GeoJSONGeometry: Sendable, Hashable, Codable {
  /// point is a `Point`.
  case point(GeoJSONPoint)
  /// multiPoint is a `MultiPoint`.
  case multiPoint(GeoJSONMultiPoint)
  /// lineString is a `LineString`.
  case lineString(GeoJSONLineString)
  /// multiLineString is a `MultiLineString`.
  case multiLineString(GeoJSONMultiLineString)
  /// polygon is a `Polygon`.
  case polygon(GeoJSONPolygon)
  /// multiPolygon is a `MultiPolygon`.
  case multiPolygon(GeoJSONMultiPolygon)
  /// geometryCollection is a `GeometryCollection`.
  case geometryCollection(GeoJSONGeometryCollection)

  /// Reads the geometry its `type` names, refusing a `type` RFC 7946 does not define.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: WireKey.self)
    let type = try container.decode(String.self, forKey: "type")
    switch type {
    case "Point":
      self = .point(try GeoJSONPoint(from: decoder))
    case "MultiPoint":
      self = .multiPoint(try GeoJSONMultiPoint(from: decoder))
    case "LineString":
      self = .lineString(try GeoJSONLineString(from: decoder))
    case "MultiLineString":
      self = .multiLineString(try GeoJSONMultiLineString(from: decoder))
    case "Polygon":
      self = .polygon(try GeoJSONPolygon(from: decoder))
    case "MultiPolygon":
      self = .multiPolygon(try GeoJSONMultiPolygon(from: decoder))
    case "GeometryCollection":
      self = .geometryCollection(try GeoJSONGeometryCollection(from: decoder))
    default:
      throw DecodingError.dataCorruptedError(
        forKey: "type",
        in: container,
        debugDescription: "`\(type)` is not a GeoJSON geometry"
      )
    }
  }

  /// encode writes the geometry it holds.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .point(let geometry):
      try geometry.encode(to: encoder)
    case .multiPoint(let geometry):
      try geometry.encode(to: encoder)
    case .lineString(let geometry):
      try geometry.encode(to: encoder)
    case .multiLineString(let geometry):
      try geometry.encode(to: encoder)
    case .polygon(let geometry):
      try geometry.encode(to: encoder)
    case .multiPolygon(let geometry):
      try geometry.encode(to: encoder)
    case .geometryCollection(let geometry):
      try geometry.encode(to: encoder)
    }
  }
}
