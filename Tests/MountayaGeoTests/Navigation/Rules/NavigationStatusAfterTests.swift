import Testing

@testable import MountayaGeo

@Suite("navigationStatusAfter")
struct NavigationStatusAfterTests {
  private func after(_ status: NavigationStatus, on events: NavigationEvent...) -> NavigationStatus
  {
    events.reduce(status, navigationStatusAfter)
  }

  @Test("a start routes and a stop idles, from every status")
  func startAndStop() {
    for status in NavigationStatus.allCases {
      #expect(navigationStatusAfter(status, on: .start) == .routing, "\(status)")
      #expect(navigationStatusAfter(status, on: .stop) == .idle, "\(status)")
    }
  }

  /// A first route that fails leaves nothing to follow; a new one that fails leaves the route held.
  @Test("a first route that fails fails, and a new one leaves the traveller off route")
  func failures() {
    #expect(after(.routing, on: .routeFailed) == .failed)
    #expect(after(.rerouting, on: .routeFailed) == .offRoute)
    #expect(after(.rerouting, on: .routeFailed, .reroute) == .rerouting)
  }

  @Test("a reroute moves only a traveller off the route")
  func rerouteOffRoute() {
    #expect(
      NavigationStatus.allCases.filter { navigationStatusAfter($0, on: .reroute) != $0 } == [
        .offRoute
      ])
    #expect(navigationStatusAfter(.offRoute, on: .reroute) == .rerouting)
  }

  /// While a new route is awaited the answer decides, and an answer nobody awaits moves nothing.
  @Test("a position moves nothing while a new route is awaited")
  func awaited() {
    #expect(after(.rerouting, on: .onRoute, .offRoute) == .rerouting)
    #expect(after(.rerouting, on: .routeReceived) == .navigating)
  }

  @Test("an answer the navigation is not awaiting moves nothing")
  func unawaited() {
    for status in NavigationStatus.allCases where status != .routing && status != .rerouting {
      #expect(navigationStatusAfter(status, on: .routeReceived) == status, "\(status)")
      #expect(navigationStatusAfter(status, on: .routeFailed) == status, "\(status)")
    }
  }

  @Test("a traveller arrives only from a route they follow")
  func arrival() {
    #expect(
      NavigationStatus.allCases.filter {
        navigationStatusAfter($0, on: .arrived) == .arrived && $0 != .arrived
      } == [.navigating, .offRoute, .rerouting])
    #expect(after(.arrived, on: .offRoute, .onRoute) == .arrived)
  }

  @Test("a journey with a reroute")
  func journey() {
    let events: [NavigationEvent] = [
      .start, .routeReceived, .offRoute, .reroute, .routeReceived, .arrived,
    ]
    var journey: [NavigationStatus] = [.idle]
    for event in events {
      journey.append(navigationStatusAfter(journey[journey.count - 1], on: event))
    }

    #expect(
      journey == [.idle, .routing, .navigating, .offRoute, .rerouting, .navigating, .arrived])
  }
}
