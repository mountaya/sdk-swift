import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// searchHighlight answers the parts the case's `title` is drawn in once its `query` is matched
  /// against it.
  static let searchHighlight = Runner(id: "geo.search.highlight", table: .public) {
    _, fixtureCase in
    let input = fixtureCase.input
    return .value(
      .array(
        highlightParts(try input.string(at: "title"), query: try input.string(at: "query")).map {
          .object([
            OrderedJSON.Member(key: "match", value: .bool($0.match)),
            OrderedJSON.Member(key: "text", value: .string($0.text)),
          ])
        }))
  }

  /// searchQuery answers the rounds a search asks as a reader types the case's `queries`, each
  /// settling before the next, under its `limit`. Each typed query is read through
  /// `searchQueryChangeOf(settled:typed:)`, after the query the last one settled: a round is asked,
  /// the search cleared, or nothing. The cap is held to `isSearchLimit(_:)`, and a cap that is no
  /// whole number is refused as the `Int` a round's cap is cannot hold one (`sdk/SPEC.md` §10). The
  /// ceiling is held to the one Geo publishes.
  static let searchQuery = Runner(id: "geo.search.query", table: .public) { fixture, fixtureCase in
    try fixture.holdConstants(["searchLimitMax": Double(searchLimitMax)])
    let input = fixtureCase.input
    func answer(refused: Bool, rounds: [OrderedJSON]) -> RunnerOutcome {
      .value(
        .object([
          OrderedJSON.Member(key: "refused", value: .bool(refused)),
          OrderedJSON.Member(key: "rounds", value: .array(rounds)),
        ]))
    }
    let cap = try input.optionalNumber(at: "limit")
    let limit = cap.flatMap { Int(exactly: $0) }
    if cap != nil, limit.map(isSearchLimit) != true {
      return answer(refused: true, rounds: [])
    }
    var rounds: [String] = []
    var settled = ""
    for typed in try GeoFixtures.textList(input, at: "queries") {
      switch searchQueryChangeOf(settled: settled, typed: typed) {
      case .ask(let query):
        rounds.append(query)
        settled = query
      case .clear:
        settled = ""
      case .unchanged:
        break
      }
    }
    return answer(
      refused: false,
      rounds: rounds.map { query in
        .object([
          OrderedJSON.Member(key: "limit", value: limit.map { .number(Double($0)) } ?? .null),
          OrderedJSON.Member(key: "query", value: .string(query)),
        ])
      })
  }

  /// searchViewportBounds answers the box a viewport-restricted search sends for a camera at the
  /// case's `center` and `zoom`. The cosine floor and the span's ceiling are held to the ones Geo
  /// publishes.
  static let searchViewportBounds = Runner(id: "geo.search.viewport-bounds", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "cosineFloor": searchBoundsCosineFloor,
      "maxSpanDegrees": searchBoundsMaxSpanDegrees,
    ])
    let input = fixtureCase.input
    return .value(
      GeoFixtures.numbers(
        MountayaGeo.searchViewportBounds(
          center: try input.numbers(at: "center"), zoom: try input.number(at: "zoom"))))
  }

  /// searchRows answers the row the case's `entity` of its `kind` renders as for its `query`, in
  /// English with metric figures, or null. The entity is read by the Data API's own decoder from
  /// the JSON the fixture writes. The row is written as the fixture writes one: its `matched` runs
  /// as the text each covers, read through the title's scalars, and every member it does not state
  /// absent, `activities` and `matched` where it lists none, a payload's geometry where the search
  /// answered none.
  static let searchRows = Runner(id: "geo.search.rows", table: .public) { _, fixtureCase in
    let input = fixtureCase.input
    guard let entity = input["entity"] else {
      throw FixtureError(description: "the case has no `entity`")
    }
    let query = try input.string(at: "query")
    let row: SearchRow?
    switch try input.string(at: "kind") {
    case "place":
      row = placeRow(try GeoFixtures.decoded(DataSchema.Place.self, from: entity), query: query)
    case "poi":
      row = poiRow(try GeoFixtures.decoded(DataSchema.POI.self, from: entity), query: query)
    case "way":
      row = wayRow(try GeoFixtures.decoded(DataSchema.Way.self, from: entity), query: query)
    case "itinerary":
      row = itineraryRow(
        try GeoFixtures.decoded(DataSchema.ItinerarySearchResult.self, from: entity), query: query)
    case "collection":
      row = collectionRow(
        try GeoFixtures.decoded(DataSchema.CollectionSearchResult.self, from: entity), query: query)
    case "zone":
      row = zoneRow(
        try GeoFixtures.decoded(DataSchema.ZoneSearchResult.self, from: entity), query: query)
    case let kind:
      throw FixtureError(description: "`\(kind)` is no kind of row")
    }
    return .value(row.map(GeoSearchFixtures.written) ?? .null)
  }

  /// searchFilters answers the sections the case's `filter` shows of its `sections`. The fixture
  /// names a section as the Data API's search answer names its field and `SearchTargetsInput` its
  /// flag, `places`, and the rule takes the `SearchTarget` that spells it `PLACES`, so each name is
  /// read in upper case, as the fixture's description says an SDK holding `SearchTarget` reads it,
  /// and written back the fixture's way.
  static let searchFilters = Runner(id: "geo.search.filters", table: .public) { _, fixtureCase in
    let input = fixtureCase.input
    let id = try input.string(at: "filter")
    guard let filter = SearchFilter.allCases.first(where: { $0.id == id }) else {
      throw FixtureError(description: "`\(id)` is no filter")
    }
    let sections = try GeoFixtures.textList(input, at: "sections").map {
      DataSchema.SearchTarget(rawValue: $0.uppercased())
    }
    return .value(
      GeoFixtures.texts(
        sectionsForFilter(sections, filter: filter).map { $0.rawValue.lowercased() }))
  }
}

