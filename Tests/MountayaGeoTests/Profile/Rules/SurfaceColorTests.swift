import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("surfaceColor")
struct SurfaceColorTests {
  @Test("each surface paints in its colour, an unclassified or unknown one in the shared grey")
  func colours() {
    #expect(surfaceColors.count == 19)
    #expect(surfaceColor("asphalt") == HexColor(hex: "#334155"))
    #expect(surfaceColor("fine-gravel") == HexColor(hex: "#ca8a04"))
    #expect(surfaceColor(.unknown) == unclassifiedColor)
    #expect(surfaceColor("moon-dust") == unclassifiedColor)
    #expect(unclassifiedColor == HexColor(hex: "#94a3b8"))
  }
}
