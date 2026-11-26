/// SearchPick is what picking a search result does to a map (`geo.search.pick`): how the camera
/// moves, nil where it stays, and what the map's search highlight is handed, nil where nothing is
/// marked, which takes down the mark of the pick before.
///
/// Two are equal where both members are.
public struct SearchPick: Sendable, Hashable {
  /// camera is how the camera moves onto the result, or nil where it stays.
  public var camera: SearchPickCamera?
  /// mark is what the map's search highlight draws, or nil where nothing is marked.
  public var mark: SearchHighlight?

  /// Creates a pick from its camera move and its mark.
  public init(camera: SearchPickCamera?, mark: SearchHighlight?) {
    self.camera = camera
    self.mark = mark
  }
}
