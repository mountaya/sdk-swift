import MountayaGeo

/// NavigationVoice is how a navigation tells a traveller of a maneuver aloud: the engine decides
/// when a maneuver is due, and the voice says it, in the host's words.
///
/// An instruction is a copy key and its arguments, never a sentence (`stepInstruction(_:)`), so a
/// voice turns it into the host's own words, in the host's own language, before it speaks. The
/// engine hands it each maneuver once, while the traveller is on the route, and asks it to stop
/// where the navigation stops or follows a new route. It is bound to the main actor, as the engine
/// that drives it is.
@MainActor
public protocol NavigationVoice: AnyObject {
  /// say announces the maneuver `instruction` names, the one the traveller reaches next.
  func say(_ instruction: NavigationInstruction)

  /// hush stops what is being said, and drops what waits to be.
  func hush()
}
