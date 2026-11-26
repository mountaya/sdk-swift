import MountayaClient

/// ItineraryLeg is one leg of an itinerary as an element draws it: a segment, or a listed group of
/// segments collapsed into one, with the figures the server stated for it as its own section. A
/// table's rows and a profile's chips are an itinerary's legs, `itinerarySegments(_:groups:)`.
///
/// Every figure is the server's, computed once over the full track, and keeps the wire's type: an
/// ascent is an `Int`. None is a running total, which the rows of a table accumulate, and none is
/// a difficulty, which a leg does not fold, so a leg states neither.
///
/// Two are equal where they hold the same texts, scalar for scalar, the same geometry and the same
/// figures, each number by the same-number relation, as every value of the geo layer compares.
public struct ItineraryLeg: Sendable, Hashable {
  /// id is the segment's own id, or `segmentGroupIdPrefix` then the group's id for a collapsed
  /// group.
  public var id: String
  /// memberIds is the ids of the segments a collapsed group stands for, in chain order, and empty
  /// for a leg that stands for itself alone. A map names the segment under its pointer, never the
  /// group, so a leg is matched on its members as well as on its own id.
  public var memberIds: [String]
  /// name is the segment's name, or the group's.
  public var name: String
  /// color is the segment's colour, or the group's, painted as given, nil where it states none.
  public var color: String?
  /// geometry is the segment's geometry as it stores it, or the lines of a group's members, nil
  /// where it has none: its span on a profile's axis is the length of its own lines.
  public var geometry: GeoJSONGeometry?
  /// sectionDistance is the leg's own distance along the ground, in meters.
  public var sectionDistance: Double?
  /// sectionAscent is the meters the leg climbs.
  public var sectionAscent: Int?
  /// sectionDescent is the meters the leg loses, stated positive, as the wire states it.
  public var sectionDescent: Int?
  /// duration is the seconds the leg is expected to take.
  public var duration: Double?
  /// altitudeMin is the lowest altitude on the leg, in meters.
  public var altitudeMin: Int?
  /// altitudeMax is the highest altitude on the leg, in meters.
  public var altitudeMax: Int?

  /// Creates a leg from its identity, its geometry and its figures, each figure unstated unless
  /// given.
  public init(
    id: String,
    memberIds: [String] = [],
    name: String,
    color: String? = nil,
    geometry: GeoJSONGeometry? = nil,
    sectionDistance: Double? = nil,
    sectionAscent: Int? = nil,
    sectionDescent: Int? = nil,
    duration: Double? = nil,
    altitudeMin: Int? = nil,
    altitudeMax: Int? = nil
  ) {
    self.id = id
    self.memberIds = memberIds
    self.name = name
    self.color = color
    self.geometry = geometry
    self.sectionDistance = sectionDistance
    self.sectionAscent = sectionAscent
    self.sectionDescent = sectionDescent
    self.duration = duration
    self.altitudeMin = altitudeMin
    self.altitudeMax = altitudeMax
  }

  /// Two legs are equal where every text is written alike, the geometries are the same and every
  /// figure is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.id, rhs.id)
      && lhs.memberIds.elementsEqual(rhs.memberIds) { sameText($0, $1) }
      && sameText(lhs.name, rhs.name) && sameText(lhs.color, rhs.color)
      && sameGeometry(lhs.geometry, rhs.geometry)
      && sameNumber(lhs.sectionDistance, rhs.sectionDistance)
      && lhs.sectionAscent == rhs.sectionAscent && lhs.sectionDescent == rhs.sectionDescent
      && sameNumber(lhs.duration, rhs.duration) && lhs.altitudeMin == rhs.altitudeMin
      && lhs.altitudeMax == rhs.altitudeMax
  }

  /// hash feeds every member, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(id)
    hasher.combine(memberIds)
    hasher.combine(name)
    hasher.combine(color)
    hasher.combine(sameGeometry: geometry)
    hasher.combine(sameNumber: sectionDistance)
    hasher.combine(sectionAscent)
    hasher.combine(sectionDescent)
    hasher.combine(sameNumber: duration)
    hasher.combine(altitudeMin)
    hasher.combine(altitudeMax)
  }
}
