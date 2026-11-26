import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersSelectionEngine")
@MainActor
struct LayersSelectionEngineTests {
  private static let catalogue = TileFixtures.layers(
    [
      TileFixtures.category(
        "conditions",
        children: [TileFixtures.overlay("slopes"), TileFixtures.overlay("snow-depth")]),
      TileFixtures.category(
        "enrichment", children: [TileFixtures.overlay("hillshade"), TileFixtures.overlay("pois")]),
    ],
    terrains: [TileFixtures.terrain("outdoors"), TileFixtures.terrain("satellite")])

  /// shown reads a selection as `terrain|overlay|enrichments|refused`.
  private static func shown(_ selection: LayersSelection) -> String {
    [
      selection.terrain ?? "-", selection.overlay ?? "-",
      selection.enrichments.joined(separator: "+"), selection.refusal == nil ? "kept" : "refused",
    ].joined(separator: "|")
  }

  @Test("a classic overlay replaces the one before, a second press clears it, and nil clears it")
  func overlays() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let engine = LayersSelectionEngine(map: map)
    await settled()
    map.land(0)
    await settled()

    engine.setOverlay("slopes")
    engine.setOverlay("snow-depth")
    #expect(Self.shown(engine.state) == "outdoors|snow-depth||kept")
    engine.setOverlay("snow-depth")
    #expect(Self.shown(engine.state) == "outdoors|-||kept")
    engine.setOverlay("slopes")
    engine.setOverlay(nil)
    await settled()

