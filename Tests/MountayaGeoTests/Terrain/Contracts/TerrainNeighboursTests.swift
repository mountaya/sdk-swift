import Testing

@testable import MountayaGeo

@Suite("TerrainNeighbours")
struct TerrainNeighboursTests {
  @Test("two neighbourhoods are equal where every elevation is the same number, and hash alike")
  func equality() {
    let neighbours = TerrainNeighbours(north: 1, south: 2, east: 3, west: 4)
    #expect(neighbours == TerrainNeighbours(north: 1, south: 2, east: 3, west: 4))
    #expect(
      neighbours.hashValue == TerrainNeighbours(north: 1, south: 2, east: 3, west: 4).hashValue)
    #expect(neighbours != TerrainNeighbours(north: 1, south: 2, east: 4, west: 3))
    // The numbers are compared as the same numbers: NaN as itself, and -0 as another than 0.
    let unknown = TerrainNeighbours(north: .nan, south: 2, east: 3, west: 4)
    #expect(unknown == TerrainNeighbours(north: .nan, south: 2, east: 3, west: 4))
    #expect(
      unknown.hashValue == TerrainNeighbours(north: .nan, south: 2, east: 3, west: 4).hashValue)
    #expect(
      TerrainNeighbours(north: 0, south: 2, east: 3, west: 4)
        != TerrainNeighbours(north: -0.0, south: 2, east: 3, west: 4))
  }

  @Test("each elevation is named by its side")
  func sides() {
    let neighbours = TerrainNeighbours(north: 1199, south: 1201, east: 1200.5, west: 1199.5)
    #expect(
      [neighbours.north, neighbours.south, neighbours.east, neighbours.west]
        == [1199, 1201, 1200.5, 1199.5])
    #expect(
      String(describing: neighbours)
        == "TerrainNeighbours(north: 1199.0, south: 1201.0, east: 1200.5, west: 1199.5)")
  }
}
