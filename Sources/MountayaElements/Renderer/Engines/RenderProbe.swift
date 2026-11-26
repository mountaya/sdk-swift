#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  /// RenderProbe counts what the renderer does, for a test that holds a hot path to its budget
  /// (`sdk/hot-paths.yaml` in the contract): each body SwiftUI evaluates of a view that reports to
  /// it, by the view's name, and each source the renderer sends MapLibre, by the source's id.
  /// SwiftUI tells nobody when it evaluates a body, so each view a budget reads says so itself.
  ///
  /// Nothing reports anywhere unless a test installs a probe: on a view, through
  /// `environment(\.renderProbe, _:)`, or on a renderer, as its `probe`. Without one, a report is a
  /// read of an environment value or a property that is nil, and allocates nothing: the name a
  /// report would carry is never built.
  ///
  /// It also holds what a test cannot reach through a drawn view: the curve store of the profile
  /// chart drawn last, whose builds and draws a test reads, and that chart's scrub, which a test
  /// plays as a pointer moving over the chart would, since no test drags a finger across a view. It
  /// is bound to the main actor, where SwiftUI evaluates a body.
  @MainActor
  final class RenderProbe {
    /// counts is how many times each part was evaluated or sent, by its name.
    private(set) var counts: [String: Int] = [:]
    /// curves is the curve store of the profile chart drawn last, nil before one is drawn.
    private(set) weak var curves: ProfileCurves?
    /// scrub is the scrub of the profile chart drawn last, handed the sample a pointer stands on,
    /// nil where it left, or nil before one is drawn.
    private(set) var scrub: ((Int?) -> Void)?

    /// Creates a probe that has counted nothing.
    init() {}

    /// report counts one evaluation or sending of `part`.
    func report(_ part: String) {
      counts[part, default: 0] += 1
    }

    /// subscript is how many times `part` was evaluated or sent, 0 for a part never reported.
    subscript(_ part: String) -> Int {
      counts[part] ?? 0
    }

    /// chart holds what the profile chart drawn last draws its curve with and scrubs through.
    func chart(curves: ProfileCurves, scrub: @escaping (Int?) -> Void) {
      self.curves = curves
      self.scrub = scrub
    }
  }
#endif
