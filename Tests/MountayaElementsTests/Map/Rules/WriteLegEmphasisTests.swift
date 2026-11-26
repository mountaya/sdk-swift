import MountayaClient
import Testing

@testable import MountayaElements

@Suite("writeLegEmphasis")
@MainActor
struct WriteLegEmphasisTests {
  /// Slot is a map recording each write of its emphasis slot.
  final class Slot: LegEmphasisTarget {
    var writes: [String] = []

    func setGeometry(_ geometry: GeoJSONGeometry?, in slot: GeometrySlot, color: String?) {
      writes.append("set \(slot) \(color ?? "own")")
    }

    func clearGeometry(in slot: GeometrySlot) {
      writes.append("clear \(slot)")
    }
  }

  private let leg: GeoJSONGeometry = .lineString(
    GeoJSONLineString(coordinates: [[6, 45], [6, 45.1]]))

  @Test("a leg pointed at is written to the emphasis slot, in its colour or the map's own")
  func lit() {
    let map = Slot()
    #expect(writeLegEmphasis(on: map, isLit: false, stretch: leg))
    #expect(writeLegEmphasis(on: map, isLit: true, stretch: leg, color: "#e8590c"))
    #expect(map.writes == ["set emphasis own", "set emphasis #e8590c"])
  }

  @Test("pointing at none clears only what the element lit")
  func cleared() {
    let map = Slot()
    #expect(!writeLegEmphasis(on: map, isLit: false, stretch: nil))
    #expect(map.writes.isEmpty)
    #expect(!writeLegEmphasis(on: map, isLit: true, stretch: nil))
    #expect(map.writes == ["clear emphasis"])
  }
}
