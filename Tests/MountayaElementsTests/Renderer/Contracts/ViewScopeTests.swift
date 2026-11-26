import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing
import UIKit

@testable import MountayaElements

/// A view's own words, `strings`, replace the scope's for that view alone, each at its path, laid
/// over the scope SwiftUI's environment carries, as `sdk-dart`'s and `sdk-kotlin`'s are.
@Suite("ViewScope", .serialized)
@MainActor
struct ViewScopeTests {
  @Test("a view's words replace the scope's at their paths, and every other word is the scope's")
  func overlay() {
    let scope = ViewScope.scope(
      .standard, strings: ["controls.zoomIn": "Plus", "tooltips.zoomIn.description": "Closer"])

    #expect(scope.word("controls.zoomIn") == "Plus")
    #expect(scope.word("tooltips.zoomIn.description") == "Closer")
    #expect(scope.word("controls.zoomOut") == ElementsScope.standard.word("controls.zoomOut"))
    #expect(scope.language == .en && scope.locale == "en")
    #expect(ViewScope.scope(.standard, strings: nil) == .standard)
    #expect(ViewScope.scope(.standard, strings: [:]) == .standard)
  }

  /// A view's words are layered over the app's: a word the app's scope states stays where the view
  /// names none, in the scope's own language.
  @Test("a view's words are laid over the scope around it, the app's own words kept")
  func layered() {
    let around = scopeOf(
      .standard,
      stating: ElementsScopeStatement(
        language: .fr, words: .bySection(["controls": ["zoomOut": "Moins"]])))
    let scope = ViewScope.scope(around, strings: ["controls.zoomIn": "Plus"])

    #expect(scope.word("controls.zoomIn") == "Plus")
    #expect(scope.word("controls.zoomOut") == "Moins", "the app's own word stays")
    #expect(scope.word("controls.compass") == around.word("controls.compass"))
    #expect(scope.language == .fr && scope.locale == around.locale)
  }

  /// A counted word takes a view's word in every form, its count filled where it names one, and a
  /// path naming a section names no word.
  @Test("a counted word takes a view's word in every form, and a section takes none")
  func counted() throws {
    let scope = ViewScope.scope(
      .standard, strings: ["search.resultCount": "{count} found", "search": "nothing"])
    let word = try #require(
      scope.words["search"].flatMap { section -> JSONValue? in
        guard case .object(let words) = section else { return nil }
        return words["resultCount"]
      })

