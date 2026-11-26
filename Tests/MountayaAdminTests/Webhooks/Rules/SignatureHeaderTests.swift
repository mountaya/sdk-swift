import Testing

@testable import MountayaAdmin

@Suite("SignatureHeader")
struct SignatureHeaderTests {
  @Test("a header states its t as written, the instant it names, and every v1 in order")
  func parses() throws {
    let header = try #require(SignatureHeader.parse("t=01763111564,v1=aa,v0=cc,v1=bb"))

    #expect(header.stated == "01763111564")
    #expect(header.timestamp == 1_763_111_564)
    #expect(header.signatures == ["aa", "bb"])
  }

  @Test("an empty v1 is a signature, which matches nothing, and not a malformed header")
  func emptySignature() throws {
    let header = try #require(SignatureHeader.parse("t=1,v1="))

    #expect(header.signatures == [""])
  }

  @Test("a key and a value are trimmed of white space, and a key is matched whole")
  func trims() throws {
    let header = try #require(SignatureHeader.parse("\u{2028} t\t= 5 ,v1 = a b ,V1=c,v1x=d"))

    #expect(header.stated == "5")
    #expect(header.signatures == ["a b"])
  }

  @Test("a value keeps every character but the white space at its ends, an equals sign included")
  func keepsValue() throws {
    let header = try #require(SignatureHeader.parse("t=5,v1=a=b"))

    #expect(header.signatures == ["a=b"])
  }

  @Test(
    "a header that is not one is refused",
    arguments: [
      "", ",", "t=5", "v1=a", "t=5,t=5,v1=a", "t=5,v1=a,", "t=5;v1=a", "t=+5,v1=a", "t=5 6,v1=a",
      "t=0x5,v1=a", "t=５,v1=a", "t=9007199254740992,v1=a",
    ]
  )
  func refuses(header: String) {
    #expect(SignatureHeader.parse(header) == nil)
  }

  @Test("the largest t read is the largest whole number a double holds exactly")
  func largest() {
    #expect(SignatureHeader.wholeSeconds("9007199254740991") == 9_007_199_254_740_991)
    #expect(SignatureHeader.wholeSeconds("0009007199254740991") == 9_007_199_254_740_991)
    #expect(SignatureHeader.wholeSeconds("9007199254740992") == nil)
    #expect(SignatureHeader.wholeSeconds("0") == 0)
  }

  @Test("a header the request does not carry, or one of white space alone, is missing")
  func missing() {
    #expect(SignatureHeader.isMissing(nil))
    #expect(SignatureHeader.isMissing(""))
    #expect(SignatureHeader.isMissing(" \t\r\n\u{A0}\u{FEFF}"))
    #expect(!SignatureHeader.isMissing(","))
    #expect(!SignatureHeader.isMissing("\u{85}"))
  }
}
