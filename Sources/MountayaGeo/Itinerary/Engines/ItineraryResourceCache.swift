import MountayaClient

/// ItineraryResourceCache is the answers about itineraries that the elements reading through one
/// client share: one read for every element asking about one itinerary on one surface, whatever
/// their number (`geo.data.itinerary-cache`).
///
/// An app makes one per client, over that client's `ItinerarySource`, and hands it to every
/// `ItineraryResourceEngine` that reads through the client. Answers are shared by cache, itinerary
/// and surface, so two clients, whose credentials may see two itineraries under one id, never
/// share one. A Swift function has no identity to key answers by, so the cache an app makes is
/// what holds its client's answers, and they go with it.
///
/// ```swift
/// let itineraries = ItineraryResourceCache { id, surface in
///   try await client.studio.itineraries.getItinerary(
///     itinerary_id: id, query: .init { $0.surface = surface }
///   ).data
/// }
/// let profile = ItineraryResourceEngine(cache: itineraries, itineraryId: "itin_abc")
/// // Once the app has saved the itinerary, every element over it reads it again.
/// itineraries.invalidate(itineraryId: "itin_abc")
/// ```
///
/// An element asking a question already asked joins its read, or is shown its answer, and asks
/// nothing. The `capacity` answers read most recently are kept, a read in flight among them, the
/// one read least recently dropped past it, and a read dropped while in flight still lands for the
/// elements waiting on it. A failure is dropped at once, so the next question asks again, and
/// `invalidate(itineraryId:)` drops answers the app knows are stale and asks again for every
/// element watching one, each showing what it showed until the new answer lands.
///
/// It is bound to the main actor, as the engines it serves are, and holds no lock: each read is
/// asked in a task of its own, and its answer lands in the main actor's turn after its source
/// answers. No read is cancelled while the cache stands, since an answer is shared and an element
/// that stopped waiting for one would cancel it for every element still waiting; a cache let go of
/// cancels its reads in flight, whose answers nobody can receive.
@MainActor
public final class ItineraryResourceCache {
  /// capacity is how many answers a cache keeps: the itineraries it read most recently, each on
  /// one surface, a read in flight counted.
  public nonisolated static let capacity = 16

  /// Outcome is how a read ended: the itinerary's projections, or what its source threw.
  enum Outcome {
    /// answered is a read whose source answered, projected once for every engine it lands for.
    case answered(ResolvedItinerary)
    /// failed is a read whose source threw.
    case failed(any Error)
  }

  /// Key is one answer within a cache: an itinerary on one surface, the id and the surface's word
  /// each compared scalar for scalar.
  private struct Key: Hashable {
    let itineraryId: String
    let surface: RestSchema.ReadSurface?

    static func == (lhs: Key, rhs: Key) -> Bool {
      sameText(lhs.itineraryId, rhs.itineraryId)
        && sameText(lhs.surface?.rawValue, rhs.surface?.rawValue)
    }

    func hash(into hasher: inout Hasher) {
      hasher.combine(itineraryId)
      hasher.combine(surface?.rawValue)
    }
  }

  /// Entry is what a cache holds for one key: a read in flight, by its number, or its answer.
  private enum Entry {
    case reading(Int)
    case answered(ResolvedItinerary)
  }

  /// Waiter is an engine waiting on a read's answer, held weakly, and the ticket it asked under.
  private struct Waiter {
    weak var engine: ItineraryResourceEngine?
    let ticket: Int
  }

  /// Flight is one read in flight: the key it reads, and every engine waiting on its answer.
  private struct Flight {
    let key: Key
    var waiting: [Waiter]
  }

  /// Watcher is an engine watching one of the cache's answers, held weakly, so an engine let go of
  /// is told nothing.
  private struct Watcher {
    weak var engine: ItineraryResourceEngine?
  }

  private let source: ItinerarySource
  private var entries: [Key: Entry] = [:]
  /// recency is every key the cache holds, the one read least recently first.
  private var recency: [Key] = []
  /// flights is every read in flight, by its number, whether or not the cache still keeps it.
  private var flights: [Int: Flight] = [:]
  /// tasks is the task asking the source for each read in flight, by its number.
  private var tasks: [Int: Task<Void, Never>] = [:]
  private var nextFlight = 0
  /// watchers is every engine watching an answer of the cache, in the order each began to.
  private var watchers: [Watcher] = []

