import Foundation
import MountayaClient

/// tileTimestampParameter is the query parameter a server reads a stamped overlay's instant from
/// (`geo.layers.tile-timestamp`).
let tileTimestampParameter = "timestamp"

/// timestampedSources answers the tile sources a map asks again for `instant`
/// (`geo.layers.tile-timestamp`): those of the classic overlay `overlay` names, where the catalogue
/// says the server resolves its time, `capabilities.server.timestamp`, each with tile addresses
/// that carry the instant as their `timestamp` parameter, in UTC to the millisecond as
/// `2026-03-14T09:26:53.900Z` writes it, its colons percent-encoded as ECMAScript's
/// `encodeURIComponent` encodes them.
///
/// The overlay is looked up among the catalogue's classic categories alone, every category but the
/// one keyed `enrichment` (`findOverlay(_:slug:kind:)`): an enrichment is never stamped. None is
/// answered with no overlay named, for a slug no classic category holds, for an overlay the server
/// does not stamp, a time the client resolves on data it holds included, and for an instant that
/// names none (`namesInstant(_:)`), which has no spelling to stamp an address with.
///
/// An address is edited as text and never parsed and written again, since an address written anew
/// spells every parameter anew: the parameter takes the place of the first pair whose name decodes
/// to `timestamp`, `+` read as a space and each percent escape as the byte it names, a name that
/// does not decode naming another parameter, or is appended after every other pair; every other
/// such pair and every empty pair are dropped; and the path, its `{z}`, `{x}` and `{y}` braces, the
/// fragment and every other pair are kept byte for byte, so a signature over them still verifies.
/// An address with no scheme is kept as it is.
///
/// ```swift
/// let sources = timestampedSources(catalogue, overlay: "snow-depth", at: pinned)
/// ```
public func timestampedSources(
  _ catalogue: TileSchema.Layers, overlay: String?, at instant: Date
) -> [TimestampedSource] {
  guard let overlay, let found = findOverlay(catalogue, slug: overlay, kind: .classic),
    found.capabilities.server.timestamp, namesInstant(instant)
  else { return [] }
  // The instant in UTC to the millisecond, its colons percent-encoded: of what it writes, digits,
  // `-`, `T`, `.`, `Z` and `:`, the colon alone is no letter a query component keeps as it is.
  var stamp = Array("\(tileTimestampParameter)=".utf8)
  for byte in Timestamp.string(from: instant).utf8 {
    if byte == UInt8(ascii: ":") {
      stamp += [UInt8(ascii: "%"), UInt8(ascii: "3"), UInt8(ascii: "A")]
    } else {
      stamp.append(byte)
    }
  }
  var sources: [TimestampedSource] = []
  for source in found.sources {
    var tiles: [String] = []
    for tile in source.tiles {
      tiles.append(stamped(tile, with: stamp))
    }
    sources.append(TimestampedSource(sourceId: source.id, tiles: tiles))
  }
  return sources
}

/// stamped is the tile address `tile` with its `timestamp` pair set to `stamp`, the pair already
/// written, as `timestampedSources(_:overlay:at:)` edits one: as text, the fragment from the first
/// `#` and the query from the first `?` before it set apart, the query split at each `&`.
private func stamped(_ tile: String, with stamp: [UInt8]) -> String {
  let bytes = Array(tile.utf8)
  guard hasScheme(bytes) else { return tile }
  let fragmentAt = bytes.firstIndex(of: UInt8(ascii: "#")) ?? bytes.endIndex
  let address = bytes[..<fragmentAt]
  let queryAt = address.firstIndex(of: UInt8(ascii: "?"))
  var written = Array(address[..<(queryAt ?? address.endIndex)])
  var separator = UInt8(ascii: "?")
  var placed = false
  // Each pair of the query, up to the `&` that ends it.
  var start = queryAt.map { $0 + 1 } ?? address.endIndex
  while start <= address.endIndex, queryAt != nil {
    let end = address[start...].firstIndex(of: UInt8(ascii: "&")) ?? address.endIndex
    let pair = address[start..<end]
    start = end + 1
    let isTimestamp = namesTimestamp(pair)
    // Every other timestamp pair, and every empty pair, is dropped.
    guard isTimestamp ? !placed : !pair.isEmpty else { continue }
    written.append(separator)
    separator = UInt8(ascii: "&")
    if isTimestamp {
      written += stamp
      placed = true
    } else {
      written += pair
    }
  }
  if !placed {
    written.append(separator)
    written += stamp
  }
  written += bytes[fragmentAt...]
  return String(decoding: written, as: UTF8.self)
}

/// hasScheme tells whether an address opens with a scheme: a letter, then letters, digits, `+`,
/// `-` or `.`, then `:`.
private func hasScheme(_ bytes: [UInt8]) -> Bool {
  guard let first = bytes.first, isLetter(first) else { return false }
  for byte in bytes.dropFirst() {
    if byte == UInt8(ascii: ":") { return true }
    guard
      isLetter(byte) || isDigit(byte) || byte == UInt8(ascii: "+") || byte == UInt8(ascii: "-")
        || byte == UInt8(ascii: ".")
    else { return false }
  }
  return false
}

/// namesTimestamp tells whether a pair of a query sets the `timestamp` parameter: its name, the
/// text before its first `=` or the whole pair, read with `+` as a space and each percent escape as
/// the byte it names, spells `timestamp`. A name holding an escape that names no byte names
/// another parameter.
private func namesTimestamp(_ pair: ArraySlice<UInt8>) -> Bool {
  let name = pair[..<(pair.firstIndex(of: UInt8(ascii: "=")) ?? pair.endIndex)]
  var decoded: [UInt8] = []
  var index = name.startIndex
  while index < name.endIndex {
    let byte = name[index]
    if byte == UInt8(ascii: "%") {
      guard let high = hexValue(name, at: index + 1), let low = hexValue(name, at: index + 2) else {
        return false
      }
      decoded.append(high << 4 | low)
      index += 3
    } else {
      decoded.append(byte == UInt8(ascii: "+") ? UInt8(ascii: " ") : byte)
      index += 1
    }
  }
  return decoded == Array(tileTimestampParameter.utf8)
}

/// hexValue is the value of the hexadecimal digit at `index` of `bytes`, or nil where none stands
/// there.
private func hexValue(_ bytes: ArraySlice<UInt8>, at index: Int) -> UInt8? {
  guard index < bytes.endIndex else { return nil }
  let byte = bytes[index]
  if isDigit(byte) { return byte - UInt8(ascii: "0") }
  if (UInt8(ascii: "a")...UInt8(ascii: "f")).contains(byte) { return byte - UInt8(ascii: "a") + 10 }
  if (UInt8(ascii: "A")...UInt8(ascii: "F")).contains(byte) { return byte - UInt8(ascii: "A") + 10 }
  return nil
}

private func isLetter(_ byte: UInt8) -> Bool {
  (UInt8(ascii: "a")...UInt8(ascii: "z")).contains(byte)
    || (UInt8(ascii: "A")...UInt8(ascii: "Z")).contains(byte)
}

private func isDigit(_ byte: UInt8) -> Bool {
  (UInt8(ascii: "0")...UInt8(ascii: "9")).contains(byte)
}
