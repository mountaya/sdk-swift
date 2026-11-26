import MountayaClient
import MountayaGeo
import Observation
import SwiftUI

/// ManualTime is time a test moves by hand, for a search engine whose pauses it measures: it
/// stands still until `advance(by:)` moves it, waking each wait due on the way at its deadline,
/// earliest first, and letting the main actor run what each wakes before moving on. Its wait runs
/// on the main actor, so a task waiting on it wakes there and nowhere else.
@MainActor
public final class ManualTime {
  private struct Waiting {
    let id: Int
    let deadline: Duration
    let continuation: CheckedContinuation<Void, any Error>
  }

  private var now: Duration = .zero
  private var nextId = 0
  private var waiting: [Waiting] = []

  /// Creates time standing at its start.
  public init() {}

  /// sleep is the wait an engine is handed: it returns once the time has moved `duration` on, and
  /// throws `CancellationError` once its task is cancelled.
  public var sleep: @MainActor @Sendable (Duration) async throws -> Void {
    { [self] duration in try await wait(duration) }
  }

  private func wait(_ duration: Duration) async throws {
    try Task.checkCancellation()
    guard duration > .zero else { return }
    let id = nextId
    nextId += 1
    let deadline = now + duration
    try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        waiting.append(Waiting(id: id, deadline: deadline, continuation: continuation))
      }
    } onCancel: {
      Task { @MainActor in self.cancel(id) }
    }
  }

  private func cancel(_ id: Int) {
    guard let index = waiting.firstIndex(where: { $0.id == id }) else { return }
    waiting.remove(at: index).continuation.resume(throwing: CancellationError())
  }

  /// advance moves the time `duration` on, waking each wait due on the way at its deadline, and
  /// letting the main actor run what it wakes before moving on.
  public func advance(by duration: Duration) async {
    await settled()
    let target = now + duration
    while let earliest = waiting.map(\.deadline).filter({ $0 <= target }).min() {
      now = max(now, earliest)
      let due = waiting.filter { $0.deadline == earliest }.sorted { $0.id < $1.id }
      waiting.removeAll { $0.deadline == earliest }
      for wait in due {
        wait.continuation.resume()
      }
      await settled()
    }
    now = max(now, target)
  }
}

/// HeldSearch is a search's transport a test drives: it records every request in the order the
/// engine sends it and holds each open until the test answers it with itineraries or zones of the
/// names it gives.
@MainActor
public final class HeldSearch {
  /// sent is every request's input, in the order sent.
  public private(set) var sent: [DataSchema.SearchInput] = []
  private var answers: [CheckedContinuation<DataSchema.SearchResult, any Error>?] = []

  /// Creates a transport that has sent nothing.
  public init() {}

  /// fetch is the transport as a search takes it.
  public var fetch: SearchFetch {
    { @MainActor input in try await self.request(input) }
  }

  private func request(_ input: DataSchema.SearchInput) async throws -> DataSchema.SearchResult {
    let index = sent.count
    sent.append(input)
    answers.append(nil)
    return try await withCheckedThrowingContinuation { continuation in
      answers[index] = continuation
    }
  }

  /// answer answers the request `index` with an itinerary or a zone of each name of `names`, as
  /// its branch asks.
  public func answer(_ index: Int, names: [String]) {
    guard answers.indices.contains(index), let answer = answers[index] else { return }
    answers[index] = nil
    let isZones = sent[index].targets.zones == true
    answer.resume(
      returning: DataSchema.SearchResult {
        if isZones {
          $0.zones = DataSchema.ZonesResult { result in
            result.zones = names.enumerated().map { index, name in
              DataSchema.ZoneSearchResult {
                $0.id = "zone-\(index)"
                $0.name = name
              }
            }
          }
        } else {
          $0.itineraries = DataSchema.ItinerariesResult { result in
            result.itineraries = names.enumerated().map { index, name in
              DataSchema.ItinerarySearchResult {
                $0.id = "itinerary-\(index)"
                $0.name = name
                $0.distance = 12_500
                $0.ascent = 1_200
              }
            }
          }
        }
      })
  }

  /// release fails every request still open, so no task waits for ever once a test ends.
  public func release() {
    for index in answers.indices {
      answers[index]?.resume(throwing: CancellationError())
      answers[index] = nil
    }
  }
}

/// Typed is the text of a search box a test holds and types into, as an app holds its own.
@MainActor
@Observable
public final class Typed {
  /// query is the box's text.
  public var query = ""

  /// Creates an empty box.
  public init() {}

  /// binding is the box's text as a view takes it.
  public var binding: Binding<String> {
    Bindable(self).query
  }
}
