/// routeRequestsAfter answers what an event leaves of a navigation's route requests: the requests
/// held, the one to send now, and whether the answer the event carries is acted on
/// (`geo.navigation.route-request`).
///
/// At most one request is in flight. A request is sent at once where none is, and otherwise
/// waits, in the place of any already waiting, so only the newest waits: dropping it instead would
/// lose the newest destination a traveller asked for. An answer to the request in flight is acted
/// on where nothing waits; where a request waits, the answer is to a question already replaced, so
/// it is dropped and the waiting request is sent in its place. An answer to any other ticket, one
/// a cancel abandoned, is dropped. A cancel drops the waiting request and abandons the one in
/// flight, so the next request is sent at once.
///
/// Stated as a pure transition over a value, so the engine that sends the requests holds one
/// field and decides nothing of this itself.
func routeRequestsAfter<Request>(
  _ state: RouteRequests<Request>, on event: RouteRequests<Request>.Event
) -> RouteRequests<Request>.Outcome {
  switch event {
  case .made(let request):
    guard let inFlight = state.inFlight else { return sending(state, request: request) }
    return RouteRequests.Outcome(
      state: RouteRequests(
        inFlight: inFlight, sent: state.sent, waiting: RouteRequests.Waiting(request: request)),
      send: nil, deliver: false)
  case .answered(let ticket):
    guard ticket == state.inFlight else {
      return RouteRequests.Outcome(state: state, send: nil, deliver: false)
    }
    guard let waiting = state.waiting else {
      return RouteRequests.Outcome(
        state: RouteRequests(inFlight: nil, sent: state.sent, waiting: nil), send: nil,
        deliver: true)
    }
    return sending(state, request: waiting.request)
  case .cancelled:
    return RouteRequests.Outcome(
      state: RouteRequests(inFlight: nil, sent: state.sent, waiting: nil), send: nil,
      deliver: false)
  }
}

/// sending sends a request under the next ticket, with nothing left waiting.
private func sending<Request>(_ state: RouteRequests<Request>, request: Request)
  -> RouteRequests<Request>.Outcome
{
  let ticket = state.sent + 1
  return RouteRequests.Outcome(
    state: RouteRequests(inFlight: ticket, sent: ticket, waiting: nil),
    send: RouteRequests.Send(request: request, ticket: ticket), deliver: false)
}
