import Foundation
import GateSupport
import MountayaClient
import MountayaGeo

/// GeoSearchScripts plays the search engine's fixtures (`geo/search-section-order.json` and the
/// four beside it) on time the script moves, over a transport that holds every request until a
/// step settles it, and writes what the list shows as the fixtures write it.
///
/// The engine, its tasks and the transport all run on the main actor, the transport answering a
/// request as the engine sends it, so the requests are numbered in the order they leave, and each
/// step settles once what the list shows, the requests and the waits stand still (`Quiescence`),
/// waiting on no real time.
enum GeoSearchScripts {
  /// Script is a search an engine fixture builds and the steps it plays.
  struct Script {
    var targets: [DataSchema.SearchTarget]?
    var query: String?
    var pause: Duration?
    var limit: SearchLimit?
    var language: DataSchema.Language?
    var camera: MapViewport?
    var isConfined = false
    var isOpen = false
    /// handler is true where the search is built with a failure handler, whose case then expects
    /// `failed` and `handed`.
    var handler = false
    var steps: [OrderedJSON] = []
  }

  /// Played is what a script answers: every request sent, in order, as the fixtures write one, the
  /// requests abandoned while still open, and what the list showed once the search was built and
  /// after each step.
  struct Played {
    let requests: [OrderedJSON]
    let cancelled: [Int]
    let snapshots: [OrderedJSON]
    /// refused is true where the search could not be built, as the fixtures write a refusal.
    var refused = false
    /// failed is each section in error once the last step has played, its `id` and the `code` its
    /// failure holds, and handed each failure the handler was handed, as the code it holds; both
    /// nil where the search was built with no handler.
    var failed: [OrderedJSON]?
    var handed: [OrderedJSON]?

    /// outcome is the answer as the fixtures expect it.
    var outcome: RunnerOutcome {
      guard !refused else {
        return .value(.object([OrderedJSON.Member(key: "refused", value: .bool(true))]))
      }
      var members = [
        OrderedJSON.Member(key: "cancelled", value: .array(cancelled.map { .number(Double($0)) }))
      ]
      if let failed { members.append(OrderedJSON.Member(key: "failed", value: .array(failed))) }
      if let handed { members.append(OrderedJSON.Member(key: "handed", value: .array(handed))) }
      members += [
        OrderedJSON.Member(key: "requests", value: .array(requests)),
        OrderedJSON.Member(key: "snapshots", value: .array(snapshots)),
      ]
      return .value(.object(members))
    }
  }

  /// script reads an engine fixture's input: `targets`, `query`, `pause` in milliseconds, `limit`,
  /// `language`, `camera`, null and absent both a camera with nothing to read, `scoped`, `open`
  /// and `steps`.
  static func script(_ input: OrderedJSON) throws(FixtureError) -> Script {
    var script = Script()
    if input["targets"] != nil {
      script.targets = try GeoFixtures.textList(input, at: "targets").map(branch)
    }
    script.query = try input.optionalString(at: "query")
    script.pause = try input.optionalNumber(at: "pause").map { .milliseconds($0) }
    script.limit = try limit(input.optionalInteger(at: "limit"))
    script.language = try input.optionalString(at: "language").map(
      DataSchema.Language.init(rawValue:))
    script.camera = try camera(input["camera"])
    script.isConfined = try input.flag(at: "scoped")
    script.isOpen = try input.flag(at: "open")
    script.handler = try input.flag(at: "handler")
    script.steps = input["steps"] == nil ? [] : try input.array(at: "steps")
    return script
  }

  /// code is the code a failure holds as the fixtures write it: the Data API's where the API
  /// reported a branch failed, null for a failure that holds none, as a failed request's does here.
  static func code(of failure: any Error) -> OrderedJSON {
    (failure as? SearchBranchError)?.code.map { .string($0.rawValue) } ?? .null
  }

  /// branch reads a branch as the fixtures name it, the search input's member, `places`, into the
  /// target it upper-cases to.
  static func branch(_ name: String) -> DataSchema.SearchTarget {
    DataSchema.SearchTarget(rawValue: name.uppercased())
  }

  /// limit reads a cap a case states into the one a search takes, failing a case that states one
  /// no search takes.
  private static func limit(_ value: Int?) throws(FixtureError) -> SearchLimit? {
    guard let value else { return nil }
    guard let limit = SearchLimit(value) else {
      throw FixtureError(description: "the cap \(value) is no cap a search takes")
    }
    return limit
  }

  /// camera reads a camera a case writes, `{center, zoom}`, or none for null or no camera.
  static func camera(_ written: OrderedJSON?) throws(FixtureError) -> MapViewport? {
    guard let written, !written.isNull else { return nil }
    return MapViewport(
      center: try written.numbers(at: "center"), zoom: try written.number(at: "zoom"))
  }

