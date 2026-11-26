import Foundation
import MountayaClient
import MountayaGeo

/// ElevationReads is how a map reads the terrain its readout states (`map.readout.open`): the
/// elevation source the layers catalogue names, its address `elevation.url`, whose TileJSON
/// document states the `encoding`, the `maxzoom` and the tile template, read once for that address
/// and held, and the tiles `geo.terrain.elevation-sample` needs, `getElevationTile` at the source's
/// deepest zoom. Every read goes through the client's tile transport, `Mountaya.mapFile(at:
/// operationId:)`, under the credential the map draws its base map with, and asks nothing of the
/// Data API. A tile's image is read into its pixels by `decoder`, the platform's own codec, off the
/// main actor, so a decode never holds the frame the map is drawing.
///
/// It is bound to the main actor, as the map it reads for is.
@MainActor
final class ElevationReads {
  /// Source is the elevation source a TileJSON document describes, and its tile template.
  struct Source: Sendable {
    let source: ElevationSource
    let template: String
  }

  /// decoder reads a tile's image into its pixels.
  var decoder: any ElevationImageDecoding = PlatformElevationDecoder()
  /// held is the source read last, with the catalogue's address it was read from.
  private var held: (address: String, source: Source)?

  /// source answers the source `elevation`, the catalogue's, names: the one held for its address,
  /// else its TileJSON read through `client`. It throws what the read throws, and a
  /// `ConfigurationError` where the address or the document names no source to read.
  func source(of elevation: TileSchema.Elevation, through client: Mountaya) async throws -> Source {
    let address = elevation.url.text
    if let held, sameText(held.address, address) { return held.source }
    guard let url = URL(string: address) else { throw Self.refusal(address) }
    let file = try await client.mapFile(at: url, operationId: "getElevationTileJson")
    guard case .object(let document) = try JSONDecoder().decode(JSONValue.self, from: file.bytes),
      case .array(let templates)? = document["tiles"],
      case .string(let template)? = templates.first,
      case .number(let zoom)? = document["maxzoom"], let deepest = Int(exactly: zoom)
    else { throw Self.refusal(address) }
    var encoding = ElevationEncoding.mapbox
    if case .string(let named)? = document["encoding"] {
      encoding = ElevationEncoding(rawValue: named)
    }
    let source = Source(
      source: ElevationSource(
        encoding: encoding, tileSize: elevation.tile_size.rawValue, zoom: deepest),
      template: template)
    held = (address, source)
    return source
  }

  /// tile reads the tile at `address` of `source`, its image read into its pixels off the main
  /// actor, or nil where the image is none the decoder reads, `departed` told as its read leaves.
  /// It throws what the read throws.
  func tile(
    _ address: ElevationTile, of source: Source, through client: Mountaya,
    departed: (@Sendable () -> Void)? = nil
  ) async throws -> ElevationTile? {
    let filled = source.template.replacingOccurrences(of: "{z}", with: String(address.z))
      .replacingOccurrences(of: "{x}", with: String(address.x))
      .replacingOccurrences(of: "{y}", with: String(address.y))
    guard let url = URL(string: filled) else { throw Self.refusal(filled) }
    let file = try await client.mapFile(
      at: url, operationId: "getElevationTile", departed: departed)
    guard
      let pixels = await Self.decoded(file.bytes, edge: source.source.tileSize, by: decoder)
    else { return nil }
    return ElevationTile(z: address.z, x: address.x, y: address.y, pixels: pixels)
  }

  /// decoded reads `image` into its pixels through `decoder` on the shared pool rather than the
  /// main actor, since a platform's codec takes milliseconds over a tile of 512 pixels a side.
  @concurrent
  private nonisolated static func decoded(
    _ image: Data, edge: Int, by decoder: any ElevationImageDecoding
  ) async -> [UInt8]? {
    decoder.pixels(of: image, edge: edge)
  }

  /// refusal is the failure of an address or a document that names no source to read.
  private static func refusal(_ address: String) -> MountayaError {
    .configuration(ConfigurationError(message: "`\(address)` names no elevation source to read."))
  }
}
