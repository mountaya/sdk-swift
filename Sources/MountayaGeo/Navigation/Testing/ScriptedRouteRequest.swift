/// ScriptedRouteRequest is one route request a `ScriptedNavigationEngine` sent: the `request` the
/// app made, and how the test answers it, once, with `answer(_:)` or `fail(_:)`.
///
/// An answer to a request the engine abandoned, by a stop or a close, or to one a later request
/// replaced while it was in flight, is dropped, as an answer to such a request is by every engine.
/// It is bound to the main actor, as its engine is.
@MainActor
public final class ScriptedRouteRequest<Request: Sendable> {
  /// request is what the app asked a route for, as it made the request.
  public let request: Request
  /// isAbandoned is whether a stop or a close abandoned the request, so its answer is dropped.
  public private(set) var isAbandoned = false
  /// isAnswered is whether the test answered the request, with a route or a failure.
  public private(set) var isAnswered = false

  private let deliver: (RouteFollowingEngine<Request>.Answer) -> Void

  init(request: Request, deliver: @escaping (RouteFollowingEngine<Request>.Answer) -> Void) {
    self.request = request
    self.deliver = deliver
  }

  /// answer answers the request with `route`, as a route source answers one.
  ///
  /// It throws a `ScriptedAnswerError` where the request was answered already, and delivers
  /// nothing then: a request is answered once.
  public func answer(_ route: NavigationRoute) throws(ScriptedAnswerError) {
    try settle(.route(route))
  }

  /// fail answers the request with a failure, as a route source throws `cause`.
  ///
  /// It throws a `ScriptedAnswerError` where the request was answered already, and delivers
  /// nothing then: a request is answered once.
  public func fail(_ cause: any Error) throws(ScriptedAnswerError) {
    try settle(.failure(cause))
  }

  /// abandon marks the request abandoned by a stop or a close.
  func abandon() {
    isAbandoned = true
  }

  private func settle(_ answer: RouteFollowingEngine<Request>.Answer) throws(ScriptedAnswerError) {
    guard !isAnswered else {
      throw ScriptedAnswerError(
        description:
          "ScriptedRouteRequest: the request for \(request) was answered already; answer each once."
      )
    }
    isAnswered = true
    deliver(answer)
  }
}