  /// play builds the search `script` states and plays its steps, answering every request it sent,
  /// the requests it abandoned while they were open, and what the list showed once the search was
  /// built and after each step, or that the search was refused where its pause is no
  /// `SearchPause`. A step `together` plays the steps it holds in order as one step, settling only
  /// once they have all been played.
  @MainActor
  static func play(_ script: Script) async throws -> Played {
    let pause: SearchPause
    if let stated = script.pause {
      guard let built = SearchPause(stated) else {
        return Played(requests: [], cancelled: [], snapshots: [], refused: true)
      }
      pause = built
    } else {
      pause = .standard
    }
    let time = ManualTime()
    let transport = Transport()
    let handed = Handed()
    var onError: (@MainActor @Sendable (any Error) -> Void)?
    if script.handler {
      onError = { failure in handed.failures.append(GeoSearchScripts.code(of: failure)) }
    }
    var configuration = SearchConfiguration(
      fetch: transport.fetch, language: script.language, limit: script.limit,
      targets: script.targets ?? searchSectionOrder, onError: onError)
    let engine = SearchEngine(
      configuration: configuration, query: script.query ?? "", camera: script.camera,
      isOpen: script.isOpen, isConfined: script.isConfined, pause: pause, sleep: time.sleep)
    defer {
      engine.close()
      transport.release()
    }

    /// settle lets what a step set going come to rest: what the list shows, every request sent,
    /// open and abandoned, the waits the time holds and the failures handed over.
    func settle() async {
      await Quiescence.settle {
        Progress(
          shown: shown(engine.state, asked: transport.sent.count), open: transport.open,
          cancelled: transport.cancelled, deadlines: time.deadlines, handed: handed.failures)
      }
    }

    /// apply plays one step, a `together` step's held steps one after the other.
    func apply(_ step: OrderedJSON) async throws {
      switch try step.string(at: "step") {
      case "type":
        engine.setQuery(try step.string(at: "query"))
      case "wait":
        await time.advance(by: .milliseconds(try step.number(at: "ms")), settling: settle)
      case "answer":
        try transport.answer(
          try step.integer(at: "request"), names: try GeoFixtures.textList(step, at: "names"))
      case "fail":
        try transport.fail(try step.integer(at: "request"))
      case "report":
        try transport.report(
          try step.integer(at: "request"),
          code: DataSchema.ErrorCode(rawValue: try step.optionalString(at: "code") ?? "BAD_GATEWAY")
        )
      case "configure":
        configuration = try configured(configuration, by: step)
        engine.configure(configuration)
      case "scope":
        engine.setConfined(try step.flag(at: "scoped"))
      case "open":
        engine.setOpen(try step.flag(at: "open"))
      case "retry":
        engine.retry()
      case "move":
        engine.setCamera(try camera(step["camera"]))
      case "together":
        for held in try step.array(at: "steps") {
          try await apply(held)
        }
      case let other:
        throw FixtureError(description: "`\(other)` is no step")
      }
    }

    await settle()
    var snapshots = [shown(engine.state, asked: transport.sent.count)]
    for step in script.steps {
      try await apply(step)
      await settle()
      snapshots.append(shown(engine.state, asked: transport.sent.count))
    }
    var played = Played(
      requests: try transport.sent.map { try written($0.input) },
      cancelled: transport.cancelled.sorted(), snapshots: snapshots)
    if script.handler {
      played.failed = engine.state.sections.compactMap { section -> OrderedJSON? in
        guard let failure = section.state.failure else { return nil }
        return OrderedJSON.object([
          OrderedJSON.Member(key: "code", value: code(of: failure)),
          OrderedJSON.Member(key: "id", value: .string(section.id.rawValue.lowercased())),
        ])
      }
      played.handed = handed.failures
    }
    return played
  }

  /// Handed is every failure a search's handler was handed, as the code each holds.
  @MainActor
  final class Handed {
    var failures: [OrderedJSON] = []
  }

  /// Progress is what a script reads to know a step has come to rest.
  struct Progress: Equatable {
    let shown: OrderedJSON
    let open: [Int]
    let cancelled: Set<Int>
    let deadlines: [Duration]
    let handed: [OrderedJSON]
  }

