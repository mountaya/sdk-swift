import Testing

@testable import MountayaGeo

@Suite("capturesSweptViewports")
struct CapturesSweptViewportsTests {
  private let swept = [
    CameraPose(center: [6.86, 45.92], zoom: 12, pitch: 60, bearing: 30),
    CameraPose(center: [6.87, 45.93], zoom: 12.5, pitch: 60, bearing: 35),
  ]

  @Test("the same frames in fresh values are captured, and two empty sweeps capture each other")
  func sameFrames() {
    let copy = swept.map {
      CameraPose(center: Array($0.center), zoom: $0.zoom, pitch: $0.pitch, bearing: $0.bearing)
    }
    #expect(capturesSweptViewports(swept: swept, captured: copy))
    #expect(capturesSweptViewports(swept: [], captured: []))
  }

  @Test("a frame more or less is not captured")
  func frameCount() {
    #expect(!capturesSweptViewports(swept: swept, captured: swept + [swept[0]]))
    #expect(!capturesSweptViewports(swept: swept, captured: Array(swept.prefix(1))))
    #expect(!capturesSweptViewports(swept: swept, captured: []))
  }

  /// A clearance pass that lowered a frame shows ground the sweep never framed.
  @Test("a frame with any field changed is not captured")
  func changedField() {
    let second = swept[1]
    let changes = [
      CameraPose(center: second.center, zoom: second.zoom, pitch: 52, bearing: second.bearing),
      CameraPose(center: second.center, zoom: 12.4, pitch: second.pitch, bearing: second.bearing),
      CameraPose(center: second.center, zoom: second.zoom, pitch: second.pitch, bearing: 36),
      CameraPose(
        center: [6.87, 45.931], zoom: second.zoom, pitch: second.pitch, bearing: second.bearing),
    ]
    for changed in changes {
      #expect(
        !capturesSweptViewports(swept: swept, captured: [swept[0], changed]), "for \(changed)")
    }
  }

  @Test("the frames are compared in order")
  func order() {
    #expect(!capturesSweptViewports(swept: swept, captured: swept.reversed()))
  }

  @Test("a frame at no number is the same frame on both sides, compared exactly")
  func sameNumber() {
    let unknown = [CameraPose(center: [0, 0], zoom: .nan, pitch: 0, bearing: 0)]
    #expect(capturesSweptViewports(swept: unknown, captured: unknown.map { $0 }))
  }
}
