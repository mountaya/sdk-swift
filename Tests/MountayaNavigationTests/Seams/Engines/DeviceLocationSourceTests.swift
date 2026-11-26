#if canImport(CoreLocation) && !os(tvOS)
  import CoreLocation
  import Observation
  import Testing

  @testable import MountayaNavigation

  @Suite("DeviceLocationSource")
  @MainActor
  struct DeviceLocationSourceTests {
    /// Services are location services whose permission a test sets, and whether they are switched
    /// on, counting what they are asked. They hold no way to ask for a permission, as the source
    /// never asks for one.
    @MainActor
    private final class Services: DeviceLocationSource.Platform {
      var authorizationStatus: CLAuthorizationStatus = .notDetermined
      var accuracyAuthorization: CLAccuracyAuthorization = .fullAccuracy
      var desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyKilometer
      var distanceFilter: CLLocationDistance = 1_000
      var enabled = true
      var started = 0
      var stopped = 0
      var background = 0
      /// asked counts the times the services were asked whether they are switched on.
      var asked = 0

      func startUpdatingLocation() { started += 1 }
      func stopUpdatingLocation() { stopped += 1 }
      func keepReadingInBackground() { background += 1 }
      func servicesEnabled() async -> Bool {
        asked += 1
        return enabled
      }
    }

    private struct Lost: Error {}

    /// kinds is the kind of each failure told, nil for one that is no `LocationError`.
    private static func kinds(_ told: [any Error]) -> [LocationError.Kind?] {
      told.map { ($0 as? LocationError)?.kind }
    }

    /// settled lets every task the main actor holds run, as the source's question to the services
    /// is answered and its failure told.
    private static func settled() async {
      for _ in 0..<32 {
        await Task.yield()
      }
    }

    /// Changes counts the changes an observer is told of, on the main actor it is told on.
    @MainActor
    private final class Changes {
      var count = 0
    }

    @Test(
      "it reads only while the app holds a permission at full accuracy, and starts once it is granted"
    )
    func readsOnlyAtFullAccuracy() {
      let services = Services()
      let source = DeviceLocationSource(platform: services)

      source.start { _ in }
      #expect(services.started == 0, "no permission yet, and none asked for")

      // `authorizedAlways` is the one grant every platform the source builds on spells.
      services.authorizationStatus = .authorizedAlways
      services.accuracyAuthorization = .reducedAccuracy
      source.permissionChanged()
      #expect(services.started == 0, "reduced accuracy reads nothing")

      services.accuracyAuthorization = .fullAccuracy
      source.permissionChanged()
      #expect(services.started == 1, "full accuracy granted, as a temporary one the app asked for")

      services.accuracyAuthorization = .reducedAccuracy
      source.permissionChanged()
      #expect(services.stopped == 1, "back to reduced accuracy, the positions stop")

      services.accuracyAuthorization = .fullAccuracy
      source.permissionChanged()
      services.authorizationStatus = .denied
      source.permissionChanged()
      source.stop()
      #expect(services.started == 2)
      #expect(
        services.stopped == 2, "a permission taken back stops them, and the stop asks nothing")
    }

    /// A prompt falls due 55 m before its maneuver, so a walker read every 5 m is still read
    /// between 55 and 50 m before it (SPEC.md section 8).
    @Test("a navigation reads every fix at the best accuracy, and a walker a fix every 5 m")
    func rate() {
      let navigating = Services()
      let source = DeviceLocationSource(platform: navigating)
      #expect(source.rate == .navigation)
      #expect(navigating.desiredAccuracy == kCLLocationAccuracyBestForNavigation)
      #expect(navigating.distanceFilter == kCLDistanceFilterNone)

      let walking = Services()
      let walker = DeviceLocationSource(platform: walking, rate: .walking)
      #expect(walker.rate == .walking)
      #expect(walking.desiredAccuracy == kCLLocationAccuracyBest)
      #expect(walking.distanceFilter == 5)
      #expect(LocationRate.allCases == [.navigation, .walking])
    }

    @Test("the source a host makes reads the device as a fitness activity it never pauses")
    func ownManager() {
      for rate in LocationRate.allCases {
        let source = DeviceLocationSource(rate: rate)
        #expect(source.rate == rate)
        #expect(!source.backgroundUpdates)
      }
    }

    @Test("the standing is read as the source is made, and again at each change of permission")
    func standing() {
      let services = Services()
      services.authorizationStatus = .restricted
      services.accuracyAuthorization = .reducedAccuracy
      let source = DeviceLocationSource(platform: services)
      #expect(source.standing == LocationStanding(authorization: .restricted, accuracy: .reduced))

      services.authorizationStatus = .denied
      source.permissionChanged()
      #expect(source.standing == LocationStanding(authorization: .denied, accuracy: .reduced))
      services.authorizationStatus = .authorizedAlways
      services.accuracyAuthorization = .fullAccuracy
      source.permissionChanged()
      #expect(source.standing == LocationStanding(authorization: .always, accuracy: .full))
      services.authorizationStatus = .notDetermined
      source.permissionChanged()
      #expect(source.standing.authorization == .notDetermined)
    }

    /// An app asks for access with a prompt of its own, and rechecks from the answer rather than
    /// wait for the location services to tell the change.
    @Test("a recheck reads the standing again and starts reading as it now allows")
    func recheck() {
      let services = Services()
      let source = DeviceLocationSource(platform: services)
      source.start { _ in }
      #expect(source.recheckPermission().authorization == .notDetermined)
      #expect(services.started == 0)

      services.authorizationStatus = .authorizedAlways
      #expect(
        source.recheckPermission() == LocationStanding(authorization: .always, accuracy: .full))
      #expect(source.standing == LocationStanding(authorization: .always, accuracy: .full))
      #expect(services.started == 1)
      source.recheckPermission()
      #expect(services.started == 1, "a recheck that finds nothing new starts nothing again")
      source.stop()
    }

    @Test("an observer of the standing is told of a change, and of nothing where none was read")
    func observed() {
      let services = Services()
      let source = DeviceLocationSource(platform: services)
      let changes = Changes()
      func observe() {
        withObservationTracking {
          _ = source.standing
        } onChange: {
          MainActor.assumeIsolated { changes.count += 1 }
        }
      }

      observe()
      source.permissionChanged()
      #expect(changes.count == 0, "a standing read again unchanged tells nothing")
      services.authorizationStatus = .authorizedAlways
      source.recheckPermission()
      #expect(changes.count == 1)
      observe()
      services.accuracyAuthorization = .reducedAccuracy
      source.permissionChanged()
      #expect(changes.count == 2)
    }

    @Test("a failure of the location services is told as platformFailed, and the source reads on")
    func failureTold() {
      let services = Services()
      services.authorizationStatus = .authorizedAlways
      var told: [any Error] = []
      let source = DeviceLocationSource(platform: services) { told.append($0) }
      var stated: [[Double]] = []
      source.start { stated.append($0) }

      source.failed(CLError(.network))
      source.failed(Lost())
      source.receive([CLLocation(latitude: 45.9237, longitude: 6.8652)])

      #expect(Self.kinds(told) == [.platformFailed, .platformFailed])
      #expect(((told.first as? LocationError)?.cause as? CLError)?.code == .network)
      #expect((told.last as? LocationError)?.cause is Lost, "the platform's error, carried")
      #expect(stated == [[6.8652, 45.9237]], "a failure stops nothing")
      #expect(services.stopped == 0)
      #expect(services.asked == 0, "only a refusal of access asks whether the services are on")
      source.stop()
    }

    /// The platform reads location services switched off for the whole device as a refusal of the
    /// app's own access, `kCLErrorDenied`, and only the services' own answer tells them apart.
    @Test(
      "a refusal of access is permissionRevoked with the services on, providerDisabled with them off"
    )
    func refusalOfAccess() async {
      let services = Services()
      services.authorizationStatus = .authorizedAlways
      var told: [any Error] = []
      let source = DeviceLocationSource(platform: services) { told.append($0) }
      source.start { _ in }

      source.failed(CLError(.denied))
      await Self.settled()
      services.enabled = false
      source.failed(CLError(.denied))
      await Self.settled()

      #expect(Self.kinds(told) == [.permissionRevoked, .providerDisabled])
      #expect(
        told.allSatisfy { (($0 as? LocationError)?.cause as? CLError)?.code == .denied },
        "the platform's refusal, carried")
      #expect(services.asked == 2)
      #expect(services.stopped == 0, "the source reads on, its standing deciding")
      source.stop()
    }

    /// With the services switched off, the platform reads the app's access as denied, which the
    /// source reads nothing under: without a word, the traveller would see no position and no why.
    @Test("a source started while the location services are switched off tells providerDisabled")
    func servicesOffAtStart() async {
      let services = Services()
      services.authorizationStatus = .denied
      services.enabled = false
      var told: [any Error] = []
      let source = DeviceLocationSource(platform: services) { told.append($0) }

      source.start { _ in }
      source.start { _ in }
      await Self.settled()
      #expect(Self.kinds(told) == [.providerDisabled], "told once a start")
      #expect((told.first as? LocationError)?.cause == nil)
      #expect(services.started == 0, "and nothing is read")
      source.stop()

      source.start { _ in }
      source.stop()
      await Self.settled()
      #expect(told.count == 1, "a source stopped before the services answered is told nothing")

      services.enabled = true
      source.start { _ in }
      await Self.settled()
      #expect(told.count == 1, "a denial of the app's own, which its standing tells, is no failure")
      source.stop()

      services.authorizationStatus = .authorizedAlways
      let asked = services.asked
      source.start { _ in }
      await Self.settled()
      #expect(services.asked == asked, "access not denied asks the services nothing")
      #expect(told.count == 1)
      source.stop()
    }

    @Test("with no onError, every failure is dropped and the source reads on")
    func droppedWithoutOnError() async {
      let services = Services()
      services.authorizationStatus = .authorizedAlways
      let silent = DeviceLocationSource(
        platform: services, backgroundUpdates: true, readsInBackground: false,
        speaksInBackground: false)
      var stated: [[Double]] = []
      silent.start { stated.append($0) }
      silent.failed(Lost())
      silent.failed(CLError(.denied))
      await Self.settled()
      silent.receive([CLLocation(latitude: 45.9237, longitude: 6.8652)])

      #expect(stated == [[6.8652, 45.9237]])
      #expect(services.stopped == 0)
      silent.stop()
    }

    /// Core Location raises `locationUnknown` while it cannot fix a position yet, indoors, and
    /// keeps trying: Apple asks that it be ignored, and an app told it would show a failure that is
    /// none.
    @Test("a position the location services cannot fix yet is no failure, and is told to nobody")
    func locationUnknownIgnored() {
      let services = Services()
      services.authorizationStatus = .authorizedAlways
      var told: [any Error] = []
      let source = DeviceLocationSource(platform: services) { told.append($0) }
      var stated: [[Double]] = []
      source.start { stated.append($0) }

      source.failed(CLError(.locationUnknown))
      source.failed(
        NSError(domain: kCLErrorDomain, code: CLError.Code.locationUnknown.rawValue))
      #expect(told.isEmpty)
      source.receive([CLLocation(latitude: 45.9237, longitude: 6.8652)])
      #expect(stated == [[6.8652, 45.9237]])
      source.failed(CLError(.headingFailure))
      #expect(Self.kinds(told) == [.platformFailed], "a lasting failure is told")
      source.stop()
    }

    @Test("background updates are turned on as the source starts, where the app declares the mode")
    func backgroundDeclared() {
      let services = Services()
      services.authorizationStatus = .authorizedAlways
      var told: [any Error] = []
      let source = DeviceLocationSource(
        platform: services, backgroundUpdates: true, readsInBackground: true,
        speaksInBackground: true
      ) { told.append($0) }

      #expect(source.backgroundUpdates)
      #expect(services.background == 0, "nothing is asked before a start")
      source.start { _ in }
      source.start { _ in }
      #expect(services.background == 1, "a source started twice turns them on once")
      #expect(services.started == 1)
      #expect(told.isEmpty)
      source.stop()
      source.start { _ in }
      #expect(services.background == 2)
      source.stop()
    }

    /// Turning background updates on with no `location` mode declared ends the app, so the source
    /// refuses, says so, and reads while the app is in use.
    @Test("background updates the app declares no mode for are refused, told, and nothing else")
    func backgroundRefused() {
      let services = Services()
      services.authorizationStatus = .authorizedAlways
      var told: [any Error] = []
      let source = DeviceLocationSource(
        platform: services, backgroundUpdates: true, readsInBackground: false,
        speaksInBackground: true
      ) { told.append($0) }

      source.start { _ in }
      #expect(services.background == 0)
      #expect(Self.kinds(told) == [.backgroundUndeclared])
      #expect((told.first as? LocationError)?.cause == nil)
      #expect(services.started == 1, "the positions go on while the app is in use")
      source.start { _ in }
      #expect(told.count == 1, "a source started already is refused nothing more")
      source.stop()
      source.start { _ in }
      #expect(told.count == 2, "each start is refused")
      source.stop()

      let foreground = DeviceLocationSource(platform: services) { told.append($0) }
      foreground.start { _ in }
      foreground.stop()
      #expect(told.count == 2, "a source that asks for none is refused none")
      #expect(services.background == 0)
    }

    /// A voice is refused the audio session in the background where the app declares no `audio`
    /// mode, so a navigation that reads with the screen off says nothing there: the source says so
    /// as it starts, keeps reading in the background, and asks nothing more.
    @Test("background updates with no audio mode declared are told, and read on in the background")
    func backgroundWithoutAudio() {
      let services = Services()
      services.authorizationStatus = .authorizedAlways
      var told: [any Error] = []
      let source = DeviceLocationSource(
        platform: services, backgroundUpdates: true, readsInBackground: true,
        speaksInBackground: false
      ) { told.append($0) }

      source.start { _ in }
      #expect(Self.kinds(told) == [.audioUndeclared])
      #expect(services.background == 1, "the background updates are turned on all the same")
      #expect(services.started == 1)
      source.start { _ in }
      #expect(told.count == 1, "a source started already is told nothing more")
      source.stop()
      source.start { _ in }
      #expect(told.count == 2, "each start is told")
      source.stop()

      let foreground = DeviceLocationSource(platform: services, speaksInBackground: false) {
        told.append($0)
      }
      foreground.start { _ in }
      foreground.stop()
      #expect(told.count == 2, "a source that reads in the foreground alone is told nothing")
    }

    @Test("each valid location the platform reports is stated as [longitude, latitude]")
    func statesValidLocations() {
      let source = DeviceLocationSource()
      var stated: [[Double]] = []
      source.start { stated.append($0) }

      source.receive([
        CLLocation(latitude: 45.9237, longitude: 6.8652),
        CLLocation(
          coordinate: CLLocationCoordinate2D(latitude: 1, longitude: 2), altitude: 0,
          horizontalAccuracy: -1, verticalAccuracy: 0, timestamp: .distantPast),
        CLLocation(latitude: 45.9682, longitude: 6.9271),
      ])
      source.stop()

      #expect(stated == [[6.8652, 45.9237], [6.9271, 45.9682]])
    }

    @Test("nothing is stated before a start or after a stop")
    func startAndStop() {
      let source = DeviceLocationSource()
      var stated: [[Double]] = []
      source.receive([CLLocation(latitude: 45, longitude: 6)])

      source.start { stated.append($0) }
      source.stop()
      source.receive([CLLocation(latitude: 45, longitude: 6)])

      #expect(stated.isEmpty)
    }
  }
#endif
