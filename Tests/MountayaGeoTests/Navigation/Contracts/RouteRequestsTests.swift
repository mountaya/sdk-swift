import Testing

@testable import MountayaGeo

@Suite("RouteRequests")
struct RouteRequestsTests {
  @Test("a navigation at rest has sent nothing and holds nothing")
  func atRest() {
    let rest = RouteRequests<String>.atRest

    #expect(rest.inFlight == nil)
    #expect(rest.sent == 0)
    #expect(rest.waiting == nil)
  }

  /// A request that is nil is still a request: it waits as one, wrapped.
  @Test("a waiting request is held as it was made")
  func waiting() {
    let waiting = RouteRequests<String?>(
      inFlight: 1, sent: 1, waiting: RouteRequests.Waiting(request: nil))

    #expect(waiting.waiting != nil)
    #expect(waiting.waiting?.request == .some(nil))
    #expect(waiting.inFlight == 1)
    #expect(RouteRequests<String>.Send(request: "b", ticket: 2).request == "b")
    #expect(RouteRequests<String>.Send(request: "b", ticket: 2).ticket == 2)
  }
}