  /// configured is `configuration` with the `language`, `limit`, `targets` or `units` a step states,
  /// every member it does not state as it was; `units` are a reader's unit preferences, English and
  /// metric where they leave one out.
  private static func configured(_ configuration: SearchConfiguration, by step: OrderedJSON)
    throws(FixtureError) -> SearchConfiguration
  {
    var next = configuration
    if step["language"] != nil {
      next.language = try step.optionalString(at: "language").map(
        DataSchema.Language.init(rawValue:))
    }
    if step["limit"] != nil {
      next.limit = try limit(step.optionalInteger(at: "limit"))
    }
    if step["targets"] != nil {
      next.targets = try GeoFixtures.textList(step, at: "targets").map(branch)
    }
    if let units = step["units"] {
      next.wording = SearchWording(
        units: UnitPreferences(
          language: try units.optionalString(at: "language") ?? "en",
          length: RestSchema.UnitLength(
            rawValue: try units.optionalString(at: "length") ?? "metric")),
        resolveLabel: configuration.wording.resolveLabel)
    }
    return next
  }

  /// shown writes what the list shows as the fixtures write a snapshot: the requests sent so far,
  /// the flags, and each section by its branch, its state and its rows by title.
  static func shown(_ snapshot: SearchSnapshot, asked: Int) -> OrderedJSON {
    .object([
      OrderedJSON.Member(key: "asked", value: .number(Double(asked))),
      OrderedJSON.Member(key: "fallback", value: .bool(snapshot.hasFallenBack)),
      OrderedJSON.Member(key: "query", value: .string(snapshot.query)),
      OrderedJSON.Member(key: "searching", value: .bool(snapshot.isSearching)),
      OrderedJSON.Member(
        key: "sections",
        value: .array(
          snapshot.sections.map { section in
            .object([
              OrderedJSON.Member(key: "id", value: .string(section.id.rawValue.lowercased())),
              OrderedJSON.Member(key: "rows", value: GeoFixtures.texts(section.rows.map(\.title))),
              OrderedJSON.Member(key: "state", value: .string(stateName(section.state))),
            ])
          })),
      OrderedJSON.Member(key: "settled", value: .bool(snapshot.isSettled)),
    ])
  }

  /// stateName is a section's state as the fixtures name it.
  static func stateName(_ state: SearchSectionState) -> String {
    switch state {
    case .loading: "loading"
    case .settled: "settled"
    case .failed: "error"
    }
  }

  /// written writes a request as the fixtures do, `{kind, input}`: the members it sends, through the
  /// Data API's own encoder, its `targets` holding the one branch it enables.
  static func written(_ input: DataSchema.SearchInput) throws -> OrderedJSON {
    let parsed = try OrderedJSON.parse(
      String(decoding: try JSONEncoder().encode(input), as: UTF8.self))
    guard let members = parsed.members else {
      throw FixtureError(description: "a search input that encodes as no object")
    }
    let sent = members.map { member -> OrderedJSON.Member in
      guard member.key == "targets" else { return member }
      return OrderedJSON.Member(
        key: "targets",
        value: .object((member.value.members ?? []).filter { $0.value.boolValue == true }))
    }
    return .object([
      OrderedJSON.Member(key: "input", value: .object(sent)),
      OrderedJSON.Member(key: "kind", value: .string("search")),
    ])
  }

  /// answer is what the Data API answers a request for `branch` with: one result per name of
  /// `names`, each titled by its name, or, where `reported`, the API reporting the branch failed.
  static func answer(
    for branch: DataSchema.SearchTarget, names: [String], reported: Bool,
    code: DataSchema.ErrorCode = .badGateway
  ) -> DataSchema.SearchResult {
    func osm(_ index: Int) -> DataSchema.OSMRef {
      DataSchema.OSMRef {
        $0.id = "\(index)"
        $0.key = "place"
        $0.type = .node
        $0.value = "city"
      }
    }
    let point = [6.87, 45.92]
    let named = Array(names.enumerated())
    return DataSchema.SearchResult {
      $0.errors =
        reported
        ? [
          DataSchema.SearchTargetError {
            $0.code = code
            $0.message = "\(branch.rawValue.lowercased()) failed"
            $0.target = branch
          }
        ] : []
      guard !reported else { return }
      switch branch.rawValue {
      case "PLACES":
        $0.places = DataSchema.GeocodeResult { result in
          result.places = named.map { index, name in
            DataSchema.Place {
              $0.category = .populatedPlace
              $0.label = ""
              $0.name = name
              $0.osm = osm(index)
              $0.point = point
            }
          }
        }
      case "POIS":
        $0.pois = DataSchema.PoisResult { result in
          result.pois = named.map { index, name in
            DataSchema.POI {
              $0.category = .hut
              $0.name = name
              $0.osm = osm(index)
              $0.point = point
            }
          }
        }
      case "WAYS":
        $0.ways = DataSchema.WaysResult { result in
          result.ways = named.map { index, name in
            DataSchema.Way {
              $0.activityCompatible = []
              $0.highway = "path"
              $0.name = name
              $0.osm = osm(index)
              $0.point = point
            }
          }
        }
      case "ITINERARIES":
        $0.itineraries = DataSchema.ItinerariesResult { result in
          result.count = names.count
          result.itineraries = named.map { index, name in
            DataSchema.ItinerarySearchResult {
              $0.id = "itinerary-\(index)"
              $0.name = name
            }
          }
        }
      case "COLLECTIONS":
        $0.collections = DataSchema.CollectionsResult { result in
          result.count = names.count
          result.collections = named.map { index, name in
            DataSchema.CollectionSearchResult {
              $0.id = "collection-\(index)"
              $0.name = name
            }
          }
        }
      case "ZONES":
        $0.zones = DataSchema.ZonesResult { result in
          result.count = names.count
          result.zones = named.map { index, name in
            DataSchema.ZoneSearchResult {
              $0.id = "zone-\(index)"
              $0.name = name
            }
          }
        }
      default:
        break
      }
    }
  }