    #expect(Self.shown(engine.state) == "outdoors|-||kept")
    #expect(
      map.calls == [
        "overlay:slopes", "overlay:snow-depth", "overlay:-", "overlay:slopes", "overlay:-",
      ])
    engine.close()
  }

  @Test("enrichments stack in the order turned on, one turned on again going last")
  func enrichments() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let engine = LayersSelectionEngine(map: map)

    engine.toggleEnrichment("hillshade")
    engine.toggleEnrichment("pois")
    engine.toggleEnrichment("hillshade")
    #expect(engine.state.enrichments == ["pois"])
    engine.toggleEnrichment("hillshade")
    await settled()

    #expect(engine.state.enrichments == ["pois", "hillshade"])
    #expect(
      map.calls == [
        "add-enrichment:hillshade", "add-enrichment:pois", "remove-enrichment:hillshade",
        "add-enrichment:hillshade",
      ])
    map.release()
    engine.close()
  }

  @Test("the terrain the map reports is stated once the catalogue lands, unless one was chosen")
  func terrain() async {
    let shows = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let reporting = LayersSelectionEngine(map: shows)
    await settled()
    #expect(reporting.state.terrain == nil)
    shows.terrain = "satellite"
    shows.land(0)
    await settled()
    #expect(reporting.state.terrain == "satellite")
    #expect(reporting.state.catalogue == Self.catalogue)

    let chosen = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let choosing = LayersSelectionEngine(map: chosen)
    choosing.setTerrain("satellite")
    await settled()
    chosen.land(0)
    await settled()
    #expect(choosing.state.terrain == "satellite")
    #expect(chosen.calls == ["terrain:satellite"])

    let none = HeldLayersMap(catalogue: Self.catalogue, terrain: nil, answersAtOnce: true)
    let reportingNone = LayersSelectionEngine(map: none)
    await settled()
    none.land(0)
    await settled()
    #expect(reportingNone.state.terrain == nil)
    #expect(reportingNone.state.catalogue == Self.catalogue)
    #expect(none.calls.isEmpty)
    for engine in [reporting, choosing, reportingNone] { engine.close() }
  }

  @Test("a terrain already selected is asked of the map again")
  func terrainAgain() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors")
    let engine = LayersSelectionEngine(map: map)

    engine.setTerrain("satellite")
    await settled()
    map.refuse(0)
    await settled()
    #expect(Self.shown(engine.state) == "satellite|-||refused")
    engine.setTerrain("satellite")
    await settled()
    #expect(Self.shown(engine.state) == "satellite|-||refused")
    map.accept(1)
    await settled()

    #expect(Self.shown(engine.state) == "satellite|-||kept")
    #expect(map.calls == ["terrain:satellite", "terrain:satellite"])
    map.release()
    engine.close()
  }

  @Test("the outcome of the command settled last stands")
  func lastOutcome() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors")
    let engine = LayersSelectionEngine(map: map)
    await settled()
    map.land(0)
    await settled()

    engine.setOverlay("slopes")
    engine.toggleEnrichment("hillshade")
    await settled()
    map.accept(1)
    await settled()
    #expect(engine.state.refusal == nil)
    map.refuse(0)
    await settled()
    #expect(Self.shown(engine.state) == "outdoors|slopes|hillshade|refused")
    engine.setOverlay("snow-depth")
    #expect(Self.shown(engine.state) == "outdoors|snow-depth|hillshade|refused")
    await settled()
    map.accept(2)
    await settled()

    #expect(Self.shown(engine.state) == "outdoors|snow-depth|hillshade|kept")
    map.release()
    engine.close()
  }

  @Test("a map handed in place of another starts an empty selection, owing it nothing")
  func replaced() async {
    let a = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors")
    let b = HeldLayersMap(catalogue: Self.catalogue, terrain: "satellite")
    let engine = LayersSelectionEngine(map: a)
    engine.setOverlay("slopes")
    await settled()

    engine.configure(map: b)
    #expect(Self.shown(engine.state) == "-|-||kept")
    await settled()
    a.refuse(0)
    a.land(0)
    await settled()
    #expect(Self.shown(engine.state) == "-|-||kept")
    #expect(engine.state.catalogue == nil)
    b.land(0)
    await settled()
    #expect(Self.shown(engine.state) == "satellite|-||kept")

    // The same map brought back starts afresh too, and owes its earlier selection nothing.
    engine.toggleEnrichment("pois")
    await settled()
    engine.configure(map: a)
    await settled()
    b.refuse(0)
    await settled()
    #expect(Self.shown(engine.state) == "-|-||kept")
    #expect(a.reads == 2)
    a.release()
    b.release()
    engine.close()
  }

  @Test("the map it drives handed again changes nothing, unless its catalogue read failed")
  func sameMap() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors")
    let engine = LayersSelectionEngine(map: map)
    engine.setOverlay("slopes")
    await settled()

    engine.configure(map: map)
    await settled()
    #expect(engine.state.overlay == "slopes")
    #expect(map.reads == 1)
    map.failRead(0)
    await settled()
    #expect(engine.state.refusal != nil)
    engine.configure(map: map)
    await settled()
    #expect(map.reads == 2)
    map.land(1)
    await settled()

    #expect(engine.state.catalogue == Self.catalogue)
    #expect(engine.state.refusal == nil)
    #expect(engine.state.overlay == "slopes")
    engine.configure(map: map)
    await settled()
    #expect(map.reads == 2)
    map.release()
    engine.close()
  }

  @Test("with no map a command is held and drives nothing")
  func noMap() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors")
    let engine = LayersSelectionEngine()
    engine.setOverlay("slopes")
    engine.toggleEnrichment("pois")
    engine.setTerrain("satellite")
    await settled()

    #expect(Self.shown(engine.state) == "satellite|slopes|pois|kept")
    engine.configure(map: map)
    await settled()
    #expect(Self.shown(engine.state) == "-|-||kept")
    #expect(map.calls.isEmpty)
    #expect(map.reads == 1)
    map.release()
    engine.close()
  }

  @Test("a stream yields the selection now and each change, and ends at close")
  func streams() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let engine = LayersSelectionEngine(map: map)
    let stream = engine.subscribe()
    await settled()
    map.land(0)
    await settled()
    engine.setOverlay("slopes")
    engine.close()

    var shown: [String] = []
    for await selection in stream {
      shown.append(Self.shown(selection))
    }
    #expect(shown == ["-|-||kept", "outdoors|-||kept", "outdoors|slopes||kept"])
    var after: [String] = []
    for await selection in engine.subscribe() {
      after.append(Self.shown(selection))
    }
    #expect(after == ["outdoors|slopes||kept"])
  }

  @Test("a closed engine is inert: nothing lands, and no command drives the map")
  func closed() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors")
    let engine = LayersSelectionEngine(map: map)
    engine.setOverlay("slopes")
    await settled()
    engine.close()
    map.land(0)
    map.refuse(0)
    engine.setOverlay("snow-depth")
    engine.configure(map: HeldLayersMap(catalogue: Self.catalogue, terrain: nil))
    await settled()

    #expect(Self.shown(engine.state) == "-|slopes||kept")
    #expect(engine.state.catalogue == nil)
    #expect(map.calls == ["overlay:slopes"])
    map.release()
  }

  // MARK: - The instant pinned

  /// noon is 2026-03-15T12:00:00Z, and dawn 2026-03-16T06:00:00Z.
  private static let noon = Date(timeIntervalSince1970: 1_773_576_000)
  private static let dawn = Date(timeIntervalSince1970: 1_773_640_800)

  @Test("a pin is held and driven at once, a later one in its place, none driven as none")
  func instants() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let engine = LayersSelectionEngine(map: map)
    #expect(engine.state.instant == nil)

    engine.setInstant(Self.noon)
    #expect(engine.state.instant == Self.noon, "held as it is asked")
    engine.setInstant(Self.dawn)
    engine.setInstant(nil)
    await settled()

    #expect(engine.state.instant == nil)
    #expect(map.calls == ["instant:1773576000000", "instant:1773640800000", "instant:-"])
    engine.close()
  }

  @Test("the instant already pinned is asked of the map again, and a refusal reported as any")
  func instantAgain() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors")
    let engine = LayersSelectionEngine(map: map)
    var changes = 0
    let stream = engine.subscribe()
    engine.setInstant(Self.noon)
    await settled()
    map.refuse(0)
    await settled()
    #expect(engine.state.instant == Self.noon, "a refused pin is kept")
    #expect(engine.state.refusal != nil)

    engine.setInstant(Self.noon)
    await settled()
    map.accept(1)
    await settled()
    #expect(engine.state.refusal == nil, "the pin asked again settles the refusal")
    #expect(map.calls == ["instant:1773576000000", "instant:1773576000000"])
    engine.close()
    for await _ in stream { changes += 1 }
    #expect(changes == 4, "now, the pin, the refusal, its end: the pin held again tells nothing")
    map.release()
  }

  @Test("a pin stands through every other command, and a replaced map starts with none pinned")
  func instantStands() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let engine = LayersSelectionEngine(map: map)
    engine.setInstant(Self.noon)
    engine.setOverlay("slopes")
    engine.toggleEnrichment("hillshade")
    engine.setTerrain("satellite")
    engine.setOverlay("slopes")
    #expect(engine.state.instant == Self.noon)

    let other = HeldLayersMap(catalogue: Self.catalogue, terrain: nil, answersAtOnce: true)
    engine.configure(map: other)
    #expect(engine.state.instant == nil)
    await settled()
    #expect(other.calls.isEmpty, "the map handed in is told no pin")
    engine.close()
  }

  @Test("a pin that names no instant pins none, and with no map a pin is held and drives nothing")
  func instantRefusedByType() async {
    let map = HeldLayersMap(catalogue: Self.catalogue, terrain: "outdoors", answersAtOnce: true)
    let engine = LayersSelectionEngine(map: map)
    engine.setInstant(Self.noon)
    engine.setInstant(Date(timeIntervalSince1970: .nan))
    #expect(engine.state.instant == nil)
    engine.setInstant(Date(timeIntervalSince1970: 9e12))
    #expect(engine.state.instant == nil, "past the range every SDK holds a time to")
    await settled()
    #expect(map.calls == ["instant:1773576000000", "instant:-", "instant:-"])

    engine.configure(map: nil)
    engine.setInstant(Self.dawn)
    await settled()
    #expect(engine.state.instant == Self.dawn)
    #expect(map.calls.count == 3)
    engine.close()
  }
}
