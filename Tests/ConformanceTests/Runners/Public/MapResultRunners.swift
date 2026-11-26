import Foundation
import GateSupport
import MountayaClient
import MountayaElements
import MountayaGeo

extension PublicRunners {
  /// mapAnalysisSlots answers which Data API results a map draws after each step, through the
  /// engine: `add` is the kind's add of a result handed over as it is, `pois` is
  /// `setPointsOfInterest(_:fit:)` of one, `remove` is `removeAnalysis(_:)` of the result added
  /// under its `name`, a name nothing was added under being an id nothing is drawn under, or of the
  /// `id` it names, and `clear` is the kind's clear. A result a step names nothing for is named by
  /// the id it is drawn under. Each result is read off the GeoJSON source the state draws it from,
  /// `mountaya-` then its id, as the index of each feature it draws.
  static let mapAnalysisSlots = Runner(id: "map.analysis.slots", table: .public) {
    _, fixtureCase in
    let steps = try fixtureCase.input.array(at: "steps")
    return try await MapResultScripts.slots(steps)
  }

  /// mapAnalysisEdit answers how an edit of a drawn result asks again, over a client that answers
  /// every query at once: isochrones with a band per value of the query's `range`, and suggestions
  /// with three candidates. `add` draws from `input`, which it asks for, or from `result`, handed
  /// over; `edit` is the kind's edit with a patch applying the members the case's `patch` states to
  /// the input held, the members it names `unstated` left as held, `{}` being no patch at all, and
  /// the draw options it states. `queries` is each query the client was asked, read off the full
  /// document each sends after its persisted digest is refused.
  static let mapAnalysisEdit = Runner(id: "map.analysis.edit", table: .public) {
    _, fixtureCase in
    guard #available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *) else {
      throw Unsimulated()
    }
    return try await MapResultScripts.edit(try fixtureCase.input.array(at: "steps"))
  }

  /// mapGeometrySlots answers what each geometry slot holds after each step, through the engine:
  /// `set` is `setGeometry(_:in:color:)`, `edit` `editGeometry(in:geometry:color:)` and `clear`
  /// `clearGeometry(in:)`. The answer is `geometry(in:)` of each slot, which the runner holds to
  /// what the state draws for it: the slot's source holding its geometry, and its line in its
  /// colour, or nothing where it holds none.
  static let mapGeometrySlots = Runner(id: "map.geometry.slots", table: .public) {
    _, fixtureCase in
    let steps = try fixtureCase.input.array(at: "steps")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      var answers: [OrderedJSON] = []
      for step in steps {
        guard let slot = GeometrySlot(rawValue: try step.string(at: "slot")) else {
          throw FixtureError(description: "no slot is called `\(step["slot"] ?? .null)`")
        }
        let geometry = try step["geometry"].map { written throws(FixtureError) in
          written.isNull ? nil : try GeoFixtures.geometry(written)
        }
        let color = try step.optionalString(at: "color")
        switch try step.string(at: "step") {
        case "set":
          map.setGeometry(geometry ?? nil, in: slot, color: color)
        case "edit":
          map.editGeometry(in: slot, geometry: geometry ?? nil, color: color)
        case "clear":
          map.clearGeometry(in: slot)
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
        var held: [OrderedJSON.Member] = []
        for slot in GeometrySlot.allCases.sorted(by: { $0.rawValue < $1.rawValue }) {
          let holds = map.geometry(in: slot)
          try MapResultScripts.holdDrawn(holds, in: slot, map: map)
          held.append(
            OrderedJSON.Member(
              key: slot.rawValue,
              value: .object([
                OrderedJSON.Member(key: "color", value: .string(holds.color)),
                OrderedJSON.Member(
                  key: "geometry", value: holds.geometry.map(GeoFixtures.written) ?? .null),
              ])))
        }
        answers.append(.object(held))
      }
      return .value(.array(answers))
    }
  }

  /// mapMarkerLifecycle answers which markers a map pins after each step, through the engine:
  /// `add` is `addMarker(_:)`, `edit` `editMarker(_:position:color:glyph:label:)` with each member
  /// the patch states, the ones it names `unstated` left nil as a Swift caller leaves a member it
  /// does not change, and `remove` `removeMarker(_:)`. The markers are the state's, bottom first.
  static let mapMarkerLifecycle = Runner(id: "map.marker.lifecycle", table: .public) {
    _, fixtureCase in
    let steps = try fixtureCase.input.array(at: "steps")
    return try await MainActor.run { () throws -> RunnerOutcome in
      let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
      var answers: [OrderedJSON] = []
      for step in steps {
        var refused: OrderedJSON = .null
        let change = try MapResultScripts.markerChange(step)
        do throws(MapError) {
          switch change {
          case .add(let marker): try map.addMarker(marker)
          case .edit(let id, let position, let color, let glyph, let label):
            try map.editMarker(id, position: position, color: color, glyph: glyph, label: label)
          case .remove(let id): map.removeMarker(id)
          }
        } catch {
          refused = .string(MapFixtures.kind(error))
        }
        answers.append(
          .object([
            OrderedJSON.Member(
              key: "markers",
              value: .array(
                map.state.markers.map { marker in
                  .object([
                    OrderedJSON.Member(
                      key: "color", value: marker.color.map { .string($0) } ?? .null),
                    OrderedJSON.Member(
                      key: "glyph", value: marker.glyph.map { .string($0) } ?? .null),
                    OrderedJSON.Member(key: "id", value: .string(marker.id)),
                    OrderedJSON.Member(
                      key: "label", value: marker.label.map { .string($0) } ?? .null),
                    OrderedJSON.Member(key: "lngLat", value: GeoFixtures.numbers(marker.position)),
                  ])
                })),
            OrderedJSON.Member(key: "refused", value: refused),
          ]))
      }
      return .value(.array(answers))
    }
  }
}

