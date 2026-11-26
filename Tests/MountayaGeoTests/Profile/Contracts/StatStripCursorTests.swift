import Testing

@testable import MountayaGeo

@Suite("StatStripCursor")
struct StatStripCursorTests {
  @Test("two cursors are equal where every number is, a missing grade only to another")
  func equality() {
    let cursor = StatStripCursor(distance: 5_000, elevation: 1_400, grade: 6.2)
    #expect(cursor == StatStripCursor(distance: 5_000, elevation: 1_400, grade: 6.2))
    #expect(
      cursor.hashValue == StatStripCursor(distance: 5_000, elevation: 1_400, grade: 6.2).hashValue)
    #expect(cursor != StatStripCursor(distance: 5_000, elevation: 1_400, grade: nil))
  }
}
