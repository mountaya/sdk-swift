#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Observation

  /// MarkerCallout is the label a map shows beside the marker tapped last: the marker's id, nil for
  /// none, and a count of the camera's moves while one is shown, which the label reads so it follows
  /// its marker as the camera moves. The renderer writes it as the engine tells each tap and as
  /// MapLibre moves the camera, and `MarkerLabel` draws it over the watermark and under the readout,
  /// where a map's popups stand.
  ///
  /// It is bound to the main actor, where the view and the renderer that share it live, and
  /// `Observable`, so SwiftUI draws the label again as it changes and never otherwise.
  @MainActor
  @Observable
  final class MarkerCallout {
    /// markerId is the id of the marker whose label is shown, or nil for none.
    private(set) var markerId: String?
    /// moves counts the camera's moves while a label is shown.
    private(set) var moves = 0

    /// show shows the label of the marker of id `id`, or takes the label shown off where it is nil.
    func show(_ id: String?) {
      guard markerId != id else { return }
      markerId = id
    }

    /// cameraMoved tells the label shown, where one is, that the camera moved.
    func cameraMoved() {
      guard markerId != nil else { return }
      moves &+= 1
    }
  }
#endif
