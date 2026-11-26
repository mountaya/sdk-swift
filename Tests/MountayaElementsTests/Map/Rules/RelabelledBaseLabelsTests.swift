import MountayaClient
import Testing

@testable import MountayaElements

@Suite("relabelledBaseLabels")
struct RelabelledBaseLabelsTests {
  @Test("a base label reading a name is relabelled, one reading none is left, a placed one skipped")
  func scope() {
    let labels = [
      SymbolLabel(id: "place-label", textField: "{name}"),
      SymbolLabel(id: "road-shield", textField: "{ref}"),
      SymbolLabel(id: "waypoint-label", textField: "{name}"),
      SymbolLabel(id: "peak-label", textField: "{name}\n{ele}"),
    ]
    let relabelled = relabelledBaseLabels(
      labels, isPlaced: { $0 == "waypoint-label" }, language: .de)
    #expect(relabelled.map(\.id) == ["place-label", "road-shield", "peak-label"])
    #expect(relabelled.map { $0.label != nil } == [true, false, true])
    #expect(
      relabelled.first?.label
        == ["coalesce", ["get", "name:de"], ["get", "name"]],
      "\(String(describing: relabelled.first?.label))")
  }
}
