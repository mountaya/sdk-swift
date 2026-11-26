import Foundation

/// EventFramer reads the bytes of a `text/event-stream` body into records, by the Server-Sent
/// Events rules and not by what the API happens to write.
///
/// A line ends at a CRLF, an LF or a lone CR, a record ends at an empty line, and one byte-order
/// mark at the very start is dropped. A line is split into its field and its value on its bytes,
/// at its first colon, and the one space that may follow the colon is a byte too, so a combining
/// mark after either is the value's own first character, never a part of the colon or the space;
/// each part is decoded as UTF-8 once the line is whole, and a line ending is never inside a
/// character, so a character split between two reads arrives whole. A comment, a line beginning
/// with a colon, dispatches nothing, and a record still open when the body ends is discarded.
struct EventFramer: Sendable {
  /// Framed is what one record, once ended, is.
  enum Framed: Sendable, Hashable {
    /// record is a record that carried data.
    case record(EventRecord)
    /// position is a record that carried an `id:` and no data, which moves the position a
    /// reopen resumes from without handing anything on.
    case position(String)
  }

  private static let byteOrderMark: [UInt8] = [0xEF, 0xBB, 0xBF]
  private static let lineFeed = UInt8(ascii: "\n")
  private static let carriageReturn = UInt8(ascii: "\r")
  private static let colon = UInt8(ascii: ":")
  private static let space = UInt8(ascii: " ")

  private var line: [UInt8] = []
  private var startRead = false
  /// afterCarriageReturn is true where the last byte read ended a line at a CR, so a line feed
  /// that follows, in the same read or the next, belongs to it.
  private var afterCarriageReturn = false
  private var data: [String] = []
  private var event: String?
  private var id: String?

  /// feed reads the next bytes of the body and returns the records they end, in order.
  mutating func feed(_ bytes: Data) -> [Framed] {
    var framed: [Framed] = []
    for byte in bytes {
      if !startRead {
        line.append(byte)
        if Self.byteOrderMark.starts(with: line) {
          if line.count == Self.byteOrderMark.count {
            line.removeAll()
            startRead = true
          }
          continue
        }
        startRead = true
        let held = line
        line.removeAll()
        for heldByte in held {
          take(heldByte, into: &framed)
        }
        continue
      }
      take(byte, into: &framed)
    }
    return framed
  }

  private mutating func take(_ byte: UInt8, into framed: inout [Framed]) {
    if afterCarriageReturn {
      afterCarriageReturn = false
      if byte == Self.lineFeed {
        return
      }
    }
    switch byte {
    case Self.lineFeed:
      endLine(into: &framed)
    case Self.carriageReturn:
      endLine(into: &framed)
      afterCarriageReturn = true
    default:
      line.append(byte)
    }
  }

  private mutating func endLine(into framed: inout [Framed]) {
    // The buffer keeps its storage for the next line, so a stream's lines cost no allocation each.
    defer { line.removeAll(keepingCapacity: true) }
    guard let first = line.first else {
      dispatch(into: &framed)
      return
    }
    if first == Self.colon {
      return
    }
    let field: ArraySlice<UInt8>
    var value: ArraySlice<UInt8>
    if let colon = line.firstIndex(of: Self.colon) {
      field = line[..<colon]
      value = line[(colon + 1)...]
      if value.first == Self.space {
        value = value.dropFirst()
      }
    } else {
      field = line[...]
      value = []
    }
    if field.elementsEqual("data".utf8) {
      data.append(String(decoding: value, as: UTF8.self))
    } else if field.elementsEqual("event".utf8) {
      event = String(decoding: value, as: UTF8.self)
    } else if field.elementsEqual("id".utf8) {
      if !value.contains(0) {
        id = String(decoding: value, as: UTF8.self)
      }
    }
    // `retry:` and any field the rules do not name are read no further: the reconnect schedule
    // is the contract's, never the server's.
  }

  private mutating func dispatch(into framed: inout [Framed]) {
    defer {
      data.removeAll()
      event = nil
      id = nil
    }
    if !data.isEmpty {
      framed.append(.record(EventRecord(event: event, data: data.joined(separator: "\n"), id: id)))
    } else if let id {
      framed.append(.position(id))
    }
  }
}
