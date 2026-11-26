import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("ZoomControl")
@MainActor
struct ZoomControlTests {
  private static let live = Controls.color("#212529")
  private static let dimmed = Controls.color("#adb5bd")

  @Test("each half drives the map, unless a handler stands in for its default, half by half")
  func drives() throws {
    let map = try Maps.engine()
    ZoomControl(map: map).zoomIn()
    #expect(map.state.camera.zoom == 13)
    ZoomControl(map: map).zoomOut()
    #expect(map.state.camera.zoom == 12)

    var taps = 0
    let handled = ZoomControl(map: map, onZoomInTap: { taps += 1 })
    handled.zoomIn()
    #expect(taps == 1)
    #expect(map.state.camera.zoom == 12, "a handler stands in for the map's step")
    handled.zoomOut()
    #expect(map.state.camera.zoom == 11, "the other half still drives the map")
  }

  @Test("where the reader asked for reduced motion, each half's step lands at once")
  func reducedMotion() throws {
    let map = try Maps.engine()
    let surface = ScriptedMapSurface(drawing: map)
    ZoomControl(map: map).zoomIn(reducingMotion: true)
    ZoomControl(map: map).zoomOut(reducingMotion: true)
    ZoomControl(map: map).zoomIn()

    #expect(
      surface.moves.map(\.motion) == [.jump, .jump, .ease(duration: .milliseconds(250))])
    #expect(map.state.camera.zoom == 13)
  }

  @Test("each half follows the map's zoom window, whoever answers its press")
  func window() throws {
    let map = try Maps.engine()
    #expect(ZoomControl.disabledSteps(map).isEmpty)
    try map.setZoomBounds(min: 4, max: 12)
    #expect(ZoomControl.disabledSteps(map) == [.zoomIn])
    try map.jump(to: CameraTarget(zoom: 4))
    #expect(ZoomControl.disabledSteps(map) == [.zoomOut])
    try map.setZoomBounds(min: 4, max: 4)
    #expect(ZoomControl.disabledSteps(map) == [.zoomIn, .zoomOut])
    #expect(ZoomControl.disabledSteps(nil).isEmpty)
  }

  @Test("a half with neither a map nor a handler is inert, and one at its window's end disabled")
  func drawn() throws {
    let map = try Maps.engine()
    let live = try #require(Controls.drawn(ZoomControl(map: map)))
    let inert = try #require(Controls.drawn(ZoomControl(map: nil)))
    let handled = try #require(Controls.drawn(ZoomControl(map: nil, onZoomInTap: {})))
    try map.setZoomBounds(min: 0, max: 12)
    let ceiling = try #require(Controls.drawn(ZoomControl(map: map)))
    let shut = try #require(Controls.drawn(ZoomControl(map: map).disabled(true)))

    #expect(live.size == CGSize(width: 44, height: 88), "zoom in above zoom out, on one chip")
    #expect(Pixels.pixel(live, at: CGPoint(x: 22, y: 22))?.isNear(Self.live) == true)
    #expect(Pixels.pixel(live, at: CGPoint(x: 22, y: 66))?.isNear(Self.live) == true)
    #expect(Pixels.pixel(inert, at: CGPoint(x: 22, y: 22))?.isNear(Self.dimmed) == true)
    #expect(Pixels.pixel(inert, at: CGPoint(x: 22, y: 66))?.isNear(Self.dimmed) == true)
    #expect(Pixels.pixel(handled, at: CGPoint(x: 22, y: 22))?.isNear(Self.live) == true)
    #expect(Pixels.pixel(handled, at: CGPoint(x: 22, y: 66))?.isNear(Self.dimmed) == true)
    #expect(Pixels.pixel(ceiling, at: CGPoint(x: 22, y: 22))?.isNear(Self.dimmed) == true)
    #expect(Pixels.pixel(ceiling, at: CGPoint(x: 22, y: 66))?.isNear(Self.live) == true)
    #expect(Pixels.pixel(shut, at: CGPoint(x: 22, y: 66))?.isNear(Self.dimmed) == true)
  }
}
