import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing
import UIKit

@testable import MountayaElements

@Suite("SearchControl", .serialized)
@MainActor
struct SearchControlTests {
  /// field is the text field SwiftUI draws the box with, found in `view`'s hierarchy.
  private static func field(in view: UIView) -> UITextField? {
    if let field = view as? UITextField { return field }
    for child in view.subviews {
      if let field = field(in: child) { return field }
    }
    return nil
  }

  /// row is a row of `title`, the runs `query` matches emphasized, handing back `payload`.
  private static func row(
    _ title: String, query: String = "", payload: SearchRowPayload,
    secondary: SearchRowSecondary? = nil
  ) -> SearchRow {
    SearchRow(
      id: "row:\(title)", title: title, matched: highlightRanges(title, query: query),
      secondary: secondary, activities: [], payload: payload)
  }

  @Test("typing waits out the pause, then asks a request per branch, the skeleton shown meanwhile")
  func typing() async throws {
    let time = ManualTime()
    let held = HeldSearch()
    let typed = Typed()
    let engine = SearchEngine(
      configuration: SearchConfiguration(targets: [.itineraries, .zones]),
      pause: SearchPause(.milliseconds(150)) ?? .standard, sleep: time.sleep)
    let host = UIHostingController(
      rootView: TypingHost(typed: typed, engine: engine, fetch: held.fetch))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { engine.configuration.fetch != nil }, "configured as it appears")

    // The app writes the text it holds, which the box shows.
    let field = try #require(Self.field(in: host.view))
    typed.query = "cha"
    #expect(await MapWindow.until { engine.query == "cha" })
    #expect(field.text == "cha")
    #expect(engine.state.isSearching, "the skeleton of the round owed")
    #expect(engine.state.sections.allSatisfy { $0.state.isLoading })
    await time.advance(by: .milliseconds(149))
    #expect(held.sent.isEmpty)
    await time.advance(by: .milliseconds(1))
    #expect(held.sent.map(\.query) == ["cha", "cha"])
    #expect(!engine.isConfined, "a control with no map confines nothing")

