/// ScriptedAnswerError is an answer a test gave a `ScriptedRouteRequest` that was answered
/// already, which is a mistake in the test: a route request is answered once, by every route
/// source.
public struct ScriptedAnswerError: Error, Sendable, CustomStringConvertible {
  /// description names the request answered twice, as a developer reads it in a test's failure.
  public let description: String

  init(description: String) {
    self.description = description
  }
}
