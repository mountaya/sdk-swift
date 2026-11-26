import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("readCameraTarget")
struct ReadCameraTargetTests {
  @Test("a target is answered as stated, a centre past the antimeridian and a pole included")
  func taken() throws {
    for target in [
      CameraTarget(center: [6.86, 45.83], zoom: 12), CameraTarget(center: [197.5, 0], pitch: 0),
      CameraTarget(center: [-179.9, -16.5], zoom: 9.5, bearing: -30, pitch: 60),
      CameraTarget(zoom: 0, bearing: 0, pitch: 0), CameraTarget(), CameraTarget(center: [0, 90]),
      CameraTarget(center: [0, -90]),
    ] {
      #expect(try readCameraTarget(target) == target)
    }
  }

  @Test("a centre that names no place is refused as a position, naming the centre")
  func position() {
    for center: [Double] in [
      [6, 90.0001], [6.86, 45.83, 1035], [.nan, 45.83], [6], [], [.infinity, 0],
    ] {
      #expect(throws: MapError(kind: .positionRefused, name: "center")) {
        try readCameraTarget(CameraTarget(center: center, zoom: .nan))
      }
    }
  }

  @Test("a zoom, a bearing or a pitch that is no finite number is refused, naming it")
  func numbers() {
    #expect(throws: MapError(kind: .numberRefused, name: "zoom")) {
      try readCameraTarget(CameraTarget(center: [6.86, 45.83], zoom: -.infinity))
    }
    #expect(throws: MapError(kind: .numberRefused, name: "bearing")) {
      try readCameraTarget(CameraTarget(bearing: .infinity, pitch: .nan))
    }
    #expect(throws: MapError(kind: .numberRefused, name: "pitch")) {
      try readCameraTarget(CameraTarget(pitch: .nan))
    }
  }
}
