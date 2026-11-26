import Foundation
import Testing

@testable import MountayaClient

@Suite("URI")
struct URITests {
  @Test("an address travels as its string, under any encoder")
  func string() throws {
    let read = try ScriptedSender.decode(URI.self, from: #""https://example.com/a?b=c""#)

    #expect(read.text == "https://example.com/a?b=c")
    #expect(read.url?.absoluteString == "https://example.com/a?b=c")
    #expect(try ScriptedSender.json(read) == #""https://example.com/a?b=c""#)
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(URI.self, from: "12")
    }
  }

  /// An answer is the API's account of what it holds, so an address it sends is the text it
  /// wrote, whatever it holds (`sdk/SPEC.md` §4).
  @Test("an answer's address is the text the wire sent, one Foundation would rewrite included")
  func keptAsSent() throws {
    for text in [
      "HTTPS://GATEWAY.example:443/v1/../v2/caf%C3%A9", "https://refuge.example/sale-50%-off",
      "https://r\u{E9}servation.refuge.example/nuit", "gateway.example.com/v1", "/v1/x", "",
      "urn:isbn:0451450523", "mountaya+test://x",
    ] {
      let json = String(decoding: try JSONEncoder().encode(text), as: UTF8.self)
      let read = try ScriptedSender.decode(URI.self, from: json)
      #expect(read.text.unicodeScalars.elementsEqual(text.unicodeScalars), "\(text)")
      #expect(read.description == text)
    }
  }

  /// A request holds an address to a scheme, as JSON Schema's `uri` is an absolute address, and
  /// the transport refuses a body that holds one with no scheme before any request; an answer a
  /// caller keeps writes its addresses back as they arrived.
  @Test("a type a request carries refuses an address with no scheme, and an answer's writes any")
  func noScheme() throws {
    for text in [
      "", "www.example.com", "/v1/itineraries", "://x.com", "https:", "1http://x", "https:\n",
      "ht_tp://x", "https://x\u{2028}y", "\u{212A}ttp://x",
    ] {
      #expect(throws: EncodingError.self, "\(text.debugDescription)") {
        try ScriptedSender.json(URI(text).wire)
      }
      #expect(
        try ScriptedSender.decode(CodedURI.self, from: try ScriptedSender.json(URI(text))).address
          == URI(text))
    }
    for text in ["a:b", "git+ssh://h/r", "HTTPS://Data.Mountaya.com/", "http://localhost:8080"] {
      #expect(try ScriptedSender.json(URI(text).wire) == "\"\(text)\"")
      #expect(try ScriptedSender.json(URI(text)) == "\"\(text)\"")
    }
    #expect(try ScriptedSender.json(URI("gateway.example.com/v1")) == "\"gateway.example.com/v1\"")
  }

  @Test("Foundation's URL is written as its absolute string, and read back where it reads one")
  func foundation() throws {
    let url = try #require(URL(string: "https://example.com/refuge"))

    #expect(URI(url).text == "https://example.com/refuge")
    #expect(URI(url).url == url)
  }

  @Test("two spellings of one address are two addresses")
  func scalars() {
    let composed = URI("https://example.com/caf\u{E9}")
    let decomposed = URI("https://example.com/cafe\u{301}")

    #expect(composed != decomposed)
    #expect(composed == URI("https://example.com/caf\u{E9}"))
    #expect(Set([composed, decomposed]).count == 2)
  }
}
