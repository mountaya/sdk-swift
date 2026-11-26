import Testing

@testable import MountayaElements

@Suite("ProfileParts")
struct ProfilePartsTests {
  @Test("the standard parts are the services above the pins alone, and each part is its own")
  func parts() {
    let every: [ProfileParts] = [
      .amenities, .sections, .tooltip, .navigator, .elevationAxis, .distanceAxis,
    ]
    let all = every.reduce(ProfileParts()) { $0.union($1) }

    #expect(ProfileParts.standard == [.amenities])
    #expect(Set(every.map(\.rawValue)).count == every.count)
    #expect(every.allSatisfy { $0.rawValue.nonzeroBitCount == 1 })
    #expect(every.allSatisfy { all.contains($0) })
    #expect(!ProfileParts.standard.contains(.tooltip), "the strip states the cursor by default")
  }
}
