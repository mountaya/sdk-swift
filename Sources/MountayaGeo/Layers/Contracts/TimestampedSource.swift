/// TimestampedSource is one tile source of an overlay the server stamps, and the tile addresses that
/// ask it for an instant (`geo.layers.tile-timestamp`): each of the source's templates carrying the
/// instant as its `timestamp` parameter, every other part of it as the catalogue wrote it.
///
/// Two are equal where they hold the same, a text by its scalars.
public struct TimestampedSource: Sendable, Equatable {
  /// sourceId is the source's id in the layers catalogue, which a map draws it under.
  public var sourceId: String
  /// tiles is the source's tile address templates, in the catalogue's order, each asking for the
  /// instant.
  public var tiles: [String]

  /// Creates the source of id `sourceId`, drawn from `tiles`.
  public init(sourceId: String, tiles: [String]) {
    self.sourceId = sourceId
    self.tiles = tiles
  }

  /// Two sources are equal where their ids and their addresses are the same, by their scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.sourceId, rhs.sourceId) && lhs.tiles.count == rhs.tiles.count
      && zip(lhs.tiles, rhs.tiles).allSatisfy { sameText($0, $1) }
  }
}
