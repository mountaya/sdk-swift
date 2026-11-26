import Testing

@testable import MountayaClient

@Suite("QueryItem")
struct QueryItemTests {
  @Test("an item compares by its name and its value")
  func equality() {
    #expect(QueryItem(name: "limit", value: "20") == QueryItem(name: "limit", value: "20"))
    #expect(QueryItem(name: "limit", value: "20") != QueryItem(name: "offset", value: "20"))
  }
}
