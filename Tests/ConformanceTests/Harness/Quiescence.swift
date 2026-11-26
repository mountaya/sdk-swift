/// Quiescence is how a script waits, with no clock, for what a step set going to come to rest: in
/// rounds, each letting the shared pool run what was queued there before it and then the main
/// actor run what its queue holds, until what the script observes has stood still for
/// `quietRounds` rounds in a row.
///
/// An engine bound to the main actor, its tasks and a script's seams all run on the main actor, but
/// a seam the script hands an engine as a closure of the main actor's is, to the engine, a function
/// of no actor's, so each call and each return is a hop off the main actor and back, which a loaded
/// machine can hold back while the main actor turns on (a probe measured 22 and 65 turns in 3,000
/// such calls under busy loops). A count of the main actor's turns is no wait for such a hop: a
/// loaded machine holds one back past any count, and a report rendered then reads an answered
/// request or an answered read as still loading. A round's job on the pool, of a priority no
/// engine's task is below, runs only once every job queued there before it has been taken, so a
/// round waits as long as a loaded pool makes it, a hop queued there landing first, and the state
/// a script reads stands still for three rounds only once nothing the step set going is on its
/// way. It is the harness's own and nothing a product reaches.
enum Quiescence {
  /// quietRounds is how many rounds in a row the observed state must stand still.
  static let quietRounds = 3

  /// turnsPerRound is how many turns of the main actor a round lets run after its job on the
  /// pool: each runs every job queued on the main actor before it.
  static let turnsPerRound = 16

  /// maxRounds bounds a step whose state never stands still, which is then read as it stands, so
  /// the comparison says what moved rather than the run hanging.
  static let maxRounds = 1_000

  /// settle lets what a step set going come to rest, reading `observed` after each round.
  @MainActor
  static func settle<Observed: Equatable>(observing observed: () -> Observed) async {
    var last = observed()
    var quiet = 0
    var rounds = 0
    while quiet < quietRounds, rounds < maxRounds {
      await poolTurn()
      for _ in 0..<turnsPerRound {
        await Task.yield()
      }
      rounds += 1
      let now = observed()
      if now == last {
        quiet += 1
      } else {
        last = now
        quiet = 0
      }
    }
  }

  /// poolTurn returns once a job of low priority, queued on the shared pool now, has run. It is
  /// waited for through a continuation rather than its task's value, which would raise its
  /// priority to the waiter's and let it run ahead of what was queued before it.
  @MainActor
  private static func poolTurn() async {
    await withCheckedContinuation { (ran: CheckedContinuation<Void, Never>) in
      Task.detached(priority: .low) {
        ran.resume()
      }
    }
  }
}
