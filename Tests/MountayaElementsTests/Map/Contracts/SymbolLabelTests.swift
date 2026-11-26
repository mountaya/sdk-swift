import MountayaClient
import Testing

@testable import MountayaElements

@Suite("SymbolLabel")
struct SymbolLabelTests {
  @Test("a label is its layer's id and its text field")
  func label() {
    #expect(
      SymbolLabel(id: "place-label", textField: "{name}")
        == SymbolLabel(id: "place-label", textField: "{name}"))
    #expect(
      SymbolLabel(id: "place-label", textField: "{name}")
        != SymbolLabel(id: "place-label", textField: "{ref}"))
  }
}
