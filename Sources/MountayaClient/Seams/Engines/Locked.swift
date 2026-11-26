#if canImport(os)
  import os
#else
  import Synchronization
#endif

/// Locked is a value shared across tasks and threads, read and changed under a lock.
///
/// It is what lets a value be read synchronously from any thread, which a session token's
/// snapshot has to be: a map's request hook asks for one on a thread of its own and cannot
/// await. The lock is the platform's: an unfair lock on Apple platforms, the standard library's
/// mutex elsewhere. It is Sendable: its one state sits behind that lock.
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