/// MapResultScripts plays the Data API result scripts of the map's fixtures on the main actor,
/// where the engine runs.
@MainActor
enum MapResultScripts {
  /// MarkerChange is one step of `map.marker.lifecycle`, as a Swift caller makes it.
  enum MarkerChange {
    case add(MapMarker)
    case edit(
      String, position: [Double]?, color: String?, glyph: String?, label: String?)
    case remove(String)
  }

  /// markerChange reads a step of `map.marker.lifecycle`: an edit states each member its patch
  /// writes, the ones it names `unstated` left nil as a Swift caller leaves a member it keeps.
  static func markerChange(_ step: OrderedJSON) throws(FixtureError) -> MarkerChange {
    switch try step.string(at: "step") {
    case "add":
      let marker = step["marker"] ?? .null
      return .add(
        MapMarker(
          id: try marker.string(at: "id"), position: try marker.numbers(at: "lngLat"),
          color: try marker.optionalString(at: "color"),
          glyph: try marker.optionalString(at: "glyph"),
          label: try marker.optionalString(at: "label")))
    case "edit":
      let patch = step["patch"] ?? .null
      let unstated = Set(
        step["unstated"] == nil ? [] : try GeoFixtures.textList(step, at: "unstated"))
      func stated(_ member: String) throws(FixtureError) -> String? {
        unstated.contains(member) ? nil : try patch.optionalString(at: member)
      }
      return .edit(
        try step.string(at: "id"),
        position: patch["lngLat"] == nil || unstated.contains("lngLat")
          ? nil : try patch.numbers(at: "lngLat"),
        color: try stated("color"), glyph: try stated("glyph"), label: try stated("label"))
    case "remove":
      return .remove(try step.string(at: "id"))
    case let other:
      throw FixtureError(description: "no step is called `\(other)`")
    }
  }

  /// Outcomes is what each call of a script came to, in the order the calls were made.
  @MainActor
  final class Outcomes {
    var values: [String] = []
  }

  /// holdDrawn holds what the state draws for a geometry slot to what it holds: its source's one
  /// feature its geometry and its line its colour, or neither where it holds no geometry.
  static func holdDrawn(_ held: SlotGeometry, in slot: GeometrySlot, map: MapEngine)
    throws(FixtureError)
  {
    let source = map.state.sources.first { $0.id == "mountaya-\(slot.rawValue)" }
    let line = map.state.layers.first { $0.id == "mountaya-\(slot.rawValue)-line" }
    guard let geometry = held.geometry else {
      guard source == nil, line == nil else {
        throw FixtureError(description: "the \(slot) holds no geometry and draws one")
      }
      return
    }
    guard case .geoJson(let drawn)? = source?.kind, drawn.features.count == 1,
      let feature = drawn.features.first?.geometry, sameGeometry(feature, geometry),
      line?.paint["line-color"] == .string(held.color)
    else {
      throw FixtureError(description: "the \(slot) draws other than it holds")
    }
  }

