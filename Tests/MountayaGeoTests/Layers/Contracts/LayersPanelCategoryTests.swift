import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersPanelCategory")
struct LayersPanelCategoryTests {
  @Test("two categories are equal where their slugs and their names are, by their scalars")
  func equality() {
    let hazards = LayersPanelCategory(slug: "hazards", name: "Hazards")

    #expect(hazards == LayersPanelCategory(slug: "hazards", name: "Hazards"))
    #expect(hazards != LayersPanelCategory(slug: "hazards", name: "Dangers"))
    #expect(hazards != LayersPanelCategory(slug: "weather", name: "Hazards"))
    #expect(
      LayersPanelCategory(slug: "m\u{E9}t\u{E9}o", name: "M")
        != LayersPanelCategory(slug: "me\u{301}te\u{301}o", name: "M"))
    #expect(
      LayersPanelCategory(slug: "weather", name: "M\u{E9}t\u{E9}o")
        != LayersPanelCategory(slug: "weather", name: "Me\u{301}te\u{301}o"))
    #expect(Set([hazards, LayersPanelCategory(slug: "hazards", name: "Hazards")]).count == 1)
  }
}
