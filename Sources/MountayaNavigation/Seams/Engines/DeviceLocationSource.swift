#if canImport(CoreLocation) && !os(tvOS)
  import CoreLocation
  internal import Foundation
  import MountayaGeo
  import Observation

  /// DeviceLocationSource states where the device is, from the platform's location services, at
  /// the rate the host chooses, `LocationRate`: every fix they read for a navigation by default, at
  /// `kCLLocationAccuracyBestForNavigation` with no distance filter, or a walker's, at
  /// `kCLLocationAccuracyBest` once the device has moved 5 m. Either reads the location as a fitness
  /// activity and never lets the platform pause the updates on its own (SPEC.md section 8).
  ///
  /// It never asks for location access: it reads positions only while the app holds a permission
  /// to, `whenInUse` or `always`, at full accuracy, and starts reading the moment the app is granted
  /// both, so the prompt and its wording stay the app's. A traveller who turned precise location off
  /// is read nowhere rather than kilometres away: under reduced accuracy it states nothing, and it
  /// never asks for more. An app that navigates under reduced accuracy asks for full accuracy itself,
  /// with `CLLocationManager.requestTemporaryFullAccuracyAuthorization(withPurposeKey:)` on a
  /// manager of its own and a purpose in its `NSLocationTemporaryUsageDescriptionDictionary`, and
  /// the source starts reading once it is granted. A position the platform marks invalid is not
  /// stated.
  ///
  /// `standing` is where the app stands on location access, read as the source is made, again as
  /// the location services tell each change of permission or accuracy, and on
  /// `recheckPermission()`, which an app calls from the answer to its own request for access. It is
  /// observable, so a SwiftUI view that reads it is drawn again when it changes.
  ///
  /// Every failure is a `LocationError`, told to `onError`, its kinds the ones every SDK names
  /// (SPEC.md section 8). `backgroundUpdates` keeps the positions coming with the screen off, which
  /// it does only where the app declares the `location` mode under `UIBackgroundModes` in its
  /// Info.plist: there it turns the location manager's background updates on as the source starts.
  /// Where the app declares no such mode, turning them on would end the app, so the request is
  /// refused, `backgroundUndeclared` told as the source starts, and the positions go on while the
  /// app is in use. A Mac app keeps reading in the background as it is, so the request asks nothing
  /// more of macOS, and visionOS reads no location in the background, so the request is refused
  /// there. On an iPhone or an iPad, a voice speaking through the system's audio session is silent
  /// in the background unless the app also declares the `audio` mode, so a source started with
  /// background updates where the app declares none tells `audioUndeclared` too, and reads on. A
  /// source started while the device's location services are switched off tells
  /// `providerDisabled`. A failure the location services report, `didFailWithError`, is told too,
  /// and the source keeps reading: a refusal of access, `CLError.denied`, as `providerDisabled`
  /// where the services are switched off and as `permissionRevoked` where they are on, arriving as
  /// a change of `standing` as well, and any other as `platformFailed`, the error carried; a
  /// position they cannot fix yet, `CLError.locationUnknown`, which they raise indoors while they
  /// keep trying, is no failure and is told to nobody, as Apple asks it be ignored. Whether the
  /// services are on is asked off the main actor, as Apple asks, since the answer may hold up the
  /// thread it is asked on, so those two are told once it comes. With no `onError`, each failure is
  /// dropped, and a debug build prints it once, where a developer reads the console.
  ///
  /// It is bound to the main actor, as every source is, and its location manager is made and read
  /// there.
  @MainActor
  @Observable
  public final class DeviceLocationSource: LocationSource {
    /// Platform is what the source reads of the location services and asks of them, which
    /// `CLLocationManager` is.
    @MainActor
    protocol Platform: AnyObject {
      var authorizationStatus: CLAuthorizationStatus { get }
      var accuracyAuthorization: CLAccuracyAuthorization { get }
      var desiredAccuracy: CLLocationAccuracy { get set }
      var distanceFilter: CLLocationDistance { get set }
      func startUpdatingLocation()
      func stopUpdatingLocation()
      /// keepReadingInBackground turns the background updates on, where the platform has them.
      func keepReadingInBackground()
      /// servicesEnabled tells whether the device's location services are switched on, for every
      /// app, asked off the main actor.
      func servicesEnabled() async -> Bool
    }

    /// standing is where the app stands on location access, as last read.
    public private(set) var standing: LocationStanding

    /// backgroundUpdates is whether the source asks to keep reading with the screen off, which it
    /// does where the app declares the platform's background location mode.
    public let backgroundUpdates: Bool

    /// rate is how often the source reads the device, the host's choice as it made the source.
    public let rate: LocationRate

    @ObservationIgnored private let onError: (@MainActor (any Error) -> Void)?
    @ObservationIgnored private let platform: any Platform
    /// readsInBackground is whether the platform keeps a source reading in the background, which
    /// an app's Info.plist decides where the platform suspends an app.
    @ObservationIgnored private let readsInBackground: Bool
    /// speaksInBackground is whether the platform lets a voice take the audio session in the
    /// background, which an app's Info.plist decides on an iPhone or an iPad.
    @ObservationIgnored private let speaksInBackground: Bool
    @ObservationIgnored private let receiver = Receiver()
    @ObservationIgnored private var deliver: (@MainActor ([Double]) throws -> Void)?
    @ObservationIgnored private var updating = false

    /// Creates a source over a location manager of its own, reading the device at `rate`, every
    /// fix a navigation reads by default, as a fitness activity the platform never pauses on its
    /// own, reading with the screen off where `backgroundUpdates` asks it to and the app declares
    /// the platform's background location mode, and telling `onError` each failure.
    public convenience init(
      rate: LocationRate = .navigation, backgroundUpdates: Bool = false,
      onError: (@MainActor (any Error) -> Void)? = nil
    ) {
      let manager = CLLocationManager()
      #if os(iOS) || os(macOS) || os(visionOS)
        manager.activityType = .fitness
        manager.pausesLocationUpdatesAutomatically = false
      #endif
      self.init(
        platform: manager, rate: rate, backgroundUpdates: backgroundUpdates,
        readsInBackground: DeviceLocationSource.declaresBackgroundLocation(),
        speaksInBackground: DeviceLocationSource.declaresBackgroundAudio(), onError: onError)
      manager.delegate = receiver
    }

    /// Creates a source over `platform`, set to read at `rate`, which tells it of a change of
    /// permission through `permissionChanged()` and of a failure through `failed(_:)`, keeps
    /// reading in the background where `readsInBackground` says the app declares it may, and says
    /// nothing of a voice in the background where `speaksInBackground` says the app declares one
    /// may speak.
    init(
      platform: any Platform, rate: LocationRate = .navigation, backgroundUpdates: Bool = false,
      readsInBackground: Bool = false, speaksInBackground: Bool = false,
      onError: (@MainActor (any Error) -> Void)? = nil
    ) {
      platform.desiredAccuracy = Self.accuracy(of: rate)
      platform.distanceFilter = Self.distanceFilter(of: rate)
      self.platform = platform
      self.rate = rate
      self.backgroundUpdates = backgroundUpdates
      self.readsInBackground = readsInBackground
      self.speaksInBackground = speaksInBackground
      self.onError = onError
      standing = DeviceLocationSource.standing(of: platform)
      listen()
    }

    /// listen hands the delegate what the location manager reports, to this source while it lives.
    private func listen() {
      weak let owner = self
      receiver.receive = { locations in owner?.receive(locations) }
      receiver.authorize = { owner?.permissionChanged() }
      receiver.fail = { error in owner?.failed(error) }
    }

    /// start begins stating the device's positions, once the app holds a permission to read them
    /// at full accuracy. A source started with background updates turns them on as it starts, or
    /// tells `onError` they were refused, `backgroundUndeclared`, and tells it too where the app
    /// declares no `audio` mode for a voice to speak in the background, `audioUndeclared`. A source
    /// started while the device's location services are switched off tells `providerDisabled`.
    public func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) {
      let starting = self.deliver == nil
      self.deliver = deliver
      if starting, backgroundUpdates {
        if readsInBackground {
          platform.keepReadingInBackground()
        } else {
          tell(LocationError(kind: .backgroundUndeclared))
        }
        if !speaksInBackground {
          tell(LocationError(kind: .audioUndeclared))
        }
      }
      // The platform reads switched-off services as a denial of the app's own access, so they are
      // asked about only then, as Apple asks.
      if starting, platform.authorizationStatus == .denied {
        tellServicesOff()
      }
      update()
    }

    /// stop ends the positions.
    public func stop() {
      deliver = nil
      update()
    }

    /// recheckPermission reads where the app stands on location access again, and starts or stops
    /// reading as it now allows: for an app that just asked the traveller for access, from the
    /// answer to its request, before the location services tell the change. It answers the
    /// standing read.
    @discardableResult
    public func recheckPermission() -> LocationStanding {
      permissionChanged()
      return standing
    }

    /// receive states each location the platform reports valid, as `[longitude, latitude]`.
    func receive(_ locations: [CLLocation]) {
      guard let deliver else { return }
      for location in locations where location.horizontalAccuracy >= 0 {
        // A coordinate the platform reports valid names a place, so none is refused.
        try? deliver([location.coordinate.longitude, location.coordinate.latitude])
      }
    }

    /// permissionChanged reads the app's standing again, as the location manager reports a change
    /// of its status or of its accuracy, and reads positions as it allows.
    func permissionChanged() {
      let read = Self.standing(of: platform)
      // A standing read again unchanged tells no observer of a change.
      if read != standing {
        standing = read
      }
      update()
    }

    /// failed tells `onError` of a failure the location manager reports, as a `LocationError`, and
    /// reads on: a refusal of access as `providerDisabled` where the device's location services are
    /// switched off, which is asked off the main actor and told once it is answered, and as
    /// `permissionRevoked` where they are on; any other as `platformFailed`. A position it cannot
    /// fix yet, `CLError.locationUnknown`, is none: the manager keeps trying.
    func failed(_ error: any Error) {
      switch (error as? CLError)?.code {
      case .locationUnknown?:
        return
      case .denied?:
        let platform = self.platform
        Task { [weak self] in
          let enabled = await platform.servicesEnabled()
          self?.tell(
            LocationError(kind: enabled ? .permissionRevoked : .providerDisabled, cause: error)
          )
        }
      default:
        tell(LocationError(kind: .platformFailed, cause: error))
      }
    }

    /// tellServicesOff tells `onError` the device's location services are switched off, where they
    /// are, once the platform answers, off the main actor, and while the source is still started.
    private func tellServicesOff() {
      let platform = self.platform
      Task { [weak self] in
        guard !(await platform.servicesEnabled()), let self, deliver != nil else { return }
        tell(LocationError(kind: .providerDisabled))
      }
    }

    /// tell hands `failure` to `onError`, or drops it where the source was given none, and a debug
    /// build prints it then, once, where a developer reads the console.
    private func tell(_ failure: LocationError) {
      guard let onError else {
        #if DEBUG
          print("DeviceLocationSource dropped a failure, having no onError: \(failure)")
        #endif
        return
      }
      onError(failure)
    }

    /// update reads positions where the source is started and the app holds a permission to read
    /// them at full accuracy, and reads none otherwise.
    private func update() {
      let wanted = deliver != nil && standing.isReadable
      guard wanted != updating else { return }
      updating = wanted
      if wanted {
        platform.startUpdatingLocation()
      } else {
        platform.stopUpdatingLocation()
      }
    }

    /// accuracy is the accuracy the location services read at for `rate`: the best for a
    /// navigation, or the best they give otherwise for a walker.
    static func accuracy(of rate: LocationRate) -> CLLocationAccuracy {
      switch rate {
      case .navigation: kCLLocationAccuracyBestForNavigation
      case .walking: kCLLocationAccuracyBest
      }
    }

    /// distanceFilter is how far the device moves before the location services read it again for
    /// `rate`: no distance at all for a navigation, and 5 m for a walker, the slack a prompt is read
    /// with, so a fix still lands between a prompt's 55 m and its 50 m.
    static func distanceFilter(of rate: LocationRate) -> CLLocationDistance {
      switch rate {
      case .navigation: kCLDistanceFilterNone
      case .walking: 5
      }
    }

    /// standing is where `platform`'s app stands on location access, as the platform states it.
    private static func standing(of platform: any Platform) -> LocationStanding {
      let authorization: LocationAuthorization
      switch platform.authorizationStatus {
      case .notDetermined: authorization = .notDetermined
      case .restricted: authorization = .restricted
      case .denied: authorization = .denied
      case .authorizedWhenInUse: authorization = .whenInUse
      case .authorizedAlways: authorization = .always
      @unknown default: authorization = .denied
      }
      let accuracy: LocationAccuracy =
        platform.accuracyAuthorization == .fullAccuracy ? .full : .reduced
      return LocationStanding(authorization: authorization, accuracy: accuracy)
    }

    /// declaresBackgroundLocation tells whether the platform keeps this app reading its location in
    /// the background: where it suspends an app, the app's Info.plist lists `location` among its
    /// background modes; a Mac app is never suspended; visionOS reads no location in the
    /// background.
    private static func declaresBackgroundLocation() -> Bool {
      #if os(macOS)
        return true
      #elseif os(visionOS)
        return false
      #else
        let modes = ["UIBackgroundModes", "WKBackgroundModes"].flatMap { key in
          Bundle.main.object(forInfoDictionaryKey: key) as? [String] ?? []
        }
        return modes.contains("location")
      #endif
    }

    /// declaresBackgroundAudio tells whether the platform lets this app's voice take the audio
    /// session in the background: on an iPhone or an iPad, where the app's Info.plist lists
    /// `audio` among its background modes; everywhere else the app has nothing to declare, a Mac
    /// app, Mac Catalyst's among them, never being suspended, and no other platform holding the
    /// system's voice this package speaks through.
    private static func declaresBackgroundAudio() -> Bool {
      #if os(iOS) && !targetEnvironment(macCatalyst)
        let modes = Bundle.main.object(forInfoDictionaryKey: "UIBackgroundModes") as? [String] ?? []
        return modes.contains("audio")
      #else
        return true
      #endif
    }
  }

  extension CLLocationManager: DeviceLocationSource.Platform {
    /// keepReadingInBackground turns the background updates on where the platform suspends an
    /// app, and does nothing where it keeps no such setting.
    func keepReadingInBackground() {
      #if os(iOS) || os(watchOS)
        allowsBackgroundLocationUpdates = true
      #endif
    }

    /// servicesEnabled asks the platform whether its location services are switched on, off the
    /// main actor, since Apple warns the answer may hold up the thread it is asked on.
    func servicesEnabled() async -> Bool {
      await Task.detached { CLLocationManager.locationServicesEnabled() }.value
    }
  }

  /// Receiver is the location manager's delegate, kept apart so the source publishes none of the
  /// delegate's methods. It is bound to the main actor, where the source makes it, and the manager
  /// calls it on the thread it was made on, the main one.
  @MainActor
  private final class Receiver: NSObject, CLLocationManagerDelegate {
    var receive: ([CLLocation]) -> Void = { _ in }
    var authorize: () -> Void = {}
    var fail: (any Error) -> Void = { _ in }

    nonisolated func locationManager(
      _ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]
    ) {
      MainActor.assumeIsolated { receive(locations) }
    }

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
      MainActor.assumeIsolated { authorize() }
    }

    nonisolated func locationManager(
      _ manager: CLLocationManager, didFailWithError error: any Error
    ) {
      MainActor.assumeIsolated { fail(error) }
    }
  }
#endif
