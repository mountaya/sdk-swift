import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("unansweredSearchSnapshot")
struct UnansweredSearchSnapshotTests {
  @Test("a query a live search owes a round reads as the skeleton of that round")
  func owed() {
    let snapshot = unansweredSearchSnapshot(" cha ", isLive: true, targets: [.places, .zones])

    #expect(snapshot.query == "cha")
    #expect(snapshot.isSearching)
    #expect(!snapshot.isSettled && !snapshot.hasFallenBack)
    #expect(snapshot.sections.map(\.id) == [.places, .zones])
    #expect(snapshot.sections.allSatisfy { $0.state.isLoading })
  }

  @Test("a blank query, or one with no transport, owes no round and reads settled with nothing")
  func notOwed() {
    for snapshot in [
      unansweredSearchSnapshot("   ", isLive: true, targets: [.places]),
      unansweredSearchSnapshot("cha", isLive: false, targets: [.places]),
    ] {
      #expect(!snapshot.isSearching)
      #expect(snapshot.sections.allSatisfy { $0.state.isSettled })
      #expect(snapshot.sections.allSatisfy { $0.rows.isEmpty })
    }
    #expect(unansweredSearchSnapshot("cha", isLive: false, targets: []).query == "cha")
  }
}
