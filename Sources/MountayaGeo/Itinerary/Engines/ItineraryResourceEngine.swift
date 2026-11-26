import MountayaClient
import Observation

/// ItineraryResourceEngine resolves an itinerary by its id into what an element draws: the
/// geometry its profile walks, the figures the server stated, its legs and its waypoints, shown
/// all at once (`geo.data.itinerary-resource`). Its answers are its cache's, shared with every
/// engine handed that cache, so a profile and a table over one itinerary make one read between
/// them (`ItineraryResourceCache`).
///
/// It is idle with no id, and an empty id is none, since it is the id a binding holds while it
/// holds no itinerary. It is resolving, showing nothing, until the answer to its question lands,
/// then shows every projection at once, and a failure shows nothing but what its source threw. A
/// new question, another id, surface or cache, shows nothing of the one before it, since another
/// itinerary drawn under it would read as this one, and an answer to a question it no longer asks
/// never lands, a failure of one included. A question whose answer its cache holds is shown from
/// it at once, and a question asked again asks nothing. An invalidation of what it watches asks
/// again, and it shows what it showed until the new answer lands.
///
/// ```swift
/// let profile = ItineraryResourceEngine(cache: itineraries, itineraryId: "itin_abc")
/// for await resource in profile.subscribe() {
///   guard case .resolved(let itinerary) = resource else { continue }
///   chips = itinerary.legs.map(\.name)
/// }
/// ```
///
/// It asks as soon as it is handed a question, by its initializer as by
/// `configure(cache:itineraryId:surface:)`: Observation tells an engine nothing of its readers, so
/// no reader's arrival is what asks. Engines made and dropped at once, as a view's state may be
/// made again for a redraw, share the one read their cache sends for their question. It never
/// cancels a read, since an answer is shared, and holds no clock.
///
/// It is bound to the main actor, as every engine is, and `Observable`, so a SwiftUI view that
/// reads `state` is drawn again when it changes. It reports a state only where it differs from the
/// one it holds, and a closed engine is inert.
@MainActor
@Observable
public final class ItineraryResourceEngine {
  /// state is what the element shows, `ItineraryResource.idle` until it is handed an id.
  public var state: ItineraryResource { held }

  /// held is the state the engine holds, which an observer of `state` is told of.
  private var held = ItineraryResource.idle

  /// cache is the cache the itinerary is read through, which the engine watches.
  @ObservationIgnored private var cache: ItineraryResourceCache
  /// itineraryId is the id asked about, as the engine was handed it.
  @ObservationIgnored private var itineraryId: String?
  /// surface is the surface asked about, nil for the one the credential reads by default.
  @ObservationIgnored private var surface: RestSchema.ReadSurface?
  /// waiting is the ticket of the read whose answer the state waits for, nil where it waits for
  /// none.
  @ObservationIgnored private var waiting: Int?
  @ObservationIgnored private var nextTicket = 0
  @ObservationIgnored private var closed = false
  /// subscribers is every stream `subscribe()` returned that has not ended, by its number.
  @ObservationIgnored private var subscribers: [Int: AsyncStream<ItineraryResource>.Continuation] =
    [:]
  @ObservationIgnored private var nextSubscriber = 0

  /// Creates an engine that reads through `cache` and asks about the itinerary `itineraryId` names
  /// on `surface` at once, or is idle where it names none.
  ///
  /// `surface` is nil for the surface the credential reads by default, the draft for a member of
  /// its organization, and `.published` for the published snapshot.
  public init(
    cache: ItineraryResourceCache, itineraryId: String? = nil,
    surface: RestSchema.ReadSurface? = nil
  ) {
    self.cache = cache
    self.itineraryId = itineraryId
    self.surface = surface
    cache.watch(self)
    ask(keepingShown: false)
  }

  deinit {
    // An engine let go of ends its streams, so no reader waits on a state that never comes.
    for continuation in subscribers.values {
      continuation.finish()
    }
  }

