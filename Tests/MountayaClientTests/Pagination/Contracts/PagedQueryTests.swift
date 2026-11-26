import Testing

@testable import MountayaClient

@Suite("PagedQuery")
struct PagedQueryTests {
  @Test("every query the contract pages by cursor is one, its cursor and its limit set through it")
  func printedQueries() {
    var query: any PagedQuery = RestSchema.GetZonesQuery {
      $0.status = .published
    }
    query.cursor = "c5"
    query.limit = 2

    guard let zones = query as? RestSchema.GetZonesQuery else {
      Issue.record("the query is no longer the zones' query")
      return
    }
    #expect(zones.items.map(\.name) == ["cursor", "limit", "status"])
    #expect(zones.cursor == "c5")
  }
}
