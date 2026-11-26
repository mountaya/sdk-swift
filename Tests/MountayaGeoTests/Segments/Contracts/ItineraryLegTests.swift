import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("ItineraryLeg")
struct ItineraryLegTests {
  private func leg(
    id: String = "s1", distance: Double? = 1_000, duration: Double? = 600,
    geometry: GeoJSONGeometry? = lineString([6, 45], [6.01, 45])
  ) -> ItineraryLeg {
    ItineraryLeg(
      id: id, memberIds: ["a", "b"], name: "Approach", color: "#e9501e", geometry: geometry,
      sectionDistance: distance, sectionAscent: 120, sectionDescent: 20, duration: duration,
      altitudeMin: 1_000, altitudeMax: 1_300)
  }

  @Test("two legs are equal when every member is, and hash alike")
  func equality() {
    #expect(leg() == leg())
    #expect(leg().hashValue == leg().hashValue)
    #expect(leg(distance: .nan) == leg(distance: .nan))
    #expect(leg(distance: .nan).hashValue == leg(distance: .nan).hashValue)
    #expect(leg(distance: 0) != leg(distance: -0.0))
    #expect(leg(distance: nil) != leg(distance: 0))
    #expect(leg(duration: nil) != leg())
    #expect(leg(geometry: nil) != leg())
    #expect(
      leg(geometry: lineString([6, 45], [.nan, 45]))
        == leg(geometry: lineString([6, 45], [.nan, 45]))
    )
  }

  /// `é` and `e` with a combining acute are one `String` to Swift and two ids to every other SDK.
  @Test("an id is compared scalar for scalar")
  func idByScalars() {
    #expect(leg(id: "caf\u{E9}") != leg(id: "cafe\u{301}"))
  }

  @Test("a leg built with no figures states none, and stands for itself alone")
  func defaults() {
    let bare = ItineraryLeg(id: "s1", name: "s1")

    #expect(bare.memberIds.isEmpty)
    #expect(bare.color == nil && bare.geometry == nil)
    #expect(bare.sectionDistance == nil && bare.sectionAscent == nil && bare.sectionDescent == nil)
    #expect(bare.duration == nil && bare.altitudeMin == nil && bare.altitudeMax == nil)
  }
}
