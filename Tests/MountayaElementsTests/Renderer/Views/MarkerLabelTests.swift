import MountayaClient
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("MarkerLabel")
@MainActor
struct MarkerLabelTests {
  /// ground is the tooltip's ground under the light scheme.
  private static let ground = Controls.color("#212529")
  /// black is the canvas the label is laid over.
  private static let black = Controls.color("#000000")

  /// labelled draws the label `callout` shows over a black canvas 200 by 120 points, in
  /// `direction`.
  private static func labelled(
    _ map: MapEngine, callout: MarkerCallout, direction: LayoutDirection = .leftToRight
  ) -> UIImage? {
    Controls.drawn(
      ZStack(alignment: .topLeading) {
        Color.black
        MarkerLabel(engine: map, callout: callout)
      }
      .frame(width: 200, height: 120)
      .environment(\.layoutDirection, direction))
  }

  /// map is a map drawing a marker at the point 120, 100 of a canvas, below the watermark's frame,
  /// its label holding no ink. Its projection reads a position's latitude at twice its value, so
  /// every point of the 120-point canvas is a position a map draws: the engine refuses a latitude
  /// past 90, and a projection reading a position as its point would need one.
  private static func map() throws -> (MapEngine, ScriptedMapSurface) {
    let map = MapEngine(
      client: try Mountaya(credential: .share(token: "share_0a"), exchange: Maps.Offline()))
    let surface = ScriptedMapSurface(drawing: map, canvas: [200, 120])
    surface.projection = ScreenProjection(
      point: { [$0[0], $0[1] * 2] }, position: { [$0[0], $0[1] / 2] })
    try map.addMarker(
      MapMarker(id: "hut", position: [120, 50], label: String(repeating: "\u{00A0}", count: 12)))
    return (map, surface)
  }

  @Test("the label starts past the marker's pin toward the end its text runs to")
  func placed() throws {
    let (map, surface) = try Self.map()
    let callout = MarkerCallout()
    callout.show("hut")
    let leftToRight = try #require(Self.labelled(map, callout: callout))
    let rightToLeft = try #require(
      Self.labelled(map, callout: callout, direction: .rightToLeft))

    #expect(Pixels.pixel(leftToRight, at: CGPoint(x: 150, y: 100))?.isNear(Self.ground) == true)
    #expect(Pixels.pixel(leftToRight, at: CGPoint(x: 116, y: 100))?.isNear(Self.black) == true)
    #expect(Pixels.pixel(rightToLeft, at: CGPoint(x: 90, y: 100))?.isNear(Self.ground) == true)
    #expect(Pixels.pixel(rightToLeft, at: CGPoint(x: 124, y: 100))?.isNear(Self.black) == true)
    withExtendedLifetime(surface) {}
  }

  @Test("a label that would lay over the watermark's frame moves clear of it, below it here")
  func clearOfTheMark() throws {
    let (map, surface) = try Self.map()
    try map.addMarker(
      MapMarker(id: "col", position: [60, 15.5], label: String(repeating: "\u{00A0}", count: 12)))
    let callout = MarkerCallout()
    callout.show("col")
    let image = try #require(Self.labelled(map, callout: callout))

    #expect(Pixels.pixel(image, at: CGPoint(x: 84, y: 31))?.isNear(Self.black) == true)
    let below = (72..<100).contains { y in
      Pixels.pixel(image, at: CGPoint(x: 84, y: y))?.isNear(Self.ground) == true
    }
    #expect(below, "its top at the frame's bottom, the shorter move")
    withExtendedLifetime(surface) {}
  }

  @Test("a label keeps to the map's safe area, never past the map's edge")
  func insideTheSafeArea() throws {
    let (map, surface) = try Self.map()
    try map.addMarker(
      MapMarker(id: "edge", position: [190, 50], label: String(repeating: "\u{00A0}", count: 12)))
    let callout = MarkerCallout()
    callout.show("edge")
    let image = try #require(Self.labelled(map, callout: callout))

    #expect(
      Pixels.pixel(image, at: CGPoint(x: 196, y: 100))?.isNear(Self.ground) == true,
      "held inside the map's right edge rather than cut by it")
    withExtendedLifetime(surface) {}
  }

  @Test("a marker whose point is off the map shows no label, never one held at the map's edge")
  func offTheMap() throws {
    let (map, surface) = try Self.map()
    try map.addMarker(
      MapMarker(id: "away", position: [250, 30], label: String(repeating: "\u{00A0}", count: 12)))
    let callout = MarkerCallout()
    let none = try #require(Self.labelled(map, callout: callout))
    callout.show("away")
    let away = try #require(Self.labelled(map, callout: callout))

    #expect(
      Pixels.pixel(away, at: CGPoint(x: 196, y: 60))?.isNear(Self.black) == true,
      "not held inside the map's right edge without its pin")
    #expect(away.pngData() == none.pngData())
    let canvas = CGSize(width: 200, height: 120)
    #expect(MarkerLabel.placed((text: "Hut", point: [120, 100]), canvas: canvas) != nil)
    #expect(MarkerLabel.placed((text: "Hut", point: [250, 60]), canvas: canvas) == nil)
    #expect(MarkerLabel.placed((text: "Hut", point: [120, -4]), canvas: canvas) == nil)
    #expect(MarkerLabel.placed((text: "Hut", point: [.nan, 60]), canvas: canvas) == nil)
    withExtendedLifetime(surface) {}
  }

  @Test("no marker labelled, one with no label, or one the map holds no more shows nothing")
  func nothing() throws {
    let (map, surface) = try Self.map()
    try map.addMarker(MapMarker(id: "summit", position: [120, 30]))
    let callout = MarkerCallout()
    let none = try #require(Self.labelled(map, callout: callout))
    callout.show("summit")
    let unlabelled = try #require(Self.labelled(map, callout: callout))
    callout.show("gone")
    let gone = try #require(Self.labelled(map, callout: callout))

    #expect(Pixels.pixel(none, at: CGPoint(x: 84, y: 31))?.isNear(Self.black) == true)
    #expect(unlabelled.pngData() == none.pngData())
    #expect(gone.pngData() == none.pngData())
    withExtendedLifetime(surface) {}
  }
}
