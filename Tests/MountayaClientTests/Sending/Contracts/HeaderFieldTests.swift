import Testing

@testable import MountayaClient

@Suite("HeaderField")
struct HeaderFieldTests {
  @Test("a header keeps the contract's spelling of its name")
  func spelling() {
    #expect(HeaderField(name: "Last-Event-ID", value: "7").name == "Last-Event-ID")
  }
}
