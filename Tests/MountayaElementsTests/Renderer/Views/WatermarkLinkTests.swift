import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("WatermarkLink")
@MainActor
struct WatermarkLinkTests {
  @Test("every shape of the drawing is read into its paths once")
  func paths() throws {
    let drawing = try #require(GlyphDrawing.artwork["watermark"])
    #expect(WatermarkDrawing.paths.count == drawing.shapes.count)
    #expect(WatermarkDrawing.paths.allSatisfy { !$0.isEmpty })
  }

  @Test("a map whose client holds no publishable key draws the mark at once, in white over the map")
  func drawn() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          WatermarkLink(engine: map)
        }
        .frame(width: 200, height: 120)))

    #expect(map.isWatermarked)
    // The wordmark, white at the drawing's opacity, about two fifths of the way down the mark.
    let light = (40..<140).contains { x in
      guard let pixel = Pixels.pixel(image, at: CGPoint(x: x, y: 31)) else { return false }
      return pixel.red > 160 && pixel.green > 160 && pixel.blue > 160
    }
    #expect(light)
  }

  @Test("in a layout that runs right to left, the mark stands at the top left all the same")
  func rightToLeft() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          WatermarkLink(engine: map)
        }
        .frame(width: 400, height: 120)
        .environment(\.layoutDirection, .rightToLeft)))

    func light(at x: Int) -> Bool {
      guard let pixel = Pixels.pixel(image, at: CGPoint(x: x, y: 31)) else { return false }
      return pixel.red > 160 && pixel.green > 160 && pixel.blue > 160
    }
    #expect((40..<140).contains(where: light), "the wordmark top left")
    #expect(!(260..<360).contains(where: light), "and nothing of it top right")
  }

  @Test("a map whose read is waiting draws no mark")
  func waiting() throws {
    let map = try Maps.engine()
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          WatermarkLink(engine: map)
        }
        .frame(width: 200, height: 120)))

    #expect(!map.isWatermarked)
    #expect(
      Pixels.pixel(image, at: CGPoint(x: 60, y: 31))?.isNear(Controls.color("#000000")) == true)
  }

  @Test("the mark is clipped to the map it is laid over, drawing nothing past its edges")
  func clipped() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          ZStack(alignment: .topLeading) {
            Color.black
            WatermarkLink(engine: map)
          }
          .frame(width: 30, height: 120)
        }
        .frame(width: 200, height: 120)))

    // The wordmark runs past 30 points, which a mark clipped to its map draws nothing of.
    let light = (40..<140).contains { x in
      guard let pixel = Pixels.pixel(image, at: CGPoint(x: x, y: 31)) else { return false }
      return pixel.red > 160 && pixel.green > 160 && pixel.blue > 160
    }
    #expect(map.isWatermarked)
    #expect(!light)
  }

  @Test("press hands the mark's link to the opener")
  func press() {
    let system = WatermarkLink.opener
    defer { WatermarkLink.opener = system }
    var opened: [URL] = []
    WatermarkLink.opener = { opened.append($0) }

    WatermarkLink.press("https://www.mountaya.com/fr/")

    #expect(opened.map(\.absoluteString) == ["https://www.mountaya.com/fr/"])
  }

  @Test("the mark stands in the map's safe area, under a status bar a full-bleed map spans")
  func safeArea() throws {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    map.safeAreaShown(PixelPadding(top: 60, right: 0, bottom: 0, left: 0))
    let image = try #require(
      Controls.drawn(
        ZStack(alignment: .topLeading) {
          Color.black
          WatermarkLink(engine: map)
        }
        .frame(width: 200, height: 200)))

    func light(at y: CGFloat) -> Bool {
      (40..<140).contains { x in
        guard let pixel = Pixels.pixel(image, at: CGPoint(x: CGFloat(x), y: y)) else {
          return false
        }
        return pixel.red > 160 && pixel.green > 160 && pixel.blue > 160
      }
    }
    #expect(light(at: 91), "the wordmark stands 60 points lower")
    #expect(!light(at: 31), "and nothing of it under the status bar")
  }
}