/// GeoSearchFixtures writes a search row as `geo/search-rows.json` writes one.
enum GeoSearchFixtures {
  /// written is a row as the fixture writes it.
  static func written(_ row: SearchRow) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    if !row.activities.isEmpty {
      members.append(
        OrderedJSON.Member(
          key: "activities", value: GeoFixtures.texts(row.activities.map(\.rawValue))))
    }
    members.append(OrderedJSON.Member(key: "id", value: .string(row.id)))
    if !row.matched.isEmpty {
      members.append(
        OrderedJSON.Member(
          key: "matched",
          value: GeoFixtures.texts(row.matched.map { String(row.title.unicodeScalars[$0]) })))
    }
    members.append(OrderedJSON.Member(key: "payload", value: payload(row.payload)))
    if let secondary = row.secondary {
      members.append(OrderedJSON.Member(key: "secondary", value: line(secondary)))
    }
    members.append(OrderedJSON.Member(key: "title", value: .string(row.title)))
    return .object(members)
  }

  private static func number(_ value: Double?) -> OrderedJSON {
    value.map(OrderedJSON.number) ?? .null
  }

  private static func text(_ value: String?) -> OrderedJSON {
    value.map(OrderedJSON.string) ?? .null
  }

  private static func line(_ secondary: SearchRowSecondary) -> OrderedJSON {
    switch secondary {
    case .text(let text):
      return .object([
        OrderedJSON.Member(key: "kind", value: .string("text")),
        OrderedJSON.Member(key: "text", value: .string(text)),
      ])
    case .metric(let distance, let ascent):
      return .object([
        OrderedJSON.Member(key: "ascent", value: number(ascent.map(Double.init))),
        OrderedJSON.Member(key: "distance", value: number(distance)),
        OrderedJSON.Member(key: "kind", value: .string("metric")),
      ])
    case .count(let itineraries):
      return .object([
        OrderedJSON.Member(key: "itineraries", value: number(itineraries.map(Double.init))),
        OrderedJSON.Member(key: "kind", value: .string("count")),
      ])
    }
  }

  private static func payload(_ payload: SearchRowPayload) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    func add(_ key: String, value: OrderedJSON?) {
      if let value {
        members.append(OrderedJSON.Member(key: key, value: value))
      }
    }
    switch payload {
    case .place(let point, let bounds):
      add("bounds", value: bounds.map(GeoFixtures.numbers))
      add("kind", value: .string("place"))
      add("point", value: GeoFixtures.numbers(point))
    case .poi(let point, let category):
      add("category", value: category.map { .string($0.rawValue) })
      add("kind", value: .string("poi"))
      add("point", value: GeoFixtures.numbers(point))
    case .way(let anchor, let bounds, let coordinates):
      add("anchor", value: GeoFixtures.numbers(anchor))
      add("bounds", value: bounds.map(GeoFixtures.numbers))
      add("coordinates", value: coordinates.map { .array($0.map(GeoFixtures.numbers)) })
      add("kind", value: .string("way"))
    case .itinerary(let id, let bounds, let start):
      add("bounds", value: bounds.map(GeoFixtures.numbers))
      add("itineraryId", value: .string(id))
      add("kind", value: .string("itinerary"))
      add("start", value: start.map(GeoFixtures.numbers))
    case .collection(let id, let name, let description, let isPrivate):
      add("collectionId", value: .string(id))
      add("description", value: text(description))
      add("isPrivate", value: isPrivate.map(OrderedJSON.bool) ?? .null)
      add("kind", value: .string("collection"))
      add("name", value: text(name))
    case .zone(let id, let point, let bounds):
      add("bounds", value: bounds.map(GeoFixtures.numbers))
      add("kind", value: .string("zone"))
      add("point", value: point.map(GeoFixtures.numbers))
      add("zoneId", value: .string(id))
    }
    return .object(members)
  }
}
