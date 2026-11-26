import MountayaClient
import Observation

/// searchTypingPause is how long a query goes unchanged before a search asks a round for it, unless
/// the search is given another pause (`geo.search.typing-pause`).
public let searchTypingPause: Duration = .milliseconds(150)

/// searchViewportRefreshPause is how long a camera rests before a search confined to the visible
/// area asks its round again, a pause that folds a gesture's moves into one round
/// (`geo.search.viewport-refresh`).
public let searchViewportRefreshPause: Duration = .milliseconds(350)

/// SearchEngine is the whole of a search over the Data API: the typing pause, a request per
/// branch, the abandon of a round a later one replaced, the fall back from the visible area, the
/// refresh as the camera rests, and what a result list shows, which a view draws or a consumer with
/// their own list reads as `state`.
///
/// - **A round waits for the typing to pause** (`geo.search.typing-pause`). `setQuery(_:)` states
///   what the reader typed, and a round is asked once it has gone unchanged for the pause, 150 ms
///   unless the engine is given another, a `SearchPause`, which no pause below zero is; a query the
///   engine starts with owes none, being text typed before it existed. Until a round answers the
///   query in the box, `state` is the skeleton of the round it is owed, never rows answering another
///   query.
/// - **One request per branch, sections in one order** (`geo.search.section-order`). A round asks
///   one request per branch of its configuration's targets, each enabling its branch alone under
///   the round's cap, and every section renders in the targets' order whatever order the answers
///   land in.
/// - **Only the latest round writes** (`geo.search.live-round`). A new query, a change of the
///   confinement, the language, the cap, the branches, whether there is a transport, or the
///   language or the length system of the wording's units, and a `retry()`, each start a fresh
///   round that abandons the one in flight, whose requests are cancelled and whose answers and
///   failures land nowhere; each branch of the live round fills its own section as it answers, a
///   failed branch its own alone.
/// - **A confined round broadens once** (`geo.search.broaden`). A round confined to the visible
///   area whose every branch settled empty, with none failed, asks once more everywhere and says it
///   fell back, never twice and never after a pan, and a round counts as settled only once the last
///   round it asks has answered.
/// - **A rest of the camera asks again** (`geo.search.viewport-refresh`). While the list is open,
///   the round confined and a query held, a camera stated through `setCamera(_:)` asks the round
///   again once it has rested 350 ms, the moves of one gesture folding into one round, which
///   replaces the rows in place with no section loading and never broadens.
///
/// A round is ranked around the camera's centre and confined to the box around it where it is
/// confined (`geo.search.focus`, `geo.search.viewport-bounds`), and starts unconfined, a default the
/// caller changes by `setConfined(_:)`, as `SearchControl` starts confined.
///
/// ```swift
/// let search = SearchEngine(
///   configuration: SearchConfiguration(fetch: { try await mountaya.data.search(input: $0) }))
/// search.setQuery("chamonix")
/// ```
///
/// It asks as soon as it holds a question, a query the initializer is handed included, since
/// Observation tells an engine nothing of its readers; one with no transport is inert and shows
/// every section settled with nothing. It waits out its pauses through `sleep`, `Task.sleep`
/// unless a test hands a wait of its own. It is bound to the main actor, as every engine is, and
/// `Observable`, so a SwiftUI view that reads `state` is drawn again when it changes. A closed
/// engine is inert, its state left as it stood.
@MainActor
@Observable
public final class SearchEngine {
  /// state is what a result list shows for the query in the box: the engine's answer where it
  /// answers that query, trimmed, and otherwise the skeleton of the round the query is owed, or
  /// every section settled with nothing where it owes none.
  public var state: SearchSnapshot {
    shownSearchSnapshot(
      answered, query: query,
      unanswered: unansweredSearchSnapshot(
        query, isLive: configuration.fetch != nil, targets: branches))
  }

  /// query is the query in the box, as the reader typed it.
  public private(set) var query: String
  /// isOpen is whether the result list is being looked at, which alone lets a rest of the camera
  /// ask a round again.
  public private(set) var isOpen: Bool
  /// isConfined is whether a round is confined to the visible area.
  public private(set) var isConfined: Bool
  /// camera is the camera a round reads, its centre and its zoom, or nil while there is none to
  /// read.
  public private(set) var camera: MapViewport?
  /// configuration is what the engine asks its rounds with.
  public private(set) var configuration: SearchConfiguration

  /// answered is the engine's own snapshot, which names the query the pause last settled.
  private var answered: SearchSnapshot

