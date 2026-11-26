import MountayaClient

/// ProfilePlace is a place an element marks on an itinerary's profile and lists in its waypoint
/// table: where it stands, given on the ground or at a distance on the axis, its name, colour and
/// glyph, whether it divides the itinerary and is pinned on the curve, the figures stated for the
/// stretch that reaches it, and what it says about itself. An itinerary's own places are its
/// `ItineraryPlace`s, each read through `init(_:)`.
///
/// Two are equal where they hold the same placement, texts written alike, the same flags and the
/// same figures and details, as every value of the geo layer compares.
public struct ProfilePlace: Sendable, Hashable {
  /// placement is where the place stands and its id: at a position, at every close pass of the
  /// line, or at a distance on the axis (`resolveWaypoints(_:waypoints:)`).
  public var placement: ProfileWaypoint
  /// name is the place's name, nil for a bare marker.
  public var name: String?
  /// color is the colour the place is pinned in, painted as given, nil for the profile's own.
  public var color: String?
  /// glyph is the glyph the place is pinned with, nil where it names none.
  public var glyph: RestSchema.WaypointIcon?
  /// divides is whether the place ends a section of the itinerary, its name under the axis, nil to
  /// read as `dividesRoute` reads it.
  public var divides: Bool?
  /// isPinned is whether a pin stands for the place on the curve.
  public var isPinned: Bool
  /// metrics is the figures stated for the stretch that reaches the place, which a waypoint row
  /// states over the ones the itinerary's geometry reads on its primary pass, where the place
  /// divides the itinerary (`itineraryWaypointRows(_:geometry:places:)`).
  public var metrics: ItinerarySegmentRowMetrics?
  /// details is what the place says about itself, nil where it says nothing.
  public var details: WaypointDetails?

  /// Creates a place from where it stands and what it states.
  public init(
    _ placement: ProfileWaypoint,
    name: String? = nil,
    color: String? = nil,
    glyph: RestSchema.WaypointIcon? = nil,
    divides: Bool? = nil,
    isPinned: Bool = true,
    metrics: ItinerarySegmentRowMetrics? = nil,
    details: WaypointDetails? = nil
  ) {
    self.placement = placement
    self.name = name
    self.color = color
    self.glyph = glyph
    self.divides = divides
    self.isPinned = isPinned
    self.metrics = metrics
    self.details = details
  }

  /// Creates the place an itinerary's waypoint marks, at its position, with its name, colour,
  /// glyph and details.
  public init(_ place: ItineraryPlace) {
    self.init(
      .atPosition(id: place.id, position: place.lngLat), name: place.name, color: place.color,
      glyph: place.glyph, details: place.details)
  }

  /// id is the place's own id, which its placements are keyed by.
  public var id: String { placement.id }

  /// dividesRoute is whether the place ends a section of the itinerary: as `divides` states, and
  /// where it states nothing, whether it has a name, since a named place ends a section and a bare
  /// marker is decoration.
  public var dividesRoute: Bool { divides ?? (name != nil) }

  /// Two places are equal where every member is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.placement == rhs.placement && sameText(lhs.name, rhs.name)
      && sameText(lhs.color, rhs.color) && sameText(lhs.glyph, rhs.glyph)
      && lhs.divides == rhs.divides && lhs.isPinned == rhs.isPinned && lhs.metrics == rhs.metrics
      && lhs.details == rhs.details
  }

  /// hash feeds every member.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(placement)
    hasher.combine(name)
    hasher.combine(color)
    hasher.combine(glyph)
    hasher.combine(divides)
    hasher.combine(isPinned)
    hasher.combine(metrics)
    hasher.combine(details)
  }
}
