import GateSupport
import MountayaClient

@testable import MountayaGeo

extension InternalRunners {
  /// searchFocus answers what the one request of a round of one branch sends, `focus` and `bbox`,
  /// each null where it sends none, for a search reading the case's `camera` and confined where its
  /// `scoped` says so, through the engine's own round. The point a round is ranked around is held
  /// to the internal rule besides.
  static let searchFocus = Runner(id: "geo.search.focus", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    let camera = try GeoSearchScripts.camera(input["camera"])
    let script = GeoSearchScripts.Script(
      targets: [.places], query: "chamonix", pause: .zero, camera: camera,
      isConfined: try input.flag(at: "scoped"))
    let played = try await GeoSearchScripts.play(script)
    guard played.requests.count == 1, let request = played.requests.first?["input"] else {
      throw FixtureError(description: "a round of one branch sent \(played.requests.count)")
    }
    let focus = request["focus"] ?? .null
    let ruled = camera.flatMap { MountayaGeo.searchFocus($0.center) }
    guard
      Comparison.mismatches(
        actual: focus, expected: ruled.map(GeoFixtures.numbers) ?? .null, tolerance: nil
      ).isEmpty
    else {
      throw FixtureError(description: "the round sent another focus than the rule answers")
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "bbox", value: request["bbox"] ?? .null),
        OrderedJSON.Member(key: "focus", value: focus),
      ]))
  }

  /// searchListState answers what a list shows of the case's `snapshot` under its `filter`: each
  /// section of its `rows`, titled as named, standing as its `state` says, a failed one holding the
  /// failure the API reports.
  static let searchListState = Runner(id: "geo.search.list-state", table: .internal) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    let input = fixtureCase.input
    guard let filter = SearchFilter(rawValue: try input.string(at: "filter")) else {
      throw FixtureError(description: "the case's `filter` is no filter")
    }
    guard let written = input["snapshot"] else {
      throw FixtureError(description: "the case has no `snapshot`")
    }
    var sections: [SearchSection] = []
    for section in try written.array(at: "sections") {
      let branch = GeoSearchScripts.branch(try section.string(at: "id"))
      let state: SearchSectionState
      switch try section.string(at: "state") {
      case "loading": state = .loading
      case "settled": state = .settled
      case "error": state = .failed(SearchBranchError(target: branch))
      case let other: throw FixtureError(description: "`\(other)` is no state of a section")
      }
      let rows = try GeoFixtures.textList(section, at: "rows").enumerated().map { index, title in
        SearchRow(
          id: "\(branch.rawValue):\(index)", title: title, matched: [], secondary: nil,
          activities: [],
          payload: .itinerary(itineraryId: "\(branch.rawValue)-\(index)", bounds: nil, start: nil))
      }
      sections.append(SearchSection(id: branch, state: state, rows: rows))
    }
    let snapshot = SearchSnapshot(
      query: "chamonix", isSearching: try written.flag(at: "searching"),
      isSettled: try written.flag(at: "settled"), hasFallenBack: try written.flag(at: "fallback"),
      sections: sections)
    let shown = MountayaGeo.searchListState(snapshot, filter: filter)
    let status: OrderedJSON
    switch shown.status {
    case nil:
      status = .null
    case .resultCount(let count)?:
      status = .object([
        OrderedJSON.Member(key: "count", value: .number(Double(count))),
        OrderedJSON.Member(key: "key", value: .string("resultCount")),
      ])
    case let other?:
      status = .object([OrderedJSON.Member(key: "key", value: .string(other.key))])
    }
    return .value(
      .object([
        OrderedJSON.Member(
          key: "failed",
          value: GeoFixtures.texts(shown.failed.map { $0.id.rawValue.lowercased() })),
        OrderedJSON.Member(key: "fallbackNote", value: .bool(shown.hasFallbackNote)),
        OrderedJSON.Member(key: "nothingFound", value: .bool(shown.isNothingFound)),
        OrderedJSON.Member(key: "rows", value: GeoFixtures.texts(shown.rows.map(\.title))),
        OrderedJSON.Member(key: "status", value: status),
      ]))
  }

  /// searchPick answers what picking the case's `payload` does: how the camera moves and what the
  /// map's search highlight is handed, each null where nothing is, and a member the pick does not
  /// state absent. The zoom a point is flown to is held to `pointZoom`.
  static let searchPick = Runner(id: "geo.search.pick", table: .internal) { fixture, fixtureCase in
    try fixture.holdConstants(["pointZoom": pointZoom])
    guard let written = fixtureCase.input["payload"] else {
      throw FixtureError(description: "the case has no `payload`")
    }
    let pick = pickTarget(try GeoSearchPickFixtures.payload(written))
    return .value(
      .object([
        OrderedJSON.Member(
          key: "camera", value: pick.camera.map(GeoSearchPickFixtures.written) ?? .null),
        OrderedJSON.Member(
          key: "mark", value: pick.mark.map(GeoSearchPickFixtures.written) ?? .null),
      ]))
  }
}

