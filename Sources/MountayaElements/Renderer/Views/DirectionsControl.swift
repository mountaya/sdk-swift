#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  public import SwiftUI

  /// DirectionsControl asks the app to open directions for what the map shows. It drives nothing
  /// of the map's, so its handler is required: what directions open, a panel or a screen, is the
  /// app's and cannot be guessed. It is live whether or not the map has loaded, and
  /// `.disabled(true)` disables it. Its words are the scope's, `controls.directions` naming it and
  /// `tooltips.directions` describing it (`mountayaScope(_:)`), each replaced by `strings` where it
  /// names the word's path.
  public struct DirectionsControl: View {
    private let onTap: () -> Void

    @ViewScope private var scope: ElementsScope

    /// Creates the control, its words replaced by `strings` where it names theirs, a press handed to
    /// `onTap`.
    public init(strings: [String: String]? = nil, onTap: @escaping () -> Void) {
      self.onTap = onTap
      _scope = ViewScope(strings: strings)
    }

    /// body is the control's glyph on a chip.
    public var body: some View {
      ControlChip {
        ControlButton(
          label: scope.word("controls.directions"),
          help: scope.word("tooltips.directions.description"), action: onTap
        ) {
          Glyph("directions", in: scope.controlGlyphs, size: 20, ink: .foreground)
        }
      }
    }
  }
#endif
