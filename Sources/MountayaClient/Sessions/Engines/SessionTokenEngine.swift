import Foundation

/// SessionTokenEngine keeps a session token fresh: it mints one through the application's own
/// endpoint, and mints the next before the token expires, never after a 401.
///
/// It never mints by itself: minting exchanges a secret key, which belongs on a server, so the
/// engine is given `mint`, a function calling the application's endpoint, which answers what
/// `postSession` answers: the token, its expiry and the user it was minted for.
///
/// It is read by a snapshot, a synchronous read from any thread, and by `subscribe`, a stream of
/// its own per reader. The subscriptions are its lifecycle: it mints only while one is held, and
/// the last one ending parks it, so a credential nothing reads costs no call. A `Mountaya` whose
/// credential carries it holds one for as long as it lives.
///
/// It is `Sendable` without an actor: its one stored state sits behind the platform's lock,
/// since a map's request hook reads the snapshot on a thread of its own and cannot await, which
/// an actor's isolation would ask of it.
public final class SessionTokenEngine: SessionTokenSource {
  /// Mint calls the application's own endpoint and returns the session it minted.
  public typealias Mint = @Sendable () async throws -> RestSchema.Session

  private struct State: Sendable {
    var snapshot = SessionSnapshot()
    var mint: Mint
    var subscribers: [Int: AsyncStream<SessionSnapshot>.Continuation] = [:]
    var nextSubscriber = 0
    var isEnabled = true
    var loop: Task<Void, Never>?
    /// generation moves whenever the loop is replaced, so a mint that lands after its loop was
    /// cancelled changes nothing.
    var generation = 0
  }

  private let state: Locked<State>
  private let wallClock: any WallClock
  private let sleeper: any Sleeper

  /// Creates an engine that mints through `mint`, from the first subscription on.
  ///
  /// The last two are seams, each the platform's where none is given, as a client's are:
  /// `clock` is what every wait toward the next mint is measured on, and `wallClock` is what
  /// the instant a token arrives at and the one its expiry leaves are read from, so a test pins
  /// both and holds the schedule to them.
  public convenience init(
    mint: @escaping Mint, clock: (any Clock<Duration>)? = nil, wallClock: (any WallClock)? = nil
  ) {
    self.init(
      mint: mint,
      wallClock: wallClock ?? SystemWallClock(),
      sleeper: clock.map { ClockSleeper(clock: $0) } ?? TaskSleeper()
    )
  }

  init(mint: @escaping Mint, wallClock: any WallClock, sleeper: any Sleeper) {
    self.state = Locked(State(mint: mint))
    self.wallClock = wallClock
    self.sleeper = sleeper
  }

  deinit {
    state.withLock { state in
      state.loop?.cancel()
      for continuation in state.subscribers.values {
        continuation.finish()
      }
    }
  }

  /// snapshot is the engine's state now: the token, its expiry, the user it names, whether a
  /// mint is on its way, and the last mint's failure.
  public var snapshot: SessionSnapshot {
    state.withLock { $0.snapshot }
  }

  /// mint is the function the engine mints through. Replacing it does not mint: a view that
  /// builds a new closure on every render would otherwise call the endpoint on every render.
  public var mint: Mint {
    get { state.withLock { $0.mint } }
    set { state.withLock { $0.mint = newValue } }
  }

  /// subscribe returns a stream that yields the snapshot as it is now, then each one that
  /// replaces it, for as long as the stream is held. A reader that has not read the last change
  /// is handed the newest.
  public func subscribe() -> AsyncStream<SessionSnapshot> {
    AsyncStream(bufferingPolicy: .bufferingNewest(1)) { continuation in
      let id = state.withLock { state -> Int in
        let id = state.nextSubscriber
        state.nextSubscriber += 1
        state.subscribers[id] = continuation
        continuation.yield(state.snapshot)
        return id
      }
      continuation.onTermination = { [weak self] _ in
        self?.unsubscribe(id)
      }
      start(mintingAtOnce: false)
    }
  }

  /// refresh mints a token now, whatever the schedule says, such as after the application's
  /// user signed in. It mints only while a subscription is held.
  public func refresh() {
    state.withLock { state in
      state.loop?.cancel()
      state.loop = nil
    }
    start(mintingAtOnce: true)
  }

  /// disable stops minting and clears the token, its expiry, its user and the last error, so a
  /// signed-out user's credential cannot be read off the snapshot.
  public func disable() {
    state.withLock { state in
      state.isEnabled = false
      state.loop?.cancel()
      state.loop = nil
      state.generation += 1
      state.snapshot = SessionSnapshot()
      Self.publish(state)
    }
  }

  /// enable lets the engine mint again after `disable`, from the next subscription on or at
  /// once where one is held.
  public func enable() {
    state.withLock { $0.isEnabled = true }
    start(mintingAtOnce: false)
  }

  private func unsubscribe(_ id: Int) {
    state.withLock { state in
      state.subscribers[id] = nil
      if state.subscribers.isEmpty {
        state.loop?.cancel()
        state.loop = nil
        state.generation += 1
      }
    }
  }

