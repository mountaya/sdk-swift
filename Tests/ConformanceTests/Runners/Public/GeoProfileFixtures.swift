import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

/// GeoProfileFixtures builds the wire's segments and waypoints, and the geo layer's series, from
/// what a profile fixture writes, and writes the answers back in the fixtures' shapes.
enum GeoProfileFixtures {
  /// segment builds a segment as the REST API answers one from the wire's members a fixture
  /// writes, in the wire's spelling, and a placeholder for every other the type requires, which no
  /// profile rule reads: an id of `id`, position 0, the `linestring` mode, created at the epoch by
  /// `user`, named by its id, at revision 1, in the itinerary `itinerary`. A whole number is
  /// required where the wire has an `Int`, and a number JSON cannot carry is kept as the fixture
  /// decodes it, which a JSON decoder would refuse.
  static func segment(_ fields: OrderedJSON, id placeholderId: String = "segment")
    throws(FixtureError) -> RestSchema.ItinerarySegment
  {
    guard fields.members != nil else {
      throw FixtureError(description: "a segment is not an object")
    }
    let id = try fields.optionalString(at: "id") ?? placeholderId
    var geojson: GeoJSONGeometry?
    if let geometry = fields["geojson"], !geometry.isNull {
      geojson = try GeoFixtures.geometry(geometry)
    }
    var createdAt = Date(timeIntervalSince1970: 0)
    if let written = try fields.optionalString(at: "created_at") {
      createdAt = try instant(written)
    }
    var startAt: Date?
    if let written = try fields.optionalString(at: "start_at") {
      startAt = try instant(written)
    }
    return RestSchema.ItinerarySegment(
      altitude_max: try fields.optionalInteger(at: "altitude_max"),
      altitude_min: try fields.optionalInteger(at: "altitude_min"),
      ascent: try fields.optionalInteger(at: "ascent"),
      color: try fields.optionalString(at: "color"),
      created_at: createdAt,
      created_by: RestSchema.RelationToUser(
        id: try fields.optionalString(at: "created_by") ?? "user"),
      descent: try fields.optionalInteger(at: "descent"),
      description: try fields.optionalString(at: "description"),
      distance: try fields.optionalNumber(at: "distance"),
      duration: try fields.optionalNumber(at: "duration"),
      geojson: geojson,
      gradient_max: try fields.optionalNumber(at: "gradient_max"),
      gradient_min: try fields.optionalNumber(at: "gradient_min"),
      group_id: try fields.optionalString(at: "group_id"),
      id: id,
      itinerary_id: try fields.optionalString(at: "itinerary_id") ?? "itinerary",
      mode: RestSchema.SegmentMode(rawValue: try fields.optionalString(at: "mode") ?? "linestring"),
      name: try fields.optionalString(at: "name") ?? id,
      position: try fields.optionalInteger(at: "position") ?? 0,
      revision: try fields.optionalInteger(at: "revision") ?? 1,
      road_access_info: try roadAccess(fields),
      slope_info: try ranges(fields, under: "slope_info") {
        (from, to, value) throws(FixtureError) in
        RestSchema.SlopeInfo(from_index: from, to_index: to, value: try number(value))
      },
      speed: try fields.optionalNumber(at: "speed"),
      speed_info: try ranges(fields, under: "speed_info") {
        (from, to, value) throws(FixtureError) in
        RestSchema.SpeedInfo(from_index: from, to_index: to, value: try number(value))
      },
      start_at: startAt,
      steps: nil,
      surface_info: try ranges(fields, under: "surface_info") {
        (from, to, value) throws(FixtureError) in
        RestSchema.SurfaceInfo(
          from_index: from, to_index: to, value: RestSchema.SurfaceType(rawValue: try text(value)))
      },
      trail_difficulty_info: try ranges(fields, under: "trail_difficulty_info") {
        (from, to, value) throws(FixtureError) in
        RestSchema.TrailDifficultyInfo(
          from_index: from, to_index: to,
          value: RestSchema.TrailDifficultyType(rawValue: try text(value)))
      },
      way_type_info: try ranges(fields, under: "way_type_info") {
        (from, to, value) throws(FixtureError) in
        RestSchema.WayTypeInfo(
          from_index: from, to_index: to, value: RestSchema.WayType(rawValue: try text(value)))
      }
    )
  }

