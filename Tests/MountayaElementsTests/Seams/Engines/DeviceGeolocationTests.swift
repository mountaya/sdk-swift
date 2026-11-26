import Foundation
import Testing

@testable import MountayaElements

#if canImport(CoreLocation)
  import CoreLocation

  @Suite("DeviceGeolocation")
  @MainActor
  struct DeviceGeolocationTests {
    /// Platform is the location services a test scripts: the app's permission, a fix held, and
    /// each fix asked for.
    final class Platform: DeviceGeolocation.Platform {
      var authorizationStatus: CLAuthorizationStatus = .notDetermined
      var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
      var location: CLLocation?
      private(set) var requested = 0

      func requestLocation() {
        requested += 1
      }
    }

    private static let start = Date(timeIntervalSince1970: 1_800_000_000)

    private static func fix(_ position: [Double], accuracy: Double, at time: Date) -> CLLocation {
      CLLocation(
        coordinate: CLLocationCoordinate2D(latitude: position[1], longitude: position[0]),
        altitude: 0, horizontalAccuracy: accuracy, verticalAccuracy: -1, timestamp: time)
    }

    private static func geolocation(_ platform: Platform, timeout: Duration = .seconds(10))
      -> DeviceGeolocation
    {
      DeviceGeolocation(platform: platform, now: { start }, timeout: timeout)
    }

    @Test("a permission never asked answers denied and reads prompt, and nothing is asked")
    func neverAsked() async {
      let platform = Platform()
      let geolocation = Self.geolocation(platform)
      #expect(await geolocation.locate() == .refused(.denied))
      #expect(await geolocation.permission() == .prompt)
      #expect(platform.requested == 0)
    }

    @Test("a permission refused, restricted or approximate answers denied")
    func refused() async {
      let platform = Platform()
      let geolocation = Self.geolocation(platform)
      for status: CLAuthorizationStatus in [.denied, .restricted] {
        platform.authorizationStatus = status
        #expect(await geolocation.locate() == .refused(.denied))
        #expect(await geolocation.permission() == .denied)
      }
      platform.authorizationStatus = .authorizedAlways
      platform.accuracyAuthorization = .reducedAccuracy
      #expect(await geolocation.locate() == .refused(.denied), "an approximate fix is read nowhere")
      #expect(await geolocation.permission() == .denied)
      #expect(platform.requested == 0)
    }

    @Test("a fix the platform made within a minute is answered at once, with its accuracy")
    func held() async {
      let platform = Platform()
      platform.authorizationStatus = .authorizedAlways
      platform.location = Self.fix(
        [6.86, 45.83], accuracy: 25, at: Self.start.addingTimeInterval(-59))
      let geolocation = Self.geolocation(platform)
      #expect(await geolocation.locate() == .located(position: [6.86, 45.83], accuracyMeters: 25))
      #expect(await geolocation.permission() == .granted)
      #expect(platform.requested == 0)
    }

    @Test("an older fix is asked for again, and answered with the location the platform reports")
    func asked() async {
      let platform = Platform()
      platform.authorizationStatus = .authorizedAlways
      platform.location = Self.fix(
        [6.86, 45.83], accuracy: 25, at: Self.start.addingTimeInterval(-61))
      let geolocation = Self.geolocation(platform)
      async let answered = geolocation.locate()
      while platform.requested == 0 {
        await Task.yield()
      }
      geolocation.received([
        Self.fix([7, 46], accuracy: 10, at: Self.start),
        Self.fix([8, 47], accuracy: -1, at: Self.start),
      ])
      #expect(await answered == .located(position: [7, 46], accuracyMeters: 10))
      #expect(platform.requested == 1)
    }

    @Test("a fix the platform finds none of, or that the reader stops allowing, is no fix")
    func unanswered() async {
      let platform = Platform()
      platform.authorizationStatus = .authorizedAlways
      let geolocation = Self.geolocation(platform)
      async let failed = geolocation.locate()
      while platform.requested == 0 {
        await Task.yield()
      }
      geolocation.failed()
      #expect(await failed == .refused(.unavailable))

      async let withdrawn = geolocation.locate()
      while platform.requested == 1 {
        await Task.yield()
      }
      platform.authorizationStatus = .denied
      geolocation.permissionChanged()
      #expect(await withdrawn == .refused(.denied))
    }

    @Test("a fix that does not arrive in time is unavailable")
    func timeout() async {
      let platform = Platform()
      platform.authorizationStatus = .authorizedAlways
      let geolocation = Self.geolocation(platform, timeout: .milliseconds(20))
      #expect(await geolocation.locate() == .refused(.unavailable))
    }
  }
#else
  @Suite("DeviceGeolocation")
  @MainActor
  struct DeviceGeolocationTests {
    @Test("a platform with no location services answers no API, and does not say its permission")
    func noApi() async {
      let geolocation = DeviceGeolocation()
      #expect(await geolocation.locate() == .refused(.noApi))
      #expect(await geolocation.permission() == .unknown)
    }
  }
#endif
