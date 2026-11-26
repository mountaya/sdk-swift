import MountayaElements
import MountayaGeo
import RendererSupport
import SwiftUI
import Testing

@testable import MountayaElements

@Suite("CompassControl")
@MainActor
struct CompassControlTests {
  @Test("a press turns the map back to north and level, unless a handler stands in for it")
  func drives() throws {
    let map = try Maps.engine(
      camera: CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 40, bearing: 90))
    var taps = 0
    CompassControl(map: map, onTap: { taps += 1 }).tap()
    #expect(taps == 1)
    #expect(map.state.camera.bearing == 90)

    CompassControl(map: map).tap()
    #expect(map.state.camera.bearing == 0)
    #expect(map.state.camera.pitch == 0)
  }

  @Test("where the reader asked for reduced motion, the map turns back at once")
  func reducedMotion() throws {
    let map = try Maps.engine(
      camera: CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 40, bearing: 90))
    let surface = ScriptedMapSurface(drawing: map)
    CompassControl(map: map).tap(reducingMotion: true)

    #expect(surface.moves == [.init(target: CameraTarget(bearing: 0, pitch: 0), motion: .jump)])
    #expect(map.state.camera.bearing == 0)
  }

  @Test("the rose turns against the camera's bearing, and points up with no map")
  func drawn() throws {
    let map = try Maps.engine(
      camera: CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 0, bearing: 180))
    let turned = try #require(Controls.drawn(CompassControl(map: map)))
    let upright = try #require(Controls.drawn(CompassControl(map: nil)))
    let needle = Controls.color("#e9501e")

    #expect(turned.size == CGSize(width: 44, height: 44))
    // The rose is 34 points across in the middle of the button: its needle's tip is 7 points from
    // the top of the button pointing up, and as far from the bottom turned around.
    #expect(Pixels.pixel(upright, at: CGPoint(x: 22, y: 14.5))?.isNear(needle) == true)
    #expect(Pixels.pixel(turned, at: CGPoint(x: 22, y: 29.5))?.isNear(needle) == true)
  }
}
