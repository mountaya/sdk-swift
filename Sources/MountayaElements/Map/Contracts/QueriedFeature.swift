import MountayaClient
import MountayaGeo

/// QueriedFeature is a feature a point query found on a map (`map.query.feature-shape`): a GeoJSON
/// feature, its id where its source gives it one, its properties and its geometry, with the layer
/// that drew it and the source layer it was read from.
///
/// A renderer answers a feature as an object of its own, with its whole layer, its source, a state
/// and the tile it was cut from, which no host reads and no second renderer has to give, so a query
/// answers what every renderer can. A feature two layers drew, a line and the casing under it, is
/// answered once for each, each naming its own `layer`.
///
/// Two are equal where every member is the same, a text by its scalars and a number by the
/// same-number relation, as every Geo value compares.
public struct QueriedFeature: Sendable, Equatable {
  /// ID is a feature's own id, a number or a string as its source gives it, as RFC 7946 allows.
  public enum ID: Sendable, Equatable {
    /// number is an id written as a number.
    case number(Double)
    /// string is an id written as a string.
    case string(String)

    /// Two ids are equal where they are of one kind and hold the same number or text.
    public static func == (lhs: Self, rhs: Self) -> Bool {
      switch (lhs, rhs) {
      case (.number(let a), .number(let b)): sameNumber(a, b)
      case (.string(let a), .string(let b)): sameText(a, b)
      default: false
      }
    }
  }

  /// id is the feature's own id, or nil where its source gives it none.
  public let id: ID?
  /// properties are the feature's properties that hold a string, a number, a boolean or null.
  public let properties: [String: JSONValue]
  /// geometry is the feature's geometry, as the renderer found it.
  public let geometry: GeoJSONGeometry
  /// layer is the id of the layer that drew the feature.
  public let layer: String
  /// sourceLayer is the source layer the feature was read from, where its layer reads a vector
  /// source, and nil otherwise.
  public let sourceLayer: String?

  /// Creates the feature a query answers for one a renderer found: its properties holding a list
  /// or an object are left out, since a vector tile carries none and a GeoJSON source's is the
  /// renderer's own encoding of it, which no two renderers write alike.
  public init(
    id: ID? = nil, properties: [String: JSONValue], geometry: GeoJSONGeometry, layer: String,
    sourceLayer: String? = nil
  ) {
    self.id = id
    self.properties = properties.filter { _, value in
      switch value {
      case .null, .bool, .number, .string: true
      case .array, .object: false
      }
    }
    self.geometry = geometry
    self.layer = layer
    self.sourceLayer = sourceLayer
  }

  /// Two features are equal where every member is the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.id == rhs.id && sameJson(lhs.properties, rhs.properties)
      && sameGeometry(lhs.geometry, rhs.geometry) && sameText(lhs.layer, rhs.layer)
      && sameText(lhs.sourceLayer, rhs.sourceLayer)
  }
}
