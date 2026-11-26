import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

/// GeoItineraryFixtures builds the wire's itinerary members from what a `geo.data.itinerary-*`
/// fixture writes, plays the clients its scripts read through, and writes the answers back in the
/// fixtures' shapes.
enum GeoItineraryFixtures {
  // MARK: - The wire's members

  /// group builds a segment group as the REST API answers one, from the members a fixture writes.
  static func group(_ fields: OrderedJSON) throws(FixtureError) -> RestSchema.ItinerarySegmentGroup
  {
    RestSchema.ItinerarySegmentGroup(
      color: try fields.string(at: "color"),
      created_at: try GeoProfileFixtures.instant(try fields.string(at: "created_at")),
      created_by: RestSchema.RelationToUser(id: try fields.string(at: "created_by")),
      id: try fields.string(at: "id"),
      itinerary_id: try fields.string(at: "itinerary_id"),
      name: try fields.string(at: "name"),
      revision: try fields.integer(at: "revision"),
      speed: try fields.optionalNumber(at: "speed")
    )
  }

  /// waypoint builds a waypoint as the REST API answers one from the members a fixture writes, and
  /// a placeholder for every other the type requires, which no rule reads: created at the epoch by
  /// `user`, a `point`, at revision 1, in the itinerary `itinerary`.
  ///
  /// Each member is read in the shape the wire's type holds and left out in any other, a list's
  /// entries one by one, as no decoder of the wire's hands a waypoint over holding a colour of 7,
  /// an icon that is an object, an address that is a list or a stop of no whole number of seconds,
  /// as `geo/itinerary-waypoints.json` writes some. A member written null is the wire's null, and
  /// one left out is absent.
  static func waypoint(_ fields: OrderedJSON) throws(FixtureError) -> RestSchema.ItineraryWaypoint {
    guard fields.members != nil else {
      throw FixtureError(description: "a waypoint is not an object")
    }
    var geojson: GeoJSONGeometry?
    if let geometry = fields["geojson"], !geometry.isNull {
      geojson = try GeoFixtures.geometry(geometry)
    }
    return RestSchema.ItineraryWaypoint(
      amenities: (fields["amenities"]?.elements ?? []).compactMap {
        $0.stringValue.map { RestSchema.WaypointAmenity(rawValue: $0) }
      },
      color: fields["color"]?.stringValue,
      contact: contact(fields["contact"]),
      created_at: Date(timeIntervalSince1970: 0),
      created_by: RestSchema.RelationToUser(id: "user"),
      description: fields["description"]?.stringValue,
      geojson: geojson,
      icon: fields["icon"]?.stringValue.map { RestSchema.WaypointIcon(rawValue: $0) },
      id: try fields.string(at: "id"),
      itinerary_id: "itinerary",
      media: media(fields["media"]),
      mode: .point,
      name: fields["name"]?.stringValue,
      position: try fields.integer(at: "position"),
      properties: properties(fields["properties"]),
      revision: 1,
      timing: timing(fields["timing"])
    )
  }

  /// merged reads a member a block states as optional and nullable: absent where the fixture
  /// leaves it out or writes it in a shape `read` does not hold, and null where it writes null.
  private static func merged<Value>(_ value: OrderedJSON?, read: (OrderedJSON) -> Value?)
    -> Value??
  {
    guard let value else { return nil }
    if value.isNull { return .some(nil) }
    return read(value).map { .some($0) }
  }

  /// webAddress reads a web address the wire holds as the text it sent, whatever it holds, one
  /// with no scheme included (`sdk/SPEC.md` §4).
  private static func webAddress(_ value: OrderedJSON) -> URI? {
    value.stringValue.map(URI.init)
  }

  private static func contact(_ value: OrderedJSON?) -> RestSchema.WaypointContact? {
    guard let value, value.members != nil else { return nil }
    return RestSchema.WaypointContact {
      $0.address = merged(value["address"]) { $0.stringValue }
      $0.booking_url = merged(value["booking_url"], read: webAddress)
      $0.email = merged(value["email"]) { $0.stringValue }
      $0.opening_hours = merged(value["opening_hours"]) { $0.stringValue }
      $0.phone = merged(value["phone"]) { $0.stringValue }
      $0.website = merged(value["website"], read: webAddress)
    }
  }

  private static func media(_ value: OrderedJSON?) -> RestSchema.WaypointMedia? {
    guard let value, value.members != nil else { return nil }
    return RestSchema.WaypointMedia {
      $0.links = merged(value["links"]) { list in list.elements.map { $0.compactMap(link) } }
      $0.photos = merged(value["photos"]) { list in list.elements.map { $0.compactMap(photo) } }
    }
  }

