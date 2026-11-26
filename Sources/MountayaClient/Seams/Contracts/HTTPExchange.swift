/// HTTPExchange is the seam every request leaves the client through: one attempt sent, and its
/// answer read as it arrives.
///
/// The client decides everything around an attempt itself: which headers it carries, how long it
/// may take, whether it is repeated and what its answer means. A conformance only moves bytes,
/// which is what lets a test put a scripted one here and run the client without a network, and a
/// consumer wrap `SystemExchange`, the platform's, to watch every attempt go by.
public protocol HTTPExchange: Sendable {
  /// send sends one attempt and returns its answer once the status and the headers have
  /// arrived, the body following as it is read.
  ///
  /// It throws for a request that never arrived, which the client reads as a dropped
  /// connection, and `CancellationError` once the calling task is cancelled. It never follows a
  /// redirect, keeps no cookie, and sends no header that changes what the answer says beyond the
  /// ones it was given.
  func send(_ request: ExchangeRequest) async throws -> ExchangeResponse
}
