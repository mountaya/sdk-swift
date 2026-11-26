import MountayaElements
import Testing

@Suite("CameraMotion")
struct CameraMotionTests {
  @Test("a motion is a jump, an ease of a duration or the renderer's own, or a flight")
  func motions() {
    #expect(CameraMotion.ease(duration: nil) != CameraMotion.ease(duration: .zero))
    #expect(CameraMotion.ease(duration: .milliseconds(250)) == .ease(duration: .milliseconds(250)))
    #expect(CameraMotion.jump != CameraMotion.fly)
  }

  @Test("an ease given no duration takes the renderer's own, as the other SDKs' ease does")
  func easeDefault() {
    #expect(CameraMotion.ease() == .ease(duration: nil))
    #expect(CameraMotion.ease() != .ease(duration: .milliseconds(250)))
  }
}
