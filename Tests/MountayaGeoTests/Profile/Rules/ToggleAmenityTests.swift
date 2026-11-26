import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("toggleAmenity")
struct ToggleAmenityTests {
  @Test("a press adds its service at the end, or takes a picked one out")
  func toggle() {
    #expect(toggleAmenity("water", in: ["food"]) == ["food", "water"])
    #expect(toggleAmenity("water", in: ["water", "food"]) == ["food"])
    #expect(toggleAmenity("water", in: ["water", "food", "water"]) == ["food"])
    #expect(toggleAmenity("water", in: []) == ["water"])
  }
}
