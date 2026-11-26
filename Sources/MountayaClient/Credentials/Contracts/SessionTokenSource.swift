/// SessionTokenSource is a source of session tokens that is read by a snapshot and tells its
/// subscribers of each change: the shape `SessionTokenEngine` has, and the one a source of the
/// application's own takes.
///
/// The snapshot is a synchronous read from any thread, since a map's request hook asks for a
/// token on a thread of its own and cannot await. A request reads it on every attempt.
public protocol SessionTokenSource: Sendable {
  /// snapshot is the source's state now: the token, its expiry, the user it names, whether a
  /// mint is on its way, and the last mint's failure.
  var snapshot: SessionSnapshot { get }

  /// subscribe returns a stream that yields the snapshot as it is now, then each one that
  /// replaces it, for as long as the stream is held.
  ///
  /// Each call returns a stream of its own, since a stream is read by one reader. A reader that
  /// has not read the last change is handed the newest.
  func subscribe() -> AsyncStream<SessionSnapshot>
}
