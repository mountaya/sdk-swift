import MountayaClient

/// AmenityStack is the services a pinned place offers, stacked above its pin on a profile
/// (`geo.profile.amenity-stacks`): the pin, the services drawn as badges, how many follow them as
/// one count, and every service the place offers, the one label the stack is read by.
///
/// Two are equal where they stand over one pin with the same services, as every value of the geo
/// layer compares.
public struct AmenityStack: Sendable, Hashable {
  /// pin is the pin the stack stands above.
  public var pin: CurvePin
  /// shown is the services drawn as badges, the first ones in the order the place states them.
  public var shown: [RestSchema.WaypointAmenity]
  /// counted is how many services follow the ones shown, drawn as one count.
  public var counted: Int
  /// named is every service the place offers, in its order.
  public var named: [RestSchema.WaypointAmenity]

  /// Creates a stack from its pin, the services shown and counted, and every service named.
  public init(
    pin: CurvePin, shown: [RestSchema.WaypointAmenity], counted: Int,
    named: [RestSchema.WaypointAmenity]
  ) {
    self.pin = pin
    self.shown = shown
    self.counted = counted
    self.named = named
  }

  /// Two stacks are equal where the pins are and the services are written alike.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.pin == rhs.pin && sameText(lhs.shown, rhs.shown) && lhs.counted == rhs.counted
      && sameText(lhs.named, rhs.named)
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(pin)
    hasher.combine(shown)
    hasher.combine(counted)
    hasher.combine(named)
  }
}
