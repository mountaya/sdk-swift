import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("controlMoveTarget")
struct ControlMoveTargetTests {
  private static let world = ZoomBounds(minZoom: -2, maxZoom: 22)

  private static func camera(zoom: Double, bearing: Double = 0, pitch: Double = 0) -> CameraPose {
    CameraPose(center: [6.86, 45.83], zoom: zoom, pitch: pitch, bearing: bearing)
  }

  @Test("a zoom step moves one level from the zoom the camera stands at, unrounded")
  func steps() {
    #expect(
      controlMoveTarget(Self.camera(zoom: 12.4), window: Self.world, move: .zoomIn).zoom == 13.4)
    #expect(
      controlMoveTarget(Self.camera(zoom: 12.4), window: Self.world, move: .zoomOut).zoom == 11.4)
    #expect(
      controlMoveTarget(Self.camera(zoom: 0.5), window: Self.world, move: .zoomOut).zoom == -0.5)
  }

  @Test("a step past an end of the window stops at it, and one at an end stays")
  func held() {
    #expect(
      controlMoveTarget(Self.camera(zoom: 21.6), window: Self.world, move: .zoomIn).zoom == 22)
    #expect(
      controlMoveTarget(
        Self.camera(zoom: 14), window: ZoomBounds(minZoom: 8, maxZoom: 14), move: .zoomIn
      ).zoom == 14)
    #expect(
      controlMoveTarget(
        Self.camera(zoom: 2.5), window: ZoomBounds(minZoom: 2, maxZoom: 22), move: .zoomOut
      ).zoom == 2)
  }

  @Test("each move keeps every other member, and a reset turns the bearing and the pitch to 0")
  func keeps() {
    let tilted = Self.camera(zoom: 9, bearing: -20, pitch: 30)
    #expect(
      controlMoveTarget(tilted, window: Self.world, move: .zoomIn)
        == CameraPose(center: [6.86, 45.83], zoom: 10, pitch: 30, bearing: -20))
    #expect(
      controlMoveTarget(
        Self.camera(zoom: 13.2, bearing: 37, pitch: 45), window: Self.world, move: .resetNorth)
        == Self.camera(zoom: 13.2))
    #expect(
      controlMoveTarget(Self.camera(zoom: 13.2), window: Self.world, move: .resetNorth)
        == Self.camera(zoom: 13.2))
  }
}