  /// slots plays `map.analysis.slots`'s steps.
  static func slots(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let map = MapEngine(client: try MapFixtures.client(), geolocation: InertGeolocation())
    var ids: [(name: String, id: String)] = []
    var answers: [OrderedJSON] = []
    for step in steps {
      switch try step.string(at: "step") {
      case "add":
        let id = try await add(
          try step.string(at: "kind"), result: step["result"] ?? .null, on: map)
        ids.append((try step.optionalString(at: "name") ?? id, id))
      case "pois":
        try await map.setPointsOfInterest(
          GeoFixtures.decoded(DataSchema.PoisResult.self, from: step["result"] ?? .null))
        ids.removeAll { $0.id == MapEngine.poisAnalysisId }
        ids.append(
          (
            try step.optionalString(at: "name") ?? MapEngine.poisAnalysisId,
            MapEngine.poisAnalysisId
          ))
      case "remove":
        if let id = try step.optionalString(at: "id") {
          map.removeAnalysis(id)
        } else {
          let name = try step.string(at: "name")
          map.removeAnalysis(ids.last { $0.name == name }?.id ?? "analysis:none:0")
        }
      case "clear":
        try clear(try step.string(at: "kind"), on: map)
      case let other:
        throw FixtureError(description: "no step is called `\(other)`")
      }
      answers.append(
        try drawn(ids, on: map) { features in
          .array(
            features.map { $0.properties[featureIndexProperty].map(GeoFixtures.ordered) ?? .null })
        })
    }
    return .value(.array(answers))
  }

