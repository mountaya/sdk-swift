import MountayaGeo

/// InertNavigationVoice is a voice that says nothing: a navigation driven by it is a silent one,
/// whose maneuvers a traveller reads on the screen alone.
///
/// It is the engine's default, so no app starts speaking over a traveller's own audio before it
/// asks to. It is bound to the main actor, as every voice is.
@MainActor
public final class InertNavigationVoice: NavigationVoice {
  /// Creates a voice that says nothing.
  public init() {}

  /// say does nothing.
  public func say(_ instruction: NavigationInstruction) {}

  /// hush does nothing.
  public func hush() {}
}
