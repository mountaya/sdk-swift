import MountayaClient

/// ItineraryPlace is a waypoint of an itinerary as an element draws it: a place on the itinerary,
/// where it stands, its name, its colour, the glyph it is pinned with, and what it says about the
/// place it marks. An itinerary's places are `itineraryWaypoints(_:)`.
///
/// A place marks an itinerary where a leg divides it: it is a pin on a profile's curve and a name
/// under its axis, placed by its point, since a waypoint's `position` is the API's ordinal and
/// states no distance (`resolveWaypoints(_:waypoints:)`). Its name, its colour and its glyph are
/// carried as the wire states them.
///
/// Two are equal where they hold the same texts, scalar for scalar, the same position, each number
/// by the same-number relation, and the same details, as every value of the geo layer compares.
public struct ItineraryPlace: Sendable, Hashable {
  /// id is the waypoint's own id.
  public var id: String
  /// lngLat is where the place stands, `[longitude, latitude]` in degrees, with no altitude.
  public var lngLat: [Double]
  /// name is the place's name, nil for a bare marker, which has none.
  public var name: String?
  /// color is the colour the place is pinned in, painted as given, nil where it states none.
  public var color: String?
  /// glyph is the icon the place is pinned with, which names a glyph of the set it is drawn from,
  /// nil where it states none.
  public var glyph: RestSchema.WaypointIcon?
  /// details is what the waypoint says about the place, nil where it says nothing.
  public var details: WaypointDetails?

  /// Creates a place from its id and where it stands, with what it states.
  public init(
    id: String,
    lngLat: [Double],
    name: String? = nil,
    color: String? = nil,
    glyph: RestSchema.WaypointIcon? = nil,
    details: WaypointDetails? = nil
  ) {
    self.id = id
    self.lngLat = lngLat
    self.name = name
    self.color = color
    self.glyph = glyph
    self.details = details
  }

  /// Two places are equal where every text is written alike, the positions are the same numbers
  /// and the details are the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id) && sameNumbers(lhs.lngLat, rhs.lngLat)
      && sameText(lhs.name, rhs.name) && sameText(lhs.color, rhs.color)
      && sameText(lhs.glyph, rhs.glyph) && lhs.details == rhs.details
  }

  /// hash feeds every member, the position as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(sameNumbers: lngLat)
    hasher.combine(name)
    hasher.combine(color)
    hasher.combine(glyph)
    hasher.combine(details)
  }
}