  private static func link(_ value: OrderedJSON) -> RestSchema.WaypointLink? {
    guard value.members != nil, let label = value["label"]?.stringValue,
      let url = value["url"].flatMap(webAddress)
    else { return nil }
    return RestSchema.WaypointLink(label: label, url: url)
  }

  private static func photo(_ value: OrderedJSON) -> RestSchema.WaypointPhoto? {
    guard value.members != nil, let url = value["url"].flatMap(webAddress) else { return nil }
    return RestSchema.WaypointPhoto(url: url) {
      $0.caption = merged(value["caption"]) { $0.stringValue }
    }
  }

  private static func properties(_ value: OrderedJSON?) -> [RestSchema.WaypointProperty]? {
    guard let entries = value?.elements else { return nil }
    return entries.compactMap { entry in
      guard entry.members != nil, let key = entry["key"]?.stringValue,
        let label = entry["label"]?.stringValue, let text = entry["value"]?.stringValue
      else { return nil }
      return RestSchema.WaypointProperty(key: key, label: label, value: text) {
        $0.format = merged(entry["format"]) {
          $0.stringValue.map { RestSchema.WaypointPropertyFormat(rawValue: $0) }
        }
      }
    }
  }

  private static func timing(_ value: OrderedJSON?) -> RestSchema.WaypointTiming? {
    guard let value, value.members != nil else { return nil }
    return RestSchema.WaypointTiming {
      $0.cutoff_at = merged(value["cutoff_at"]) { written in
        written.stringValue.flatMap { try? GeoProfileFixtures.instant($0) }
      }
      $0.stop_duration = merged(value["stop_duration"]) { written in
        written.numberValue.flatMap { Int(exactly: $0) }
      }
    }
  }

  // MARK: - The answers, as the fixtures write them

  /// legValue writes a leg as `geo/itinerary-segments.json` writes one: its colour and its members
  /// only where it has them, and the running totals and the difficulty a leg never states as null.
  static func legValue(_ leg: ItineraryLeg) -> OrderedJSON {
    var members = [
      OrderedJSON.Member(key: "geojson", value: leg.geometry.map(GeoFixtures.written) ?? .null),
      OrderedJSON.Member(key: "id", value: .string(leg.id)),
      OrderedJSON.Member(
        key: "metrics",
        value: .object([
          OrderedJSON.Member(key: "altitudeMax", value: whole(leg.altitudeMax)),
          OrderedJSON.Member(key: "altitudeMin", value: whole(leg.altitudeMin)),
          OrderedJSON.Member(key: "ascent", value: .null),
          OrderedJSON.Member(key: "descent", value: .null),
          OrderedJSON.Member(key: "difficulty", value: .null),
          OrderedJSON.Member(key: "distance", value: .null),
          OrderedJSON.Member(key: "duration", value: GeoProfileFixtures.number(leg.duration)),
          OrderedJSON.Member(key: "sectionAscent", value: whole(leg.sectionAscent)),
          OrderedJSON.Member(key: "sectionDescent", value: whole(leg.sectionDescent)),
          OrderedJSON.Member(
            key: "sectionDistance", value: GeoProfileFixtures.number(leg.sectionDistance)),
        ])),
      OrderedJSON.Member(key: "name", value: .string(leg.name)),
    ]
    if let color = leg.color {
      members.append(OrderedJSON.Member(key: "color", value: .string(color)))
    }
    if !leg.memberIds.isEmpty {
      members.append(OrderedJSON.Member(key: "memberIds", value: GeoFixtures.texts(leg.memberIds)))
    }
    return .object(members)
  }

  /// placeValue writes a place as `geo/itinerary-waypoints.json` writes one: each member only
  /// where it holds something.
  static func placeValue(_ place: ItineraryPlace) -> OrderedJSON {
    var members = [
      OrderedJSON.Member(key: "id", value: .string(place.id)),
      OrderedJSON.Member(key: "lngLat", value: GeoFixtures.numbers(place.lngLat)),
    ]
    if let color = place.color {
      members.append(OrderedJSON.Member(key: "color", value: .string(color)))
    }
    if let glyph = place.glyph {
      members.append(OrderedJSON.Member(key: "glyph", value: .string(glyph.rawValue)))
    }
    if let name = place.name {
      members.append(OrderedJSON.Member(key: "name", value: .string(name)))
    }
    if let details = place.details {
      members.append(OrderedJSON.Member(key: "details", value: detailsValue(details)))
    }
    return .object(members)
  }

