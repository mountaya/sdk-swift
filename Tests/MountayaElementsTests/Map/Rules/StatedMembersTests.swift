import MountayaClient
import Testing

@testable import MountayaElements

@Suite("statedMembers")
struct StatedMembersTests {
  @Test("a member written as nil is unstated, and every other is kept as written")
  func unstated() {
    let patch: [String: JSONValue?] = ["line-color": "#228be6", "line-opacity": nil]

    #expect(statedMembers(patch) == ["line-color": "#228be6"])
  }

  @Test("null, false, zero and the empty string are values")
  func falsyValues() {
    let patch: [String: JSONValue?] = [
      "color": .some(.null), "visible": false, "opacity": 0, "label": "",
    ]

    #expect(statedMembers(patch) == ["color": .null, "visible": false, "opacity": 0, "label": ""])
  }

  @Test("a patch of nothing but unstated members states nothing, and an empty one neither")
  func nothing() {
    #expect(statedMembers(["color": nil, "label": nil]).isEmpty)
    #expect(statedMembers([:]).isEmpty)
  }

  @Test("merged over what is held, a stated member replaces the held one and adds one not held")
  func merged() {
    let held: [String: JSONValue] = ["color": "#e64980", "label": "Hut"]
    let merged = held.merging(statedMembers(["label": "Refuge", "zIndex": 2, "color": nil])) {
      _, stated in stated
    }

    #expect(merged == ["color": "#e64980", "label": "Refuge", "zIndex": 2])
  }
}
