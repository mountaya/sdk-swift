import Testing

@testable import MountayaClient

@Suite("SelectionError")
struct SelectionErrorTests {
  @Test("the description names the field by its path")
  func namesTheField() {
    let error = SelectionError(path: ["routes", "nope"], message: "no such field")

    #expect(error.description == "`routes.nope`: no such field")
  }

  @Test("a selection wrong as a whole has no path to name")
  func wholeSelection() {
    #expect(SelectionError(path: [], message: "selects nothing").description == "selects nothing")
  }
}
