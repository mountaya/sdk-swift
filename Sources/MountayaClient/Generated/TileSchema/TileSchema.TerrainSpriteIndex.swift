// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// The index of a terrain's sprite sheet, in the sprite format of the MapLibre
  /// Style Specification: one entry per icon, keyed by the icon's name, giving
  /// where the icon sits on the sheet `getTerrainSprite` serves beside it as a
  /// PNG. A map renderer reads it on its own; a client never needs to.
  public typealias TerrainSpriteIndex = [String: JSONValue]
}