  /// subscribe returns a stream that yields the state as it is now, then every state that differs
  /// from the one before it, in order, for as long as the stream is held. It ends at `close()`.
  public func subscribe() -> AsyncStream<ItineraryResource> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: ItineraryResource.self, bufferingPolicy: .unbounded)
    continuation.yield(held)
    if closed {
      continuation.finish()
      return stream
    }
    let number = nextSubscriber
    nextSubscriber += 1
    subscribers[number] = continuation
    return stream
  }

  /// configure hands the engine a question: the itinerary `itineraryId` names on `surface`, read
  /// through `cache`. It asks where the question differs from the one held, by its cache, its id
  /// or its surface, an empty id being none, and does nothing where it is the same.
  public func configure(
    cache: ItineraryResourceCache, itineraryId: String?, surface: RestSchema.ReadSurface? = nil
  ) {
    guard !closed else { return }
    let unchanged =
      cache === self.cache
      && sameText(Self.asked(self.itineraryId), Self.asked(itineraryId))
      && sameText(self.surface?.rawValue, surface?.rawValue)
    if unchanged { return }
    if cache !== self.cache {
      self.cache.unwatch(self)
      cache.watch(self)
      self.cache = cache
    }
    self.itineraryId = itineraryId
    self.surface = surface
    ask(keepingShown: false)
  }

  /// close stops the engine for good: no answer lands after it, every stream ends, its cache asks
  /// nothing more for it, and every later command does nothing. The state stays as it was.
  public func close() {
    guard !closed else { return }
    closed = true
    waiting = nil
    cache.unwatch(self)
    let ended = subscribers.values
    subscribers = [:]
    for continuation in ended {
      continuation.finish()
    }
  }

  /// landed acts on how the read the engine asked under `ticket` ended, where the state still
  /// waits for it: an answer is shown, and a failure shows nothing.
  func landed(ticket: Int, with outcome: ItineraryResourceCache.Outcome) {
    guard !closed, ticket == waiting else { return }
    waiting = nil
    switch outcome {
    case .answered(let resolved): commit(.resolved(resolved))
    case .failed(let error): commit(.failed(error))
    }
  }

  /// revalidate asks again where an invalidation of the itinerary `itineraryId` names, or of every
  /// itinerary where it is nil, dropped what the engine asks about, showing what it shows until
  /// the new answer lands.
  func revalidate(itineraryId dropped: String?) {
    guard !closed, let asked = Self.asked(itineraryId) else { return }
    if let dropped, !sameText(dropped, asked) { return }
    ask(keepingShown: true)
  }

  /// ask asks the cache the question held: idle where it names no id, shown at once where the
  /// cache holds its answer, and otherwise waited for, showing nothing, or, where `keepingShown`,
  /// what it shows. The read is waited for before the cache is asked, and nothing is shown for it
  /// where its answer landed within the asking.
  private func ask(keepingShown: Bool) {
    guard let itineraryId = Self.asked(itineraryId) else {
      waiting = nil
      commit(.idle)
      return
    }
    let ticket = nextTicket
    nextTicket += 1
    // The cache's reads land in a later turn of the main actor, but an answer landing within the
    // asking, from a read run at once, would otherwise name a ticket not yet waited for and be
    // dropped, leaving the engine resolving for good.
    waiting = ticket
    if let resolved = cache.read(itineraryId, surface: surface, for: self, ticket: ticket) {
      waiting = nil
      commit(.resolved(resolved))
      return
    }
    if waiting == ticket, !keepingShown {
      commit(.resolving)
    }
  }

  /// commit publishes a state, where it differs from the one held: to an observer of `state`, then
  /// to every stream `subscribe()` returned, in the order they were returned.
  private func commit(_ next: ItineraryResource) {
    guard !Self.isSame(held, next) else { return }
    held = next
    for key in subscribers.keys.sorted() {
      guard let continuation = subscribers[key] else { continue }
      if case .terminated = continuation.yield(next) {
        subscribers[key] = nil
      }
    }
  }

  /// asked is the id a question asks about: none for no id and for an empty one.
  private static func asked(_ itineraryId: String?) -> String? {
    guard let itineraryId, !itineraryId.isEmpty else { return nil }
    return itineraryId
  }

  /// isSame tells whether two states are one: both idle, both resolving, or both showing the same
  /// itinerary. Two failures are two states, since an error is no value to compare.
  private static func isSame(_ a: ItineraryResource, _ b: ItineraryResource) -> Bool {
    switch (a, b) {
    case (.idle, .idle), (.resolving, .resolving): return true
    case (.resolved(let shown), .resolved(let next)): return shown == next
    default: return false
    }
  }
}
