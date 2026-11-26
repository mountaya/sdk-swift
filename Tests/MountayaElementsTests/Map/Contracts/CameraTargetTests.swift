import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("CameraTarget")
struct CameraTargetTests {
  private static let camera = CameraPose(center: [6.86, 45.83], zoom: 12, pitch: 30, bearing: 15)

  @Test("a target states its members, each nil keeping the camera's own")
  func members() {
    let target = CameraTarget(center: [7, 46], pitch: 0)
    #expect(target.zoom == nil && target.bearing == nil)
    #expect(
      target.applied(to: Self.camera)
        == CameraPose(center: [7, 46], zoom: 12, pitch: 0, bearing: 15))
    #expect(CameraTarget().applied(to: Self.camera) == Self.camera)
    #expect(
      CameraTarget(center: [197.5, 0]).applied(to: Self.camera).center == [197.5, 0],
      "a centre past the antimeridian is kept as written")
  }

  @Test("two targets are equal where they state the same members, each the same number")
  func equality() {
    #expect(CameraTarget(zoom: .nan) == CameraTarget(zoom: .nan))
    #expect(CameraTarget(zoom: 0) != CameraTarget(zoom: -0.0))
    #expect(CameraTarget(zoom: 0) != CameraTarget())
    #expect(CameraTarget(center: [6, 45]) != CameraTarget(center: [6, 45, 0]))
    #expect(CameraTarget(bearing: 1, pitch: 2) == CameraTarget(bearing: 1, pitch: 2))
  }
}
