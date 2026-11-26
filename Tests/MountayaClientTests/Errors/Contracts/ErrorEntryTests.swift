import Testing

@testable import MountayaClient

@Suite("ErrorEntry")
struct ErrorEntryTests {
  @Test("a path keeps an array index as a number beside the keys")
  func pathKeepsIndices() {
    let entry = ErrorEntry(
      message: "Required.",
      code: "VALIDATION_FAILED",
      path: [.key("request"), .key("body"), .key("waypoints"), .index(2), .key("name")]
    )

    #expect(entry.path?[3] == .index(2))
    #expect(entry.path?[3] != .key("2"))
  }

  @Test("an entry about no field in particular has no path, which is not an empty one")
  func absentPath() {
    #expect(ErrorEntry(message: "Not JSON.", code: "BAD_REQUEST").path == nil)
    #expect(ErrorEntry(message: "x", path: []).path == [])
  }
}
