import MountayaClient

@testable import MountayaGeo

/// HeldSearch is a search's transport a test drives: it records every request in the order the
/// engine sends it, holds each open until the test answers, fails or reports it, and records each
/// request the engine abandoned while it was still open. It is bound to the main actor, where the
/// engine sends, so the requests are numbered in the order they leave.
@MainActor
final class HeldSearch {
  /// Failed is what a request the test fails throws.
  struct Failed: Error {}

  /// sent is every request's input, in the order sent.
  private(set) var sent: [DataSchema.SearchInput] = []
  /// cancelled is every request the engine abandoned while no answer had settled it.
  private(set) var cancelled: Set<Int> = []
  private var answers: [CheckedContinuation<DataSchema.SearchResult, any Error>?] = []
  private var done: Set<Int> = []

  /// fetch is the transport as a search takes it.
  var fetch: SearchFetch {
    { @MainActor input in try await self.request(input) }
  }

  /// branches is the branch each request asked, in the order sent.
  var branches: [DataSchema.SearchTarget] {
    sent.map(Self.branch)
  }

  private func request(_ input: DataSchema.SearchInput) async throws -> DataSchema.SearchResult {
    let index = sent.count
    sent.append(input)
    answers.append(nil)
    return try await withTaskCancellationHandler {
      try await withCheckedThrowingContinuation { continuation in
        answers[index] = continuation
      }
    } onCancel: {
      Task { @MainActor in
        if !self.done.contains(index) { self.cancelled.insert(index) }
      }
    }
  }

  /// answer answers the request `index` with one result per name of `names` for its branch.
  func answer(_ index: Int, names: [String]) {
    settle(index) { $0.resume(returning: Self.result(Self.branch(sent[index]), names: names)) }
  }

  /// report answers the request `index` with the Data API reporting its branch failed.
  func report(_ index: Int, message: String? = "unreachable") {
    let branch = Self.branch(sent[index])
    settle(index) {
      $0.resume(
        returning: DataSchema.SearchResult {
          $0.errors = [
            DataSchema.SearchTargetError {
              $0.target = branch
              $0.code = .badGateway
              $0.message = message
            }
          ]
        })
    }
  }

  /// fail fails the request `index`.
  func fail(_ index: Int) {
    settle(index) { $0.resume(throwing: Failed()) }
  }

  /// release fails every request still open, so no task waits for ever once a test ends.
  func release() {
    for index in answers.indices {
      answers[index]?.resume(throwing: CancellationError())
      answers[index] = nil
    }
  }

  private func settle(
    _ index: Int, resolve: (CheckedContinuation<DataSchema.SearchResult, any Error>) -> Void
  ) {
    guard answers.indices.contains(index), let answer = answers[index] else { return }
    answers[index] = nil
    done.insert(index)
    resolve(answer)
  }

  /// branch is the one branch `input` enables.
  nonisolated static func branch(_ input: DataSchema.SearchInput) -> DataSchema.SearchTarget {
    let targets = input.targets
    let flags: [(Bool?, DataSchema.SearchTarget)] = [
      (targets.places, .places), (targets.pois, .pois), (targets.ways, .ways),
      (targets.itineraries, .itineraries), (targets.collections, .collections),
      (targets.zones, .zones),
    ]
    return flags.first { $0.0 == true }?.1 ?? DataSchema.SearchTarget(rawValue: "NONE")
  }

  /// result is the Data API's answer for `branch`: one result per name, each titled by its name.
  nonisolated static func result(_ branch: DataSchema.SearchTarget, names: [String])
    -> DataSchema.SearchResult
  {
    let named = Array(names.enumerated())
    return DataSchema.SearchResult {
      switch branch.rawValue {
      case "PLACES":
        $0.places = DataSchema.GeocodeResult { result in
          result.places = named.map { index, name in
            SearchEntities.place(name: name, point: [6.87, 45.92 + Double(index) / 100])
          }
        }
      case "POIS":
        $0.pois = DataSchema.PoisResult { result in
          result.pois = named.map { _, name in SearchEntities.poi(name: name) }
        }
      case "WAYS":
        $0.ways = DataSchema.WaysResult { result in
          result.ways = named.map { _, name in SearchEntities.way(name: name) }
        }
      case "ITINERARIES":
        $0.itineraries = DataSchema.ItinerariesResult { result in
          result.itineraries = named.map { index, name in
            DataSchema.ItinerarySearchResult {
              $0.id = "itinerary-\(index)"
              $0.name = name
            }
          }
        }
      case "COLLECTIONS":
        $0.collections = DataSchema.CollectionsResult { result in
          result.collections = named.map { index, name in
            DataSchema.CollectionSearchResult {
              $0.id = "collection-\(index)"
              $0.name = name
            }
          }
        }
      case "ZONES":
        $0.zones = DataSchema.ZonesResult { result in
          result.zones = named.map { index, name in
            DataSchema.ZoneSearchResult {
              $0.id = "zone-\(index)"
              $0.name = name
            }
          }
        }
      default:
        break
      }
    }
  }
}

/// settledSearch lets every task the main actor holds run, enough turns of it for a round's
/// requests, their answers and a broadened round's requests to land.
@MainActor
func settledSearch() async {
  for _ in 0..<16 {
    await Task.yield()
  }
}

/// shown reads a snapshot as `query|searching|settled|fellBack|section:state[rows],...`, each
/// state's first letter, so a test states what a list shows in one line.
func shown(_ snapshot: SearchSnapshot) -> String {
  let sections = snapshot.sections.map { section in
    let state: String
    switch section.state {
    case .loading: state = "l"
    case .settled: state = "s"
    case .failed: state = "e"
    }
    let rows =
      section.rows.isEmpty ? "" : "[" + section.rows.map(\.title).joined(separator: ",") + "]"
    return "\(section.id.rawValue.lowercased()):\(state)\(rows)"
  }
  return [
    snapshot.query, snapshot.isSearching ? "searching" : "idle",
    snapshot.isSettled ? "settled" : "-", snapshot.hasFallenBack ? "fell-back" : "-",
    sections.joined(separator: ","),
  ].joined(separator: "|")
}
