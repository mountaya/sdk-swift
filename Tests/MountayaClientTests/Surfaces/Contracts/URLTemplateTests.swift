import Foundation
import Testing

@testable import MountayaClient

@Suite("URLTemplate")
struct URLTemplateTests {
  @Test("a value is placed percent-encoded as one segment, and a renderer's placeholders stay")
  func filled() {
    let template = TileTemplates.getItineraryTile

    #expect(template.pathParameters == ["itinerary_id", "z", "x", "y"])
    #expect(
      template.filled(with: ["itinerary_id": "it 7/{z}"])
        == "/v1/itineraries/it%207%2F%7Bz%7D/{z}/{x}/{y}")
    #expect(template.filled(with: [:]) == template.path)
    #expect(template.filled(with: ["absent": "x"]) == template.path)
  }

  @Test("the Tile API's templates are the routes a renderer fetches, each under the tile origin")
  func tileTemplates() throws {
    let names = TileTemplates.all.map(\.operationId)

    #expect(names.count == 13)
    #expect(Set(names).count == names.count)
    #expect(names.contains("getTerrainStyle") && names.contains("getZonesTile"))
    for template in TileTemplates.all {
      // Every placeholder filled, as a renderer fills its own: the address it fetches is a Tile
      // API request, which the map's request hook sends the credential to.
      let values = Dictionary(uniqueKeysWithValues: template.pathParameters.map { ($0, "1") })
      let url = try #require(
        URL(string: BaseURLs.standard.tiles.absoluteString + template.filled(with: values)))
      #expect(isTileRequest(url, tiles: BaseURLs.standard.tiles), "\(template.operationId)")
      #expect(!template.mediaTypes.isEmpty, "\(template.operationId)")
    }
  }

  @Test("a template compares by every part the contract states")
  func equality() {
    let tile = URLTemplate(
      operationId: "getTile", path: "/v1/{z}/{x}/{y}", pathParameters: ["z", "x", "y"])

    #expect(
      tile
        == URLTemplate(
          operationId: "getTile", path: "/v1/{z}/{x}/{y}", pathParameters: ["z", "x", "y"]))
    #expect(tile != URLTemplate(operationId: "getTile", path: "/v1/{z}/{x}/{y}"))
    #expect(tile.queryParameters.isEmpty && tile.mediaTypes.isEmpty)
  }
}
