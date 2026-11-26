#if canImport(CoreLocation)
  internal import CoreLocation
  import Foundation

  /// DeviceGeolocation answers the device's position from the platform's location services, one
  /// fix at a time, for a map to frame (`map.camera.locate`).
  ///
  /// It never asks for location access: it reads a fix only while the app holds a permission to,
  /// `whenInUse` or `always`, at full accuracy, so the prompt and its wording stay the app's. A fix
  /// asked for before the app has asked answers `denied`, and the permission reads `prompt`, which is
  /// the app's cue to run its own flow. A reader who turned precise location off is located nowhere
  /// rather than kilometres away: under reduced accuracy it answers `denied`, and it never asks for
  /// more. A fix the platform made within `locateMaxFixAge`, a minute, is answered at once;
  /// otherwise it asks the platform for one and answers `unavailable` where none arrives within
  /// `locateFixWait`, ten seconds.
  ///
  /// It makes its location manager on the first question, so a map that never locates touches no
  /// location service. It is bound to the main actor, as every geolocation is, and its location
  /// manager is made and read there.
  @MainActor
  public final class DeviceGeolocation: Geolocation {
    /// Platform is what the geolocation reads of the location services and asks of them, which
    /// `CLLocationManager` is.
    @MainActor
    protocol Platform: AnyObject {
      var authorizationStatus: CLAuthorizationStatus { get }
      var accuracyAuthorization: CLAccuracyAuthorization { get }
      var location: CLLocation? { get }
      func requestLocation()
    }

    /// maximumAge is how old a fix the platform holds may be and still be answered,
    /// `locateMaxFixAge` in seconds.
    static let maximumAge = TimeInterval(locateMaxFixAge.components.seconds)

    private var platform: (any Platform)?
    private let receiver = Receiver()
    private let now: @MainActor () -> Date
    /// timeout is how long a fix is waited for before `unavailable` is answered.
    private let timeout: Duration
    private var waiting: [CheckedContinuation<GeolocationFix, Never>] = []
    private var deadline: Task<Void, Never>?

    /// Creates a geolocation over a location manager of its own, made on the first question.
    public init() {
      now = { Date() }
      timeout = locateFixWait
      listen()
    }

    /// Creates a geolocation over `platform`, which reports to it through `received(_:)`,
    /// `failed()` and `permissionChanged()`, its clock reading `now`, a fix waited for `timeout`.
    init(platform: any Platform, now: @escaping @MainActor () -> Date, timeout: Duration) {
      self.platform = platform
      self.now = now
      self.timeout = timeout
      listen()
    }

    /// locate answers the device's position, or the reason there is none.
    public func locate() async -> GeolocationFix {
      let platform = currentPlatform()
      guard Self.isPrecise(platform) else { return .refused(.denied) }
      if let held = platform.location, let fix = fresh(held) {
        return fix
      }
      return await withCheckedContinuation { continuation in
        waiting.append(continuation)
        guard waiting.count == 1 else { return }
        platform.requestLocation()
        let timeout = timeout
        deadline = Task { [weak self] in
          try? await Task.sleep(for: timeout)
          guard !Task.isCancelled else { return }
          self?.answer(.refused(.unavailable))
        }
      }
    }

    /// permission answers what asking for a fix would do: `prompt` where the app never asked,
    /// `granted` where it holds a permission at full accuracy, and `denied` otherwise.
    public func permission() async -> GeolocationPermission {
      let platform = currentPlatform()
      switch platform.authorizationStatus {
      case .notDetermined:
        return .prompt
      case .authorizedAlways, .authorizedWhenInUse:
        return platform.accuracyAuthorization == .fullAccuracy ? .granted : .denied
      default:
        return .denied
      }
    }

    /// received answers every fix waited on with the last valid location the platform reported.
    func received(_ locations: [CLLocation]) {
      guard let location = locations.last(where: { $0.horizontalAccuracy >= 0 }) else { return }
      answer(Self.fix(location))
    }

    /// failed answers every fix waited on as unavailable, the platform having found none.
    func failed() {
      answer(.refused(.unavailable))
    }

    /// permissionChanged answers every fix waited on as denied where the app no longer holds a
    /// permission to read one at full accuracy.
    func permissionChanged() {
      guard let platform, !waiting.isEmpty, !Self.isPrecise(platform) else { return }
      answer(.refused(.denied))
    }

    /// currentPlatform is the location services the geolocation reads, made on the first question.
    private func currentPlatform() -> any Platform {
      if let platform { return platform }
      let manager = CLLocationManager()
      manager.desiredAccuracy = kCLLocationAccuracyHundredMeters
      manager.delegate = receiver
      platform = manager
      return manager
    }

    /// listen hands the delegate what the location manager reports, to this geolocation while it
    /// lives.
    private func listen() {
      weak let owner = self
      receiver.receive = { locations in owner?.received(locations) }
      receiver.fail = { owner?.failed() }
      receiver.authorize = { owner?.permissionChanged() }
    }

    /// answer ends every wait on a fix with `fix`.
    private func answer(_ fix: GeolocationFix) {
      deadline?.cancel()
      deadline = nil
      let answered = waiting
      waiting = []
      for continuation in answered {
        continuation.resume(returning: fix)
      }
    }

    /// fresh is a fix of `location` where the platform made it within the maximum age, and nil
    /// for one older or invalid.
    private func fresh(_ location: CLLocation) -> GeolocationFix? {
      guard location.horizontalAccuracy >= 0,
        now().timeIntervalSince(location.timestamp) <= Self.maximumAge
      else { return nil }
      return Self.fix(location)
    }

    private static func fix(_ location: CLLocation) -> GeolocationFix {
      .located(
        position: [location.coordinate.longitude, location.coordinate.latitude],
        accuracyMeters: location.horizontalAccuracy)
    }

    /// isPrecise tells whether the app holds a permission to read a fix at full accuracy.
    private static func isPrecise(_ platform: any Platform) -> Bool {
      switch platform.authorizationStatus {
      case .authorizedAlways, .authorizedWhenInUse:
        return platform.accuracyAuthorization == .fullAccuracy
      default:
        return false
      }
    }
  }

  extension CLLocationManager: DeviceGeolocation.Platform {}

  /// Receiver is the location manager's delegate, kept apart so the geolocation publishes none of
  /// the delegate's methods. It is bound to the main actor, where the geolocation makes it, and the
  /// manager calls it on the thread it was made on, the main one.
  @MainActor
  private final class Receiver: NSObject, CLLocationManagerDelegate {
    var receive: ([CLLocation]) -> Void = { _ in }
    var fail: () -> Void = {}
    var authorize: () -> Void = {}

    nonisolated func locationManager(
      _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
      MainActor.assumeIsolated { receive(locations) }
    }

    nonisolated func locationManager(
      _ manager: CLLocationManager, didFailWithError error: any Error
    ) {
      MainActor.assumeIsolated { fail() }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
      MainActor.assumeIsolated { authorize() }
    }
  }
#else
  /// DeviceGeolocation answers the device's position from the platform's location services, which
  /// this platform has none of: it answers `noApi`, and its permission reads `unknown`. It is bound
  /// to the main actor, as every geolocation is.
  @MainActor
  public final class DeviceGeolocation: Geolocation {
    /// Creates a geolocation over a platform with no location services.
    public init() {}

    /// locate answers no fix, as a platform with no location services does.
    public func locate() async -> GeolocationFix {
      .refused(.noApi)
    }

    /// permission answers `unknown`.
    public func permission() async -> GeolocationPermission {
      .unknown
    }
  }
#endif
