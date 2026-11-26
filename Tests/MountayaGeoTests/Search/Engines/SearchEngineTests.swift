import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchEngine")
@MainActor
struct SearchEngineTests {
  /// pair is the two branches most cases ask, itineraries then zones.
  private static let pair: [DataSchema.SearchTarget] = [.itineraries, .zones]

  /// camera is a camera at latitude 0, where every edge of a box is exact.
  private static let camera = MapViewport(center: [6.5, 0], zoom: 10)

  /// box is the box a round confined to `camera` sends.
  private static let box = [6.32421875, -0.17578125, 6.67578125, 0.17578125]

  private static func engine(
    _ held: HeldSearch, query: String = "", targets: [DataSchema.SearchTarget] = pair,
    camera: MapViewport? = nil, isOpen: Bool = false, isConfined: Bool = false,
    pause: Duration = .zero, time: ManualTime = ManualTime(),
    language: DataSchema.Language? = nil, limit: SearchLimit? = nil,
    onError: (@MainActor @Sendable (any Error) -> Void)? = nil
  ) -> SearchEngine {
    SearchEngine(
      configuration: SearchConfiguration(
        fetch: held.fetch, language: language, limit: limit, targets: targets, onError: onError),
      query: query, camera: camera, isOpen: isOpen, isConfined: isConfined,
      pause: SearchPause(pause) ?? .standard, sleep: time.sleep)
  }

  @Test("a search holding no query asks nothing and shows every section settled with nothing")
  func idle() async {
    let held = HeldSearch()
    let engine = Self.engine(held)
    await settledSearch()

    #expect(held.sent.isEmpty)
    #expect(shown(engine.state) == "|idle|-|-|itineraries:s,zones:s")
    engine.close()
  }

