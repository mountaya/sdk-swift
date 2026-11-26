import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("roadAccessStripePattern")
struct RoadAccessStripePatternTests {
  @Test("a stretch is striped 6 pixels wide on white in a 16-pixel tile, in its kind's colour")
  func pattern() {
    #expect(
      roadAccessStripePattern(.permit)
        == StripePattern(
          size: 16, width: 6, color: "#9c36b5", ground: "#ffffff", lineCap: .round,
          segments: [[[-8, 8], [8, -8]], [[0, 16], [16, 0]], [[8, 24], [24, 8]]]))
    for kind in RoadAccessKind.allCases {
      #expect(roadAccessStripePattern(kind).color == roadAccessColor(kind).hex, "\(kind.id)")
    }
  }

  @Test("each stripe rises at 45 degrees, and the three tile seamlessly")
  func seamless() {
    let pattern = roadAccessStripePattern(.forbidden)

    for segment in pattern.segments {
      let (from, to) = (segment[0], segment[1])
      // From its lower left end to its upper right one, at 45 degrees.
      #expect(to[0] - from[0] == from[1] - to[1])
      #expect(to[0] > from[0])
    }
    // The halves past the tile's edges are the middle stripe moved by half a tile either way, so
    // a stripe leaving one tile goes on in the next.
    let middle = pattern.segments[1]
    #expect(pattern.segments[0] == middle.map { [$0[0] - 8, $0[1] - 8] })
    #expect(pattern.segments[2] == middle.map { [$0[0] + 8, $0[1] + 8] })
  }
}
