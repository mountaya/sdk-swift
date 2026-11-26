#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// GeolocateControl centres a map on the device, framing the box a fix's accuracy spans
  /// (`map.camera.locate`), and says what its fix and the standing permission say
  /// (`geo.controls.geolocate-state`).
  ///
  /// It shows a `GeolocateControlEngine` standing over the map: drawn in the `accent` from a press
  /// until every fix it asked for settles, and live after a refusal, since a live control can say
  /// where the setting is and be pressed again once it changed. It never asks the reader for
  /// access: while the standing permission, read without prompting when it comes to stand over a
  /// map and again once each fix settles, answers refused, its description says location is
  /// blocked and to allow it in the settings (`tooltips.geolocate.deniedDescription`); a fix that
  /// found no signal, or one refused while the permission was never asked, keeps the ordinary one.
  ///
  /// A press asks the map for one fix, unless the app hands `onTap` in its place, which a press
  /// then calls alone, for an app that runs its own flow, a prompt of its own among it; `isLocating`
  /// then says when its fix is out, since the control tracks only its own. `onError` is handed
  /// each fix of the control's that fails, the map's `MapError` naming the reason. Where the reader
  /// asked for reduced motion, the map frames its fix at once rather than easing there. With neither
  /// a map nor a handler it is inert, and `.disabled(true)` disables it. Its words are the scope's,
  /// `controls.geolocate` naming it and the `tooltips` describing it (`mountayaScope(_:)`), each
  /// replaced by `strings` where it names the word's path.
  public struct GeolocateControl: View {
    private let map: MapEngine?
    private let isLocating: Bool?
    private let onTap: (() -> Void)?
    private let onError: ((any Error) -> Void)?

    @State private var engine: GeolocateControlEngine
    /// heard is the map the engine stands over, which its state speaks of.
    @State private var heard: ObjectIdentifier?
    @ViewScope private var scope: ElementsScope
    @Environment(\.accessibilityReduceMotion) private var reducesMotion

    /// Creates the control over `map`, `isLocating` saying when the app's own fix is out, its words
    /// replaced by `strings` where it names theirs, a press handed to `onTap` in place of the map
    /// where the app hands one, and each failed fix of the control's handed to `onError`.
    public init(
      map: MapEngine?, isLocating: Bool? = nil, strings: [String: String]? = nil,
      onTap: (() -> Void)? = nil, onError: ((any Error) -> Void)? = nil
    ) {
      self.init(
        map: map, engine: GeolocateControlEngine(), isLocating: isLocating, strings: strings,
        onTap: onTap, onError: onError)
    }

    /// Creates the control over `map`, showing `engine`.
    init(
      map: MapEngine?, engine: GeolocateControlEngine, isLocating: Bool? = nil,
      strings: [String: String]? = nil, onTap: (() -> Void)? = nil,
      onError: ((any Error) -> Void)? = nil
    ) {
      self.map = map
      self.isLocating = isLocating
      self.onTap = onTap
      self.onError = onError
      _engine = State(initialValue: engine)
      _scope = ViewScope(strings: strings)
    }

    /// body is the control's glyph on a chip.
    public var body: some View {
      let identity = map.map(ObjectIdentifier.init)
      let state = engine.state
      let isBlocked = heard == identity && state.isBlocked
      ControlChip {
        ControlButton(
          label: scope.word("controls.geolocate"),
          help: Self.description(isBlocked: isBlocked, in: scope),
          isBusy: isLocating ?? state.isBusy, action: { press(reducingMotion: reducesMotion) }
        ) {
          Glyph("geolocate", in: scope.controlGlyphs, size: 20, ink: .foreground)
        }
        .disabled(map == nil && onTap == nil)
      }
      .task(id: identity) {
        engine.configure(map: map)
        heard = identity
      }
    }

    /// press is a press: the handler where the app handed one, a fix the engine asks the map for
    /// otherwise, framed at once where `reducingMotion`.
    func press(reducingMotion: Bool = false) {
      Self.press(
        engine: engine, map: map, reducingMotion: reducingMotion, onTap: onTap, onError: onError)
    }

    /// press asks `engine` for a fix, framed by `map` at once where `reducingMotion`, or hands the
    /// press to `onTap` where the app handed one.
    static func press(
      engine: GeolocateControlEngine, map: MapEngine? = nil, reducingMotion: Bool = false,
      onTap: (() -> Void)?, onError: ((any Error) -> Void)?
    ) {
      if let onTap {
        onTap()
      } else {
        map?.reducesMotion = reducingMotion
        engine.locate(onError: { error in onError?(error) })
      }
    }

    /// description is what the control says it does, in the words of `scope`: that location is
    /// blocked while the standing permission answers refused, and what a press does otherwise.
    static func description(isBlocked: Bool, in scope: ElementsScope) -> String {
      scope.word(
        isBlocked ? "tooltips.geolocate.deniedDescription" : "tooltips.geolocate.description")
    }
  }
#endif