  /// edit plays `map.analysis.edit`'s steps.
  @available(macOS 15, iOS 18, tvOS 18, watchOS 11, visionOS 2, *)
  static func edit(_ steps: [OrderedJSON]) async throws -> RunnerOutcome {
    let exchange = MapFixtures.Queries(holding: false)
    let map = MapEngine(
      client: try MapFixtures.client(exchange: exchange), geolocation: InertGeolocation())
    var ids: [(name: String, id: String)] = []
    var refused: [OrderedJSON] = []
    for step in steps {
      do {
        switch try step.string(at: "step") {
        case "add":
          let name = try step.string(at: "name")
          let kind = try step.string(at: "kind")
          let id: String
          if let input = step["input"] {
            id = try await add(kind, input: input, on: map)
          } else {
            id = try await add(kind, result: step["result"] ?? .null, on: map)
          }
          ids.append((name, id))
        case "edit":
          let name = try step.string(at: "name")
          let id = ids.last { $0.name == name }?.id ?? "analysis:none:0"
          let patch = step["patch"] ?? .object([])
          let unstated = Set(
            step["unstated"] == nil ? [] : try GeoFixtures.textList(step, at: "unstated"))
          try await editAnalysis(
            try step.string(at: "kind"), id: id, patch: patch, unstated: unstated,
            options: step["options"], on: map)
        case let other:
          throw FixtureError(description: "no step is called `\(other)`")
        }
        refused.append(.null)
      } catch let error as MapError {
        refused.append(.string(MapFixtures.kind(error)))
      }
      await MainQueue.settle {
        [exchange.progress, .array(map.state.layers.map { .string($0.id) })]
      }
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "drawn", value: try marks(ids, on: map)),
        OrderedJSON.Member(key: "queries", value: .array(exchange.queries.map(\.written))),
        OrderedJSON.Member(key: "refused", value: .array(refused)),
      ]))
  }

  /// add draws a result of `kind` handed over as the fixture writes it, and answers its id.
  static func add(_ kind: String, result: OrderedJSON, on map: MapEngine) async throws -> String {
    switch kind {
    case "directions":
      return try await map.addDirections(
        GeoFixtures.decoded(DataSchema.DirectionsResult.self, from: result)
      ).id
    case "suggestions":
      return try await map.addSuggestions(
        GeoFixtures.decoded(DataSchema.SuggestionsResult.self, from: result)
      ).id
    case "isochrones":
      return try await map.addIsochrones(
        GeoFixtures.decoded(DataSchema.IsochronesResult.self, from: result)
      ).id
    case "places":
      return try await map.addPlaces(
        GeoFixtures.decoded(DataSchema.GeocodeResult.self, from: result)
      ).id
    default:
      throw FixtureError(description: "no result of kind `\(kind)` is drawn as handed over")
    }
  }

  /// add asks for a result of `kind` with the input the fixture writes, and answers its id.
  static func add(_ kind: String, input: OrderedJSON, on map: MapEngine) async throws -> String {
    switch kind {
    case "isochrones":
      return try await map.addIsochrones(
        GeoFixtures.decoded(DataSchema.IsochronesInput.self, from: input)
      ).id
    case "suggestions":
      return try await map.addSuggestions(
        GeoFixtures.decoded(DataSchema.SuggestionsInput.self, from: input)
      ).id
    case "directions":
      return try await map.addDirections(
        GeoFixtures.decoded(DataSchema.DirectionsInput.self, from: input)
      ).id
    default:
      throw FixtureError(description: "no result of kind `\(kind)` is asked for")
    }
  }

  /// editAnalysis edits the result `id` through the edit of `kind`: no patch where the case's
  /// patch states no member, else one writing each member it states onto the input held, through
  /// the input's own encoding, and the draw options the case states.
  static func editAnalysis(
    _ kind: String, id: String, patch: OrderedJSON, unstated: Set<String>, options: OrderedJSON?,
    on map: MapEngine
  ) async throws {
    let stated = (patch.members ?? []).filter { !unstated.contains($0.key) }
    let chosen = try options?.optionalInteger(at: "chosen")
    switch kind {
    case "isochrones":
      _ = try await map.editIsochrones(
        id, patch: try patched(stated, of: DataSchema.IsochronesInput.self))
    case "suggestions":
      _ = try await map.editSuggestions(
        id, patch: try patched(stated, of: DataSchema.SuggestionsInput.self), chosen: chosen)
    case "directions":
      _ = try await map.editDirections(
        id, patch: try patched(stated, of: DataSchema.DirectionsInput.self))
    default:
      throw FixtureError(description: "no result of kind `\(kind)` is edited")
    }
  }

  /// patched is a patch writing each of `stated` onto an input of `type`, through the input's own
  /// encoding, or nil where it states no member.
  nonisolated static func patched<Input: Codable & Sendable>(
    _ stated: [OrderedJSON.Member], of type: Input.Type
  )
    throws(FixtureError) -> (@Sendable (inout Input) -> Void)?
  {
    guard !stated.isEmpty else { return nil }
    return { input in
      guard let encoded = try? JSONEncoder().encode(input),
        let written = try? OrderedJSON.parse(String(decoding: encoded, as: UTF8.self)),
        var members = written.members
      else { return }
      for member in stated {
        members.removeAll { $0.key == member.key }
        members.append(member)
      }
      if let merged = try? JSONDecoder().decode(
        Input.self, from: Data(OrderedJSON.object(members).serialized().utf8))
      {
        input = merged
      }
    }
  }

  /// clear clears every result of `kind`.
  static func clear(_ kind: String, on map: MapEngine) throws(FixtureError) {
    switch kind {
    case "directions": map.clearDirections()
    case "suggestions": map.clearSuggestions()
    case "isochrones": map.clearIsochrones()
    case "places": map.clearPlaces()
    case "matrix": map.clearMatrix()
    case "pois": map.clearPointsOfInterest()
    default: throw FixtureError(description: "no kind `\(kind)` is cleared")
    }
  }

  /// drawn writes each result drawn, by the name it was added under, as `write` reads the features
  /// its source draws.
  static func drawn(
    _ ids: [(name: String, id: String)], on map: MapEngine,
    write: ([GeoJSONFeature]) -> OrderedJSON
  ) throws(FixtureError) -> OrderedJSON {
    var members: [OrderedJSON.Member] = []
    for source in map.state.sources {
      guard let name = ids.last(where: { "mountaya-\($0.id)" == source.id })?.name else {
        throw FixtureError(description: "the map draws `\(source.id)`, which no step drew")
      }
      guard case .geoJson(let features) = source.kind else {
        throw FixtureError(description: "`\(source.id)` is no GeoJSON")
      }
      members.append(OrderedJSON.Member(key: name, value: write(features.features)))
    }
    return .object(members)
  }

  /// marks writes what each named result draws: an isochrone band's value, or whether a suggested
  /// candidate is the one chosen.
  static func marks(_ ids: [(name: String, id: String)], on map: MapEngine) throws(FixtureError)
    -> OrderedJSON
  {
    try drawn(ids, on: map) { features in
      .array(
        features.map { feature in
          let kind = feature.properties[featureKindProperty]
          let mark =
            kind == .string("suggestion")
            ? feature.properties["chosen"] : feature.properties["value"]
          return mark.map(GeoFixtures.ordered) ?? .null
        })
    }
  }
}