/// GeoSearchPickFixtures reads a picked row's payload as `geo/search-pick.json` writes it, and
/// writes a pick back as the fixture expects it.
enum GeoSearchPickFixtures {
  /// payload reads a payload by its `kind`, each member it does not state nil.
  static func payload(_ written: OrderedJSON) throws(FixtureError) -> SearchRowPayload {
    func numbers(_ key: String) throws(FixtureError) -> [Double]? {
      guard let value = written[key], !value.isNull else { return nil }
      return try value.numberList(naming: key)
    }
    switch try written.string(at: "kind") {
    case "place":
      return .place(point: try written.numbers(at: "point"), bounds: try numbers("bounds"))
    case "poi":
      return .poi(
        point: try written.numbers(at: "point"),
        category: try written.optionalString(at: "category").map(
          DataSchema.POICategory.init(rawValue:)))
    case "way":
      return .way(
        anchor: try written.numbers(at: "anchor"), bounds: try numbers("bounds"),
        coordinates: written["coordinates"] == nil ? nil : try written.positions(at: "coordinates"))
    case "itinerary":
      return .itinerary(
        itineraryId: try written.string(at: "itineraryId"), bounds: try numbers("bounds"),
        start: try numbers("start"))
    case "zone":
      return .zone(
        zoneId: try written.string(at: "zoneId"), point: try numbers("point"),
        bounds: try numbers("bounds"))
    case "collection":
      return .collection(
        collectionId: try written.string(at: "collectionId"),
        name: try written.optionalString(at: "name"),
        description: try written.optionalString(at: "description"),
        isPrivate: written["isPrivate"]?.boolValue)
    case let kind:
      throw FixtureError(description: "`\(kind)` is no kind of payload")
    }
  }

  /// written writes a camera move as the fixture expects one.
  static func written(_ camera: SearchPickCamera) -> OrderedJSON {
    switch camera {
    case .fit(let bounds):
      return .object([
        OrderedJSON.Member(key: "bounds", value: GeoFixtures.numbers(bounds)),
        OrderedJSON.Member(key: "kind", value: .string("fit")),
      ])
    case .fly(let center, let zoom):
      return .object([
        OrderedJSON.Member(key: "center", value: GeoFixtures.numbers(center)),
        OrderedJSON.Member(key: "kind", value: .string("fly")),
        OrderedJSON.Member(key: "zoom", value: .number(zoom)),
      ])
    }
  }

  /// written writes a mark as the fixture expects one, a way's extent and line only where it
  /// states them.
  static func written(_ mark: SearchHighlight) -> OrderedJSON {
    switch mark {
    case .place(let point):
      return .object([
        OrderedJSON.Member(key: "kind", value: .string("place")),
        OrderedJSON.Member(key: "point", value: GeoFixtures.numbers(point)),
      ])
    case .poi(let point, let category):
      var members: [OrderedJSON.Member] = []
      if let category {
        members.append(OrderedJSON.Member(key: "category", value: .string(category.rawValue)))
      }
      members.append(OrderedJSON.Member(key: "kind", value: .string("poi")))
      members.append(OrderedJSON.Member(key: "point", value: GeoFixtures.numbers(point)))
      return .object(members)
    case .way(let anchor, let bounds, let coordinates):
      var members = [OrderedJSON.Member(key: "anchor", value: GeoFixtures.numbers(anchor))]
      if let bounds {
        members.append(OrderedJSON.Member(key: "bounds", value: GeoFixtures.numbers(bounds)))
      }
      if let coordinates {
        members.append(
          OrderedJSON.Member(
            key: "coordinates", value: .array(coordinates.map(GeoFixtures.numbers))))
      }
      members.append(OrderedJSON.Member(key: "kind", value: .string("way")))
      return .object(members)
    }
  }
}
