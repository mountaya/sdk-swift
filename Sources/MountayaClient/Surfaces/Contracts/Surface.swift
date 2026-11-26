/// Surface is one of the public surfaces an operation belongs to, each with an origin of its own.
public enum Surface: String, Sendable, Hashable, CaseIterable {
  /// rest is the Map Studio API.
  case rest
  /// tiles is the Tile API.
  case tiles
  /// data is the Data API.
  case data
}
