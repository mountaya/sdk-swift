/// NavigationStepsReading is a route's step list as it was read from its surface: the steps, and
/// whether the list was refused for not tiling the route's geometry (`geo.navigation.steps`).
///
/// A refused list reads as no steps, never as a repair of them, and the route is followed as one
/// with none. Two are equal where both members are.
public struct NavigationStepsReading: Sendable, Hashable {
  /// refused is whether the list was refused, its ranges not covering the geometry once in travel
  /// order.
  public var refused: Bool
  /// steps is the steps in the one vocabulary, in travel order: empty where there were none or the
  /// list was refused.
  public var steps: [NavigationStep]

  /// Creates a reading from whether the list was refused and the steps read.
  public init(refused: Bool, steps: [NavigationStep]) {
    self.refused = refused
    self.steps = steps
  }
}
