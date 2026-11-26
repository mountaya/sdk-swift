import Foundation
import MountayaClient
import Observation

/// LayersSelectionEngine is the terrain, classic overlay, enrichments and pinned instant behind a
/// layers picker (`geo.layers.selection`, `geo.layers.selection-outcome`,
/// `geo.layers.selection-instant`): it reads the layers catalogue of the map it drives, holds what
/// the reader asked for, and drives the map by the catalogue's rules.
///
/// - **One classic overlay.** A slope, a snow depth and an avalanche risk each repaint the same
///   ground, so selecting one replaces the last, and a second press on the one selected clears it.
/// - **Enrichments stack.** A hillshade under a slope overlay is a composition, so each toggles on
///   and off by itself, kept in the order it was turned on, one turned on again going last.
/// - **The terrain the map shows.** Once the catalogue lands, a selection with no terrain selected
///   states the one the map reports it shows, and none for a map that reports none, so a picker
///   marks what the map draws and never a guess; a terrain selected first is kept, and nothing asks
///   the map to switch to the one it reports.
/// - **The instant pinned.** A pin is a command as the others are: the selection holds the instant
///   pinned last, or none, the clock's reading, and it stands through every other command.
///
/// The selection is what was asked for and the map is what is drawn, neither mirrored into the
/// other: each command drives the map as it is made, whether or not anyone reads the state, and a
/// command the map refuses keeps what it asked for and reports the refusal, `state.refusal`, until
/// a later command or catalogue read settles. A map handed in place of another, or none, starts an
/// empty selection, the same map brought back included, and no catalogue or outcome owed to a map
/// it drove before lands. With no map a command is held and drives nothing.
///
/// ```swift
/// let layers = LayersSelectionEngine(map: map)
/// layers.setOverlay("slopes")
/// layers.toggleEnrichment("hillshade")
/// ```
///
/// It reads the catalogue as soon as it is handed a map, by its initializer as by
/// `configure(map:)`, since Observation tells an engine nothing of its readers; a map shares one
/// catalogue read among every reader (`map.layers.manifest`), so an engine made and dropped costs
/// no read. A read that fails is kept by nobody, and `configure(map:)` handed the same map asks
/// again.
/// It keeps no time and reads no clock: it holds the instant a reader pinned, and the map draws its
/// time-aware overlays for it.
///
/// It is bound to the main actor, as every engine is, and `Observable`, so a SwiftUI view that
/// reads `state` is drawn again when it changes. A closed engine is inert.
@MainActor
@Observable
public final class LayersSelectionEngine {
  /// state is what the selection holds.
  public var state: LayersSelection { held }

  /// held is the selection the engine holds, which an observer of `state` is told of.
  private var held = LayersSelection()

  /// map is the map the selection drives, or nil for none.
  @ObservationIgnored private var map: (any LayersSelectionTarget)?
  /// drives counts the maps the engine was handed, which numbers the selection a command is made
  /// under, so an outcome owed to an earlier one lands nowhere, the same map brought back included.
  @ObservationIgnored private var drives = 0
  /// catalogueRead is the number of the catalogue read the selection waits for, or nil for none.
  @ObservationIgnored private var catalogueRead: Int?
  @ObservationIgnored private var nextRead = 0
  @ObservationIgnored private var closed = false
  /// subscribers is every stream `subscribe()` returned that has not ended, by its number.
  @ObservationIgnored private var subscribers: [Int: AsyncStream<LayersSelection>.Continuation] =
    [:]
  @ObservationIgnored private var nextSubscriber = 0

  /// Creates a selection driving `map`, whose catalogue it reads at once, or none.
  public init(map: (any LayersSelectionTarget)? = nil) {
    self.map = map
    readCatalogue()
  }

  deinit {
    // An engine let go of ends its streams, so no reader waits on a state that never comes.
    for continuation in subscribers.values {
      continuation.finish()
    }
  }

