import GateSupport
import Testing

@Suite("OrderedJSON")
struct OrderedJSONTests {
  @Test("an object keeps its members in document order")
  func keepsDocumentOrder() throws {
    let value = try OrderedJSON.parse(#"{"zebra": 1, "apple": {"m": true, "b": null}, "10": []}"#)

    #expect(value.members?.map(\.key) == ["zebra", "apple", "10"])
    #expect(value["apple"]?.members?.map(\.key) == ["m", "b"])
  }

  @Test("null, an absent key and an empty object are three things")
  func nullAbsentAndEmpty() throws {
    let value = try OrderedJSON.parse(#"{"a": null, "b": {}}"#)

    #expect(value["a"]?.isNull == true)
    #expect(value["b"]?.members?.isEmpty == true)
    #expect(value["c"] == nil)
    #expect(value["a"] != value["b"])
  }

  @Test("a whole number equals itself written with a fraction")
  func numbers() throws {
    #expect(try OrderedJSON.parse("16") == OrderedJSON.parse("16.0"))
    #expect(try OrderedJSON.parse("1800000000000").numberValue == 1_800_000_000_000)
    #expect(try OrderedJSON.parse("-1.5e-3").numberValue == -0.0015)
  }

  @Test("objects compare by their keys, in any order")
  func objectEquality() throws {
    let left = try OrderedJSON.parse(#"{"a": 1, "b": [1, 2]}"#)
    let right = try OrderedJSON.parse(#"{"b": [1, 2], "a": 1}"#)

    #expect(left == right)
    #expect(left != (try OrderedJSON.parse(#"{"a": 1, "b": [2, 1]}"#)))
    #expect(left != (try OrderedJSON.parse(#"{"a": 1}"#)))
  }

  @Test("two spellings of one text are two strings, compared by their scalars")
  func scalars() throws {
    let composed = try OrderedJSON.parse(#""Zoom arri\u00e8re""#)
    let decomposed = try OrderedJSON.parse(#""Zoom arrie\u0300re""#)

    #expect(composed != decomposed)
    #expect(composed == OrderedJSON.string("Zoom arri\u{E8}re"))
  }

  @Test("escapes decode, a surrogate pair included")
  func escapes() throws {
    let value = try OrderedJSON.parse(#""a\n\"\\ é 😀 \/""#)

    #expect(value.stringValue == "a\n\"\\ \u{E9} \u{1F600} /")
  }

  @Test(
    "a document that is not strict JSON is refused",
    arguments: [
      #"{"a": 1,}"#, "[1, 2,]", #"{"a": 1, "a": 2}"#, "01", "1.", #"{"a": 1} x"#, #"{'a': 1}"#,
      "// comment\n1", #""\ud83d""#, "", "[1 2]", "nul",
    ]
  )
  func refusals(document: String) {
    #expect(throws: OrderedJSONError.self) { try OrderedJSON.parse(document) }
  }

  @Test("an error names the line and the column")
  func errorPosition() {
    do {
      _ = try OrderedJSON.parse("{\n  \"a\": tru\n}")
      Issue.record("the document parsed")
    } catch {
      #expect(error.line == 2)
      #expect(error.column == 11)
    }
  }

  @Test("it serializes with two spaces, one member to a line, and a trailing brace")
  func serialization() throws {
    let value = OrderedJSON.object([
      .init(key: "capabilities", value: .object([.init(key: "a.b", value: .string("pass"))])),
      .init(key: "registryVersion", value: .number(6)),
      .init(key: "empty", value: .array([])),
      .init(key: "text", value: .string("a \"quoted\"\n·")),
    ])

    #expect(
      value.serialized() == """
        {
          "capabilities": {
            "a.b": "pass"
          },
          "registryVersion": 6,
          "empty": [],
          "text": "a \\"quoted\\"\\n·"
        }
        """
    )
    #expect(try OrderedJSON.parse(value.serialized()) == value)
  }
}
