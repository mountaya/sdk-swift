import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("amenityStacks")
struct AmenityStacksTests {
  private func pin(_ key: String, amenities: [RestSchema.WaypointAmenity]?) -> CurvePin {
    CurvePin(
      key: key,
      place: ProfilePlace(
        .atDistance(id: key, distance: 0),
        details: amenities.map { WaypointDetails(amenities: $0) }),
      distance: 0, x: 0, y: 0, altitude: 0)
  }

  private let six: [RestSchema.WaypointAmenity] = [
    "water", "hot-meal", "toilets", "first-aid", "showers", "wifi",
  ]

  @Test("six services show four and count two, all named")
  func defaults() {
    #expect(defaultAmenityStackMax == 4)
    let stacks = amenityStacks([pin("col#0", amenities: six)])
    #expect(stacks.first?.shown.count == 4 && stacks.first?.counted == 2)
    #expect(stacks.first?.named.count == 6)
  }

  @Test("a maximum is rounded down, none below zero or no number")
  func maximum() {
    #expect(amenityStacks([pin("col#0", amenities: six)], max: 2.7).first?.shown.count == 2)
    #expect(amenityStacks([pin("col#0", amenities: six)], max: -1).first?.counted == 6)
    #expect(amenityStacks([pin("col#0", amenities: six)], max: .nan).first?.counted == 6)
    #expect(amenityStacks([pin("col#0", amenities: six)], max: 0).first?.shown.isEmpty == true)
    #expect(amenityStacks([pin("col#0", amenities: six)], max: .infinity).first?.counted == 0)
  }

  @Test("a place offering no service takes no stack")
  func none() {
    let stacks = amenityStacks([
      pin("start#0", amenities: nil), pin("gate#0", amenities: []),
      pin("spring#0", amenities: ["water"]),
    ])
    #expect(stacks.map(\.pin.key) == ["spring#0"])
  }
}