  /// Transport is a search's transport that records every request and holds it open until a step
  /// answers it, fails it or reports its branch failed, and records each request the engine
  /// abandoned while it was still open. It is bound to the main actor, where the engine sends.
  @MainActor
  final class Transport {
    /// Held is one request sent: its input, the answer it waits for, and whether a step settled it.
    struct Held {
      let input: DataSchema.SearchInput
      var answer: CheckedContinuation<DataSchema.SearchResult, any Error>?
      var isDone = false
    }

    /// Failed is what a request a step fails throws.
    struct Failed: Error {}

    private(set) var sent: [Held] = []
    private(set) var cancelled: Set<Int> = []

    /// open is each request sent and not yet answered, failed or reported, by its number.
    var open: [Int] { sent.indices.filter { !sent[$0].isDone } }

    /// fetch is the transport as a search takes it, which runs on the main actor.
    var fetch: SearchFetch {
      { @MainActor input in try await self.request(input) }
    }

    /// request records `input` and holds it open until a step settles it.
    func request(_ input: DataSchema.SearchInput) async throws -> DataSchema.SearchResult {
      let index = sent.count
      sent.append(Held(input: input))
      return try await withTaskCancellationHandler {
        try await withCheckedThrowingContinuation { continuation in
          sent[index].answer = continuation
        }
      } onCancel: {
        Task { @MainActor in self.abandon(index) }
      }
    }

    /// abandon records that the engine abandoned the request `index`, where no step settled it.
    private func abandon(_ index: Int) {
      if !sent[index].isDone {
        cancelled.insert(index)
      }
    }

    /// answer answers the request `index` with one result per name of `names`.
    func answer(_ index: Int, names: [String]) throws(FixtureError) {
      let branch = try branch(of: index)
      try settle(index) {
        $0.resume(returning: GeoSearchScripts.answer(for: branch, names: names, reported: false))
      }
    }

    /// report answers the request `index` with the API reporting its branch failed with `code`.
    func report(_ index: Int, code: DataSchema.ErrorCode = .badGateway) throws(FixtureError) {
      let branch = try branch(of: index)
      try settle(index) {
        $0.resume(
          returning: GeoSearchScripts.answer(for: branch, names: [], reported: true, code: code))
      }
    }

    /// fail fails the request `index`.
    func fail(_ index: Int) throws(FixtureError) {
      try settle(index) { $0.resume(throwing: Failed()) }
    }

    /// release fails every request still open, so no task waits for ever once a case ends.
    func release() {
      for index in sent.indices {
        sent[index].answer?.resume(throwing: CancellationError())
        sent[index].answer = nil
      }
    }

    private func branch(of index: Int) throws(FixtureError) -> DataSchema.SearchTarget {
      guard sent.indices.contains(index) else {
        throw FixtureError(description: "request \(index) was never sent")
      }
      let targets = sent[index].input.targets
      let enabled: [(Bool?, DataSchema.SearchTarget)] = [
        (targets.places, .places), (targets.pois, .pois), (targets.ways, .ways),
        (targets.itineraries, .itineraries), (targets.collections, .collections),
        (targets.zones, .zones),
      ]
      let branches = enabled.filter { $0.0 == true }.map(\.1)
      guard branches.count == 1, let branch = branches.first else {
        throw FixtureError(description: "request \(index) enables \(branches.count) branches")
      }
      return branch
    }

    private func settle(
      _ index: Int, resolve: (CheckedContinuation<DataSchema.SearchResult, any Error>) -> Void
    ) throws(FixtureError) {
      guard let answer = sent[index].answer else {
        throw FixtureError(description: "request \(index) was settled already")
      }
      sent[index].answer = nil
      sent[index].isDone = true
      resolve(answer)
    }
  }
}
