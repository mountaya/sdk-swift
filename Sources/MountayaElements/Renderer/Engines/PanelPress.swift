#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  /// PanelPress is what a panel's rows press through: the press of the panel as it was drawn last.
  ///
  /// A row is a part of its own that SwiftUI draws again only where what it shows changes
  /// (`panel-rows` in the contract's `sdk/hot-paths.yaml`), so a row it keeps holds the action it was
  /// drawn with, which a panel drawn since with another handler or another map must not answer for.
  /// The panel holds one press for its life, hands it what to do each time it draws, and puts it in
  /// its rows' environment, `panelTogglePress` or `layersPanelPress`, where a row reads it: a row that
  /// held it would be drawn again whenever the panel is, since SwiftUI compares no reference a view
  /// holds. A row presses through it, and is answered by the panel as it is now. It is bound to the
  /// main actor, where SwiftUI draws the panel and carries out a press.
  @MainActor
  final class PanelPress<Value> {
    /// pressed is what the panel drawn last does with a press.
    private var pressed: (Value) -> Void = { _ in }

    /// Creates a press that does nothing until a panel hands it what to do.
    init() {}

    /// hold holds `pressed` as what a press does, from the panel drawn last.
    func hold(_ pressed: @escaping (Value) -> Void) {
      self.pressed = pressed
    }

    /// press presses `value`, as the panel drawn last answers it.
    func press(_ value: Value) {
      pressed(value)
    }
  }
#endif
