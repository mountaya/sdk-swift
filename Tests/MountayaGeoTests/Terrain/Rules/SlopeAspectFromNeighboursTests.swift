import Testing

@testable import MountayaGeo

@Suite("slopeAspectFromNeighbours")
struct SlopeAspectFromNeighboursTests {
  private let spacing = 0.0001

  private func answer(
    north: Double, south: Double, east: Double, west: Double, latitude: Double = 45.9
  ) -> SlopeAspect {
    slopeAspectFromNeighbours(
      TerrainNeighbours(north: north, south: south, east: east, west: west), latitude: latitude,
      spacingDegrees: spacing)
  }

  @Test("flat ground has no slope and faces nowhere")
  func flat() {
    #expect(
      answer(north: 1200, south: 1200, east: 1200, west: 1200) == SlopeAspect(slope: 0, aspect: nil)
    )
  }

  @Test("the aspect is the compass bearing of the descent")
  func descent() {
    #expect(answer(north: 1199, south: 1201, east: 1200, west: 1200).aspect == 0)
    #expect(answer(north: 1200, south: 1200, east: 1199, west: 1201).aspect == 90)
    #expect(answer(north: 1201, south: 1199, east: 1200, west: 1200).aspect == 180)
    #expect(answer(north: 1200, south: 1200, east: 1201, west: 1199).aspect == 270)
  }

  /// A bearing of zero is +0, a north-facing slope, never -0 and never 360.
  @Test("a north-facing slope reads zero as a positive zero")
  func northIsPositiveZero() throws {
    let aspect = try #require(answer(north: 1199, south: 1201, east: 1200, west: 1200).aspect)
    #expect(aspect == 0)
    #expect(aspect.sign == .plus)
  }

  @Test("a bearing just west of north stays under a turn")
  func justWestOfNorth() throws {
    let just = answer(north: 1150, south: 1250, east: 1200.01, west: 1199.99)
    #expect(isClose(try #require(just.aspect), 359.9835336328873, within: 1e-9))
    #expect(isClose(just.slope, 77.462040543526, within: 1e-9))
  }

  /// The east-west span shrinks by the cosine of the latitude, so the same fall eastward is steeper
  /// nearer a pole.
  @Test("the east-west span shrinks with the latitude")
  func latitude() {
    #expect(
      isClose(
        answer(north: 1200, south: 1200, east: 1199, west: 1201).slope, 7.36347066874295,
        within: 1e-9))
    #expect(
      isClose(
        answer(north: 1200, south: 1200, east: 1199, west: 1201, latitude: 60).slope,
        10.196443687446688, within: 1e-9))
  }

  @Test("the slope is the gradient's magnitude as an angle")
  func magnitude() {
    #expect(
      isClose(
        answer(north: 1199, south: 1201, east: 1200, west: 1200).slope, 5.1389088537818175,
        within: 1e-9))
    #expect(
      isClose(
        answer(north: 1000, south: 1400, east: 1200, west: 1200).slope, 86.81777613564847,
        within: 1e-9))
  }

  @Test("a neighbour that is not a number leaves both not a number")
  func unknownNeighbour() throws {
    let unknown = answer(north: .nan, south: 1200, east: 1200, west: 1200)
    #expect(unknown.slope.isNaN)
    #expect(try #require(unknown.aspect).isNaN)
  }

  @Test("a spacing of zero on flat ground is not a number rather than flat")
  func zeroSpacing() throws {
    let none = slopeAspectFromNeighbours(
      TerrainNeighbours(north: 1200, south: 1200, east: 1200, west: 1200), latitude: 45.9,
      spacingDegrees: 0)
    #expect(none.slope.isNaN)
    #expect(try #require(none.aspect).isNaN)
    #expect(answer(north: 1, south: 1, east: 1, west: 1, latitude: 89).aspect == nil)
  }
}