  /// Creates a cache holding no answer, which reads each itinerary it is asked about through
  /// `source`.
  public init(source: @escaping ItinerarySource) {
    self.source = source
  }

  deinit {
    // A cache let go of cancels the reads it has in flight, whose answers nobody can receive.
    for task in tasks.values {
      task.cancel()
    }
  }

  /// invalidate drops what the cache holds of the itinerary `itineraryId` names, on every surface,
  /// or every answer it holds where `itineraryId` is nil, and asks again for every engine watching
  /// what it dropped, in the order each began to watch, each showing what it showed until the new
  /// answer lands. The engines over one itinerary on one surface make one read between them.
  ///
  /// An app calls it once it has changed an itinerary (a save, a publish), so every element over it
  /// shows the itinerary as it now stands. A read in flight it drops still lands for the engines
  /// waiting on it, and is not kept.
  public func invalidate(itineraryId: String? = nil) {
    if let itineraryId {
      entries = entries.filter { !sameText($0.key.itineraryId, itineraryId) }
      recency.removeAll { sameText($0.itineraryId, itineraryId) }
    } else {
      entries = [:]
      recency = []
    }
    watchers.removeAll { $0.engine == nil }
    for watcher in watchers {
      watcher.engine?.revalidate(itineraryId: itineraryId)
    }
  }

  /// read answers a question from the cache: the answer where it holds one, which is then the
  /// answer read most recently, and nil where `engine` is to wait, under `ticket`, for a read it
  /// joins or one sent for it now.
  func read(
    _ itineraryId: String, surface: RestSchema.ReadSurface?, for engine: ItineraryResourceEngine,
    ticket: Int
  ) -> ResolvedItinerary? {
    let key = Key(itineraryId: itineraryId, surface: surface)
    let waiter = Waiter(engine: engine, ticket: ticket)
    if let entry = entries[key] {
      // Read again, so it moves to the most recent end.
      recency.removeAll { $0 == key }
      recency.append(key)
      switch entry {
      case .answered(let resolved):
        return resolved
      case .reading(let number):
        flights[number]?.waiting.append(waiter)
        return nil
      }
    }
    let number = nextFlight
    nextFlight += 1
    flights[number] = Flight(key: key, waiting: [waiter])
    entries[key] = .reading(number)
    recency.append(key)
    while recency.count > Self.capacity {
      entries[recency.removeFirst()] = nil
    }
    let source = self.source
    tasks[number] = Task { [weak self] in
      let outcome: Outcome
      do {
        let itinerary = try await source(itineraryId, surface)
        outcome = .answered(ResolvedItinerary(itinerary))
      } catch {
        outcome = .failed(error)
      }
      self?.land(number, with: outcome)
    }
    return nil
  }

  /// watch has the cache ask again for `engine` when an invalidation drops what it watches.
  func watch(_ engine: ItineraryResourceEngine) {
    watchers.removeAll { $0.engine == nil }
    guard !watchers.contains(where: { $0.engine === engine }) else { return }
    watchers.append(Watcher(engine: engine))
  }

  /// unwatch has the cache ask nothing more for `engine`.
  func unwatch(_ engine: ItineraryResourceEngine) {
    watchers.removeAll { $0.engine == nil || $0.engine === engine }
  }

  /// land keeps a read's answer where the cache still holds the read, drops its failure at once,
  /// and tells every engine waiting on it, each under the ticket it asked with.
  private func land(_ number: Int, with outcome: Outcome) {
    tasks[number] = nil
    guard let flight = flights.removeValue(forKey: number) else { return }
    // An invalidation or the bound may have dropped the read, and a later read replaced it: the
    // entry is then another's, and is left as it is.
    if case .reading(number)? = entries[flight.key] {
      switch outcome {
      case .answered(let resolved):
        entries[flight.key] = .answered(resolved)
      case .failed:
        entries[flight.key] = nil
        recency.removeAll { $0 == flight.key }
      }
    }
    for waiter in flight.waiting {
      waiter.engine?.landed(ticket: waiter.ticket, with: outcome)
    }
  }
}