  /// subscribe returns a stream that yields the selection as it is now, then every change of it, in
  /// order, for as long as the stream is held. It ends at `close()`.
  public func subscribe() -> AsyncStream<LayersSelection> {
    let (stream, continuation) = AsyncStream.makeStream(
      of: LayersSelection.self, bufferingPolicy: .unbounded)
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

  /// configure hands the selection the map it drives. The map it drives already changes nothing,
  /// unless its catalogue read failed, which it asks again; another one, nil included, starts an
  /// empty selection and reads its catalogue.
  public func configure(map: (any LayersSelectionTarget)?) {
    guard !closed else { return }
    if map === self.map {
      if held.catalogue == nil, catalogueRead == nil {
        readCatalogue()
      }
      return
    }
    self.map = map
    drives += 1
    catalogueRead = nil
    commit(LayersSelection())
    readCatalogue()
  }

  /// setTerrain selects the terrain `slug` names and switches the map's base map to it. The map is
  /// asked even for the terrain already selected, which is how a switch it refused is tried again.
  public func setTerrain(_ slug: String) {
    guard !closed else { return }
    if !sameText(held.terrain, slug) {
      var next = held
      next.terrain = slug
      commit(next)
    }
    drive { map in try await map.setTerrain(slug) }
  }

  /// setOverlay selects the classic overlay `slug` names in place of the one selected before, and
  /// draws it; the slug already selected clears it, which is what a second press means, and nil
  /// clears whatever is selected.
  public func setOverlay(_ slug: String?) {
    guard !closed else { return }
    let selected = sameText(held.overlay, slug) ? nil : slug
    if !sameText(held.overlay, selected) {
      var next = held
      next.overlay = selected
      commit(next)
    }
    drive { map in
      if let selected {
        try await map.setOverlay(selected)
      } else {
        try await map.clearOverlay()
      }
    }
  }

  /// toggleEnrichment turns the enrichment `slug` names on where it is off, last among those on,
  /// and off where it is on, leaving every other overlay as it is.
  public func toggleEnrichment(_ slug: String) {
    guard !closed else { return }
    let isOn = held.enrichments.contains { sameText($0, slug) }
    var next = held
    next.enrichments =
      isOn ? held.enrichments.filter { !sameText($0, slug) } : held.enrichments + [slug]
    commit(next)
    drive { map in
      if isOn {
        try await map.removeEnrichment(slug)
      } else {
        try await map.addEnrichment(slug)
      }
    }
  }

  /// setInstant pins `instant`, the instant the map draws its time-aware overlays for, or pins none
  /// where it is nil, so the map draws the present (`geo.layers.selection-instant`). A `Date` that
  /// names no instant, of no number or past the 8.64e15 milliseconds every SDK holds a time to,
  /// pins none. The map is asked even for the instant already pinned, which is how a pin it refused
  /// is tried again, and a refusal is kept and reported as any command's; the pin stands through
  /// every other command, and a map handed in place of this one starts with none pinned.
  public func setInstant(_ instant: Date?) {
    guard !closed else { return }
    var pinned: Double?
    if let instant, namesInstant(instant) {
      pinned = instant.timeIntervalSinceReferenceDate
    }
    if held.instantTime != pinned {
      var next = held
      next.instantTime = pinned
      commit(next)
    }
    drive { map in try await map.setInstant(pinned.map { Date(timeIntervalSinceReferenceDate: $0) })
    }
  }

  /// close stops the engine for good: no catalogue or outcome lands after it, every stream ends,
  /// and every later command does nothing. The state stays as it was.
  public func close() {
    guard !closed else { return }
    closed = true
    map = nil
    catalogueRead = nil
    let ended = subscribers.values
    subscribers = [:]
    for continuation in ended {
      continuation.finish()
    }
  }

  /// readCatalogue reads the catalogue of the map the selection drives, where it holds none, and
  /// folds it in as it lands while the selection still waits for it.
  private func readCatalogue() {
    guard !closed, let map, held.catalogue == nil else { return }
    let read = nextRead
    nextRead += 1
    catalogueRead = read
    Task { [weak self] in
      let outcome: Result<TileSchema.Layers, any Error>
      do {
        outcome = .success(try await map.loadLayers())
      } catch {
        outcome = .failure(error)
      }
      guard let self, !self.closed, self.catalogueRead == read else { return }
      self.catalogueRead = nil
      var next = self.held
      switch outcome {
      case .success(let catalogue):
        next.catalogue = catalogue
        // The map is asked what it shows only while nothing is selected, as the catalogue lands.
        if next.terrain == nil {
          next.terrain = map.terrain
        }
        next.refusal = nil
      case .failure(let error):
        next.refusal = error
      }
      self.commit(next)
    }
  }

  /// drive runs `command` on the map the selection drives, and reports its outcome while the
  /// selection it was made under stands: its refusal, or, where it succeeds, the end of a refusal
  /// an earlier one reported.
  private func drive(
    _ command: @escaping @MainActor (any LayersSelectionTarget) async throws -> Void
  ) {
    guard let map else { return }
    let drive = drives
    Task { [weak self] in
      let refusal: (any Error)?
      do {
        try await command(map)
        refusal = nil
      } catch {
        refusal = error
      }
      guard let self, !self.closed, self.drives == drive else { return }
      if refusal == nil, self.held.refusal == nil { return }
      var next = self.held
      next.refusal = refusal
      self.commit(next)
    }
  }

  /// commit holds `next` and tells every stream of it.
  private func commit(_ next: LayersSelection) {
    held = next
    for continuation in subscribers.values {
      continuation.yield(next)
    }
  }
}
