import Testing

@testable import MountayaClient

@Suite("DataOperation")
struct DataOperationTests {
  private static let directions = DataOperation(
    name: "directions",
    inputType: "DirectionsInput!",
    selection: [
      "routes": ["distance": true, "duration": true, "analysis": ["elevations": true]]
    ]
  )

  @Test("the full document is printed from the field tree")
  func fullDocument() {
    #expect(
      Self.directions.document == """
        query Directions($input: DirectionsInput!) {
          directions(input: $input) {
            routes {
              distance
              duration
              analysis {
                elevations
              }
            }
          }
        }

        """
    )
  }

  @Test("an operation carries the budget it is declared with, none where it states none")
  func budget() {
    #expect(Self.directions.timeout == nil)
    #expect(DataOperation.directions.timeout == .seconds(30))
    #expect(
      DataOperation(name: "x", inputType: "XInput!", selection: true, timeout: .seconds(9))
        != DataOperation(name: "x", inputType: "XInput!", selection: true))
  }

  @Test("no selection sends the full document unchanged")
  func absentSelection() throws {
    #expect(try Self.directions.document(selecting: nil) == Self.directions.document)
  }

  @Test("a selection is printed in the tree's order, however it was written")
  func treeOrder() throws {
    let document = try Self.directions.document(selecting: [
      "routes": ["analysis": ["elevations": true], "distance": true]
    ])

    #expect(
      document == """
        query Directions($input: DirectionsInput!) {
          directions(input: $input) {
            routes {
              distance
              analysis {
                elevations
              }
            }
          }
        }

        """
    )
  }

  @Test("a field outside the tree is refused at the call, naming it")
  func outsideTheTree() {
    #expect {
      try Self.directions.document(selecting: ["routes": ["nope": true]])
    } throws: { error in
      guard case .selection(let refusal) = error as? MountayaError else { return false }
      return refusal.path == ["routes", "nope"]
    }
  }
}
