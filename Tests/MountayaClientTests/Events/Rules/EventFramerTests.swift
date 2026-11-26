import Foundation
import Testing

@testable import MountayaClient

@Suite("EventFramer")
struct EventFramerTests {
  private static func frame(_ chunks: [[UInt8]]) -> [EventFramer.Framed] {
    var framer = EventFramer()
    return chunks.flatMap { framer.feed(Data($0)) }
  }

  @Test("a line ends at a CRLF, an LF or a lone CR, split across reads included")
  func lineEndings() {
    let expected = [EventFramer.Framed.record(EventRecord(event: nil, data: "a\nb", id: nil))]

    #expect(Self.frame([Array("data: a\r".utf8), Array("\ndata: b\r\n\r\n".utf8)]) == expected)
    #expect(Self.frame([Array("data: a\rdata: b\r\r".utf8)]) == expected)
    #expect(Self.frame([Array("data:a\ndata:b\n\n".utf8)]) == expected)
  }

  @Test("one byte-order mark at the start is dropped, and a character split across reads is whole")
  func bytes() {
    let framed = Self.frame([
      [0xEF, 0xBB], [0xBF] + Array("data: ".utf8) + [0xC3], [0xA9, 0x0A, 0x0A],
    ])

    #expect(framed == [.record(EventRecord(event: nil, data: "é", id: nil))])
  }

  @Test(
    "an id with no data moves the position, a comment dispatches nothing, and a tail is dropped")
  func positions() {
    let framed = Self.frame([
      Array("id: 1-0\nevent: message\ndata: a\n\n: beat\n\nid: 2-0\n\ndata: tail\n".utf8)
    ])

    #expect(
      framed == [.record(EventRecord(event: "message", data: "a", id: "1-0")), .position("2-0")])
  }

  /// The reconnect schedule is the contract's, so a `retry:` the server sends changes nothing.
  @Test("a retry, a field no rule names and an id holding NUL are ignored")
  func ignored() {
    let framed = Self.frame([Array("retry: 10\nkind: x\nid: a\u{0}b\ndata: a\n\n".utf8)])

    #expect(framed == [.record(EventRecord(event: nil, data: "a", id: nil))])
  }

  /// A combining mark joins the character before it, so a line split on characters would read
  /// `:\u{301}` as no colon and ` \u{301}` as no space: the rules split a line on its code points.
  @Test(
    "a field is split from its value on the colon itself, a combining mark after it the value's")
  func combiningMarks() {
    let framed = Self.frame([
      Array("data:\u{301}x\n\nevent: \u{301}y\ndata: \u{301}z\nid:\u{301}1\n\n".utf8)
    ])

    #expect(
      framed == [
        .record(EventRecord(event: nil, data: "\u{301}x", id: nil)),
        .record(EventRecord(event: "\u{301}y", data: "\u{301}z", id: "\u{301}1")),
      ])
  }

  /// The line buffer keeps its storage from one line to the next, so a line after a longer one
  /// holds its own bytes and none of the longer one's.
  @Test("a short line after a long one is read whole and alone, in one read and split across reads")
  func lineAfterLongerLine() {
    let long = String(repeating: "é", count: 3_000)
    let head = Array("event: long\ndata: \(long)\n".utf8)
    let tail = Array("\nevent: s\nid: 1\ndata: a\n\n".utf8)
    let expected: [EventFramer.Framed] = [
      .record(EventRecord(event: "long", data: long, id: nil)),
      .record(EventRecord(event: "s", data: "a", id: "1")),
    ]

    #expect(Self.frame([head + tail]) == expected)
    // The first split falls inside a character of the long line, the second just after its end.
    let inside = 1_001
    #expect(Self.frame([Array(head[..<inside]), Array(head[inside...]), tail]) == expected)
  }
}
