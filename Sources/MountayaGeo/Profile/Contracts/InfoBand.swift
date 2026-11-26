/// InfoBand is one band of an analysis bar: the stretch of an itinerary's distance axis an analysis
/// value holds over, in kilometers, so it stands under the points it colours.
///
/// Two are equal where they hold the same numbers and the same value, as every value of the geo
/// layer compares.
public struct InfoBand<Value> {
  /// startKm is where the band starts, in kilometers from the itinerary's start.
  public var startKm: Double
  /// endKm is where it ends, past `startKm`.
  public var endKm: Double
  /// value is the value over the band.
  public var value: Value

  /// Creates a band from its two ends and its value.
  public init(startKm: Double, endKm: Double, value: Value) {
    self.startKm = startKm
    self.endKm = endKm
    self.value = value
  }
}

extension InfoBand: Sendable where Value: Sendable {}

extension InfoBand: Equatable where Value: Equatable {
  /// Two bands are equal where both ends are the same numbers and the values the same.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameNumber(lhs.startKm, rhs.startKm) && sameNumber(lhs.endKm, rhs.endKm)
      && sameValue(lhs.value, rhs.value)
  }
}

extension InfoBand: Hashable where Value: Hashable {
  /// hash feeds both ends as the same-number relation reads them, then the value.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameNumber: startKm)
    hasher.combine(sameNumber: endKm)
    hasher.combine(sameValue: value)
  }
}
