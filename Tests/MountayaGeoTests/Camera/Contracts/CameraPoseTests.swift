import Testing

@testable import MountayaGeo

@Suite("CameraPose")
struct CameraPoseTests {
  private let pose = CameraPose(center: [6.86, 45.92], zoom: 12, pitch: 60, bearing: 30)

  @Test("two poses are equal where every field is, and hash alike")
  func equality() {
    let copy = CameraPose(center: [6.86, 45.92], zoom: 12, pitch: 60, bearing: 30)
    #expect(pose == copy)
    #expect(pose.hashValue == copy.hashValue)
    #expect(pose != CameraPose(center: [6.86, 45.921], zoom: 12, pitch: 60, bearing: 30))
    #expect(pose != CameraPose(center: [6.86, 45.92], zoom: 11.8, pitch: 60, bearing: 30))
    #expect(pose != CameraPose(center: [6.86, 45.92], zoom: 12, pitch: 52, bearing: 30))
    #expect(pose != CameraPose(center: [6.86, 45.92], zoom: 12, pitch: 60, bearing: 31))
  }

  @Test("two poses compare their numbers as the same numbers")
  func sameNumbers() {
    let unknown = CameraPose(center: [0, 0], zoom: .nan, pitch: 0, bearing: 0)
    #expect(unknown == CameraPose(center: [0, 0], zoom: .nan, pitch: 0, bearing: 0))
    #expect(
      unknown.hashValue == CameraPose(center: [0, 0], zoom: .nan, pitch: 0, bearing: 0).hashValue)
    #expect(
      CameraPose(center: [0, 0], zoom: 12, pitch: 0, bearing: 0)
        != CameraPose(center: [0, 0], zoom: 12, pitch: 0, bearing: -0.0))
  }

  @Test("each field is named by what it holds")
  func description() {
    #expect(
      String(describing: pose)
        == "CameraPose(center: [6.86, 45.92], zoom: 12.0, pitch: 60.0, bearing: 30.0)")
  }
}
