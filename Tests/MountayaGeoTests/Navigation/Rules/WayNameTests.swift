import Testing

@testable import MountayaGeo

@Suite("wayName")
struct WayNameTests {
  @Test("an empty name and the API's dash are no name")
  func noName() {
    #expect(wayName("") == nil)
    #expect(wayName("-") == nil)
    #expect(wayName(nil) == nil)
  }

  /// Kept as written: nothing is trimmed, and a dash that is part of a name is a name.
  @Test("any other name is kept as written")
  func keptAsWritten() {
    #expect(wayName("Route des Pèlerins") == "Route des Pèlerins")
    #expect(wayName(" ") == " ")
    #expect(wayName(" - ") == " - ")
    #expect(wayName("--") == "--")
  }
}
