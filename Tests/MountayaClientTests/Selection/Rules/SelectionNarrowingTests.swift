import Testing

@testable import MountayaClient

@Suite("SelectionNarrowing")
struct SelectionNarrowingTests {
  private static let tree: FieldSelection = [
    "routes": [
      "analysis": ["elevations": true, "advisories": ["tollway": true]],
      "distance": true,
      "duration": true,
    ],
    "summary": true,
  ]

  private static func refusal(_ selection: FieldSelection) -> SelectionError? {
    do {
      _ = try SelectionNarrowing.narrow(tree, to: selection)
      return nil
    } catch {
      guard case .selection(let refusal) = error else { return nil }
      return refusal
    }
  }

  @Test("the narrowed selection follows the tree's order")
  func followsTheTree() throws {
    let narrowed = try SelectionNarrowing.narrow(
      Self.tree,
      to: ["summary": true, "routes": ["duration": true, "analysis": ["elevations": true]]]
    )

    #expect(
      narrowed == [
        "routes": ["analysis": ["elevations": true], "duration": true], "summary": true,
      ]
    )
  }

  @Test("the whole tree narrows to itself")
  func wholeTree() throws {
    #expect(try SelectionNarrowing.narrow(Self.tree, to: Self.tree) == Self.tree)
  }

  @Test("a field outside the tree is named by its path, with the fields that are there")
  func unknownField() throws {
    let refusal = try #require(Self.refusal(["routes": ["analysis": ["nope": true]]]))

    #expect(refusal.path == ["routes", "analysis", "nope"])
    #expect(refusal.message.contains("`elevations`, `advisories`"))
  }

  @Test("an object selected with `true` is selected whole, at any depth")
  func objectSelectedWhole() throws {
    #expect(
      try SelectionNarrowing.narrow(Self.tree, to: ["routes": true])
        == [
          "routes": [
            "analysis": ["elevations": true, "advisories": ["tollway": true]],
            "distance": true,
            "duration": true,
          ]
        ]
    )
    #expect(
      try SelectionNarrowing.narrow(
        Self.tree, to: ["summary": true, "routes": ["duration": true, "analysis": true]])
        == [
          "routes": [
            "analysis": ["elevations": true, "advisories": ["tollway": true]],
            "duration": true,
          ],
          "summary": true,
        ]
    )
  }

  @Test("a value given fields and an empty object are each refused")
  func shapeMismatches() {
    #expect(Self.refusal(["summary": ["text": true]])?.path == ["summary"])
    #expect(Self.refusal(["routes": [:]])?.path == ["routes"])
    #expect(
      Self.refusal(["routes": ["analysis": ["advisories": [:]]]])?.path
        == ["routes", "analysis", "advisories"])
  }

  @Test("a selection that names no field is refused as a whole")
  func emptySelection() {
    #expect(Self.refusal([:])?.path == [])
    #expect(Self.refusal(true)?.path == [])
    #expect(Self.refusal(false)?.path == [])
    #expect(Self.refusal(["summary": false])?.path == [])
  }
}
