import Testing

@testable import MountayaClient

@Suite("ConditionalTag")
struct ConditionalTagTests {
  @Test("a tag is sent exactly as given, a wildcard and a weak one included")
  func asGiven() throws {
    #expect(try ConditionalTag.tag(declared: true, given: "\"d42\"") == "\"d42\"")
    #expect(try ConditionalTag.tag(declared: true, given: "W/\"d42\"") == "W/\"d42\"")
    #expect(try ConditionalTag.tag(declared: true, given: "*") == "*")
  }

  @Test("none is sent where the caller names none, or where the operation declares no If-Match")
  func none() throws {
    #expect(try ConditionalTag.tag(declared: true, given: nil) == nil)
    #expect(try ConditionalTag.tag(declared: false, given: "\"d42\"") == nil)
    #expect(try ConditionalTag.tag(declared: false, given: "") == nil)
  }

  @Test("a tag no header can carry is refused")
  func refused() {
    for tag in ["", "\"d4\n2\"", "\"\u{2116}\"", "\u{85}", "\"d\u{E9}42\""] {
      #expect(throws: MountayaError.self) { try ConditionalTag.tag(declared: true, given: tag) }
    }
  }
}
