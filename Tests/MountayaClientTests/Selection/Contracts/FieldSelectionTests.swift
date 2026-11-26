import Testing

@testable import MountayaClient

@Suite("FieldSelection")
struct FieldSelectionTests {
  @Test("a literal keeps its fields in the order written, with true selecting a field whole")
  func literal() {
    let selection: FieldSelection = [
      "routes": ["distance": true, "analysis": ["elevations": true]]
    ]

    let elevations = FieldSelection(node: .fields([.init(name: "elevations", selection: true)]))
    let routes = FieldSelection(
      node: .fields([
        .init(name: "distance", selection: FieldSelection(node: .whole)),
        .init(name: "analysis", selection: elevations),
      ])
    )
    #expect(selection == FieldSelection(node: .fields([.init(name: "routes", selection: routes)])))
  }

  @Test("a field set to false is left out")
  func falseLeavesOut() {
    let selection: FieldSelection = ["distance": true, "duration": false]

    #expect(selection == ["distance": true])
  }

  @Test("a field named twice takes the selection given last")
  func lastWins() {
    let selection = FieldSelection([("distance", true), ("distance", false), ("duration", true)])

    #expect(selection == ["duration": true])
  }

  @Test("a selection built from pairs is the one the literal writes")
  func pairsAreTheLiteral() {
    let built = FieldSelection([("routes", FieldSelection([("distance", true)]))])

    #expect(built == ["routes": ["distance": true]])
  }
}
