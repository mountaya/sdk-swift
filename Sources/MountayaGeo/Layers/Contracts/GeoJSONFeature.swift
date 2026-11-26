import MountayaClient

/// GeoJSONFeature is RFC 7946's `Feature`: a `geometry`, `nil` for a datum the answer placed
/// nowhere, and the `properties` a renderer's expressions read and a click hands back, the datum
/// itself and the drawing properties Geo stamps on it.
///
/// Two are equal where they hold the same geometry and the same properties, each number the same
/// number, `NaN` the same as `NaN` and 0 another than -0, as every value of the geo layer compares,
/// and equal features hash alike. The properties are an object, so their members keep no order.
public struct GeoJSONFeature: Sendable, Hashable {
  /// geometry is where the feature is drawn, or `nil` where its datum states no place.
  public var geometry: GeoJSONGeometry?
  /// properties are the feature's properties, as the JSON object a renderer takes.
  public var properties: [String: JSONValue]

  /// Creates a feature from its geometry and its properties.
  public init(geometry: GeoJSONGeometry?, properties: [String: JSONValue]) {
    self.geometry = geometry
    self.properties = properties
  }

  /// Two features are equal where their geometries and their properties are the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameGeometry(lhs.geometry, rhs.geometry) && sameJson(lhs.properties, rhs.properties)
  }

  /// hash feeds the geometry and the properties as the same-number relation reads them.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameGeometry: geometry)
    hasher.combine(sameJson: properties)
  }
}
