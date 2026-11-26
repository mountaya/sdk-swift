import Foundation
import MountayaClient
import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("ElevationReads")
@MainActor
struct ElevationReadsTests {
  /// Elevation answers the source's TileJSON and each tile with its own bytes, and records each
  /// request.
  private actor Elevation: HTTPExchange {
    private(set) var sent: [URL] = []

    func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
      sent.append(request.url)
      let body =
        request.url.path.hasSuffix("tiles.json")
        ? #"{"encoding": "terrarium", "maxzoom": 16, "tiles": ["https://tiles.mountaya.com/v1/elevation/{z}/{x}/{y}"]}"#
        : "[[[128, 0, 0]]]"
      return ExchangeResponse(
        status: 200, headers: ["Content-Type": "application/json"],
        body: ExchangeBody(Data(body.utf8)))
    }
  }

  /// Bytes reads a tile as one pixel of the bytes `[128, 0, 0]`.
  private struct OnePixel: ElevationImageDecoding {
    func pixels(of image: Data, edge: Int) -> [UInt8]? { edge == 1 ? [128, 0, 0] : nil }
  }

  /// OffMain reads a tile as `OnePixel` does off the main thread, and reads none on it.
  private struct OffMain: ElevationImageDecoding {
    func pixels(of image: Data, edge: Int) -> [UInt8]? {
      !Thread.isMainThread && edge == 1 ? [128, 0, 0] : nil
    }
  }

  private let elevation = TileSchema.Elevation(
    id: "e", tile_size: TileSchema.ElevationTileSize(rawValue: 1),
    url: URI("https://tiles.mountaya.com/v1/elevation/tiles.json"))

  @Test("the source is read off its TileJSON once, and each tile through the client")
  func reads() async throws {
    let exchange = Elevation()
    let client = try Mountaya(credential: .publishable(key: "pk_a"), exchange: exchange)
    let reads = ElevationReads()
    reads.decoder = OnePixel()

    let source = try await reads.source(of: elevation, through: client)
    _ = try await reads.source(of: elevation, through: client)
    let tile = try await reads.tile(
      ElevationTile(z: 16, x: 3, y: 4), of: source, through: client)

    #expect(source.source == ElevationSource(encoding: .terrarium, tileSize: 1, zoom: 16))
    #expect(tile == ElevationTile(z: 16, x: 3, y: 4, pixels: [128, 0, 0]))
    #expect(
      await exchange.sent.map(\.path) == ["/v1/elevation/tiles.json", "/v1/elevation/16/3/4"])
  }

  @Test("a tile's image is decoded off the main thread")
  func decodedOffMain() async throws {
    let client = try Mountaya(credential: .publishable(key: "pk_a"), exchange: Elevation())
    let reads = ElevationReads()
    reads.decoder = OffMain()

    let source = try await reads.source(of: elevation, through: client)
    let tile = try await reads.tile(
      ElevationTile(z: 16, x: 3, y: 4), of: source, through: client)

    #expect(tile?.pixels == [128, 0, 0], "the decoder answers off the main thread alone")
  }

  @Test("an address elsewhere than the Tile API is refused, and sent nothing")
  func elsewhere() async throws {
    let exchange = Elevation()
    let client = try Mountaya(credential: .publishable(key: "pk_a"), exchange: exchange)
    let foreign = TileSchema.Elevation(
      id: "e", tile_size: TileSchema.ElevationTileSize(rawValue: 1),
      url: URI("https://example.com/tiles.json"))

    await #expect(throws: MountayaError.self) {
      _ = try await ElevationReads().source(of: foreign, through: client)
    }
    #expect(await exchange.sent.isEmpty)
  }
}