extension MapFixtures {
  /// Queries is an exchange answering the Data API's queries: a query sent with its persisted
  /// digest alone is refused at once, as the protocol asks, and one sending its full document is
  /// recorded, then answered at once or held until a step answers it, isochrones with a band per
  /// value of the query's `range`, each band's value that value, suggestions with three candidates
  /// and directions with one route. A query held fails with `CancellationError` the moment its task
  /// is cancelled, which it records.
  @MainActor
  final class Queries: HTTPExchange {
    /// Query is one query sent with its full document.
    struct Query {
      let kind: String
      let input: OrderedJSON
      var answer: CheckedContinuation<ExchangeResponse, any Error>?
      var cancelled = false

      /// written is the query as the fixtures write one, `{kind, input}`.
      var written: OrderedJSON {
        .object([
          OrderedJSON.Member(key: "input", value: input),
          OrderedJSON.Member(key: "kind", value: .string(kind)),
        ])
      }
    }

    let holding: Bool
    private(set) var queries: [Query] = []

    init(holding: Bool) {
      self.holding = holding
    }

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      let body = try request.body.map { try OrderedJSON.parse(String(decoding: $0, as: UTF8.self)) }
      guard let document = body?["query"]?.stringValue else {
        return Self.answer(
          #"{"errors": [{"message": "PersistedQueryNotFound", "extensions": {"code": "PERSISTED_QUERY_NOT_FOUND"}}]}"#
        )
      }
      let kind = Self.kind(of: document)
      let input = body?["variables"]?["input"] ?? .null
      let index = queries.count
      queries.append(Query(kind: kind, input: input))
      guard holding else { return Self.answer(Self.answered(kind, input: input)) }
      return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          queries[index].answer = continuation
        }
      } onCancel: {
        Task { @MainActor in self.cancel(index) }
      }
    }

    /// answer lets the held query `index` answer, where it is still held.
    func answer(_ index: Int) {
      guard queries.indices.contains(index), let answer = queries[index].answer else { return }
      queries[index].answer = nil
      answer.resume(
        returning: Self.answer(Self.answered(queries[index].kind, input: queries[index].input)))
    }

    /// progress is what a script reads of the exchange to know a step has come to rest: every query
    /// sent, those still held and those withdrawn.
    var progress: OrderedJSON {
      .array(
        queries.map(\.written) + [
          .number(Double(queries.filter { $0.answer != nil }.count)),
          .number(Double(queries.filter(\.cancelled).count)),
        ])
    }

    /// release fails every query still held, as a script ends.
    func release() {
      for index in queries.indices {
        if let answer = queries[index].answer {
          queries[index].answer = nil
          answer.resume(throwing: CancellationError())
        }
      }
    }

    private func cancel(_ index: Int) {
      queries[index].cancelled = true
      guard let answer = queries[index].answer else { return }
      queries[index].answer = nil
      answer.resume(throwing: CancellationError())
    }

    /// kind reads the kind a document asks for off its operation's name, `Isochrones` reading as
    /// `isochrones` and `Geocode` as `places`.
    static func kind(of document: String) -> String {
      let words = document.split(whereSeparator: { !$0.isLetter })
      guard let index = words.firstIndex(of: "query"), words.indices.contains(index + 1) else {
        return ""
      }
      let operation = words[index + 1].lowercased()
      return operation == "geocode" ? "places" : operation
    }

    /// answered is the body a query of `kind` is answered with.
    static func answered(_ kind: String, input: OrderedJSON) -> String {
      func route(_ seed: Int) -> String {
        #"{"distance": 1000, "duration": 600, "geometry": {"coordinates": [[6.86, 45.83], [6.9, 45.9]], "type": "LineString"}, "summary": "Route \#(seed)"}"#
      }
      let center = input["locations"]?.elements?.first?.serialized() ?? "[6.86, 45.83]"
      switch kind {
      case "isochrones":
        let bands = (input["range"]?.elements ?? []).map { value in
          #"{"area": 1, "center": \#(center), "geometry": {"coordinates": [[[6.85, 45.82], [6.87, 45.82], [6.87, 45.84], [6.85, 45.82]]], "type": "Polygon"}, "reachFactor": 1, "value": \#(value.serialized())}"#
        }
        return #"{"data": {"isochrones": {"isochrones": [\#(bands.joined(separator: ","))]}}}"#
      case "suggestions":
        return #"{"data": {"suggestions": {"routes": [\#(route(0)), \#(route(1)), \#(route(2))]}}}"#
      default:
        return #"{"data": {"directions": {"routes": [\#(route(0))]}}}"#
      }
    }

    private static func answer(_ text: String) -> ExchangeResponse {
      ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(text.utf8)))
    }
  }
}
