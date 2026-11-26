import MountayaClient

/// SearchRowPayload is what picking a search result hands back, one kind per section, so one
/// handler answers every section: where to move the camera, what to frame and what to open. A
/// position is `[longitude, latitude]`, an altitude the wire's point carries dropped, and a box
/// `[west, south, east, north]`, each `nil` where the search answered none that names a place. A
/// way's `coordinates` are its line as the wire traced it.
///
/// Two are equal where they are the same kind holding the same values, a list of numbers compared
/// as every list of the geo layer is, `NaN` the same as `NaN` and 0 another than -0, and a text by
/// its scalars.
public enum SearchRowPayload: Sendable, Hashable {
  /// place moves the camera to a geocoded place's `point`, framing its `bounds` where it has some.
  case place(point: [Double], bounds: [Double]?)
  /// poi moves the camera to a point of interest's `point`, its `category` picking the pin.
  case poi(point: [Double], category: DataSchema.POICategory?)
  /// way moves the camera to a way's `anchor`, its centroid, framing its `bounds` and tracing its
  /// line, `coordinates`, where the search verified one.
  case way(anchor: [Double], bounds: [Double]?, coordinates: [[Double]]?)
  /// itinerary opens an itinerary by its `itineraryId`, framed on its `bounds` and started at its
  /// `start`.
  case itinerary(itineraryId: String, bounds: [Double]?, start: [Double]?)
  /// collection opens a collection, carrying the fields an editor over it shows at once, a
  /// `description` `nil` for one that has none.
  case collection(collectionId: String, name: String?, description: String?, isPrivate: Bool?)
  /// zone opens a zone by its `zoneId`, at its anchor `point` and framed on its `bounds` where it
  /// has them.
  case zone(zoneId: String, point: [Double]?, bounds: [Double]?)

  /// Two payloads are equal where they are of one kind and hold the same values.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    switch (lhs, rhs) {
    case (.place(let point, let bounds), .place(let otherPoint, let otherBounds)):
      return sameNumbers(point, otherPoint) && sameBox(bounds, otherBounds)
    case (.poi(let point, let category), .poi(let otherPoint, let otherCategory)):
      return sameNumbers(point, otherPoint) && sameText(category, otherCategory)
    case (
      .way(let anchor, let bounds, let coordinates),
      .way(let otherAnchor, let otherBounds, let otherCoordinates)
    ):
      return sameNumbers(anchor, otherAnchor) && sameBox(bounds, otherBounds)
        && samePositions(coordinates, otherCoordinates)
    case (
      .itinerary(let id, let bounds, let start),
      .itinerary(let otherId, let otherBounds, let otherStart)
    ):
      return sameText(id, otherId) && sameBox(bounds, otherBounds) && sameBox(start, otherStart)
    case (
      .collection(let id, let name, let description, let isPrivate),
      .collection(let otherId, let otherName, let otherDescription, let otherIsPrivate)
    ):
      return sameText(id, otherId) && sameText(name, otherName)
        && sameText(description, otherDescription) && isPrivate == otherIsPrivate
    case (.zone(let id, let point, let bounds), .zone(let otherId, let otherPoint, let otherBounds)):
      return sameText(id, otherId) && sameBox(point, otherPoint) && sameBox(bounds, otherBounds)
    default:
      return false
    }
  }

  /// hash feeds the kind and its values, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    switch self {
    case .place(let point, let bounds):
      hasher.combine(0)
      hasher.combine(sameNumbers: point)
      hasher.combine(sameBox: bounds)
    case .poi(let point, let category):
      hasher.combine(1)
      hasher.combine(sameNumbers: point)
      hasher.combine(category)
    case .way(let anchor, let bounds, let coordinates):
      hasher.combine(2)
      hasher.combine(sameNumbers: anchor)
      hasher.combine(sameBox: bounds)
      hasher.combine(samePositions: coordinates)
    case .itinerary(let id, let bounds, let start):
      hasher.combine(3)
      hasher.combine(id)
      hasher.combine(sameBox: bounds)
      hasher.combine(sameBox: start)
    case .collection(let id, let name, let description, let isPrivate):
      hasher.combine(4)
      hasher.combine(id)
      hasher.combine(name)
      hasher.combine(description)
      hasher.combine(isPrivate)
    case .zone(let id, let point, let bounds):
      hasher.combine(5)
      hasher.combine(id)
      hasher.combine(sameBox: point)
      hasher.combine(sameBox: bounds)
    }
  }
}