  /// settled is the query the typing pause last settled, as typed.
  @ObservationIgnored private var settled: String
  @ObservationIgnored private let pause: Duration
  @ObservationIgnored private let refreshPause: Duration
  @ObservationIgnored private let sleep: @MainActor @Sendable (Duration) async throws -> Void
  /// pauseTask is the typing pause running, or nil for none.
  @ObservationIgnored private var pauseTask: Task<Void, Never>?
  /// refreshTask is the pause after a rest of the camera running, or nil for none.
  @ObservationIgnored private var refreshTask: Task<Void, Never>?
  /// roundTask is the live round's task, or nil for none, and branchTasks the tasks of its
  /// requests out.
  @ObservationIgnored private var roundTask: Task<Void, Never>?
  @ObservationIgnored private var branchTasks: [Task<Bool, Never>] = []
  /// liveRound is the number of the round that writes, or nil for none.
  @ObservationIgnored private var liveRound: Int?
  @ObservationIgnored private var rounds = 0
  /// retries and refreshes count the retries asked for and the rests that asked a round again, each
  /// of which tells a round to run again.
  @ObservationIgnored private var retries = 0
  @ObservationIgnored private var refreshes = 0
  /// lastKey and lastRefresh are the identity of the round asked last and the rest it was asked
  /// at: a round is a refresh only where the identity is the same and a rest moved the count on.
  @ObservationIgnored private var lastKey: RoundKey?
  @ObservationIgnored private var lastRefresh = 0
  /// isRefreshing is whether the live round is a refresh, during which no section loads, so the
  /// busy flag is held for the length of the round.
  @ObservationIgnored private var isRefreshing = false
  @ObservationIgnored private var closed = false
  /// subscribers is every stream `subscribe()` returned that has not ended, by its number.
  @ObservationIgnored private var subscribers: [Int: AsyncStream<SearchSnapshot>.Continuation] =
    [:]
  @ObservationIgnored private var nextSubscriber = 0

  /// Creates a search asking its rounds with `configuration`, holding `query` already settled, so
  /// it owes no pause, reading `camera`, its list open where `isOpen` says so and its rounds
  /// confined to the visible area where `isConfined` says so, which they are not by default. It
  /// asks a round at once where it holds a query and a transport.
  ///
  /// `pause` is the typing pause and `refreshPause` the pause after the camera rests, each waited
  /// out by `sleep`, which throws once its task is cancelled; a typing pause of zero asks a round as
  /// the query is typed, and one below zero is no `SearchPause`, so no search is built with it; a
  /// refresh pause below zero is none. `sleep` runs on the main actor, so a test's own wait wakes
  /// the engine in a known order.
  public init(
    configuration: SearchConfiguration = SearchConfiguration(),
    query: String = "",
    camera: MapViewport? = nil,
    isOpen: Bool = false,
    isConfined: Bool = false,
    pause: SearchPause = .standard,
    refreshPause: Duration = searchViewportRefreshPause,
    sleep: @escaping @MainActor @Sendable (Duration) async throws -> Void = {
      try await Task.sleep(for: $0)
    }
  ) {
    self.configuration = configuration
    self.query = query
    self.settled = query
    self.camera = camera
    self.isOpen = isOpen
    self.isConfined = isConfined
    self.pause = pause.duration
    self.refreshPause = max(refreshPause, .zero)
    self.sleep = sleep
    self.answered = Self.cleared(
      Self.listed(configuration.targets), query: trimWhiteSpace(query))
    schedule()
  }

  deinit {
    // An engine let go of ends its streams and its pauses, so nothing waits on it.
    pauseTask?.cancel()
    refreshTask?.cancel()
    roundTask?.cancel()
    for task in branchTasks {
      task.cancel()
    }
    for continuation in subscribers.values {
      continuation.finish()
    }
  }