  @Test("a query the search starts with is asked at once, one request per branch in their order")
  func startsAsked() async {
    let held = HeldSearch()
    let engine = Self.engine(held, query: "mont", targets: searchSectionOrder)
    #expect(engine.state.isSearching, "the skeleton before any request leaves")
    await settledSearch()

    #expect(held.branches == searchSectionOrder)
    #expect(searchSectionOrder == [.itineraries, .places, .ways, .pois, .zones, .collections])
    for (index, input) in held.sent.enumerated() {
      #expect(input.query == "mont")
      #expect(input.focus == nil && input.bbox == nil && input.limit == nil)
      #expect(input.language == nil)
      let flags = [
        input.targets.itineraries, input.targets.places, input.targets.ways, input.targets.pois,
        input.targets.zones, input.targets.collections,
      ]
      #expect(flags.map { $0 == true } == (0..<6).map { $0 == index }, "one branch alone")
      #expect(flags.allSatisfy { $0 != nil }, "every flag stated")
    }
    #expect(
      shown(engine.state)
        == "mont|searching|-|-|itineraries:l,places:l,ways:l,pois:l,zones:l,collections:l")
    held.release()
    engine.close()
  }

  @Test("answers landing in any order fill their sections in the order the targets list them")
  func sectionOrder() async {
    let held = HeldSearch()
    let engine = Self.engine(held, query: "mont", targets: [.zones, .places])
    await settledSearch()

    held.answer(1, names: ["Mont Blanc"])
    await settledSearch()
    #expect(shown(engine.state) == "mont|searching|-|-|zones:l,places:s[Mont Blanc]")
    held.answer(0, names: ["Couloir du Mont"])
    await settledSearch()
    #expect(
      shown(engine.state) == "mont|idle|settled|-|zones:s[Couloir du Mont],places:s[Mont Blanc]")
    engine.close()
  }

  @Test("a branch listed twice is asked once, and one this build cannot enable is asked none")
  func listedBranches() async {
    let held = HeldSearch()
    let engine = Self.engine(
      held, query: "mont", targets: [.zones, .places, .zones, DataSchema.SearchTarget("TRAILS")])
    await settledSearch()

    #expect(held.branches == [.zones, .places])
    #expect(engine.state.sections.map(\.id) == [.zones, .places])
    held.release()
    engine.close()
  }

  @Test("a round asks in its language and under its cap, ranked and confined around the camera")
  func requestMembers() async throws {
    let held = HeldSearch()
    let cap = try #require(SearchLimit(5))
    let engine = Self.engine(
      held, query: " chamonix ", targets: [.places], camera: Self.camera, isConfined: true,
      language: .fr, limit: cap)
    await settledSearch()

    let input = try #require(held.sent.first)
    #expect(input.query == "chamonix", "the query trimmed")
    #expect(input.language == .fr)
    #expect(input.limit == 5)
    #expect(input.focus == [6.5, 0])
    #expect(input.bbox == Self.box)
    held.release()
    engine.close()
  }

  @Test("a camera that names no point ranks around nothing, and one of no zoom confines nothing")
  func unreadCamera() async throws {
    let held = HeldSearch()
    let noZoom = Self.engine(
      held, query: "a", targets: [.places],
      camera: MapViewport(center: [197.5, 21.3], zoom: .nan), isConfined: true)
    let noPoint = Self.engine(
      held, query: "b", targets: [.places], camera: MapViewport(center: [.nan, 45], zoom: 12),
      isConfined: true)
    let none = Self.engine(held, query: "c", targets: [.places], isConfined: true)
    await settledSearch()

    #expect(held.sent.map(\.query) == ["a", "b", "c"])
    #expect(held.sent[0].focus == [-162.5, 21.3])
    #expect(held.sent[0].bbox == nil)
    #expect(held.sent[1].focus == nil && held.sent[1].bbox == nil)
    #expect(held.sent[2].focus == nil && held.sent[2].bbox == nil)
    held.release()
    for engine in [noZoom, noPoint, none] { engine.close() }
  }

  @Test("a round is asked once the query has gone unchanged for the pause, its skeleton meanwhile")
  func typingPause() async {
    let held = HeldSearch()
    let time = ManualTime()
    let engine = Self.engine(held, targets: [.places], pause: .milliseconds(150), time: time)

    engine.setQuery("c")
    #expect(shown(engine.state) == "c|searching|-|-|places:l")
    await time.advance(by: .milliseconds(100))
    engine.setQuery("ch")
    await time.advance(by: .milliseconds(100))
    engine.setQuery("cha")
    await time.advance(by: .milliseconds(149))
    #expect(held.sent.isEmpty)
    #expect(shown(engine.state) == "cha|searching|-|-|places:l")
    await time.advance(by: .milliseconds(1))

    #expect(held.sent.map(\.query) == ["cha"])
    held.answer(0, names: ["Chamonix"])
    await settledSearch()
    #expect(shown(engine.state) == "cha|idle|settled|-|places:s[Chamonix]")
    engine.close()
  }

  @Test("a pause of zero asks as the query is typed, abandoning the round in flight")
  func noPause() async {
    let held = HeldSearch()
    let engine = Self.engine(held, targets: [.places], pause: .zero)

    engine.setQuery("c")
    await settledSearch()
    engine.setQuery("ch")
    await settledSearch()

    #expect(held.sent.map(\.query) == ["c", "ch"])
    #expect(held.cancelled == [0])
    held.answer(1, names: ["Chamonix"])
    await settledSearch()
    #expect(shown(engine.state) == "ch|idle|settled|-|places:s[Chamonix]")
    engine.close()
  }

  @Test("white space typed around the settled query asks nothing, nor does a blank query")
  func unchangedQuery() async {
    let held = HeldSearch()
    let time = ManualTime()
    let engine = Self.engine(
      held, query: "chamonix", targets: [.places], pause: .milliseconds(150), time: time)
    await settledSearch()
    held.answer(0, names: ["Chamonix"])
    await settledSearch()

    engine.setQuery("chamonix ")
    #expect(shown(engine.state) == "chamonix|idle|settled|-|places:s[Chamonix]")
    await time.advance(by: .milliseconds(150))
    #expect(held.sent.count == 1)

    let blank = Self.engine(held, targets: [.places], pause: .milliseconds(150), time: time)
    blank.setQuery("   ")
    #expect(shown(blank.state) == "|idle|-|-|places:s", "a blank query shows nothing loading")
    await time.advance(by: .milliseconds(150))
    #expect(held.sent.count == 1)
    engine.close()
    blank.close()
  }

  @Test("rows answering another query are never shown under the one typed")
  func otherQuery() async {
    let held = HeldSearch()
    let time = ManualTime()
    let engine = Self.engine(
      held, query: "chamonix", targets: [.places], pause: .milliseconds(150), time: time)
    await settledSearch()

    engine.setQuery("zermatt")
    held.answer(0, names: ["Chamonix"])
    await settledSearch()
    #expect(shown(engine.state) == "zermatt|searching|-|-|places:l", "a round landing in the pause")
    await time.advance(by: .milliseconds(150))
    #expect(held.sent.map(\.query) == ["chamonix", "zermatt"])
    #expect(held.cancelled.isEmpty, "the round in flight is abandoned once the pause ends")
    held.answer(1, names: ["Zermatt"])
    await settledSearch()
    #expect(shown(engine.state) == "zermatt|idle|settled|-|places:s[Zermatt]")
    engine.close()
  }

  @Test("only the latest round writes: a round abandoned lands nothing, answered or failed")
  func latestRound() async {
    let held = HeldSearch()
    let engine = Self.engine(held, query: "chamonix")
    await settledSearch()

    engine.setQuery("zermatt")
    await settledSearch()
    #expect(held.cancelled == [0, 1])
    held.answer(0, names: ["Lac Blanc"])
    held.fail(1)
    await settledSearch()
    #expect(shown(engine.state) == "zermatt|searching|-|-|itineraries:l,zones:l")
    held.answer(2, names: ["Gornergrat"])
    held.answer(3, names: [])
    await settledSearch()
    #expect(shown(engine.state) == "zermatt|idle|settled|-|itineraries:s[Gornergrat],zones:s")
    engine.close()
  }

  @Test("a failed branch fills its own section, as does one the Data API reports failed")
  func failures() async throws {
    let held = HeldSearch()
    let heard = Heard()
    let engine = Self.engine(held, query: "chamonix", onError: { heard.errors.append($0) })
    await settledSearch()

    held.fail(0)
    await settledSearch()
    #expect(shown(engine.state) == "chamonix|searching|-|-|itineraries:e,zones:l")
    held.report(1)
    await settledSearch()

    #expect(shown(engine.state) == "chamonix|idle|settled|-|itineraries:e,zones:e")
    #expect(engine.state.sections[0].state.failure is HeldSearch.Failed)
    let reported = try #require(engine.state.sections[1].state.failure as? SearchBranchError)
    #expect(
      reported == SearchBranchError(target: .zones, code: .badGateway, message: "unreachable"))
    #expect(heard.errors.count == 1, "the thrown failure is handed on, the report is not")
    #expect(heard.errors.first is HeldSearch.Failed)
    engine.close()
  }

  @Test("a change of what a round asks starts a fresh round, and one of nothing else asks nothing")
  func configure() async throws {
    let held = HeldSearch()
    let engine = Self.engine(held, query: "chamonix")
    await settledSearch()
    #expect(held.sent.count == 2)
    var configuration = engine.configuration
    func configured(_ change: (inout SearchConfiguration) -> Void) async -> Int {
      change(&configuration)
      engine.configure(configuration)
      await settledSearch()
      return held.sent.count
    }

    #expect(
      await configured {
        $0.fetch = held.fetch
        $0.wording = SearchWording(resolveLabel: { _ in "Mot" })
        $0.onError = { _ in }
      } == 2, "a replaced transport, word resolver and handler ask nothing")
    #expect(
      await configured { $0.wording = SearchWording(units: UnitPreferences(language: "en")) } == 4,
      "units stated where none were")
    #expect(
      await configured {
        $0.wording = SearchWording(
          units: UnitPreferences(
            language: "en", pace: .perDistance, slope: .percentage))
      } == 4, "a unit no row reads")
    #expect(
      await configured {
        $0.wording = SearchWording(
          units: UnitPreferences(language: "en", length: .imperial))
      } == 6, "the length system")
    #expect(
      await configured {
        $0.wording = SearchWording(
          units: UnitPreferences(language: "fr", length: .imperial))
      } == 8, "the units' language")
    #expect(await configured { $0.language = .fr } == 10)
    let cap = try #require(SearchLimit(5))
    #expect(await configured { $0.limit = cap } == 12)
    #expect(await configured { $0.targets = [.zones] } == 13)
    #expect(held.sent.last?.language == .fr && held.sent.last?.limit == 5)
    #expect(held.branches.last == .zones)
    #expect(shown(engine.state) == "chamonix|searching|-|-|zones:l")
    #expect(held.cancelled == Set(0..<12), "each round abandoned the one in flight")

    configuration.fetch = nil
    engine.configure(configuration)
    #expect(shown(engine.state) == "chamonix|idle|-|-|zones:s", "no transport asks nothing")
    await settledSearch()
    #expect(held.cancelled.contains(12))
    engine.close()
  }

  @Test("rounds abandoned before their task ran send nothing")
  func abandonedUnsent() async {
    let held = HeldSearch()
    let engine = Self.engine(held, query: "a")
    engine.setQuery("ab")
    engine.setQuery("abc")
    await settledSearch()

    #expect(held.sent.map(\.query) == ["abc", "abc"])
    #expect(held.cancelled.isEmpty)
    held.release()
    engine.close()
  }

  @Test("a retry asks a fresh round, every section loading again")
  func retry() async {
    let held = HeldSearch()
    let engine = Self.engine(held, query: "chamonix")
    await settledSearch()
    held.fail(0)
    held.answer(1, names: ["Couloir Nord"])
    await settledSearch()

    engine.retry()
    #expect(shown(engine.state) == "chamonix|searching|-|-|itineraries:l,zones:l")
    await settledSearch()
    #expect(held.sent.count == 4)
    held.answer(2, names: ["Lac Blanc"])
    held.answer(3, names: ["Couloir Nord"])
    await settledSearch()
    #expect(
      shown(engine.state)
        == "chamonix|idle|settled|-|itineraries:s[Lac Blanc],zones:s[Couloir Nord]")
    engine.close()
  }

  @Test("a confined round that found nothing asks once more everywhere, and says it fell back")
  func broaden() async {
    let held = HeldSearch()
    let engine = Self.engine(
      held, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true)
    await settledSearch()

    held.answer(0, names: [])
    await settledSearch()
    #expect(shown(engine.state) == "chamonix|searching|-|-|itineraries:s,zones:l")
    held.answer(1, names: [])
    await settledSearch()
    #expect(held.sent.count == 4)
    #expect(held.sent[2].bbox == nil && held.sent[3].bbox == nil, "everywhere")
    #expect(held.sent[2].focus == [6.5, 0], "still ranked around the camera")
    #expect(
      shown(engine.state) == "chamonix|searching|-|fell-back|itineraries:l,zones:l",
      "no round settled while the broadened one is out")
    held.answer(2, names: [])
    held.answer(3, names: [])
    await settledSearch()
    #expect(shown(engine.state) == "chamonix|idle|settled|fell-back|itineraries:s,zones:s")
    #expect(held.sent.count == 4, "never twice")

    engine.setQuery("zermatt")
    await settledSearch()
    #expect(held.sent[4].bbox == Self.box, "a new query is confined again")
    #expect(!engine.state.hasFallenBack)
    held.release()
    engine.close()
  }

  @Test("a failed or reported branch is no empty one, and an unconfined round never falls back")
  func noBroaden() async {
    let failing = HeldSearch()
    let failed = Self.engine(
      failing, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true)
    let reporting = HeldSearch()
    let reported = Self.engine(
      reporting, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true)
    let unconfining = HeldSearch()
    let unconfined = Self.engine(unconfining, query: "chamonix", camera: Self.camera)
    let unread = HeldSearch()
    let noCamera = Self.engine(unread, query: "chamonix", isOpen: true, isConfined: true)
    await settledSearch()

    failing.fail(0)
    failing.answer(1, names: [])
    reporting.answer(0, names: [])
    reporting.report(1)
    unconfining.answer(0, names: [])
    unconfining.answer(1, names: [])
    unread.answer(0, names: [])
    unread.answer(1, names: [])
    await settledSearch()

    for held in [failing, reporting, unconfining, unread] {
      #expect(held.sent.count == 2)
    }
    #expect(shown(unconfined.state) == "chamonix|idle|settled|-|itineraries:s,zones:s")
    #expect(
      unread.sent.allSatisfy { $0.bbox == nil }, "a camera with nothing to read confines nothing")
    for engine in [failed, reported, unconfined, noCamera] { engine.close() }
  }

  @Test("a rest of the camera asks the round again after the pause, its rows kept in place")
  func refresh() async {
    let held = HeldSearch()
    let time = ManualTime()
    let engine = Self.engine(
      held, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true, time: time)
    await settledSearch()
    held.answer(0, names: ["Lac Blanc"])
    held.answer(1, names: [])
    await settledSearch()

    engine.setCamera(MapViewport(center: [7, 0], zoom: 10))
    await time.advance(by: .milliseconds(349))
    #expect(held.sent.count == 2)
    await time.advance(by: .milliseconds(1))
    #expect(held.sent.count == 4)
    #expect(held.sent[2].focus == [7, 0])
    #expect(held.sent[2].bbox == [6.82421875, -0.17578125, 7.17578125, 0.17578125])
    #expect(
      shown(engine.state) == "chamonix|searching|-|-|itineraries:s[Lac Blanc],zones:s",
      "no section loads in a refresh")
    held.answer(2, names: [])
    await settledSearch()
    #expect(
      shown(engine.state) == "chamonix|searching|-|-|itineraries:s,zones:s",
      "busy for the length of the round")
    held.answer(3, names: [])
    await settledSearch()
    #expect(shown(engine.state) == "chamonix|idle|settled|-|itineraries:s,zones:s")
    #expect(held.sent.count == 4, "a refresh never falls back")
    engine.close()
  }

  @Test("the moves of one gesture fold into one round, asked from the last")
  func gesture() async {
    let held = HeldSearch()
    let time = ManualTime()
    let engine = Self.engine(
      held, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true, time: time)
    await settledSearch()
    held.answer(0, names: ["Lac Blanc"])
    held.answer(1, names: [])
    await settledSearch()

    for longitude in [6.75, 7, 7.25, 7.5, 7.75] {
      engine.setCamera(MapViewport(center: [longitude, 0], zoom: 10))
      await time.advance(by: .milliseconds(16))
    }
    #expect(held.sent.count == 2)
    await time.advance(by: .milliseconds(334))
    #expect(held.sent.count == 4)
    #expect(held.sent[2].focus == [7.75, 0])
    held.release()
    engine.close()
  }

  @Test("a rest asks nothing while the list is closed, unconfined or holding no query")
  func noRefresh() async {
    let time = ManualTime()
    let closedHeld = HeldSearch()
    let closed = Self.engine(
      closedHeld, query: "chamonix", camera: Self.camera, isConfined: true, time: time)
    let unconfinedHeld = HeldSearch()
    let unconfined = Self.engine(
      unconfinedHeld, query: "chamonix", camera: Self.camera, isOpen: true, time: time)
    let emptyHeld = HeldSearch()
    let empty = Self.engine(
      emptyHeld, camera: Self.camera, isOpen: true, isConfined: true, time: time)
    let closingHeld = HeldSearch()
    let closing = Self.engine(
      closingHeld, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true,
      time: time)
    await settledSearch()

    for engine in [closed, unconfined, empty, closing] {
      engine.setCamera(MapViewport(center: [7, 0], zoom: 10))
    }
    await time.advance(by: .milliseconds(100))
    closing.setOpen(false)
    await time.advance(by: .milliseconds(400))

    #expect(closedHeld.sent.count == 2)
    #expect(unconfinedHeld.sent.count == 2)
    #expect(emptyHeld.sent.isEmpty)
    #expect(closingHeld.sent.count == 2, "a closing drops the rest waiting")
    #expect(
      closed.camera == MapViewport(center: [7, 0], zoom: 10), "the camera is held all the same")

    closed.setOpen(true)
    closed.setCamera(MapViewport(center: [7, 0], zoom: 10))
    await time.advance(by: .milliseconds(350))
    #expect(closedHeld.sent.count == 4, "opened again, a rest asks")
    for held in [closedHeld, unconfinedHeld, emptyHeld, closingHeld] { held.release() }
    for engine in [closed, unconfined, empty, closing] { engine.close() }
  }

  @Test("a rest after a fall back asks the visible area again and no longer says it fell back")
  func refreshAfterFallBack() async {
    let held = HeldSearch()
    let time = ManualTime()
    let engine = Self.engine(
      held, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true, time: time)
    await settledSearch()
    held.answer(0, names: [])
    held.answer(1, names: [])
    await settledSearch()
    held.answer(2, names: ["Lac Blanc"])
    held.answer(3, names: [])
    await settledSearch()
    #expect(engine.state.hasFallenBack)

    engine.setCamera(MapViewport(center: [7, 0], zoom: 10))
    await time.advance(by: .milliseconds(350))
    #expect(held.sent.count == 6)
    #expect(held.sent[4].bbox != nil)
    #expect(shown(engine.state) == "chamonix|searching|-|-|itineraries:s[Lac Blanc],zones:s")
    held.release()
    engine.close()
  }

  @Test("a change of confinement is a fresh round, every section loading again")
  func confinement() async {
    let held = HeldSearch()
    let engine = Self.engine(held, query: "chamonix", camera: Self.camera)
    await settledSearch()
    held.answer(0, names: ["Lac Blanc"])
    held.answer(1, names: [])
    await settledSearch()

    engine.setConfined(true)
    #expect(shown(engine.state) == "chamonix|searching|-|-|itineraries:l,zones:l")
    await settledSearch()
    #expect(held.sent[2].bbox == Self.box)
    engine.setConfined(true)
    await settledSearch()
    #expect(held.sent.count == 4, "the same confinement asks nothing")
    held.release()
    engine.close()
  }

  @Test("a stream is told the state now and each change, and ends at close")
  func stream() async {
    let held = HeldSearch()
    let engine = Self.engine(held, targets: [.places])
    let stream = engine.subscribe()

    engine.setQuery("chamonix")
    await settledSearch()
    held.answer(0, names: ["Chamonix"])
    await settledSearch()
    engine.close()

    var told: [String] = []
    for await state in stream {
      told.append(shown(state))
    }
    #expect(told.first == "|idle|-|-|places:s")
    #expect(told.last == "chamonix|idle|settled|-|places:s[Chamonix]")
    #expect(told.contains("chamonix|searching|-|-|places:l"))
    var after: [String] = []
    for await state in engine.subscribe() {
      after.append(shown(state))
    }
    #expect(after == ["chamonix|idle|settled|-|places:s[Chamonix]"], "a stream after close")
  }

  @Test("a closed engine is inert: its round abandoned, nothing landing, no command heard")
  func closed() async {
    let held = HeldSearch()
    let time = ManualTime()
    let engine = Self.engine(
      held, query: "chamonix", camera: Self.camera, isOpen: true, isConfined: true, time: time)
    await settledSearch()

    engine.close()
    await settledSearch()
    #expect(held.cancelled == [0, 1])
    held.answer(0, names: ["Lac Blanc"])
    engine.setQuery("zermatt")
    engine.retry()
    engine.setConfined(false)
    engine.setCamera(MapViewport(center: [7, 0], zoom: 10))
    await time.advance(by: .milliseconds(400))
    #expect(held.sent.count == 2)
    #expect(shown(engine.state) == "chamonix|searching|-|-|itineraries:l,zones:l")
    #expect(engine.query == "chamonix")
    held.release()
  }

  @Test("a search with no transport asks nothing, the typed query shown settled with nothing")
  func inert() async {
    let time = ManualTime()
    let engine = SearchEngine(
      configuration: SearchConfiguration(targets: [.places]),
      pause: SearchPause(.milliseconds(150)) ?? .standard, sleep: time.sleep)

    engine.setQuery("chamonix")
    #expect(shown(engine.state) == "chamonix|idle|-|-|places:s")
    await time.advance(by: .milliseconds(150))
    #expect(shown(engine.state) == "chamonix|idle|-|-|places:s")
    engine.close()
  }

  /// Heard holds every failure a search's handler was handed.
  @MainActor
  final class Heard {
    var errors: [any Error] = []
  }
}
