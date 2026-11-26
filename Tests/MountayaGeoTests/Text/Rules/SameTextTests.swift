import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("sameText")
struct SameTextTests {
  @Test("two texts are the same where they are written with the same scalars")
  func scalarsCompared() {
    #expect(sameText("Mont", "Mont"))
    #expect(!sameText("Mont", "mont"))
    // `==` calls these one string by canonical equivalence; the scalars are two texts.
    #expect("\u{E9}" == "e\u{301}")
    #expect(!sameText("\u{E9}", "e\u{301}"))
    #expect(sameText("", ""))
  }

  @Test("an absent text is the same only as another absent one")
  func absent() {
    #expect(sameText(nil as String?, nil))
    #expect(!sameText(nil, "Mont"))
    #expect(!sameText("Mont", nil))
    #expect(sameText("Mont" as String?, "Mont"))
    #expect(!sameText("\u{E9}" as String?, "e\u{301}"))
  }

  @Test(
    "two words of an open vocabulary are the same where their raw values are, scalar for scalar")
  func vocabulary() {
    #expect(
      sameText(RestSchema.UnitLength.metric, RestSchema.UnitLength(rawValue: "metric")))
    // The generated `==` calls these one word by canonical equivalence; the scalars are two.
    #expect(
      RestSchema.UnitLength(rawValue: "\u{E9}") == RestSchema.UnitLength(rawValue: "e\u{301}"))
    #expect(
      !sameText(
        RestSchema.UnitLength(rawValue: "\u{E9}"), RestSchema.UnitLength(rawValue: "e\u{301}")))
    #expect(sameText(nil as RestSchema.UnitLength?, nil))
    #expect(!sameText(RestSchema.UnitLength.metric, nil))
    #expect(sameText([RestSchema.UnitLength.metric], [.metric]))
    #expect(!sameText([RestSchema.UnitLength.metric], []))
    #expect(
      !sameText(
        [RestSchema.UnitLength(rawValue: "\u{E9}")], [RestSchema.UnitLength(rawValue: "e\u{301}")]))
  }

  @Test(
    "two tables are the same where every entry is, key and value scalar for scalar, in any order")
  func tables() {
    #expect(sameText(["cx": "1", "r": "2"], ["r": "2", "cx": "1"]))
    #expect(!sameText(["cx": "1"], ["cx": "1", "r": "2"]))
    #expect(!sameText(["cx": "1"], ["cy": "1"]))
    #expect(!sameText(["d": "\u{E9}"], ["d": "e\u{301}"]))
    // A dictionary finds a key by canonical equivalence, and the scalars of the one it finds decide.
    #expect(["\u{E9}": "1"]["e\u{301}"] == "1")
    #expect(!sameText(["\u{E9}": "1"], ["e\u{301}": "1"]))
  }
}
