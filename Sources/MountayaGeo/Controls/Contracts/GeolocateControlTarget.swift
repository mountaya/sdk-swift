/// GeolocateControlTarget is the map a locate control stands over (`geo.controls.geolocate-state`):
/// the fix a press asks it for, and the standing permission it reads without prompting.
/// `MapEngine` is one; a map of an app's own, or a test's double, is another.
///
/// It is bound to the main actor, as every map is, and compared by identity, so a control handed
/// the map it stands over already changes nothing.
@MainActor
public protocol GeolocateControlTarget: AnyObject {
  /// locate asks for one fix of the device's position and frames it, answering the position, and
  /// throws where no fix is framed.
  func locate() async throws -> [Double]

  /// isLocationRefused reads, without asking anyone, whether the standing permission refuses a
  /// fix: true where the reader or the platform refused it, false where it is granted, never asked
  /// or cannot be known. It throws where it cannot say.
  func isLocationRefused() async throws -> Bool
}
