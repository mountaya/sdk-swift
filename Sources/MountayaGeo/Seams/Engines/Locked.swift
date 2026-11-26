#if canImport(os)
  import os
#else
  import Synchronization
#endif

/// Locked is a value shared across tasks and threads, read and changed under a lock.
///
/// It is what lets a rule keep a cache it reads synchronously from any thread, which a formatter
/// cache has to be: a formatter is asked for from whatever thread a caller formats on, and a rule
/// cannot await. The lock is the platform's: an unfair lock on Apple platforms, the standard
/// library's mutex elsewhere. It is Sendable: its one state sits behind that lock. It is the
/// client's own primitive, declared again here because Geo reaches the client through its public
/// API alone.
final class Locked<State: Sendable>: Sendable {
  #if canImport(os)
    private let lock: OSAllocatedUnfairLock<State>
  #else
    private let mutex: Mutex<State>
  #endif

  init(_ state: State) {
    #if canImport(os)
      lock = OSAllocatedUnfairLock(initialState: state)
    #else
      mutex = Mutex(state)
    #endif
  }

  /// withLock runs `body` on the value under the lock and returns what it returns.
  func withLock<Result: Sendable>(_ body: @Sendable (inout State) -> Result) -> Result {
    #if canImport(os)
      lock.withLock(body)
    #else
      mutex.withLock { body(&$0) }
    #endif
  }

  /// value is the value as it is now.
  var value: State {
    withLock { $0 }
  }
}
