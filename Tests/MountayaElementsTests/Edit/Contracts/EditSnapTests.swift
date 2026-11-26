import Testing

@testable import MountayaElements

@Suite("EditSnap")
struct EditSnapTests {
  @Test("a snap holds the position the point takes and whether the magnet moved it")
  func holds() {
    let snap = EditSnap(position: [6.86, 45.83, 1035], isSnapped: false)

    #expect(snap.position == [6.86, 45.83, 1035])
    #expect(!snap.isSnapped)
  }
}
