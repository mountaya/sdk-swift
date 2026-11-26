import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("MapChrome")
@MainActor
struct MapChromeTests {
  /// chrome lays the chrome of `map` over a black canvas 200 by 120 points, as a map's.
  private static func chrome(_ map: MapEngine, callout: MarkerCallout) -> some View {
    ZStack(alignment: .topLeading) {
      Color.black
      MapChrome(engine: map, callout: callout)
    }
    .frame(width: 200, height: 120)
  }

  /// isLight tells whether the pixel of `image` at `x`, 31 points down, is the wordmark's white.
  private static func isLight(_ image: UIImage, at x: Int) -> Bool {
    guard let pixel = Pixels.pixel(image, at: CGPoint(x: x, y: 31)) else { return false }
    return pixel.red > 160 && pixel.green > 160 && pixel.blue > 160
  }

  @Test("a marker's label stands above the watermark, as a map's popups do, and never over it")
  func labelClearOfMark() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    let surface = ScriptedMapSurface(drawing: map, canvas: [200, 120])
    // The label holds no ink, so its ground alone stands where it is drawn.
    let blank = String(repeating: "\u{00A0}", count: 24)
    try map.addMarker(MapMarker(id: "hut", position: [60, 31], label: blank))
    let callout = MarkerCallout()
    let bare = try #require(Controls.drawn(Self.chrome(map, callout: callout)))
    callout.show("hut")
    let labelled = try #require(Controls.drawn(Self.chrome(map, callout: callout)))

    let marked = (90..<130).filter { Self.isLight(bare, at: $0) }
    #expect(!marked.isEmpty, "the wordmark runs where the label would stand beside its pin")
    #expect(
      marked.allSatisfy { Self.isLight(labelled, at: $0) },
      "the label moved clear of the mark, which stays whole")
    let ground = Controls.color("#212529")
    let below = (72..<120).contains { y in
      Pixels.pixel(labelled, at: CGPoint(x: 100, y: y))?.isNear(ground) == true
    }
    #expect(below, "the label stands under the frame, the shorter move")
    withExtendedLifetime(surface) {}
  }

  @Test("in a layout that runs right to left, the mark stands top left all the same")
  func rightToLeft() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    let image = try #require(
      Controls.drawn(
        Self.chrome(map, callout: MarkerCallout()).environment(\.layoutDirection, .rightToLeft)))

    #expect(map.isWatermarked)
    #expect((40..<140).contains { Self.isLight(image, at: $0) }, "the wordmark top left")
  }
}