  /// subscribe returns a stream that yields `state` as it is now, then as it changes, in order,
  /// for as long as the stream is held. It ends at `close()`.
  public func subscribe() -> AsyncStream<SearchSnapshot> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: SearchSnapshot.self, bufferingPolicy: .unbounded)
    continuation.yield(state)
    if closed {
      continuation.finish()
      return stream
    }
    let number = nextSubscriber
    nextSubscriber += 1
    subscribers[number] = continuation
    return stream
  }

  /// setQuery states what the reader typed. A round is asked once it has gone unchanged for the
  /// typing pause, and white space typed around the query already settled asks nothing.
  public func setQuery(_ query: String) {
    guard !closed, !sameText(self.query, query) else { return }
    self.query = query
    pauseTask?.cancel()
    pauseTask = nil
    if pause <= .zero {
      settle(query)
    } else {
      let wait = pause
      pauseTask = Task { [weak self, sleep] in
        do {
          try await sleep(wait)
        } catch {
          return
        }
        guard !Task.isCancelled, let self else { return }
        self.pauseTask = nil
        self.settle(query)
      }
    }
    tell()
  }

  /// setOpen states whether the result list is being looked at, which alone lets a rest of the
  /// camera ask a round again. It changes nothing shown, and closing the list leaves a round in
  /// flight to land, so a reader who opens it again waits for nothing already asked.
  public func setOpen(_ isOpen: Bool) {
    guard !closed, self.isOpen != isOpen else { return }
    self.isOpen = isOpen
    syncRefresh()
  }

  /// setConfined states whether a round is confined to the visible area. A change is the reader
  /// asking another question, so it asks a fresh round, every section loading again.
  public func setConfined(_ isConfined: Bool) {
    guard !closed, self.isConfined != isConfined else { return }
    self.isConfined = isConfined
    syncRefresh()
    schedule()
  }

  /// setCamera states the camera a round reads, its centre and its zoom, as it comes to rest, or
  /// nil where there is none to read. While the list is open, the round confined and a query held,
  /// each rest asks the round again once the camera has rested for the refresh pause, a rest during
  /// the pause starting it again.
  public func setCamera(_ camera: MapViewport?) {
    guard !closed else { return }
    self.camera = camera
    guard isRefreshLive else { return }
    refreshTask?.cancel()
    let wait = refreshPause
    refreshTask = Task { [weak self, sleep] in
      do {
        try await sleep(wait)
      } catch {
        return
      }
      guard !Task.isCancelled, let self else { return }
      self.refreshTask = nil
      self.refreshes += 1
      self.schedule()
    }
  }

  /// configure replaces what the engine asks its rounds with. A change of the language, the cap,
  /// the branches, whether there is a transport, or the language or the length system of the
  /// wording's units asks a fresh round; a configuration that changes none of them asks nothing, a
  /// replaced transport, word resolver or handler included, so a view may configure the engine each
  /// time it is drawn.
  public func configure(_ configuration: SearchConfiguration) {
    guard !closed else { return }
    let before = roundKey
    self.configuration = configuration
    syncRefresh()
    if roundKey != before {
      schedule()
    } else {
      tell()
    }
  }

  /// retry asks the query again from the top, a fresh round, which is what a failed section's
  /// retry asks.
  public func retry() {
    guard !closed else { return }
    retries += 1
    schedule()
  }

  /// close stops the engine for good: its pauses and its round are cancelled, nothing lands after
  /// it, every stream ends, and every later command does nothing. The state stays as it was.
  public func close() {
    guard !closed else { return }
    closed = true
    pauseTask?.cancel()
    pauseTask = nil
    refreshTask?.cancel()
    refreshTask = nil
    abandonRound()
    let ended = subscribers.values
    subscribers = [:]
    for continuation in ended {
      continuation.finish()
    }
  }

  // MARK: - Rounds

  /// RoundKey is what a round asks besides the rest that moves it on: a change of any member
  /// means a fresh round rather than a refresh.
  private struct RoundKey: Equatable {
    let query: String
    let isConfined: Bool
    let language: DataSchema.Language?
    let limit: SearchLimit?
    let branches: [DataSchema.SearchTarget]
    let isLive: Bool
    let retries: Int
    let unitsLanguage: String?
    let unitsLength: RestSchema.UnitLength?

    static func == (lhs: Self, rhs: Self) -> Bool {
      sameText(lhs.query, rhs.query) && lhs.isConfined == rhs.isConfined
        && sameText(lhs.language, rhs.language) && lhs.limit == rhs.limit
        && sameText(lhs.branches, rhs.branches) && lhs.isLive == rhs.isLive
        && lhs.retries == rhs.retries && sameText(lhs.unitsLanguage, rhs.unitsLanguage)
        && sameText(lhs.unitsLength, rhs.unitsLength)
    }
  }

  /// Round is one round from the moment it claims the slot: what it asks, where, and through what.
  private struct Round: Sendable {
    let number: Int
    let fetch: SearchFetch
    let branches: [DataSchema.SearchTarget]
    let query: String
    /// folded is `query` folded for matching, once for the round, which every row of every
    /// section it fills is matched against (`foldedQuery(_:)`).
    let folded: [Unicode.Scalar]
    let language: DataSchema.Language?
    let limit: SearchLimit?
    let focus: [Double]?
    let area: [Double]?
    let isRefresh: Bool
  }

  /// branches is the branches a round asks, in the order their sections render.
  private var branches: [DataSchema.SearchTarget] {
    Self.listed(configuration.targets)
  }

  /// roundKey is the identity of the round the engine would ask now.
  private var roundKey: RoundKey {
    RoundKey(
      query: trimWhiteSpace(settled), isConfined: isConfined, language: configuration.language,
      limit: configuration.limit, branches: branches, isLive: configuration.fetch != nil,
      retries: retries, unitsLanguage: configuration.wording.units?.language,
      unitsLength: configuration.wording.units?.length)
  }

  /// isRefreshLive is whether a rest of the camera asks a round again: the engine open, its rounds
  /// confined, a query settled and a transport to ask through.
  private var isRefreshLive: Bool {
    !closed && configuration.fetch != nil && isOpen && isConfined
      && !trimWhiteSpace(settled).unicodeScalars.isEmpty
  }

  /// settle takes `typed` as the query the pause settled, and asks a round for it unless it trims
  /// to the query settled before (`searchQueryChangeOf(settled:typed:)`).
  private func settle(_ typed: String) {
    let asked = trimWhiteSpace(settled)
    settled = typed
    if case .unchanged = searchQueryChangeOf(settled: asked, typed: typed) { return }
    syncRefresh()
    schedule()
  }

  /// syncRefresh drops a pending rest of the camera where a rest no longer asks a round again.
  private func syncRefresh() {
    guard !isRefreshLive else { return }
    refreshTask?.cancel()
    refreshTask = nil
  }

  /// schedule starts a round for the query settled, abandoning the one in flight, or settles every
  /// section with nothing where there is nothing to ask: a blank query, or no transport.
  private func schedule() {
    guard !closed else { return }
    let query = trimWhiteSpace(settled)
    let branches = self.branches
    guard let fetch = configuration.fetch, !query.unicodeScalars.isEmpty else {
      abandonRound()
      lastKey = nil
      isRefreshing = false
      commit(Self.cleared(branches, query: query))
      return
    }
    abandonRound()
    let key = roundKey
    let isRefresh = key == lastKey && refreshes != lastRefresh
    lastKey = key
    lastRefresh = refreshes
    isRefreshing = isRefresh
    if isRefresh {
      // A refresh keeps the rows in place under the query they answer, which it shares.
      var next = answered
      next.isSearching = true
      next.isSettled = false
      next.hasFallenBack = false
      commit(next)
    } else {
      commit(
        SearchSnapshot(
          query: query, isSearching: true,
          sections: branches.map { SearchSection(id: $0, state: .loading) }))
    }
    // The focus ranks a round around the camera's centre whether or not it is confined; a camera
    // whose centre names no point ranks around nothing and confines nothing, and one whose zoom is
    // no number confines nothing.
    let focus = camera.flatMap { searchFocus($0.center) }
    var area: [Double]?
    if isConfined, let camera, focus != nil, camera.zoom.isFinite {
      area = searchViewportBounds(center: camera.center, zoom: camera.zoom)
    }
    let round = Round(
      number: rounds, fetch: fetch, branches: branches, query: query,
      folded: foldedQuery(query), language: configuration.language, limit: configuration.limit,
      focus: focus, area: area, isRefresh: isRefresh)
    rounds += 1
    liveRound = round.number
    roundTask = Task { [weak self] in
      await self?.run(round)
    }
  }

  /// abandonRound cancels the round in flight, whose requests are withdrawn and whose answers land
  /// nowhere.
  private func abandonRound() {
    roundTask?.cancel()
    roundTask = nil
    for task in branchTasks {
      task.cancel()
    }
    branchTasks = []
    liveRound = nil
  }

  /// isLive is whether `round` still writes: no later round claimed the slot, and the engine is
  /// open.
  private func isLive(_ round: Round) -> Bool {
    !closed && liveRound == round.number
  }

  /// run asks `round`'s branches and settles the snapshot, asking once more everywhere where a
  /// confined round found nothing and none of its branches failed.
  private func run(_ round: Round) async {
    // A round abandoned before its task ran sends nothing.
    guard isLive(round) else { return }
    let first = await ask(round, area: round.area)
    guard isLive(round) else { return }
    // Only a confined round that came back cleanly empty broadens, and never a pan's: a reader
    // panning is looking somewhere on purpose.
    let broadens = !round.isRefresh && round.area != nil && first.isEveryEmpty && !first.hadError
    guard broadens else {
      isRefreshing = false
      var next = answered
      next.isSearching = false
      next.isSettled = true
      commit(next)
      return
    }
    var next = answered
    next.hasFallenBack = true
    next.isSearching = true
    next.isSettled = false
    next.sections = round.branches.map { SearchSection(id: $0, state: .loading) }
    commit(next)
    _ = await ask(round, area: nil)
    guard isLive(round) else { return }
    isRefreshing = false
    var last = answered
    last.isSearching = false
    last.isSettled = true
    commit(last)
  }

  /// ask sends one request per branch of `round`, confined to `area` where there is one, each in a
  /// task of its own started in the branches' order on the main actor, so the requests leave in
  /// that order, and writes each section as its answer lands while the round is live. It answers
  /// once every branch has answered or failed: whether every section then stands settled with
  /// nothing, and whether a branch threw.
  private func ask(_ round: Round, area: [Double]?) async -> (isEveryEmpty: Bool, hadError: Bool) {
    var asked: [Task<Bool, Never>] = []
    for branch in round.branches {
      guard let targets = enabledTargets(branch) else { continue }
      let input = DataSchema.SearchInput(query: round.query, targets: targets) {
        $0.language = round.language
        $0.limit = round.limit?.value
        $0.focus = round.focus
        $0.bbox = area
      }
      asked.append(Task { await self.answer(branch, asking: input, in: round) })
    }
    branchTasks = asked
    var hadError = false
    for task in asked {
      if await task.value {
        hadError = true
      }
    }
    let isEveryEmpty = answered.sections.allSatisfy { $0.state.isSettled && $0.rows.isEmpty }
    return (isEveryEmpty, hadError)
  }

  /// answer sends `input`, the request of `round` for `branch`, and writes the section its answer
  /// or its failure fills while the round is live. It answers whether the request threw, or landed
  /// for a round no longer live.
  private func answer(
    _ branch: DataSchema.SearchTarget, asking input: DataSchema.SearchInput, in round: Round
  ) async -> Bool {
    // A request of a round abandoned before its task ran is never sent.
    guard isLive(round), !Task.isCancelled else { return true }
    do {
      let result = try await round.fetch(input)
      guard isLive(round) else { return true }
      replace(
        searchSectionOf(
          result, branch: branch, folded: round.folded, wording: configuration.wording),
        in: round)
      return false
    } catch {
      guard isLive(round) else { return true }
      // The section reads its failure before the host hears of it.
      replace(SearchSection(id: branch, state: .failed(error)), in: round)
      configuration.onError?(error)
      return true
    }
  }

  /// replace writes `section` into the snapshot in place of its branch's, while `round` is live; a
  /// refresh stays busy for the length of the round, since none of its sections loads.
  private func replace(_ section: SearchSection, in round: Round) {
    guard isLive(round) else { return }
    var next = answered
    next.sections = answered.sections.map { sameText($0.id, section.id) ? section : $0 }
    next.isSearching = isRefreshing || next.sections.contains { $0.state.isLoading }
    commit(next)
  }

  /// commit holds `next` as the engine's answer and tells every stream what a list shows.
  private func commit(_ next: SearchSnapshot) {
    answered = next
    tell()
  }

  /// tell yields what a list shows to every stream.
  private func tell() {
    let shown = state
    for continuation in subscribers.values {
      continuation.yield(shown)
    }
  }

  /// listed is `targets` a round asks, each once, in the order first listed, a branch this build
  /// cannot enable left out.
  private static func listed(_ targets: [DataSchema.SearchTarget]) -> [DataSchema.SearchTarget] {
    var listed: [DataSchema.SearchTarget] = []
    for target in targets
    where enabledTargets(target) != nil && !listed.contains(where: { sameText($0, target) }) {
      listed.append(target)
    }
    return listed
  }

  /// cleared is the snapshot of a query asked nothing: every section of `branches` settled with
  /// nothing, and no round settled.
  private static func cleared(_ branches: [DataSchema.SearchTarget], query: String)
    -> SearchSnapshot
  {
    SearchSnapshot(
      query: query, sections: branches.map { SearchSection(id: $0, state: .settled) })
  }
}
