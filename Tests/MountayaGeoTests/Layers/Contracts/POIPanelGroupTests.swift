import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("POIPanelGroup")
struct POIPanelGroupTests {
  @Test("two groups are equal where every member is, a text by its scalars")
  func equality() {
    let water = POIPanelGroup(id: "water", label: "Water", keys: ["spring", "fountain"])

    #expect(water.glyph == nil)
    #expect(water == POIPanelGroup(id: "water", label: "Water", keys: ["spring", "fountain"]))
    #expect(water != POIPanelGroup(id: "water", label: "Water", keys: ["fountain", "spring"]))
    #expect(water != POIPanelGroup(id: "water", label: "Water", keys: ["spring"]))
    #expect(
      water
        != POIPanelGroup(id: "water", label: "Water", keys: ["spring", "fountain"], glyph: "pin"))
    #expect(
      POIPanelGroup(id: "\u{E9}", label: "", keys: [])
        != POIPanelGroup(id: "e\u{301}", label: "", keys: []))
  }
}
