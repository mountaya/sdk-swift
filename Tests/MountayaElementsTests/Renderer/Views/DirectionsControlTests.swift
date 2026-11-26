import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("DirectionsControl")
@MainActor
struct DirectionsControlTests {
  @Test("an action control is live with no map at all, and shut by a disabled flag")
  func live() throws {
    let live = try #require(Controls.drawn(DirectionsControl(onTap: {})))
    let shut = try #require(Controls.drawn(DirectionsControl(onTap: {}).disabled(true)))

    // The route's lower circle stands at (18, 19) of the glyph's box, its ring drawn.
    #expect(
      Pixels.pixel(live, at: CGPoint(x: 27, y: 30.5))?.isNear(Controls.color("#212529")) == true)
    #expect(
      Pixels.pixel(shut, at: CGPoint(x: 27, y: 30.5))?.isNear(Controls.color("#adb5bd")) == true)
  }
}
