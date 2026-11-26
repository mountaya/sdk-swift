import MountayaElements
import Testing

@Suite("Geolocation")
@MainActor
struct GeolocationTests {
  /// Held is a geolocation of an app's own, answering a fix its own location stack holds.
  struct Held: Geolocation {
    let fix: GeolocationFix

    func locate() async -> GeolocationFix { fix }
    func permission() async -> GeolocationPermission { .granted }
  }

  /// The device's own geolocation answers a fix of the last minute at once, and waits ten seconds
  /// at most for one: `map/camera-locate.json`'s `maxFixAgeMs` and `fixWaitMs`.
  @Test("the device's own geolocation answers a minute-old fix and waits ten seconds for one")
  func deviceTimes() {
    #expect(locateMaxFixAge == .seconds(60))
    #expect(locateFixWait == .seconds(10))
  }

  @Test("an app hands a map a geolocation of its own, a value as well as an object")
  func own() async {
    let held: any Geolocation = Held(fix: .located(position: [6.86, 45.83], accuracyMeters: 12))
    #expect(await held.locate() == .located(position: [6.86, 45.83], accuracyMeters: 12))
    #expect(await held.permission() == .granted)
  }
}
