import Testing

@testable import MountayaClient

@Suite("StructuredFieldList")
struct StructuredFieldListTests {
  @Test("a list of strings with parameters is read in order, each parameter typed")
  func strings() throws {
    let members = try #require(
      StructuredFieldList.parse(#""minute";q=60;w=60, "month";q=100000;qu="requests";pk=:Y2xp:;x"#))

    #expect(members.count == 2)
    guard case .item(.string("month"), let parameters) = members[1] else {
      Issue.record("the second member is not the string `month`")
      return
    }
    #expect(parameters.map(\.key) == ["q", "qu", "pk", "x"])
    #expect(parameters[0].value == .integer(100_000))
    #expect(parameters[1].value == .string("requests"))
    #expect(parameters[2].value == .bytes(Array("cli".utf8)))
    #expect(parameters[3].value == .boolean(true))
  }

  @Test("every bare item of RFC 9651 is read, an inner list among the members")
  func bareItems() throws {
    let members = try #require(
      StructuredFieldList.parse(#"token/a:b, -1.25, ?0, @1659578233, %"caf%c3%a9", (1 "two");p"#))

    #expect(members.count == 6)
    #expect(members[0] == .item(.token("token/a:b"), parameters: []))
    #expect(members[1] == .item(.decimal(-1.25), parameters: []))
    #expect(members[2] == .item(.boolean(false), parameters: []))
    #expect(members[3] == .item(.date(1_659_578_233), parameters: []))
    #expect(members[4] == .item(.displayString("café"), parameters: []))
    guard case .innerList(let items, let parameters) = members[5] else {
      Issue.record("the last member is not an inner list")
      return
    }
    #expect(items.map(\.item) == [.integer(1), .string("two")])
    #expect(parameters.map(\.key) == ["p"])
  }

  @Test("a parameter key written twice keeps its last value")
  func keyWrittenTwice() throws {
    let members = try #require(StructuredFieldList.parse(#""m";q=1;q=2"#))

    #expect(
      members == [
        .item(
          .string("m"), parameters: [StructuredFieldList.Parameter(key: "q", value: .integer(2))])
      ])
  }

  @Test("a field that does not parse is no list at all, rather than the members before the fault")
  func refused() {
    #expect(StructuredFieldList.parse(#""minute;q=60"#) == nil)
    #expect(StructuredFieldList.parse(#""minute";r=59;t="#) == nil)
    #expect(StructuredFieldList.parse(#""a", "#) == nil)
    #expect(StructuredFieldList.parse("1.2345") == nil)
    #expect(StructuredFieldList.parse("1234567890123456") == nil)
    #expect(StructuredFieldList.parse("") == [])
  }
}
