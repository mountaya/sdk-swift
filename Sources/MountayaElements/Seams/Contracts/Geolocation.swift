/// locateMaxFixAge is how old a fix the device made may be and still be answered at once by the
/// device's own geolocation, `DeviceGeolocation`, the seam a map takes where it is handed none:
/// `map/camera-locate.json`'s `maxFixAgeMs`.
public let locateMaxFixAge: Duration = .seconds(60)

/// locateFixWait is how long the device's own geolocation waits for a fix before it answers
/// `GeolocationRefusal.unavailable`: `map/camera-locate.json`'s `fixWaitMs`.
public let locateFixWait: Duration = .seconds(10)

/// Geolocation is where a map's fix of the device's position comes from: the platform's location
/// services, none at all, or the app's own, such as a fix its own location stack already holds.
///
/// `locate()` answers one fix or the reason there is none, and `permission()` what asking would do,
/// without asking. Neither throws: a refusal is an answer a map reads, and `MapEngine.locate()`
/// moves nothing on one and names its reason (`map.camera.locate`). A geolocation never asks the
/// reader for location access: that prompt and its wording are the app's, so one asked before the
/// app holds a permission answers `denied`, and the permission reads `prompt`.
///
/// It is bound to the main actor, as the map it answers is.
@MainActor
public protocol Geolocation {
  /// locate answers one fix of the device's position, or the reason there is none.
  func locate() async -> GeolocationFix

  /// permission answers what asking for a fix would do, without asking anyone.
  func permission() async -> GeolocationPermission
}
