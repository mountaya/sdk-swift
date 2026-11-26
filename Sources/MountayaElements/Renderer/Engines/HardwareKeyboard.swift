#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import GameController

  /// HardwareKeyboard reads whether a hardware keyboard is at hand, which a view's words about its
  /// keys are shown for: the time section's `layers.timeKeyboard` says the arrow keys step its
  /// slider, which no touch screen's reader can press. It reads the platform's keyboard as it is
  /// asked, each time a view draws, and decides nothing.
  @MainActor
  enum HardwareKeyboard {
    /// isConnected is whether a hardware keyboard is connected, the system's own included.
    static var isConnected: Bool {
      GCKeyboard.coalesced != nil
    }
  }
#endif
