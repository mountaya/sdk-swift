import MountayaElements
import Testing

@Suite("GeolocationFix")
struct GeolocationFixTests {
  @Test("two fixes are equal where they hold the same, each number the same")
  func equality() {
    #expect(
      GeolocationFix.located(position: [6.86, 45.83], accuracyMeters: .nan)
        == .located(position: [6.86, 45.83], accuracyMeters: .nan))
    #expect(
      GeolocationFix.located(position: [6.86, 45.83], accuracyMeters: 0)
        != .located(position: [6.86, 45.83], accuracyMeters: -0.0))
    #expect(GeolocationFix.refused(.denied) != .refused(.unavailable))
    #expect(GeolocationFix.refused(.noApi) != .located(position: [], accuracyMeters: 0))
  }
}
