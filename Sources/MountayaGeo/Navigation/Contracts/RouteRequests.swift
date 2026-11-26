/// RouteRequests is what a navigation holds of its route requests
/// (`geo.navigation.route-request`): the ticket of the one in flight, how many it has sent, and the
/// one waiting behind it.
///
/// A request leaves under a ticket, the count of requests sent with it, so an answer names the
/// request it answers by the ticket it left under. Internal, as the rule over it is: a consumer
/// observes which route an engine follows, never its tickets.
struct RouteRequests<Request> {
  /// Waiting is a request waiting to be sent, held as it was made, so a request that is itself
  /// an optional's `nil` is still one.
  struct Waiting {
    /// request is the request, as it was made.
    let request: Request
  }

  /// Event is what happens to a navigation's route requests.
  enum Event {
    /// made is a request made.
    case made(Request)
    /// answered is the request sent under `ticket` answering, with a route or a failure alike.
    case answered(ticket: Int)
    /// cancelled is everything abandoned: the request waiting, and the one in flight.
    case cancelled
  }

  /// Send is a request to send now, and the ticket it leaves under.
  struct Send {
    /// request is the request, as it was made.
    let request: Request
    /// ticket is the ticket it leaves under, which its answer names.
    let ticket: Int
  }

  /// Outcome is what an event leaves: the requests held, the one to send now, and whether the
  /// answer it carries is acted on.
  struct Outcome {
    /// state is the requests held after the event.
    let state: RouteRequests
    /// send is the request to send now, or nil where none leaves.
    let send: Send?
    /// deliver is whether the answer the event carries is acted on. Only an answer is ever
    /// delivered.
    let deliver: Bool
  }

  /// inFlight is the ticket of the request in flight, or nil where none is.
  let inFlight: Int?
  /// sent is how many requests have been sent, which is the ticket the last one left under.
  let sent: Int
  /// waiting is the request waiting for the one in flight to answer, or nil where none waits.
  let waiting: Waiting?

  /// atRest is a navigation that has sent nothing and holds nothing waiting.
  static var atRest: RouteRequests { RouteRequests(inFlight: nil, sent: 0, waiting: nil) }
}

extension RouteRequests: Sendable where Request: Sendable {}
extension RouteRequests.Waiting: Sendable where Request: Sendable {}
extension RouteRequests.Event: Sendable where Request: Sendable {}
extension RouteRequests.Send: Sendable where Request: Sendable {}
extension RouteRequests.Outcome: Sendable where Request: Sendable {}
