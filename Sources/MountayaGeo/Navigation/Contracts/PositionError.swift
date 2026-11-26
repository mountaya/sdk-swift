/// PositionError is a position a navigation engine refuses, because it names no place: its
/// longitude or its latitude missing or not finite, so no distance is measured from it.
///
/// It is thrown by `NavigationEngine.setPosition(_:)`, and names the position as it was stated, so
/// the location source that handed it over can be found.
public struct PositionError: Error, Sendable, CustomStringConvertible {
  /// position is the position as it was stated.
  public let position: [Double]

  /// Creates the refusal of a position that names no place.
  public init(position: [Double]) {
    self.position = position
  }

  /// description is the refusal as a developer reads it in a log.
  public var description: String {
    "NavigationEngine.setPosition: position is \(position); pass a [longitude, latitude] of two "
      + "finite numbers, in degrees."
  }
}
