import Testing

@testable import MountayaGeo

@Suite("isSearchListShown")
struct IsSearchListShownTests {
  @Test("the list shows while the focus stands in the control over a query not dismissed")
  func shown() {
    #expect(isSearchListShown(hasFocus: true, query: "Mont", isDismissed: false))
  }

  @Test("no list shows without the focus in the control, or once the reader dismissed it")
  func hidden() {
    #expect(!isSearchListShown(hasFocus: false, query: "Mont", isDismissed: false))
    #expect(!isSearchListShown(hasFocus: true, query: "Mont", isDismissed: true))
  }

  @Test("a query of white space alone shows no list")
  func whiteSpace() {
    for query in ["", "   ", "\t\n", "  \u{FEFF}"] {
      #expect(!isSearchListShown(hasFocus: true, query: query, isDismissed: false), "`\(query)`")
    }
  }
}
