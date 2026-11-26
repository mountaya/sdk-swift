import MountayaElements
import Testing

@Suite("GeolocationRefusal")
struct GeolocationRefusalTests {
  @Test("each reason is spelled as the contract spells it")
  func spellings() {
    #expect(GeolocationRefusal.allCases.map(\.rawValue) == ["denied", "no_api", "unavailable"])
  }
}
