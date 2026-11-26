/// layersManifestPath is the layers manifest's path on the Tile API, the `manifestPath`
/// `map/events-access-refused.json` declares: the catalogue `MapEngine.loadTerrain(_:variant:)`
/// reads through the client.
let layersManifestPath = "/v1/tile-layers"

/// layersManifestAddress is the address the layers manifest is read at, which a refusal of it is
/// told at (`map.events.access-refused`): the Tile API's address as the client reaches it, with the
/// manifest's path joined on and no slash doubled, every slash ending the address dropped first.
/// The read goes through the client, whose refusal carries a status and no address.
func layersManifestAddress(_ tilesBaseUrl: String) -> String {
  var address = Substring(tilesBaseUrl)
  while address.last == "/" {
    address = address.dropLast()
  }
  return String(address) + layersManifestPath
}
