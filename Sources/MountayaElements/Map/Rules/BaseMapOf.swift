import Foundation
import MountayaClient
import MountayaGeo

/// baseMapOf answers the base map a terrain slug names (`map.basemap.terrain`): the catalogue's
/// terrain of slug `slug`, matched by its scalars, or its first terrain where `slug` is nil, and
/// the document of its `variant`, the dark one where `variant` is dark and the light one otherwise.
/// A terrain whose two variants are one document draws that document in either. The document's
/// address is the text the catalogue wrote, read as Foundation reads it, as the renderer loads it.
///
/// nil where the catalogue holds no terrain of that slug, or none at all, or where its document's
/// address is one Foundation reads no URL from, which no renderer could load.
func baseMapOf(
  _ terrains: [TileSchema.Terrain], slug: String?, variant: TileSchema.TerrainVariant
) -> (terrain: TileSchema.Terrain, style: URL)? {
  let named: TileSchema.Terrain?
  if let slug {
    named = terrains.first { sameText($0.slug, slug) }
  } else {
    named = terrains.first
  }
  guard let found = named else { return nil }
  let rendition =
    sameText(variant, .dark) ? found.variants.dark : found.variants.light
  guard let style = rendition.style.url.url else { return nil }
  return (found, style)
}