  private static func detailsValue(_ details: WaypointDetails) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    func add(_ key: String, value: OrderedJSON?) {
      if let value { members.append(OrderedJSON.Member(key: key, value: value)) }
    }
    add("amenities", value: details.amenities.map { GeoFixtures.texts($0.map(\.rawValue)) })
    add("description", value: details.description.map { .string($0) })
    add(
      "contact",
      value: details.contact.map { contact in
        texts([
          ("address", contact.address), ("bookingUrl", contact.bookingUrl),
          ("email", contact.email), ("openingHours", contact.openingHours),
          ("phone", contact.phone), ("website", contact.website),
        ])
      })
    add(
      "media",
      value: details.media.map { media in
        var lists: [OrderedJSON.Member] = []
        if let links = media.links {
          lists.append(
            OrderedJSON.Member(
              key: "links",
              value: .array(
                links.map { texts([("label", $0.label), ("url", $0.url)]) })))
        }
        if let photos = media.photos {
          lists.append(
            OrderedJSON.Member(
              key: "photos",
              value: .array(
                photos.map { texts([("caption", $0.caption), ("url", $0.url)]) })))
        }
        return .object(lists)
      })
    add(
      "properties",
      value: details.properties.map { fields in
        .array(
          fields.map {
            texts([
              ("format", $0.format?.rawValue), ("key", $0.key), ("label", $0.label),
              ("value", $0.value),
            ])
          })
      })
    add(
      "timing",
      value: details.timing.map { timing in
        var members: [OrderedJSON.Member] = []
        if let cutoffAt = timing.cutoffAt {
          members.append(OrderedJSON.Member(key: "cutoffAt", value: .string(instantText(cutoffAt))))
        }
        if let stop = timing.stopDuration {
          members.append(OrderedJSON.Member(key: "stopDuration", value: .number(Double(stop))))
        }
        return .object(members)
      })
    return .object(members)
  }

  /// texts writes an object of the texts present among `members`, each under its key.
  private static func texts(_ members: [(String, String?)]) -> OrderedJSON {
    .object(
      members.compactMap { key, text in
        text.map { OrderedJSON.Member(key: key, value: .string($0)) }
      })
  }

  /// instantText writes an instant as RFC 3339 in UTC, with fractional seconds only where it has
  /// a fraction of one.
  private static func instantText(_ date: Date) -> String {
    let seconds = date.timeIntervalSince1970
    let whole = seconds.rounded(.down) == seconds
    return Date.ISO8601FormatStyle(includingFractionalSeconds: !whole).format(date)
  }

  /// whole writes a whole figure a value may leave absent, nil as `null`.
  private static func whole(_ value: Int?) -> OrderedJSON {
    value.map { .number(Double($0)) } ?? .null
  }

  // MARK: - The clients a script reads through

  /// surface reads a step's `surface`, the draft being the one a question names no surface for.
  static func surface(_ step: OrderedJSON) throws(FixtureError) -> RestSchema.ReadSurface? {
    switch try step.string(at: "surface") {
    case "draft": return nil
    case "published": return .published
    case let other: throw FixtureError(description: "`\(other)` is no surface")
    }
  }

  /// shown writes what an element shows as the fixtures read it: `idle`, `resolving` or `failed`
  /// with nothing shown, or `resolved` with the read whose answer it shows, every projection of it
  /// held.
  static func shown(_ state: ItineraryResource, statingSummary: Bool = false) throws(FixtureError)
    -> OrderedJSON
  {
    func snapshot(_ state: String, shows: Int?, summary: ProfileCharacteristics? = nil)
      -> OrderedJSON
    {
      var members: [OrderedJSON.Member] = []
      if statingSummary {
        members.append(
          OrderedJSON.Member(
            key: "characteristics",
            value: summary.map(GeoProfileFixtures.characteristics) ?? .null))
      }
      members.append(
        OrderedJSON.Member(key: "shows", value: shows.map { .number(Double($0)) } ?? .null))
      members.append(OrderedJSON.Member(key: "state", value: .string(state)))
      return .object(members)
    }
    switch state {
    case .idle: return snapshot("idle", shows: nil)
    case .resolving: return snapshot("resolving", shows: nil)
    case .failed: return snapshot("failed", shows: nil)
    case .resolved(let itinerary):
      // Every answer of a script carries a geometry and one leg named by its read.
      guard itinerary.geometry != nil, let id = itinerary.legs.first?.id, id.hasPrefix("read-"),
        let read = Int(id.dropFirst("read-".count))
      else {
        throw FixtureError(description: "a resolved element shows no answer a read names")
      }
      return snapshot("resolved", shows: read, summary: itinerary.characteristics)
    }
  }

  /// settle lets what a step set going come to rest: every read answered so far landed, every
  /// engine it moves told, and every read a step asks for sent. It reads what each engine shows and
  /// every read sent and settled until they stand still (`Quiescence`): a source of a script is a
  /// closure of the main actor's, which the cache calls and returns from through the runtime's hop,
  /// so no count of the main actor's turns is a wait for it. No clock is read.
  @MainActor
  static func settle(_ reads: Reads, engines: [ItineraryResourceEngine]) async {
    await Quiescence.settle {
      [reads.requests, .number(Double(reads.settledCount))]
        + engines.map { (try? shown($0.state, statingSummary: true)) ?? .null }
    }
  }

  /// Reads stands for the clients an itinerary is read through, `a` and `b`, each with the one
  /// cache an app makes for its client. Every read is held open until a step answers or fails it,
  /// by the order it was sent in, which is how a step names it, and an answer is an itinerary
  /// whose one segment names the read.
  @MainActor
  final class Reads {
    /// Read is one read a client was asked for.
    private struct Read {
      let itinerary: String
      let surface: RestSchema.ReadSurface?
      let client: String
      let continuation: CheckedContinuation<RestSchema.ItineraryWithDetails, any Error>
    }

    /// Failed is what a read a step fails throws.
    private struct Failed: Error {
      let read: Int
    }

    private var sent: [Read] = []
    private var settled: Set<Int> = []

    /// settledCount is how many reads a step answered, failed or drained.
    var settledCount: Int { settled.count }
    private var caches: [String: ItineraryResourceCache] = [:]
    /// segment and waypoints are what every read is answered with where the case states
    /// `answered`: the one segment's members, and the waypoints.
    private var segment: OrderedJSON = .object([])
    private var waypoints: [RestSchema.ItineraryWaypoint] = []

    /// answering answers every read with what a case's `answered` states: the one segment's members
    /// as `answered.segment` writes them, and the waypoints as `answered.waypoints` writes them, each
    /// as `geo.profile.characteristics` writes one.
    func answering(_ answered: OrderedJSON) throws(FixtureError) {
      segment = answered["segment"] ?? .object([])
      waypoints = []
      for written in try answered.array(at: "waypoints") {
        waypoints.append(try GeoProfileFixtures.timedWaypoint(written))
      }
    }

    /// cache is the cache of the client a step names, made the first time it is named.
    func cache(_ client: String) throws(FixtureError) -> ItineraryResourceCache {
      guard client == "a" || client == "b" else {
        throw FixtureError(description: "`\(client)` is no client")
      }
      if let cache = caches[client] { return cache }
      let cache = ItineraryResourceCache { @MainActor [self] itineraryId, surface in
        try await withCheckedThrowingContinuation { continuation in
          sent.append(
            Read(
              itinerary: itineraryId, surface: surface, client: client,
              continuation: continuation))
        }
      }
      caches[client] = cache
      return cache
    }

    /// answer answers the read a step names with an itinerary whose one segment names the read,
    /// stating the members the case answers with and its waypoints.
    func answer(_ index: Int) throws(FixtureError) {
      var answered = try GeoProfileFixtures.segment(segment, id: "read-\(index)")
      answered.geojson = .lineString(GeoJSONLineString(coordinates: [[6, 45], [6.01, 45]]))
      let read = try open(index)
      read.continuation.resume(
        returning: RestSchema.ItineraryWithDetails(
          activity_id: "hiking", ascent: nil,
          count: RestSchema.ItineraryCount(groups: 0, segments: 1, waypoints: 0),
          created_at: Date(timeIntervalSince1970: 0),
          created_by: RestSchema.RelationToUser(id: "user"), description: nil, distance: 1_000,
          id: read.itinerary, is_private: false, is_verified: false, name: read.itinerary,
          organization_id: nil, etag: "etag", revision: 1, status: .draft,
          updated_at: Date(timeIntervalSince1970: 0), groups: [], has_unpublished_changes: false,
          published_at: nil,
          segments: [answered],
          waypoints: waypoints))
    }

    /// fail fails the read a step names.
    func fail(_ index: Int) throws(FixtureError) {
      try open(index).continuation.resume(throwing: Failed(read: index))
    }

    /// drain fails every read still open, so no task is left waiting once a case ends.
    func drain() {
      for index in sent.indices where !settled.contains(index) {
        settled.insert(index)
        sent[index].continuation.resume(throwing: Failed(read: index))
      }
    }

    /// requests writes every read sent, with its `itinerary`, `source` and `surface`.
    var requests: OrderedJSON {
      .array(
        sent.map {
          .object([
            OrderedJSON.Member(key: "itinerary", value: .string($0.itinerary)),
            OrderedJSON.Member(key: "source", value: .string($0.client)),
            OrderedJSON.Member(key: "surface", value: .string($0.surface?.rawValue ?? "draft")),
          ])
        })
    }

    /// open is the read a step names, which must have been sent and not yet settled.
    private func open(_ index: Int) throws(FixtureError) -> Read {
      guard sent.indices.contains(index) else {
        throw FixtureError(description: "read \(index) was never sent")
      }
      guard settled.insert(index).inserted else {
        throw FixtureError(description: "read \(index) is settled twice")
      }
      return sent[index]
    }
  }
}