  /// waypoint builds a waypoint as the REST API answers one, holding the members a case states and
  /// a placeholder for every other the type requires, which no profile rule reads.
  static func waypoint(
    amenities: [String] = [],
    description: String? = nil,
    timing: RestSchema.WaypointTiming? = nil,
    contact: RestSchema.WaypointContact? = nil
  ) -> RestSchema.ItineraryWaypoint {
    RestSchema.ItineraryWaypoint(
      amenities: amenities.map { RestSchema.WaypointAmenity(rawValue: $0) }, color: nil,
      contact: contact, created_at: Date(timeIntervalSince1970: 0),
      created_by: RestSchema.RelationToUser(id: "user"), description: description, geojson: nil,
      icon: nil, id: "waypoint", itinerary_id: "itinerary", media: nil, mode: .point,
      name: nil, position: 0, properties: nil, revision: 1, timing: timing)
  }

  /// units builds the reader a fixture writes, `{language, length, pace, slope, temperature}`,
  /// each preference as the wire spells it.
  /// timedWaypoint builds a waypoint as `geo.profile.characteristics` writes one: its `timing`, an
  /// object stating `stop_duration` or null, and a placeholder for every other member.
  static func timedWaypoint(_ written: OrderedJSON) throws(FixtureError)
    -> RestSchema.ItineraryWaypoint
  {
    var timing: RestSchema.WaypointTiming?
    if let stated = written["timing"], stated.members != nil {
      let stop = try stated.optionalInteger(at: "stop_duration")
      timing = RestSchema.WaypointTiming { $0.stop_duration = .some(stop) }
    }
    return waypoint(timing: timing)
  }

  /// characteristics writes a summary as `geo.profile.characteristics` writes one.
  static func characteristics(_ summary: ProfileCharacteristics) -> OrderedJSON {
    func whole(_ value: Int?) -> OrderedJSON { number(value.map(Double.init)) }
    return .object([
      OrderedJSON.Member(key: "altitudeMax", value: whole(summary.altitudeMax)),
      OrderedJSON.Member(key: "altitudeMin", value: whole(summary.altitudeMin)),
      OrderedJSON.Member(key: "ascent", value: whole(summary.ascent)),
      OrderedJSON.Member(key: "descent", value: whole(summary.descent)),
      OrderedJSON.Member(key: "distance", value: number(summary.distance)),
      OrderedJSON.Member(key: "duration", value: number(summary.duration)),
      OrderedJSON.Member(key: "durationPartial", value: .bool(summary.durationPartial)),
      OrderedJSON.Member(key: "slopeMax", value: number(summary.slopeMax)),
      OrderedJSON.Member(key: "slopeMin", value: number(summary.slopeMin)),
      OrderedJSON.Member(key: "stopDuration", value: whole(summary.stopDuration)),
      OrderedJSON.Member(
        key: "trailDifficultyMax", value: text(summary.trailDifficultyMax?.rawValue)),
      OrderedJSON.Member(
        key: "trailDifficultyMin", value: text(summary.trailDifficultyMin?.rawValue)),
    ])
  }

  static func units(_ value: OrderedJSON?) throws(FixtureError) -> UnitPreferences {
    guard let value, value.members != nil else {
      throw FixtureError(description: "the reader's `units` are absent")
    }
    return UnitPreferences(
      language: try value.string(at: "language"),
      length: RestSchema.UnitLength(rawValue: try value.string(at: "length")),
      pace: RestSchema.UnitPace(rawValue: try value.string(at: "pace")),
      slope: RestSchema.UnitSlope(rawValue: try value.string(at: "slope")),
      temperature: RestSchema.UnitTemperature(rawValue: try value.string(at: "temperature"))
    )
  }

  /// series builds the elevation series a fixture writes, as `geo/elevation-series.json` answers
  /// one. Its `hasElevation` is no field of the series, since it is whether the series has a
  /// sample, so it is held to that: a fixture that disagrees with itself fails rather than being
  /// read past.
  static func series(_ value: OrderedJSON?) throws(FixtureError) -> ElevationSeries {
    guard let value, value.members != nil else {
      throw FixtureError(description: "`series` is not an object")
    }
    var points: [ElevationPoint] = []
    for point in try value.array(at: "points") {
      points.append(
        ElevationPoint(
          distance: try point.number(at: "distance"),
          elevation: try point.number(at: "elevation"),
          lngLat: try point.numbers(at: "lngLat"),
          index: try point.integer(at: "index")
        ))
    }
    let series = ElevationSeries(
      points: points,
      totalDistance: try value.number(at: "totalDistance"),
      minElevation: try value.optionalNumber(at: "minElevation"),
      maxElevation: try value.optionalNumber(at: "maxElevation")
    )
    guard try value.flag(at: "hasElevation") == series.hasElevation else {
      throw FixtureError(description: "`hasElevation` disagrees with the points the series holds")
    }
    return series
  }

