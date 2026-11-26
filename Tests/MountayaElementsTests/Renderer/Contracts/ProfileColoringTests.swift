import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("ProfileColoring")
struct ProfileColoringTests {
  @Test("a coloring is told apart by its case and by what it carries")
  func equality() {
    let stretch = CurveColor(from: 0, to: 100, color: "#e03131")

    #expect(ProfileColoring.plain == .plain)
    #expect(ProfileColoring.stretches([stretch]) == .stretches([stretch]))
    #expect(ProfileColoring.stretches([stretch]) != .stretches([]))
    #expect(ProfileColoring.slope(slopeBuckets) != .slope([]))
    #expect(ProfileColoring.classes([]) != .stretches([]))
    #expect(Set<ProfileColoring>([.plain, .plain, .slope(slopeBuckets)]).count == 2)
  }

  @Test("a slope given no buckets is painted from Geo's own ramp")
  func slopeDefault() {
    #expect(ProfileColoring.slope() == .slope(slopeBuckets))
    #expect(ProfileColoring.slope() != .slope([]))
  }
}