    #expect(countedText(word, count: 1, language: .en) == "1 found")
    #expect(countedText(word, count: 3, language: .en) == "3 found")
    #expect(scope.word("search.placeholder") == ElementsScope.standard.word("search.placeholder"))
  }

  // MARK: - Each view speaks its own words

  /// spoken is the labels of the control buttons `view` draws, as each reports them to a probe.
  private static func spoken(_ view: some View) -> Set<String> {
    let probe = RenderProbe()
    _ = ImageRenderer(content: view.environment(\.renderProbe, probe)).uiImage
    return Set(
      probe.counts.keys.filter { $0.hasPrefix("ControlButton ") }
        .map { String($0.dropFirst("ControlButton ".count)) })
  }

  @Test("each control speaks its own words, the scope's at every path it names none for")
  func controls() throws {
    let map = try Maps.engine()
    let zoomIn = ElementsScope.standard.word("controls.zoomIn")
    let zoom = Self.spoken(ZoomControl(map: map, strings: ["controls.zoomOut": "Moins"]))
    let compass = Self.spoken(CompassControl(map: map, strings: ["controls.compass": "Nord"]))
    let geolocate = Self.spoken(
      GeolocateControl(map: map, strings: ["controls.geolocate": "Ici"]))
    let directions = Self.spoken(DirectionsControl(strings: ["controls.directions": "Route"]) {})
    let download = Self.spoken(DownloadControl(strings: ["controls.download": "Fichier"]) {})
    let stack = Self.spoken(
      MapControls(
        map, zoom: true, compass: false, layers: true, preferences: false,
        strings: ["controls.zoomIn": "Plus", "controls.layers": "Fonds"]))

    #expect(zoom == ["Moins", zoomIn], "\(zoom)")
    #expect(compass == ["Nord"], "\(compass)")
    #expect(geolocate == ["Ici"], "\(geolocate)")
    #expect(directions == ["Route"], "\(directions)")
    #expect(download == ["Fichier"], "\(download)")
    #expect(
      stack == ["Plus", ElementsScope.standard.word("controls.zoomOut"), "Fonds"], "\(stack)")
  }

  /// Seen holds the scope a view of the app's read as it was drawn.
  @MainActor
  final class Seen {
    var scope: ElementsScope?
  }

  /// Reader is a view of the app's that reads the scope around it as it is drawn.
  struct Reader: View {
    let seen: Seen
    @Environment(\.mountayaScope) private var scope

    var body: some View {
      seen.scope = scope
      return Color.red.frame(width: 1, height: 1)
    }
  }

  /// The stack's words are its own controls' and panels', and never the app's own controls'.
  @Test("a stack's words reach its own controls and none of the app's")
  func stackContent() {
    let seen = Seen()
    _ =
      ImageRenderer(
        content: MapControls(nil, zoom: true, strings: ["controls.zoomIn": "Plus"]) {
          Reader(seen: seen)
        }
      ).uiImage

    #expect(seen.scope == .standard)
  }

  @Test("each panel's rows speak its own words")
  func panels() async throws {
    let map = try Maps.engine()
    try map.setSpecification(Maps.pointsOfInterest, named: "pois")
    let probe = RenderProbe()
    let preferences = Held(UnitPreferences(language: "en"))
    let (poiHost, poiWindow) = Hosted.showing(
      POIPanel(map: map, showsAllToggle: true, strings: ["pois.displayOnMap": "Tout montrer"])
        .environment(\.renderProbe, probe))
    let (preferencesHost, preferencesWindow) = Hosted.showing(
      PreferencesPanel(preferences: preferences.binding, strings: ["preferences.metric": "Mètres"])
        .environment(\.renderProbe, probe))

    #expect(
      await MapWindow.until {
        probe["PanelRow Tout montrer"] >= 1 && probe["PreferenceCard Mètres"] >= 1
      },
      "\(probe.counts)")
    #expect(probe["PanelRow " + ElementsScope.standard.word("pois.displayOnMap")] == 0)
    poiWindow.isHidden = true
    preferencesWindow.isHidden = true
    _ = (poiHost, preferencesHost)
  }

  /// png is `view` drawn, as the bytes of its image, to compare two drawings by.
  private static func png(_ view: some View) -> Data? {
    let renderer = ImageRenderer(content: view.frame(width: 360))
    renderer.scale = 2
    return renderer.uiImage?.pngData()
  }

  /// same tells whether `view` stating `strings` draws as it draws under a scope stating them, and
  /// unlike it stating none.
  private static func same(
    _ view: ([String: String]?) -> some View, strings: [String: String],
    words: [String: JSONValue]
  ) -> (stated: Bool, differs: Bool) {
    let own = png(view(strings))
    let scoped = png(view(nil).mountayaScope(ElementsScopeStatement(words: .bySection(words))))
    let plain = png(view(nil))
    return (own != nil && own == scoped, own != plain)
  }

  /// resolved is an engine reading `itinerary`, once it shows it.
  private static func resolved(_ itinerary: RestSchema.ItineraryWithDetails) async throws
    -> ItineraryResourceEngine
  {
    let engine = ItineraryResourceEngine(
      cache: Itineraries.cache(itinerary), itineraryId: itinerary.id)
    try #require(
      await MapWindow.until { if case .resolved = engine.state { true } else { false } })
    return engine
  }

  @Test("each data element and the card speak their own words, their parts included")
  func elements() async throws {
    let flat = try await Self.resolved(Itineraries.flat)
    var bare = Itineraries.itinerary
    bare.segments = []
    bare.waypoints = []
    let empty = try await Self.resolved(bare)
    let profile = Self.same(
      { ItineraryProfile(engine: flat, strings: $0) }, strings: ["profile.empty": "Sans altitude"],
      words: ["profile": ["empty": "Sans altitude"]])
    let segments = Self.same(
      { ItinerarySegmentTable(engine: empty, strings: $0) }, strings: ["table.empty": "Aucune"],
      words: ["table": ["empty": "Aucune"]])
    let waypoints = Self.same(
      { ItineraryWaypointTable(engine: empty, strings: $0) },
      strings: ["table.waypointEmpty": "Aucun"], words: ["table": ["waypointEmpty": "Aucun"]])
    let place = ItineraryPlace(id: "spring", lngLat: [6, 45.015])
    let card = Self.same(
      { WaypointCard(place: place, strings: $0) }, strings: ["waypointCard.empty": "Rien"],
      words: ["waypointCard": ["empty": "Rien"]])

    #expect(profile == (true, true), "\(profile)")
    #expect(segments == (true, true), "\(segments)")
    #expect(waypoints == (true, true), "\(waypoints)")
    #expect(card == (true, true), "\(card)")
    flat.close()
    empty.close()
  }

  /// field is the text field SwiftUI draws a search box with, found in `view`'s hierarchy.
  private static func field(in view: UIView) -> UITextField? {
    if let field = view as? UITextField { return field }
    for child in view.subviews {
      if let field = field(in: child) { return field }
    }
    return nil
  }

  /// The box's field is a part of its own, which reads the words the box hands it.
  @Test("the search box speaks its own words, its field's included")
  func search() async throws {
    let (host, window) = Hosted.showing(
      SearchControl(map: nil, strings: ["search.placeholder": "Un sommet, un refuge"]))
    let field = try #require(
      await MapWindow.until { Self.field(in: host.view) != nil }
        ? Self.field(in: host.view) : nil)
    let prompt = { field.placeholder ?? field.attributedPlaceholder?.string ?? "" }

    #expect(await MapWindow.until { prompt() == "Un sommet, un refuge" }, "\(prompt())")
    window.isHidden = true
  }
}
