/// roadAccessGlyphPrefix is the namespace a restricted stretch's glyph opens with in the marker set.
let roadAccessGlyphPrefix = "road-access-"

/// roadAccessGlyph is the name of the glyph a restricted stretch of `kind` is marked with, the
/// warning its icon carries: `road-access-` then the kind as the contract spells it, so `permit`
/// is `road-access-permit` and `local-access` is `road-access-local-access`
/// (`geo.icons.resolution`). The marker set holds one for every kind.
public func roadAccessGlyph(_ kind: RoadAccessKind) -> String {
  roadAccessGlyphPrefix + kind.id
}
