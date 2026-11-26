import Testing

@testable import MountayaGeo

@Suite("linkedWebAddress")
struct LinkedWebAddressTests {
  @Test("a stored address is read past the white space at its ends")
  func trimmed() {
    #expect(linkedWebAddress("  https://refuge.example/topo ") == "https://refuge.example/topo")
    #expect(linkedWebAddress("https://refuge.example/topo\n") == "https://refuge.example/topo")
    #expect(
      linkedWebAddress("\u{FEFF}https://refuge.example/topo") == "https://refuge.example/topo")
  }

  @Test("an address that is no web address is never linked")
  func neverLinked() {
    #expect(linkedWebAddress(" javascript:alert(1)") == nil)
    #expect(linkedWebAddress("ask at the bar") == nil)
    #expect(linkedWebAddress("") == nil)
    #expect(linkedWebAddress(nil) == nil)
    #expect(linkedWebAddress("\u{85}https://refuge.example/topo") == nil)
  }
}
