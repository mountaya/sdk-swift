import Foundation
import MountayaClient

@testable import MountayaGeo

/// settled lets every task the main actor holds run, a few turns of it, which is how a test waits
/// for an engine's answers to land with no clock.
@MainActor
func settled() async {
  for _ in 0..<8 {
    await Task.yield()
  }
}

/// HeldLayersMap is a map a layers selection drives, each command and catalogue read held until
/// the test answers it, in the order sent, or answered at once where `answersAtOnce` says so.
@MainActor
final class HeldLayersMap: LayersSelectionTarget {
  struct Refused: Error {}

  /// calls is every command the map was given, each its command and its slug, or an instant's
  /// milliseconds from the epoch, `-` for none.
  private(set) var calls: [String] = []
  private var heldCalls: [CheckedContinuation<Void, any Error>?] = []
  private var heldReads: [CheckedContinuation<TileSchema.Layers, any Error>?] = []
  var terrain: String?
  let catalogue: TileSchema.Layers
  let answersAtOnce: Bool

  init(catalogue: TileSchema.Layers, terrain: String?, answersAtOnce: Bool = false) {
    self.catalogue = catalogue
    self.terrain = terrain
    self.answersAtOnce = answersAtOnce
  }

  /// reads is how many catalogue reads the map was asked for.
  var reads: Int { heldReads.count }

  func loadLayers() async throws -> TileSchema.Layers {
    try await withCheckedThrowingContinuation { heldReads.append($0) }
  }

  func setTerrain(_ slug: String?) async throws { try await command("terrain", slug: slug) }
  func setOverlay(_ slug: String) async throws { try await command("overlay", slug: slug) }
  func clearOverlay() async throws { try await command("overlay", slug: nil) }
  func addEnrichment(_ slug: String) async throws {
    try await command("add-enrichment", slug: slug)
  }
  func removeEnrichment(_ slug: String) async throws {
    try await command("remove-enrichment", slug: slug)
  }
  func setInstant(_ instant: Date?) async throws {
    try await command(
      "instant", slug: instant.map { String(Int64(($0.timeIntervalSince1970 * 1000).rounded())) })
  }

  /// land lands the catalogue read `read`.
  func land(_ read: Int) { takeRead(read)?.resume(returning: catalogue) }
  /// failRead fails the catalogue read `read`.
  func failRead(_ read: Int) { takeRead(read)?.resume(throwing: Refused()) }
  /// accept lets the command `call` succeed.
  func accept(_ call: Int) { takeCall(call)?.resume() }
  /// refuse lets the command `call` fail.
  func refuse(_ call: Int) { takeCall(call)?.resume(throwing: Refused()) }

  /// release answers everything still held, so no task waits for ever.
  func release() {
    for index in heldReads.indices { takeRead(index)?.resume(throwing: Refused()) }
    for index in heldCalls.indices { takeCall(index)?.resume(throwing: Refused()) }
  }

  private func takeRead(_ index: Int) -> CheckedContinuation<TileSchema.Layers, any Error>? {
    guard heldReads.indices.contains(index) else { return nil }
    defer { heldReads[index] = nil }
    return heldReads[index]
  }

  private func takeCall(_ index: Int) -> CheckedContinuation<Void, any Error>? {
    guard heldCalls.indices.contains(index) else { return nil }
    defer { heldCalls[index] = nil }
    return heldCalls[index]
  }

  private func command(_ name: String, slug: String?) async throws {
    calls.append("\(name):\(slug ?? "-")")
    guard !answersAtOnce else {
      heldCalls.append(nil)
      return
    }
    try await withCheckedThrowingContinuation { heldCalls.append($0) }
  }
}

/// HeldLocateMap is a map a locate control stands over, each permission read and each fix held
/// until the test answers it, in the order sent.
@MainActor
final class HeldLocateMap: GeolocateControlTarget {
  struct Refused: Error {}

  private(set) var reads = 0
  private(set) var fixes = 0
  private var heldReads: [CheckedContinuation<Bool, any Error>?] = []
  private var heldFixes: [CheckedContinuation<[Double], any Error>?] = []

  func locate() async throws -> [Double] {
    fixes += 1
    return try await withCheckedThrowingContinuation { heldFixes.append($0) }
  }

  func isLocationRefused() async throws -> Bool {
    reads += 1
    return try await withCheckedThrowingContinuation { heldReads.append($0) }
  }

  /// answer answers the read `read`, refused or not, and fail fails it.
  func answer(_ read: Int, refused: Bool) { take(read)?.resume(returning: refused) }
  func fail(_ read: Int) { take(read)?.resume(throwing: Refused()) }
  /// locate lets the fix `fix` land, and refuse refuses it.
  func land(_ fix: Int) { takeFix(fix)?.resume(returning: [6.86, 45.83]) }
  func refuse(_ fix: Int) { takeFix(fix)?.resume(throwing: Refused()) }

  /// release answers everything still held, so no task waits for ever.
  func release() {
    for index in heldReads.indices { take(index)?.resume(returning: false) }
    for index in heldFixes.indices { takeFix(index)?.resume(throwing: Refused()) }
  }

  private func take(_ index: Int) -> CheckedContinuation<Bool, any Error>? {
    guard heldReads.indices.contains(index) else { return nil }
    defer { heldReads[index] = nil }
    return heldReads[index]
  }

  private func takeFix(_ index: Int) -> CheckedContinuation<[Double], any Error>? {
    guard heldFixes.indices.contains(index) else { return nil }
    defer { heldFixes[index] = nil }
    return heldFixes[index]
  }
}
