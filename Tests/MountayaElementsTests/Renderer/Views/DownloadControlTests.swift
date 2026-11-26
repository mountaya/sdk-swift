import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("DownloadControl")
@MainActor
struct DownloadControlTests {
  @Test("an action control is live with no map at all, its handler the one it drives")
  func live() throws {
    let live = try #require(Controls.drawn(DownloadControl(onTap: {})))
    let shut = try #require(Controls.drawn(DownloadControl(onTap: {}).disabled(true)))

    #expect(live.size == CGSize(width: 44, height: 44))
    // The download arrow's shaft runs down the middle of the glyph.
    #expect(
      Pixels.pixel(live, at: CGPoint(x: 22, y: 20))?.isNear(Controls.color("#212529")) == true)
    #expect(
      Pixels.pixel(shut, at: CGPoint(x: 22, y: 20))?.isNear(Controls.color("#adb5bd")) == true)
  }
}