  /// seriesValue writes a series in the shape the profile fixtures write one.
  static func seriesValue(_ series: ElevationSeries) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "hasElevation", value: .bool(series.hasElevation)),
      OrderedJSON.Member(key: "maxElevation", value: number(series.maxElevation)),
      OrderedJSON.Member(key: "minElevation", value: number(series.minElevation)),
      OrderedJSON.Member(
        key: "points",
        value: .array(
          series.points.map { point in
            .object([
              OrderedJSON.Member(key: "distance", value: .number(point.distance)),
              OrderedJSON.Member(key: "elevation", value: .number(point.elevation)),
              OrderedJSON.Member(key: "index", value: .number(Double(point.index))),
              OrderedJSON.Member(key: "lngLat", value: GeoFixtures.numbers(point.lngLat)),
            ])
          })),
      OrderedJSON.Member(key: "totalDistance", value: .number(series.totalDistance)),
    ])
  }

  /// totalsValue writes totals in the shape the profile fixtures write them.
  static func totalsValue(_ totals: ProfileTotals) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "ascent", value: number(totals.ascent)),
      OrderedJSON.Member(key: "descent", value: number(totals.descent)),
      OrderedJSON.Member(key: "distance", value: .number(totals.distance)),
      OrderedJSON.Member(key: "elevationMax", value: number(totals.elevationMax)),
      OrderedJSON.Member(key: "elevationMin", value: number(totals.elevationMin)),
      OrderedJSON.Member(key: "gradeMax", value: number(totals.gradeMax)),
    ])
  }

  /// number writes a figure a value may leave absent, nil as `null`.
  static func number(_ value: Double?) -> OrderedJSON {
    value.map { .number($0) } ?? .null
  }

  /// text writes a word a value may leave absent, nil as `null`.
  static func text(_ value: String?) -> OrderedJSON {
    value.map { .string($0) } ?? .null
  }

  /// instant reads an instant a fixture writes, a cut-off or a creation among them, by the client's
  /// anchor, `parseTimestamp(_:)`, as the wire's decoder reads one, so a text the wire would never
  /// hand over as an instant is none here either.
  static func instant(_ text: String) throws(FixtureError) -> Date {
    guard let date = parseTimestamp(text) else {
      throw FixtureError(description: "`\(text)` is no instant")
    }
    return date
  }

  /// The analysis ranges a fixture writes under a key, each `{from_index, to_index, value}`, or
  /// nil where it writes none.
  private static func ranges<Entry>(
    _ fields: OrderedJSON, under key: String,
    build: (Int, Int, OrderedJSON) throws(FixtureError) -> Entry
  ) throws(FixtureError) -> [Entry]? {
    guard let list = fields[key], !list.isNull else { return nil }
    guard let entries = list.elements else {
      throw FixtureError(description: "`\(key)` is not an array")
    }
    var built: [Entry] = []
    for entry in entries {
      guard let value = entry["value"] else {
        throw FixtureError(description: "an entry of `\(key)` has no `value`")
      }
      built.append(
        try build(try entry.integer(at: "from_index"), try entry.integer(at: "to_index"), value))
    }
    return built
  }

  /// roadAccess reads a segment's `road_access_info`, each range's `values` its access tags as
  /// REST spells them, or nil where the segment states none.
  private static func roadAccess(_ fields: OrderedJSON) throws(FixtureError)
    -> [RestSchema.RoadAccessInfo]?
  {
    guard let list = fields["road_access_info"], !list.isNull else { return nil }
    guard let entries = list.elements else {
      throw FixtureError(description: "`road_access_info` is not an array")
    }
    var built: [RestSchema.RoadAccessInfo] = []
    for entry in entries {
      built.append(
        RestSchema.RoadAccessInfo(
          from_index: try entry.integer(at: "from_index"),
          to_index: try entry.integer(at: "to_index"),
          values: try GeoFixtures.textList(entry, at: "values").map {
            RestSchema.RoadAccessRestrictionType(rawValue: $0)
          }))
    }
    return built
  }

  private static func number(_ value: OrderedJSON) throws(FixtureError) -> Double {
    guard let number = value.numberValue else {
      throw FixtureError(description: "a range's value is not a number")
    }
    return number
  }

  private static func text(_ value: OrderedJSON) throws(FixtureError) -> String {
    guard let text = value.stringValue else {
      throw FixtureError(description: "a range's value is not a string")
    }
    return text
  }
}
