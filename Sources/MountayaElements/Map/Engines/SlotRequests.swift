/// SlotRequests holds the requests made of a map's slots, and answers whether one still owns its
/// slot, so a load that lands late draws nothing and a call withdrawn gives the slot back
/// (`map.slots.latest-request`).
///
/// A slot's content arrives some time after it is asked for, a specification read by id, and a
/// later request or a clear may be made meanwhile, or the call that asked withdrawn. Each request
/// holds a token no other shares, and a load draws only while its token is its slot's latest. A
/// call in Swift can always be withdrawn, its task cancelled, so a request a later call takes the
/// slot from is superseded rather than lost: it waits for that call to draw, end or give the slot
/// back, and draws as its own load answers once given it back. A request that takes its slot for
/// good, and a clear, end every such wait, each request finding as it resumes that it lost.
///
/// It draws nothing and names no renderer. It is bound to the main actor, as the engine is.
@MainActor
final class SlotRequests {
  /// Superseded is a request a later call took its slot from, waiting for that call to settle.
  private struct Superseded {
    /// slot is the slot the request was made for.
    let slot: ContentSlot
    /// token is the request's own.
    let token: Int
    /// by is the token of the call that took the slot from it.
    let by: Int
    /// waiters is every wait on the request's supersession, resumed as it ends.
    var waiters: [CheckedContinuation<Void, Never>]
  }

  /// latest is the latest request for each slot a request is out for, by its token.
  private var latest: [(slot: ContentSlot, token: Int)] = []
  /// count is the last token handed out; tokens only grow, so none is ever reused.
  private var count = 0
  /// superseded is every request waiting for the call that took its slot to settle.
  private var superseded: [Superseded] = []

  /// owns tells whether the request of `token` is still the latest for `slot`.
  func owns(_ slot: ContentSlot, token: Int) -> Bool {
    latest.first { $0.slot == slot }?.token == token
  }

  /// requestedSlots is every slot a request is out for, its content drawn or not.
  func requestedSlots() -> [ContentSlot] {
    latest.map(\.slot)
  }

  /// claim records the request of a call that can be withdrawn, and answers its token: the request
  /// the slot held, where it held one, is superseded, and waits for this one to settle.
  func claim(_ slot: ContentSlot) -> Int {
    count += 1
    if let held = latest.first(where: { $0.slot == slot }) {
      superseded.append(Superseded(slot: slot, token: held.token, by: count, waiters: []))
    }
    hand(slot, to: count)
    return count
  }

  /// take records a request that takes its slot for good, and answers its token: every request
  /// still waiting to be given the slot back loses it.
  func take(_ slot: ContentSlot) -> Int {
    count += 1
    hand(slot, to: count)
    end(superseded.filter { $0.slot == slot })
    return count
  }

  /// release ends the latest request for `slot`, as the slot is cleared for good, and every wait to
  /// be given it back.
  func release(_ slot: ContentSlot) {
    latest.removeAll { $0.slot == slot }
    end(superseded.filter { $0.slot == slot })
  }

  /// settle ends the supersessions the call of `token` made, as it drew or ended: each request it
  /// took a slot from finds, as it resumes, whether it has the slot back.
  func settle(_ token: Int) {
    end(superseded.filter { $0.by == token })
  }

  /// giveBack withdraws the call of `token`, made for `slot`, before it drew: where it still owns
  /// the slot, the slot goes back to the request it took the slot from, where that request still
  /// waits, and is asked for by none otherwise. Its own wait to be given the slot back, where a
  /// later call superseded it, ends as well.
  func giveBack(_ slot: ContentSlot, token: Int) {
    if owns(slot, token: token) {
      if let taken = superseded.first(where: { $0.by == token && $0.slot == slot }) {
        hand(slot, to: taken.token)
      } else {
        latest.removeAll { $0.slot == slot }
      }
    }
    end(superseded.filter { $0.token == token })
    settle(token)
  }

  /// regains waits, while a call that took the slot from the request of `token` has not settled,
  /// for it to settle, again where another such call takes it meanwhile, and answers whether the
  /// request owns `slot` then. A wait whose task is cancelled ends as the request is withdrawn: it
  /// is given nothing back.
  func regains(_ slot: ContentSlot, token: Int) async -> Bool {
    while !Task.isCancelled, let index = superseded.firstIndex(where: { $0.token == token }) {
      await withTaskCancellationHandler {
        await withCheckedContinuation { continuation in
          superseded[index].waiters.append(continuation)
        }
      } onCancel: {
        Task { @MainActor [weak self] in
          self?.withdraw(token)
        }
      }
    }
    return !Task.isCancelled && owns(slot, token: token)
  }

  /// withdraw ends the wait of the request of `token` to be given its slot back, as its call is
  /// withdrawn while it waits.
  private func withdraw(_ token: Int) {
    end(superseded.filter { $0.token == token })
  }

  /// hand makes the request of `token` the latest for `slot`.
  private func hand(_ slot: ContentSlot, to token: Int) {
    if let index = latest.firstIndex(where: { $0.slot == slot }) {
      latest[index].token = token
    } else {
      latest.append((slot, token))
    }
  }

  /// end ends each of `records`, resuming every wait on it.
  private func end(_ records: [Superseded]) {
    for record in records {
      superseded.removeAll { $0.token == record.token && $0.by == record.by }
      for waiter in record.waiters {
        waiter.resume()
      }
    }
  }
}
