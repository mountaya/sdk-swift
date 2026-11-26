// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

/// TileTemplates is every route of the Tile API a map renderer fetches on its own, the tiles and
/// the base map's style, TileJSON, sprite and glyph documents: URL templates, resolved against the
/// surface's origin, which no method binds.
public enum TileTemplates {
  /// all is every template, in the model's order.
  public static let all: [URLTemplate] = [
    getTile,
    getStyle,
  ]

  /// The contract's `getTile`.
  public static let getTile = URLTemplate(
    operationId: "getTile",
    path: "/v1/{z}/{x}/{y}",
    pathParameters: ["z", "x", "y"],
    queryParameters: ["timestamp"],
    mediaTypes: ["application/x-protobuf"]
  )

  /// The contract's `getStyle`.
  public static let getStyle = URLTemplate(
    operationId: "getStyle",
    path: "/v1/style",
    pathParameters: [],
    queryParameters: [],
    mediaTypes: ["application/json"]
  )
}
