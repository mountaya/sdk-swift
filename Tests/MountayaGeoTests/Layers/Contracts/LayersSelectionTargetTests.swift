import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("LayersSelectionTarget")
@MainActor
struct LayersSelectionTargetTests {
  @Test("a map of an app's own is a target a selection drives, compared by identity")
  func ownMap() async {
    let map = HeldLayersMap(catalogue: TileFixtures.layers([]), terrain: nil, answersAtOnce: true)
    let target: any LayersSelectionTarget = map
    let engine = LayersSelectionEngine(map: target)

    engine.setOverlay("slopes")
    engine.setInstant(Date(timeIntervalSince1970: 1_773_576_000))
    await settled()

    #expect(map.calls == ["overlay:slopes", "instant:1773576000000"])
    #expect(target === map)
    map.release()
    engine.close()
  }
}
