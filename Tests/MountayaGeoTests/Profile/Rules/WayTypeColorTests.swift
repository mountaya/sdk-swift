import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("wayTypeColor")
struct WayTypeColorTests {
  @Test("each way type paints in its colour, an unclassified or unknown one in the shared grey")
  func colours() {
    #expect(wayTypeColors.count == 11)
    #expect(wayTypeColor("cycleway") == HexColor(hex: "#3b82f6"))
    #expect(wayTypeColor("path") == HexColor(hex: "#22c55e"))
    #expect(wayTypeColor(.unknown) == unclassifiedColor)
    #expect(wayTypeColor("bridleway") == unclassifiedColor)
  }
}
