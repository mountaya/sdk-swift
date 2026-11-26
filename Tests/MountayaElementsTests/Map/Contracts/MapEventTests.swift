import MountayaClient
import MountayaElements
import MountayaGeo
import Testing

@Suite("MapEvent")
struct MapEventTests {
  @Test("two events are equal where they are of one kind and hold the same")
  func equality() {
    let tap = MapTap(position: [6.86, 45.83], point: [1, 2])
    #expect(MapEvent.tap(tap) == .tap(tap))
    #expect(MapEvent.tap(tap) != .longTap(tap))
    #expect(
      MapEvent.featureHover(position: [170, 45], features: [])
        != .featureTap(position: [170, 45], features: []))
    #expect(
      MapEvent.featureHover(position: [.nan, 45], features: [])
        == .featureHover(position: [.nan, 45], features: []))
    #expect(
      MapEvent.accessRefused(status: 402, url: "https://tiles.test/v1/tile-layers")
        != .accessRefused(status: 403, url: "https://tiles.test/v1/tile-layers"))
    #expect(MapEvent.accessRestored == .accessRestored)
    #expect(MapEvent.failure(url: "u", status: nil) != .failure(url: "u", status: 404))
    #expect(MapEvent.failure(url: "u", status: nil) != .failure(url: "v", status: nil))
    #expect(MapEvent.layersChange(nil) == .layersChange(nil))
    #expect(MapEvent.layersChange(nil) != .accessRestored)
  }

  /// Unreadable is what a read of the client's credential threw.
  private struct Unreadable: Error {}

  /// A failure's cause is told for diagnostics: a caller reads it and never matches on it, so two
  /// failures of one request are one event whatever each carries beneath it.
  @Test("a failure carries its cause, which two events are never compared by")
  func failureCause() {
    let refused = MapEvent.failure(url: "u", status: nil, cause: Unreadable())

    guard case .failure(let url, let status, let cause) = refused else {
      Issue.record("\(refused) is no failure")
      return
    }
    #expect(url == "u" && status == nil)
    #expect(cause is Unreadable)
    #expect(refused == .failure(url: "u", status: nil))
    if case .failure(_, _, let cause) = MapEvent.failure(url: "u", status: 404) {
      #expect(cause == nil, "a failure built with no cause carries none")
    }
  }
}
