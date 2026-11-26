import Testing

@testable import MountayaClient

@Suite("WireKey")
struct WireKeyTests {
  @Test("a key is the wire's spelling, whatever Swift would make of it")
  func spelling() {
    let key: WireKey = "Last-Event-ID"

    #expect(key.stringValue == "Last-Event-ID")
    #expect(key.intValue == nil)
    #expect(WireKey(intValue: 0) == nil)
  }
}
