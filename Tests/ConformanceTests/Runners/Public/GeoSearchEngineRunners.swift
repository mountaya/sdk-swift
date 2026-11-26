import GateSupport
import MountayaClient
import MountayaGeo

extension PublicRunners {
  /// searchSectionOrder plays the case's script (`GeoSearchScripts`). The order the sections render
  /// in is held to `searchSectionOrder`, which is also the branches a search asks where none are
  /// listed, and the filters a list offers to `SearchFilter`'s cases, in order.
  static let searchSectionOrder = Runner(id: "geo.search.section-order", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants(
      [:],
      values: [
        "sectionOrder": GeoFixtures.texts(
          MountayaGeo.searchSectionOrder.map { $0.rawValue.lowercased() }),
        "filters": GeoFixtures.texts(SearchFilter.allCases.map(\.id)),
      ])
    return try await playSearch(fixtureCase.input)
  }

  /// searchTypingPause plays the case's script, the typing pause held to `searchTypingPause`.
  static let searchTypingPause = Runner(id: "geo.search.typing-pause", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "typingPauseMs": GeoSearchEngineFixtures.milliseconds(MountayaGeo.searchTypingPause)
    ])
    return try await playSearch(fixtureCase.input)
  }

  /// searchLiveRound plays the case's script.
  static let searchLiveRound = Runner(id: "geo.search.live-round", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    return try await playSearch(fixtureCase.input)
  }

  /// searchBroaden plays the case's script.
  static let searchBroaden = Runner(id: "geo.search.broaden", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([:])
    return try await playSearch(fixtureCase.input)
  }

  /// searchViewportRefresh plays the case's script, the pause after the camera rests held to
  /// `searchViewportRefreshPause`.
  static let searchViewportRefresh = Runner(id: "geo.search.viewport-refresh", table: .public) {
    fixture, fixtureCase in
    try fixture.holdConstants([
      "viewportRefreshMs": GeoSearchEngineFixtures.milliseconds(searchViewportRefreshPause)
    ])
    return try await playSearch(fixtureCase.input)
  }

  /// searchDescribe answers the second line of the case's `entity` of its `kind`, read by the Data
  /// API's own decoder, worded by its `wording`: `words`, the reader's word for a wire value by its
  /// kind and its value, and `units`, the reader's unit preferences. The elevation floor and the
  /// separator are read back through the line itself: an elevation at the floor stated and one
  /// just under it, and the text between two tokens.
  static let searchDescribe = Runner(id: "geo.search.describe", table: .public) {
    fixture, fixtureCase in
    let floor = try (fixture.constants ?? .null).number(at: "elevationFloorMeters")
    try fixture.holdConstants(
      ["elevationFloorMeters": GeoSearchEngineFixtures.elevationFloor(stated: floor)],
      values: ["separator": .string(GeoSearchEngineFixtures.separator())])
    let input = fixtureCase.input
    guard let entity = input["entity"] else {
      throw FixtureError(description: "the case has no `entity`")
    }
    let wording = try GeoSearchEngineFixtures.wording(input["wording"])
    switch try input.string(at: "kind") {
    case "place":
      return .value(
        .string(
          describePlace(
            try GeoFixtures.decoded(DataSchema.Place.self, from: entity), wording: wording)))
    case "poi":
      return .value(
        .string(
          describePoi(try GeoFixtures.decoded(DataSchema.POI.self, from: entity), wording: wording)
        ))
    case "way":
      return .value(
        .string(
          describeWay(try GeoFixtures.decoded(DataSchema.Way.self, from: entity), wording: wording)
        ))
    case let kind:
      throw FixtureError(description: "`\(kind)` is no kind of result a line describes")
    }
  }

  /// playSearch plays an engine fixture's script on time the script moves.
  private static func playSearch(_ input: OrderedJSON) async throws -> RunnerOutcome {
    let script = try GeoSearchScripts.script(input)
    return try await GeoSearchScripts.play(script).outcome
  }
}

/// GeoSearchEngineFixtures reads what the search's rule fixtures write into the SDK's values.
enum GeoSearchEngineFixtures {
  /// milliseconds is a pause as the fixtures state one, in milliseconds.
  static func milliseconds(_ duration: Duration) -> Double {
    let (seconds, attoseconds) = duration.components
    return Double(seconds) * 1000 + Double(attoseconds) / 1e15
  }

  /// hut is a hut of no name `distance` meters away at `elevation` meters, titled by what it is.
  private static func hut(elevation: Double, distance: Double) -> DataSchema.POI {
    DataSchema.POI {
      $0.category = .hut
      $0.distanceMeters = distance
      $0.elevation = elevation
      $0.name = ""
      $0.osm = DataSchema.OSMRef {
        $0.id = "1"
        $0.type = .node
      }
      $0.point = [6.85, 45.85]
    }
  }

  /// elevationFloor is the floor `stated` where the line states an elevation at it and gives a
  /// hut just under it its distance in its place, which is the floor the rule holds, and `NaN`,
  /// which no fixture states, otherwise.
  static func elevationFloor(stated: Double) -> Double {
    let at = describePoi(hut(elevation: stated, distance: 2000))
    let under = describePoi(hut(elevation: stated - 1, distance: 2000))
    return at == "\(Int(stated)) m" && under == "2.0 km" ? stated : .nan
  }

  /// separator is the text the line writes between two tokens: a path's word and its region.
  static func separator() -> String {
    let line = describeWay(
      DataSchema.Way {
        $0.highway = "path"
        $0.name = "X"
        $0.osm = DataSchema.OSMRef {
          $0.id = "1"
          $0.type = .node
        }
        $0.point = [6.85, 45.85]
        $0.region = "Valais"
      })
    guard line.hasPrefix("Path"), line.hasSuffix("Valais") else { return line }
    return String(line.dropFirst("Path".count).dropLast("Valais".count))
  }

  /// wording reads a case's `wording`, none where it states none: `words` by kind and value, which
  /// the resolver answers, and `units`, English and metric where they leave one out.
  static func wording(_ written: OrderedJSON?) throws(FixtureError) -> SearchWording {
    guard let written, !written.isNull else { return SearchWording() }
    var units: UnitPreferences?
    if let stated = written["units"], !stated.isNull {
      units = UnitPreferences(
        language: try stated.optionalString(at: "language") ?? "en",
        length: RestSchema.UnitLength(rawValue: try stated.optionalString(at: "length") ?? "metric")
      )
    }
    var words: [String: [String: String]] = [:]
    for kind in written["words"]?.members ?? [] {
      var values: [String: String] = [:]
      for value in kind.value.members ?? [] {
        guard let word = value.value.stringValue else {
          throw FixtureError(description: "the word for `\(value.key)` is not a string")
        }
        values[value.key] = word
      }
      words[kind.key] = values
    }
    let resolved = words
    return SearchWording(
      units: units,
      resolveLabel: { label in
        switch label {
        case .placeCategory(let category): resolved["placeCategory"]?[category.rawValue]
        case .poiCategory(let category): resolved["poiCategory"]?[category.rawValue]
        case .highway(let tag): resolved["highway"]?[tag]
        case .sacScale(let grade): resolved["sacScale"]?[grade]
        case .surface(let tag): resolved["surface"]?[tag]
        }
      })
  }
}
