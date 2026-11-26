import MountayaClient

/// ResolvedItinerary is every projection of one itinerary an element draws, read from one answer
/// at once: the geometry its profile walks, the figures the server stated, its legs and its
/// waypoints. Each is a projection of what `getItinerary` answers, so an element handed an id
/// draws all four from one read, and an app that holds the itinerary already reads them the same
/// way.
///
/// Every projection reads the segments in chain order: the geometry is `itineraryGeometry(_:)`,
/// the figures `profileCharacteristics(_:waypoints:)` over the segments and every waypoint, its
/// planned stops included, the legs `itinerarySegments(_:groups:)` and the waypoints
/// `itineraryWaypoints(_:)`.
///
/// Two are equal where every projection is. An answer and its copies share one storage, which is
/// compared first, so the engines showing one answer compare no vertex.
public struct ResolvedItinerary: Sendable, Hashable {
  /// Storage is what an answer and its copies share: the four projections. It is Sendable: its
  /// projections are constants of Sendable types.
  private final class Storage: Sendable {
    let geometry: GeoJSONGeometry?
    let characteristics: ProfileCharacteristics
    let legs: [ItineraryLeg]
    let waypoints: [ItineraryPlace]

    init(
      geometry: GeoJSONGeometry?, characteristics: ProfileCharacteristics, legs: [ItineraryLeg],
      waypoints: [ItineraryPlace]
    ) {
      self.geometry = geometry
      self.characteristics = characteristics
      self.legs = legs
      self.waypoints = waypoints
    }
  }

  private let storage: Storage

  /// Creates the projections of `itinerary`, as the REST API answers it, reading each once.
  public init(_ itinerary: RestSchema.ItineraryWithDetails) {
    let chain = inChainOrder(itinerary.segments, position: \.position)
    storage = Storage(
      geometry: itineraryGeometry(chain),
      characteristics: profileCharacteristics(chain, waypoints: itinerary.waypoints),
      legs: itinerarySegments(chain, groups: itinerary.groups),
      waypoints: itineraryWaypoints(itinerary.waypoints)
    )
  }

  /// geometry is the one geometry the itinerary's profile walks, its segments' in chain order, nil
  /// where no segment carries one.
  public var geometry: GeoJSONGeometry? { storage.geometry }

  /// characteristics is the summary the server's figures fold to: distance, duration, ascent and
  /// descent, the altitude band, the slope range, the planned stops and the trail difficulty.
  public var characteristics: ProfileCharacteristics { storage.characteristics }

  /// legs is the itinerary's legs, a table's rows and a profile's chips.
  public var legs: [ItineraryLeg] { storage.legs }

  /// waypoints is the itinerary's places, the pins on a profile's curve and the names under its
  /// axis.
  public var waypoints: [ItineraryPlace] { storage.waypoints }

  /// Two are equal where they share one storage, or hold the same geometry, figures, legs and
  /// places.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    if lhs.storage === rhs.storage { return true }
    return sameGeometry(lhs.geometry, rhs.geometry) && lhs.characteristics == rhs.characteristics
      && lhs.legs == rhs.legs && lhs.waypoints == rhs.waypoints
  }

  /// hash feeds every projection, each number as the same-number relation reads it.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(sameGeometry: geometry)
    hasher.combine(characteristics)
    hasher.combine(legs)
    hasher.combine(waypoints)
  }
}
