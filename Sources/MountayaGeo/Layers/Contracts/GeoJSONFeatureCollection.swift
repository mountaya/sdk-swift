/// GeoJSONFeatureCollection is RFC 7946's `FeatureCollection`: the `features` a renderer draws from
/// one source, in the order they draw.
///
/// Two are equal where they hold the same features in the same order.
public struct GeoJSONFeatureCollection: Sendable, Hashable {
  /// features are the features, in order.
  public var features: [GeoJSONFeature]

  /// Creates a collection of features, in the order they draw.
  public init(features: [GeoJSONFeature]) {
    self.features = features
  }
}