  /// start runs the loop where it is enabled, subscribed to and not already running.
  private func start(mintingAtOnce: Bool) {
    state.withLock { state in
      guard state.isEnabled, !state.subscribers.isEmpty, state.loop == nil else { return }
      state.generation += 1
      let generation = state.generation
      state.loop = Task { [weak self] in
        await self?.run(generation: generation, mintingAtOnce: mintingAtOnce)
      }
    }
  }

  /// run mints, then walks the wait down to the next mint in hops that re-read the wall clock,
  /// for as long as the loop is not cancelled.
  private func run(generation: Int, mintingAtOnce: Bool) async {
    var spent = 0
    var deadline: Date?
    if !mintingAtOnce {
      let held = snapshot
      if held.token != nil, let expiresAt = held.expiresAt {
        deadline = schedule(expiresAt: expiresAt, spent: &spent)
      }
    }
    while !Task.isCancelled {
      if let deadline {
        while let hop = RefreshSchedule.hop(toward: deadline, now: wallClock.now) {
          do {
            try await sleeper.sleep(for: hop)
          } catch {
            return
          }
        }
      }
      guard
        let mint = update(
          generation,
          change: { state in
            state.snapshot = SessionSnapshot(
              token: state.snapshot.token,
              expiresAt: state.snapshot.expiresAt,
              userId: state.snapshot.userId,
              isMinting: true,
              error: nil
            )
            return state.mint
          })
      else {
        return
      }
      do {
        let session = try await mint()
        guard !Task.isCancelled else { return }
        _ = update(generation) { state in
          state.snapshot = SessionSnapshot(
            token: session.token,
            expiresAt: session.expires_at,
            userId: session.user_id
          )
        }
        deadline = schedule(expiresAt: session.expires_at, spent: &spent)
      } catch {
        // The loop's own cancellation, a refresh, a disable, the last subscription ending or the
        // engine let go, ends the run as it stands, the next run's state its own.
        guard !Task.isCancelled else { return }
        if Self.isCancellation(error) {
          // A mint the application cancelled is never minted again on a schedule (`sdk/SPEC.md`
          // §6): it ends the run as the last error, with nothing minting, so a request awaiting a
          // first token goes on at once and one that requires a session is refused with it as the
          // cause. A refresh, an enable or the next subscription starts the next mint.
          _ = update(generation) { state in
            state.snapshot = SessionSnapshot(
              token: state.snapshot.token,
              expiresAt: state.snapshot.expiresAt,
              userId: state.snapshot.userId,
              isMinting: false,
              error: error
            )
            state.loop = nil
          }
          return
        }
        // Every other ending is a failed mint, a timeout the application set on its own call
        // among them, and is minted again on the schedule of a run of spent tokens.
        _ = update(generation) { state in
          state.snapshot = SessionSnapshot(
            token: state.snapshot.token,
            expiresAt: state.snapshot.expiresAt,
            userId: state.snapshot.userId,
            isMinting: false,
            error: error
          )
        }
        spent += 1
        deadline = wallClock.now.addingTimeInterval(
          seconds(RefreshSchedule.plan(consecutiveSpent: spent).delay))
      }
    }
  }

  /// isCancellation is true where a mint ended because the application cancelled it: Swift's
  /// `CancellationError`, or the platform loader's report of a task cancelled, as the client's own
  /// exchange reads one. A timeout is no cancellation, whatever error it arrives as: one the
  /// platform's loader raises is `URLError.timedOut`, and one the application writes is its own.
  static func isCancellation(_ error: any Error) -> Bool {
    SystemExchange.reading(error) is CancellationError
  }

  /// schedule returns when a token expiring at `expiresAt` is minted again, counting it toward
  /// the run of spent tokens where it arrived already spent.
  private func schedule(expiresAt: Date, spent: inout Int) -> Date {
    let now = wallClock.now
    var plan = RefreshSchedule.plan(lifetime: .seconds(expiresAt.timeIntervalSince(now)))
    if plan.isArmed {
      spent = 0
    } else {
      spent += 1
      plan = RefreshSchedule.plan(consecutiveSpent: spent)
    }
    return now.addingTimeInterval(seconds(plan.delay))
  }

  /// update changes the state where `generation` is still the loop's, tells every subscriber,
  /// and returns what `change` returns, or nil where the loop was replaced.
  private func update<Result: Sendable>(
    _ generation: Int,
    change: @escaping @Sendable (inout State) -> Result
  ) -> Result? {
    state.withLock { state -> Result? in
      guard state.generation == generation else { return nil }
      let result = change(&state)
      Self.publish(state)
      return result
    }
  }

  private static func publish(_ state: State) {
    for continuation in state.subscribers.values {
      continuation.yield(state.snapshot)
    }
  }

  private func seconds(_ duration: Duration) -> TimeInterval {
    let (seconds, attoseconds) = duration.components
    return TimeInterval(seconds) + TimeInterval(attoseconds) / 1e18
  }
}