    held.answer(0, names: ["Chamonix", "Champex"])
    held.answer(1, names: [])
    #expect(await MapWindow.until { engine.state.isSettled })
    let list = searchListState(engine.state, filter: .all)
    #expect(list.rows.map(\.title) == ["Chamonix", "Champex"])
    #expect(SearchControl.statusText(list.status, in: .standard) == "2 results")
    window.isHidden = true
    engine.close()
  }

  @Test("the list shows under the box while it holds focus over a query, on the panel's ground")
  func listShown() async throws {
    let held = HeldSearch()
    let typed = Typed()
    typed.query = "mont"
    let engine = SearchEngine(
      configuration: SearchConfiguration(targets: [.itineraries]), query: "mont")
    let host = UIHostingController(
      rootView: SearchControl(
        map: nil, own: engine, query: typed.binding, targets: [.itineraries],
        fetch: held.fetch
      )
      .environment(\.colorScheme, .dark))
    let window = MapWindow.showing(host.view)
    #expect(
      await MapWindow.until { held.sent.count == 1 }, "a query the box starts with owes no pause")
    held.answer(0, names: ["Tour du Mont Blanc"])
    #expect(!engine.isOpen)

    let field = try #require(Self.field(in: host.view))
    field.becomeFirstResponder()
    #expect(await MapWindow.until { engine.isOpen }, "the list shown, the engine told so")
    field.resignFirstResponder()
    #expect(await MapWindow.until { !engine.isOpen }, "the box left, the list closed")
    window.isHidden = true
    engine.close()
  }

  @Test("the list is drawn on the panel's ground under each scheme, its notes in the scope's words")
  func listDrawn() throws {
    let list = SearchListState(
      rows: [], failed: [], isNothingFound: true, hasFallbackNote: true, status: .emptyTitle)
    for scheme in [ColorScheme.light, .dark] {
      let image = try #require(
        Controls.drawn(
          SearchList(
            list: list, isSearching: false, filter: .constant(.all), isConfined: nil,
            units: UnitPreferences(language: "en"), retry: {}, select: { _ in }
          ).frame(width: 300), scheme: scheme))
      let ground = try #require(Pixels.pixel(image, at: CGPoint(x: 10, y: 10)))
      let panel = themeTokenValue(
        ElementTokens.standard.panelBg, in: scheme == .dark ? .dark : .light)
      #expect(ground.isNear(Controls.color(panel.hex)), "\(scheme): \(ground)")
    }
    let found = try #require(
      Controls.drawn(
        SearchList(
          list: SearchListState(
            rows: [], failed: [], isNothingFound: false, hasFallbackNote: false, status: nil),
          isSearching: false, filter: .constant(.all), isConfined: nil,
          units: UnitPreferences(language: "en"), retry: {}, select: { _ in }
        ).frame(width: 300)))
    let empty = try #require(
      Controls.drawn(
        SearchList(
          list: list, isSearching: false, filter: .constant(.all), isConfined: nil,
          units: UnitPreferences(language: "en"), retry: {}, select: { _ in }
        ).frame(width: 300)))
    #expect(empty.size.height > found.size.height + 40, "the empty state and the note drawn")
  }

  @Test("a failed branch's line reads the elements' word beside its retry, never the API's message")
  func failedLine() throws {
    func drawn(_ message: String?) throws -> UIImage {
      let failed = SearchSection(
        id: .places,
        state: .failed(
          SearchBranchError(target: .places, code: .internalError, message: message)))
      return try #require(
        Controls.drawn(
          SearchList(
            list: SearchListState(
              rows: [], failed: [failed], isNothingFound: false, hasFallbackNote: false,
              status: .error),
            isSearching: false, filter: .constant(.all), isConfined: nil,
            units: UnitPreferences(language: "en"), retry: {}, select: { _ in }
          ).frame(width: 300)))
    }
    let silent = try drawn(nil)
    let spoken = try drawn(
      "The places index did not answer in time, and this sentence runs over several lines.")
    #expect(spoken.size.height == silent.size.height, "the message takes no line of the list")
    #expect(spoken.pngData() == silent.pngData())
  }

  @Test("the status line, the filters and a row's title read the scope's words")
  func words() {
    #expect(SearchControl.statusText(nil, in: .standard) == "")
    #expect(SearchControl.statusText(.error, in: .standard) == "The search could not be completed.")
    #expect(SearchControl.statusText(.emptyTitle, in: .standard) == "Nothing found")
    #expect(SearchControl.statusText(.resultCount(1), in: .standard) == "1 result")
    #expect(SearchControl.statusText(.resultCount(3), in: .standard) == "3 results")
    let french = scopeOf(.standard, stating: ElementsScopeStatement(language: "fr"))
    #expect(SearchControl.statusText(.resultCount(1), in: french) == "1 r\u{E9}sultat")
    #expect(SearchControl.statusText(.resultCount(0), in: french) == "0 r\u{E9}sultat")
    #expect(SearchControl.statusText(.emptyTitle, in: french) == "Aucun r\u{E9}sultat")
    #expect(
      SearchFilter.allCases.map { SearchControl.filterLabel($0, in: .standard) }
        == ["All", "Itineraries", "Places", "Zones"])
    #expect(
      SearchFilter.allCases.map { SearchControl.filterLabel($0, in: french) }
        == ["Tout", "Itin\u{E9}raires", "Lieux", "Zones"])

    let row = Self.row(
      "Mont Blanc", query: "blanc", payload: .place(point: [6.86, 45.83], bounds: nil))
    let title = SearchControl.title(row)
    let runs = title.runs.map { run in
      (String(title[run.range].characters), run.inlinePresentationIntent)
    }
    #expect(runs.map(\.0) == ["Mont ", "Blanc"])
    #expect(runs.map(\.1) == [nil, .stronglyEmphasized])
  }

  @Test("a row is drawn the touch target high, its title and its second line in the tokens")
  func rowDrawn() throws {
    let row = Self.row(
      "Tour du Mont Blanc", query: "mont",
      payload: .itinerary(itineraryId: "tmb", bounds: nil, start: nil),
      secondary: .metric(distance: 170_000, ascent: 10_000))
    let image = try #require(
      Controls.drawn(
        SearchResultRow(row: row, units: UnitPreferences(language: "en"), select: { _ in })
          .frame(width: 300)))

    #expect(image.size.height >= 44)
    var inked = 0
    for x in stride(from: 2.0, to: 120, by: 2) {
      for y in stride(from: 2.0, to: image.size.height - 2, by: 2) {
        if let pixel = Pixels.pixel(image, at: CGPoint(x: x, y: y)), pixel.alpha > 200,
          pixel.red < 120
        {
          inked += 1
        }
      }
    }
    #expect(inked > 20, "the title and its line are drawn")
  }

  @Test("a pick moves the camera onto the row and marks it in the accent; a collection unmarks")
  func pick() throws {
    let map = try Maps.engine()
    let surface = ScriptedMapSurface(drawing: map)
    let accent = HexColor(hex: "#e9501e")

    SearchControl.pick(
      Self.row("Lac Blanc", payload: .place(point: [6.9, 45.9], bounds: nil)), map: map,
      accent: accent, onSelect: nil)
    #expect(map.state.camera.center == [6.9, 45.9])
    #expect(map.state.camera.zoom == 13)
    #expect(map.state.layers.last?.layout["icon-image"] == "poi-icon-point-e9501e")

    SearchControl.pick(
      Self.row(
        "Tour", payload: .itinerary(itineraryId: "t", bounds: [6.8, 45.8, 6.9, 45.9], start: nil)),
      map: map, accent: accent, onSelect: nil)
    #expect(surface.frames.last?.bounds == [6.8, 45.8, 6.9, 45.9], "an extent is framed")
    #expect(
      !map.state.layers.contains { $0.id.hasPrefix("mountaya-search-highlight") },
      "an itinerary with no start marks nothing, taking the mark before down")

    SearchControl.pick(
      Self.row("Couloir", payload: .zone(zoneId: "z", point: [6.95, 45.95], bounds: nil)),
      map: map, accent: accent, onSelect: nil)
    #expect(map.state.layers.last?.id == "mountaya-search-highlight-place")
    SearchControl.pick(
      Self.row(
        "Classics",
        payload: .collection(collectionId: "c", name: "Classics", description: nil, isPrivate: nil)),
      map: map, accent: accent, onSelect: nil)
    #expect(!map.state.layers.contains { $0.id.hasPrefix("mountaya-search-highlight") })

    var handed: [String] = []
    SearchControl.pick(
      Self.row("Lac Blanc", payload: .place(point: [7, 46], bounds: nil)), map: map,
      accent: accent, onSelect: { handed.append($0.id) })
    #expect(handed == ["row:Lac Blanc"])
    #expect(map.state.camera.center != [7, 46], "a handler stands in for the map")
    _ = surface
  }

  @Test("where the reader asked for reduced motion, a pick lands the camera at once")
  func pickReducingMotion() throws {
    let map = try Maps.engine()
    let surface = ScriptedMapSurface(drawing: map)
    let accent = HexColor(hex: "#e9501e")

    SearchControl.pick(
      Self.row("Lac Blanc", payload: .place(point: [6.9, 45.9], bounds: nil)), map: map,
      accent: accent, reducesMotion: true, onSelect: nil)
    SearchControl.pick(
      Self.row(
        "Tour", payload: .itinerary(itineraryId: "t", bounds: [6.8, 45.8, 6.9, 45.9], start: nil)),
      map: map, accent: accent, reducesMotion: true, onSelect: nil)
    SearchControl.pick(
      Self.row("Lac Noir", payload: .place(point: [6.95, 45.95], bounds: nil)), map: map,
      accent: accent, onSelect: nil)

    #expect(surface.moves.map(\.motion) == [.jump, .fly], "a flight is a jump, then travels again")
    #expect(surface.frames.last?.fit == CameraFit(duration: .zero), "an extent is framed at once")
  }

  @Test("the clear button, a filter chip and a retry keep their 32 points and are pressed in 44")
  func touchTargets() throws {
    let clear = try #require(Controls.drawn(SearchClearButton(label: "Clear") {}))
    let chip = try #require(
      Controls.drawn(SearchFilterChip(label: "All", isSelected: true) {}))
    let retry = try #require(Controls.drawn(SearchRetryButton(label: "Retry") {}))

    #expect(clear.size == CGSize(width: 44, height: 44))
    #expect(chip.size.height == 44 && chip.size.width >= 44)
    #expect(retry.size.height == 44 && retry.size.width >= 44)
    // The chip's capsule is 32 points high, on the hover ground, the 6 points above it clear.
    let middle = chip.size.width / 2
    #expect(
      Pixels.pixel(chip, at: CGPoint(x: middle, y: 10))?.isNear(Controls.color("#f1f3f5")) == true)
    #expect(Pixels.pixel(chip, at: CGPoint(x: middle, y: 3))?.alpha == 0)
    #expect(Pixels.pixel(chip, at: CGPoint(x: middle, y: 41))?.alpha == 0)
  }

  @Test("the control takes its map's search highlight down as it leaves or is handed another map")
  func removal() async throws {
    let first = try Maps.engine()
    let second = try Maps.engine()
    for map in [first, second] {
      map.setSearchHighlight(.place(point: [6.86, 45.83]))
    }
    func highlighted(_ map: MapEngine) -> Bool {
      map.state.sources.contains { $0.id == "mountaya-search-highlight" }
    }
    let engine = SearchEngine()
    let host = UIHostingController(
      rootView: AnyView(
        SearchControl(map: first, own: engine, fetch: { _ in DataSchema.SearchResult() })))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { engine.configuration.fetch != nil })
    #expect(highlighted(first))

    host.rootView = AnyView(
      SearchControl(map: second, own: engine, fetch: { _ in DataSchema.SearchResult() }))
    #expect(await MapWindow.until { !highlighted(first) }, "the map it no longer shows")
    #expect(highlighted(second))

    host.rootView = AnyView(EmptyView())
    #expect(await MapWindow.until { !highlighted(second) }, "the control left the screen")
    window.isHidden = true
    engine.close()
  }

  /// An engine the app hands is the app's, a typing pause of its own among it: the box shows it and
  /// drives it, the text and the scope the app holds and its map's camera, and never configures it
  /// nor closes it, the engine's own configuration standing in for the box's.
  @Test("an engine the app hands is shown and driven, and never configured nor closed")
  func handedEngine() async throws {
    let held = HeldSearch()
    let typed = Typed()
    let map = try Maps.engine()
    let engine = SearchEngine(
      configuration: SearchConfiguration(fetch: held.fetch, targets: [.itineraries]),
      pause: SearchPause(.zero) ?? .standard)
    let host = UIHostingController(
      rootView: AnyView(HandedHost(typed: typed, engine: engine, map: map)))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { engine.camera != nil }, "its map's camera drives it")
    #expect(engine.camera?.zoom == 12)

    typed.query = "mont"
    #expect(await MapWindow.until { engine.query == "mont" }, "the text the app holds drives it")
    #expect(await MapWindow.until { held.sent.count == 1 }, "its own transport asks")
    #expect(held.sent.map(\.query) == ["mont"])
    #expect(held.sent.first?.targets.itineraries == true, "for its own targets")
    #expect(engine.configuration.targets == [.itineraries], "the box configures no engine handed")
    #expect(!engine.isConfined, "an engine handed unconfined stays so where the app states none")
    let field = try #require(Self.field(in: host.view))
    engine.setQuery("monte")
    #expect(await MapWindow.until(0.5) { field.text == "monte" } == false, "the app's text stands")

    host.rootView = AnyView(EmptyView())
    _ = await MapWindow.until(0.3) { false }
    engine.setQuery("montenvers")
    #expect(engine.query == "montenvers", "the box closes no engine it is handed")
    held.release()
    window.isHidden = true
    engine.close()
  }

  /// With no text of the app's, the box shows the engine's own, whoever writes it.
  @Test("an engine the app hands shows its own text where the app holds none")
  func handedEngineText() async throws {
    let engine = SearchEngine()
    let host = UIHostingController(rootView: SearchControl(map: nil, engine: engine))
    let window = MapWindow.showing(host.view)
    #expect(await MapWindow.until { Self.field(in: host.view) != nil })
    let field = try #require(Self.field(in: host.view))

    engine.setQuery("chamonix")
    #expect(await MapWindow.until { field.text == "chamonix" }, "\(field.text ?? "")")
    window.isHidden = true
    engine.close()
  }

  /// HandedHost is an app's view holding the box's text and its search engine, which it reads, so a
  /// change of the text draws the control again, as an app's own view does.
  private struct HandedHost: View {
    let typed: Typed
    let engine: SearchEngine
    let map: MapEngine

    var body: some View {
      let _ = typed.query
      SearchControl(
        map: map, engine: engine, query: typed.binding, targets: [.zones],
        fetch: { _ in DataSchema.SearchResult() })
    }
  }

  /// TypingHost is an app's view holding the box's text in a model of its own, which it reads, so
  /// a change of the text draws the control again, as an app's own view does.
  private struct TypingHost: View {
    let typed: Typed
    let engine: SearchEngine
    let fetch: SearchFetch

    var body: some View {
      let _ = typed.query
      SearchControl(
        map: nil, own: engine, query: typed.binding, targets: [.itineraries, .zones],
        fetch: fetch)
    }
  }
}
