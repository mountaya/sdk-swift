import Foundation
import Testing

@testable import MountayaGeo

@Suite("CurveCutoff")
struct CurveCutoffTests {
  @Test("two cut-offs are equal where every member is, the instants as one number of seconds")
  func equality() {
    let gate = ProfilePlace(.atDistance(id: "gate", distance: 300), name: "Gate")
    let instant = Date(timeIntervalSince1970: 1_788_000_000)
    let cutoff = CurveCutoff(key: "gate#0", place: gate, distance: 300, x: 60, cutoffAt: instant)
    #expect(
      cutoff == CurveCutoff(key: "gate#0", place: gate, distance: 300, x: 60, cutoffAt: instant))
    #expect(
      cutoff.hashValue
        == CurveCutoff(key: "gate#0", place: gate, distance: 300, x: 60, cutoffAt: instant)
        .hashValue)
    #expect(
      cutoff
        != CurveCutoff(
          key: "gate#0", place: gate, distance: 300, x: 60, cutoffAt: instant.addingTimeInterval(1))
    )
  }
}
