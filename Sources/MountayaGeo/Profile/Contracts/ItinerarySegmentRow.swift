/// ItinerarySegmentRow is one leg of an itinerary as its table states it, and as a chip under its
/// profile states it (`geo.profile.segment-rows`): its key, its own id and the members it stands
/// for, its name and colour, its place in the table, the stretch of the distance axis it spans,
/// and its figures.
///
/// Its span is always read off its own geometry and never stated, since it is what a sparkline
/// lights and a map emphasises: a leg whose stored distance differs from its geometry's prints the
/// server's figure and still lights its own stretch. Two are equal where they hold the same texts,
/// written alike, and the same numbers, as every value of the geo layer compares.
public struct ItinerarySegmentRow: ProfileSpan, Sendable, Hashable {
  /// key is the row's key, the leg's own id, which a chain holds once.
  public var key: String
  /// id is the leg's own id, as its leg states it.
  public var id: String
  /// memberIds is the ids of the segments a collapsed group stands for, and empty for a leg that
  /// stands for itself alone.
  public var memberIds: [String]
  /// name is the leg's name, empty where it has none.
  public var name: String
  /// color is the leg's colour, painted as given, nil where it states none.
  public var color: String?
  /// index is the row's place in the table, from zero.
  public var index: Int
  /// from is where the leg starts on the distance axis, in meters.
  public var from: Double
  /// to is where the leg ends on the distance axis, in meters.
  public var to: Double
  /// metrics is the leg's figures, stated over derived, with the running totals.
  public var metrics: ItinerarySegmentRowMetrics

  /// Creates a row from its identity, its span and its figures.
  public init(
    key: String,
    id: String,
    memberIds: [String] = [],
    name: String,
    color: String? = nil,
    index: Int,
    from: Double,
    to: Double,
    metrics: ItinerarySegmentRowMetrics
  ) {
    self.key = key
    self.id = id
    self.memberIds = memberIds
    self.name = name
    self.color = color
    self.index = index
    self.from = from
    self.to = to
    self.metrics = metrics
  }

  /// Two rows are equal where every member is the same, or absent on both.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.key, rhs.key) && sameText(lhs.id, rhs.id)
      && lhs.memberIds.elementsEqual(rhs.memberIds) { sameText($0, $1) }
      && sameText(lhs.name, rhs.name) && sameText(lhs.color, rhs.color) && lhs.index == rhs.index
      && sameNumber(lhs.from, rhs.from) && sameNumber(lhs.to, rhs.to) && lhs.metrics == rhs.metrics
  }

  /// hash feeds every member, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(id)
    hasher.combine(memberIds)
    hasher.combine(name)
    hasher.combine(color)
    hasher.combine(index)
    hasher.combine(sameNumber: from)
    hasher.combine(sameNumber: to)
    hasher.combine(metrics)
  }
}
