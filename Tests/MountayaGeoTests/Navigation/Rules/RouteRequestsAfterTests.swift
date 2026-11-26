import Testing

@testable import MountayaGeo

@Suite("routeRequestsAfter")
struct RouteRequestsAfterTests {
  private typealias Requests = RouteRequests<String?>

  private func made(_ state: Requests, request: String?) -> Requests.Outcome {
    routeRequestsAfter(state, on: .made(request))
  }

  private func answered(_ state: Requests, ticket: Int) -> Requests.Outcome {
    routeRequestsAfter(state, on: .answered(ticket: ticket))
  }

  @Test("a request is sent at once where none is in flight, under the next ticket")
  func sentAtOnce() {
    let first = made(.atRest, request: "a")

    #expect(first.send?.request == "a")
    #expect(first.send?.ticket == 1)
    #expect(first.state.inFlight == 1)
    #expect(!first.deliver)
  }

  @Test("a request made in flight waits, and the newest takes its place")
  func newestWaits() {
    let a = made(.atRest, request: "a").state
    let b = made(a, request: "b")
    let c = made(b.state, request: "c")

    #expect(b.send == nil)
    #expect(b.state.waiting?.request == "b")
    #expect(c.state.waiting?.request == "c")
    #expect(c.state.inFlight == 1)
  }

  /// The answer is to a question already replaced: dropped, and the waiting one sent in its place.
  @Test("an answer something waits behind is dropped for the waiting request")
  func droppedForTheWaiting() {
    let waiting = made(made(.atRest, request: "a").state, request: "b").state
    let outcome = answered(waiting, ticket: 1)

    #expect(!outcome.deliver)
    #expect(outcome.send?.request == "b")
    #expect(outcome.send?.ticket == 2)
    #expect(outcome.state.waiting == nil)
    #expect(answered(outcome.state, ticket: 2).deliver)
  }

  @Test("an answer with nothing waiting is acted on, and leaves nothing in flight")
  func actedOn() {
    let outcome = answered(made(.atRest, request: "a").state, ticket: 1)

    #expect(outcome.deliver)
    #expect(outcome.send == nil)
    #expect(outcome.state.inFlight == nil)
    #expect(outcome.state.sent == 1)
  }

  /// A cancel abandons both; the next request leaves at once, and the abandoned answer is dropped.
  @Test("a cancel abandons what is in flight and what waits")
  func cancel() {
    let cancelled = routeRequestsAfter(
      made(made(.atRest, request: "a").state, request: "b").state, on: .cancelled)

    #expect(cancelled.state.inFlight == nil)
    #expect(cancelled.state.waiting == nil)
    #expect(!cancelled.deliver)
    #expect(!answered(cancelled.state, ticket: 1).deliver)

    let next = made(cancelled.state, request: "c")
    #expect(next.send?.ticket == 2)
    #expect(!answered(next.state, ticket: 1).deliver)
    #expect(answered(next.state, ticket: 2).deliver)
  }

  /// A request that is nil is still one, and waits as one.
  @Test("a nil request is a request")
  func nilRequest() {
    let waiting = made(made(.atRest, request: "a").state, request: nil)

    #expect(waiting.state.waiting != nil)
    #expect(waiting.state.waiting?.request == .some(nil))
    #expect(answered(waiting.state, ticket: 1).send?.request == .some(nil))
    #expect(answered(waiting.state, ticket: 1).send?.ticket == 2)
  }
}
