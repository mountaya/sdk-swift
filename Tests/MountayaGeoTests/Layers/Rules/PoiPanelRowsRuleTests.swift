import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("poiPanelRows")
struct PoiPanelRowsRuleTests {
  /// shown reads each row as `id:keys:on`.
  private static func shown(_ offer: POIPanelRows) -> [String] {
    offer.rows.map { "\($0.id):\($0.keys.joined(separator: "+")):\($0.isVisible)" }
  }

  /// hiding answers a key shown unless it is among `hidden`.
  private static func hiding(_ hidden: [String]) -> (String) -> Bool {
    { key in !hidden.contains(key) }
  }

  @Test("a row per concept drawn, in the order drawn, each on while shown")
  func drawn() {
    let offer = poiPanelRows(
      drawn: ["parking", "poi_food"], isKeyVisible: Self.hiding(["parking"]))

    #expect(Self.shown(offer) == ["parking:parking:false", "poi_food:poi_food:true"])
    #expect(offer.rows.map(\.label) == ["parking", "poi_food"])
    #expect(offer.isAnyVisible)
  }

  @Test("the master row is off only while every row is")
  func master() {
    let off = poiPanelRows(
      drawn: ["parking", "poi_food"], isKeyVisible: Self.hiding(["parking", "poi_food"]))

    #expect(!off.isAnyVisible)
    #expect(!poiPanelRows(drawn: [], isKeyVisible: { _ in true }).isAnyVisible)
  }

  @Test("a curated key list offers what is drawn, in its own order, each labelled as handed")
  func keys() {
    let offer = poiPanelRows(
      drawn: ["poi_food", "parking"], isKeyVisible: { _ in true },
      keys: ["parking", "toilets", "poi_food"], labels: ["parking": "Parking"])

    #expect(Self.shown(offer) == ["parking:parking:true", "poi_food:poi_food:true"])
    #expect(offer.rows.map(\.label) == ["Parking", "poi_food"])
  }

  @Test("a group drives its drawn keys alone, on while any is shown, and none drawn is no row")
  func groups() {
    let groups = [
      POIPanelGroup(
        id: "water", label: "Water", keys: ["spring", "drinking_water", "fountain"], glyph: "pin"),
      POIPanelGroup(id: "parking", label: "Parking", keys: ["parking"]),
      POIPanelGroup(id: "huts", label: "Huts", keys: ["hut"]),
    ]
    let some = poiPanelRows(
      drawn: ["spring", "fountain", "parking"], isKeyVisible: Self.hiding(["fountain"]),
      groups: groups)
    let none = poiPanelRows(
      drawn: ["spring", "fountain", "parking"], isKeyVisible: Self.hiding(["spring", "fountain"]),
      groups: groups)

    #expect(Self.shown(some) == ["water:spring+fountain:true", "parking:parking:true"])
    #expect(some.rows.map(\.label) == ["Water", "Parking"])
    #expect(some.rows.map(\.glyph) == ["pin", nil])
    #expect(Self.shown(none) == ["water:spring+fountain:false", "parking:parking:true"])
  }

  @Test("groups supersede a key list, and groups the app holds read its word")
  func held() {
    let groups = [
      POIPanelGroup(id: "water", label: "Water", keys: ["spring"]),
      POIPanelGroup(id: "parking", label: "Parking", keys: ["parking"]),
    ]
    let superseded = poiPanelRows(
      drawn: ["spring", "parking"], isKeyVisible: { _ in true }, keys: ["parking"],
      groups: [groups[0]])
    let owned = poiPanelRows(
      drawn: ["spring", "parking"], isKeyVisible: { _ in true }, groups: groups,
      activeGroups: ["parking"])

    #expect(Self.shown(superseded) == ["water:spring:true"])
    #expect(Self.shown(owned) == ["water:spring:false", "parking:parking:true"])
    #expect(owned.isAnyVisible)
  }

  @Test("keys are read by their scalars")
  func scalars() {
    let offer = poiPanelRows(
      drawn: ["caf\u{E9}"], isKeyVisible: { _ in true }, keys: ["cafe\u{301}", "caf\u{E9}"])

    #expect(offer.rows.map(\.id) == ["caf\u{E9}"])
  }

  @Test("the note's zoom is the overlay's floor, and none for a floor left out or no number")
  func noteZoom() {
    #expect(poiPanelNoteZoom(12) == 12)
    #expect(poiPanelNoteZoom(nil) == -.infinity)
    #expect(poiPanelNoteZoom(.nan) == -.infinity)
    #expect(poiPanelNoteZoom(-.infinity) == -.infinity)
    // The note stands below the floor, never at it.
    #expect(!(11.9 >= poiPanelNoteZoom(12)))
    #expect(12 >= poiPanelNoteZoom(12))
    #expect(3 >= poiPanelNoteZoom(.nan))
  }
}
