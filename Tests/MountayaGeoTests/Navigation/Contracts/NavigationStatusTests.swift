import Testing

@testable import MountayaGeo

@Suite("NavigationStatus")
struct NavigationStatusTests {
  /// The order the contract lists them in, from idle, rather than the order of their ids.
  @Test("the statuses are the contract's seven, in its order")
  func contractsOrder() {
    #expect(
      NavigationStatus.allCases.map(\.id) == [
        "idle", "routing", "navigating", "off-route", "rerouting", "arrived", "failed",
      ])
    #expect(NavigationStatus(rawValue: "off-route") == .offRoute)
  }
}
