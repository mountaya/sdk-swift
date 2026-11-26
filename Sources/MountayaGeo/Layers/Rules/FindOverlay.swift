import MountayaClient

/// enrichmentCategorySlug is the slug of the one category of the layers manifest whose overlays
/// stack.
public let enrichmentCategorySlug = "enrichment"

/// overlayKindOf is the kind of overlay `category` holds: an enrichment where its slug is
/// `enrichmentCategorySlug`, exactly, and a classic overlay for every other category.
public func overlayKindOf(_ category: TileSchema.CategoryOverlays) -> OverlayKind {
  sameText(category.slug, enrichmentCategorySlug) ? .enrichment : .classic
}

/// findOverlay is the overlay of the layers manifest `layers` that `slug` names: the first overlay
/// carrying the slug, exactly as the manifest spells it, reading the categories in the manifest's
/// order and each one's overlays in its own, among the categories of `kind` where a kind is named.
/// `nil` where none carries it, and where only an overlay of the other kind does.
public func findOverlay(
  _ layers: TileSchema.Layers, slug: String, kind: OverlayKind? = nil
) -> TileSchema.Overlay? {
  for category in layers.overlays where kind == nil || overlayKindOf(category) == kind {
    if let found = category.children.first(where: { sameText($0.slug, slug) }) {
      return found
    }
  }
  return nil
}
