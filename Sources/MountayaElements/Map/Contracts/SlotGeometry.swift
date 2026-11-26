import MountayaClient
import MountayaGeo

/// SlotGeometry is what one geometry slot of a map holds: its geometry, nil where it draws none,
/// and the colour it draws in, the slot's own until a call names another (`map.geometry.slots`).
///
/// Two are equal where they hold the same geometry, each number as the same number, and the same
/// colour by its scalars.
public struct SlotGeometry: Sendable, Equatable {
  /// geometry is the geometry the slot draws, or nil for none.
  public var geometry: GeoJSONGeometry?
  /// color is the colour the slot draws in, a CSS hexadecimal colour or any colour MapLibre reads.
  public var color: String

  /// Creates what a slot holds: `geometry` in `color`.
  public init(geometry: GeoJSONGeometry?, color: String) {
    self.geometry = geometry
    self.color = color
  }

  /// Two are equal where they hold the same geometry and the same colour.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.color, rhs.color)
      && {
        switch (lhs.geometry, rhs.geometry) {
        case (nil, nil): true
        case (let a?, let b?): sameGeometry(a, b)
        default: false
        }
      }()
  }
}
