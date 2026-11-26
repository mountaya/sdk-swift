import Testing

@testable import MountayaGeo

@Suite("NavigationEvent")
struct NavigationEventTests {
  @Test("the events are the contract's eight, in its order")
  func contractsOrder() {
    #expect(
      NavigationEvent.allCases.map(\.id) == [
        "start", "route-received", "route-failed", "on-route", "off-route", "reroute", "arrived",
        "stop",
      ])
  }
}
