import Foundation

/// URLTemplate is a route a map renderer fetches on its own: a tile, or the base map's style,
/// TileJSON, sprite or glyph document (SPEC.md section 3). A renderer reads it, never a caller who
/// awaits it, so no method binds one: `TileTemplates` holds every one the contract declares.
///
/// Its path is resolved against its surface's origin, `BaseURLs.tiles` for a Tile API route, and
/// a renderer expands the `{z}`, `{x}` and `{y}` it leaves in place on its own schedule.
public struct URLTemplate: Sendable, Hashable {
  /// operationId is the contract's name for the route.
  public let operationId: String
  /// path is the path template, each parameter in braces, resolved against its surface's origin.
  public let path: String
  /// pathParameters is the path's parameters, in the order the path names them.
  public let pathParameters: [String]
  /// queryParameters is the query parameters the route takes, in the contract's order.
  public let queryParameters: [String]
  /// mediaTypes is the media types the server answers the route in, in the contract's order.
  public let mediaTypes: [String]

  /// Creates a route as the contract states it.
  public init(
    operationId: String,
    path: String,
    pathParameters: [String] = [],
    queryParameters: [String] = [],
    mediaTypes: [String] = []
  ) {
    self.operationId = operationId
    self.path = path
    self.pathParameters = pathParameters
    self.queryParameters = queryParameters
    self.mediaTypes = mediaTypes
  }

  /// filled returns `path` with each placeholder `values` names replaced by its value,
  /// percent-encoded as one path segment, and every other placeholder left as written, as a
  /// renderer's `{z}`, `{x}` and `{y}` are: `TileTemplates.getItineraryTile.filled(with:
  /// ["itinerary_id": id])` is `/v1/itineraries/<id>/{z}/{x}/{y}`.
  public func filled(with values: [String: String]) -> String {
    // A value is encoded before it is placed, so its braces are `%7B` and `%7D` and no value
    // writes a placeholder another one fills: the order the values are placed in decides nothing.
    var filled = path
    for (name, value) in values {
      filled = filled.replacingOccurrences(of: "{\(name)}", with: OperationPath.segment(value))
    }
    return filled
  }
}
