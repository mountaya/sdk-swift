// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension TileSchema {
  /// A terrain rendition as a map style document, in the MapLibre Style
  /// Specification (https://maplibre.org/maplibre-style-spec/), ready to hand to
  /// a map renderer unmodified. It is the base-map provider's own style with every
  /// address rewritten to point at this API: each source that fetches tiles
  /// carries its `tiles` template on `getTerrainSourceTile` rather than a `url` of
  /// its own (a source naming no address, such as an attribution-only one, is left
  /// as the provider wrote it), `sprite` names `getTerrainSprite`, and `glyphs`
  /// names `getTerrainGlyph`, each under the same terrain and rendition as the style. So
  /// a renderer that loads it reaches the base map through this API alone, under
  /// the credential it sends here, and no address in it carries a credential of
  /// Mountaya's.
  ///
  /// The document is the provider's format rather than this contract's, so its
  /// members are not declared here, and a member the style specification adds
  /// reaches a client unchanged.
  public typealias TerrainStyle = [String: JSONValue]
}
