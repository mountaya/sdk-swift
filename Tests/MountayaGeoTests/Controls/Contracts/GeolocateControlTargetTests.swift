import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GeolocateControlTarget")
@MainActor
struct GeolocateControlTargetTests {
  /// Here is a map of an app's own, which locates at once and reads location allowed.
  @MainActor
  final class Here: GeolocateControlTarget {
    private(set) var located = 0

    func locate() async throws -> [Double] {
      located += 1
      return [6.86, 45.83]
    }

    func isLocationRefused() async -> Bool { false }
  }

  @Test("a map of an app's own is a target a control stands over, a read that cannot fail included")
  func ownMap() async {
    let map = Here()
    let engine = GeolocateControlEngine(map: map)

    engine.locate()
    await settled()

    #expect(map.located == 1)
    #expect(engine.state == GeolocateControlState(isBusy: false, isBlocked: false, isLive: true))
    engine.close()
  }
}
