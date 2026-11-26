#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  public import SwiftUI

  /// DownloadControl asks the app to export what the map shows, an itinerary the app holds, as a
  /// file. It drives nothing of the map's, so its handler is required: what a download opens, a
  /// sheet, a share or a file, is the app's and cannot be guessed. It is live whether or not the
  /// map has loaded, and `.disabled(true)` disables it. Its words are the scope's,
  /// `controls.download` naming it and `tooltips.download` describing it (`mountayaScope(_:)`),
  /// each replaced by `strings` where it names the word's path.
  public struct DownloadControl: View {
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
          label: scope.word("controls.download"),
          help: scope.word("tooltips.download.description"), action: onTap
        ) {
          Glyph("download", in: scope.controlGlyphs, size: 20, ink: .foreground)
        }
      }
    }
  }
#endif
