import Foundation
import MountayaClient

/// terrainVariantOfStyle answers which variant of `terrain` the document at `style` is, or nil
/// where the terrain's two variants are that one document, or neither is. A variant's address is
/// read as Foundation reads the text the catalogue wrote, as the renderer loads it.
func terrainVariantOfStyle(_ terrain: TileSchema.Terrain, style: URL?) -> TileSchema.TerrainVariant?
{
  let light = terrain.variants.light.style.url.url
  let dark = terrain.variants.dark.style.url.url
  switch (light == style, dark == style) {
  case (true, false): return .light
  case (false, true): return .dark
  default: return nil
  }
}
