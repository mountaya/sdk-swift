/// The schemes an address may open with, each in lower case and followed by two slashes.
private let schemes: [[Unicode.Scalar]] = [
  Array("http://".unicodeScalars), Array("https://".unicodeScalars),
]

/// The highest port a host may name.
private let maxPort = 65_535

/// The highest value one part of a dotted IPv4 address holds.
private let maxIpv4Part = 255

/// The parts of an IPv4 address.
private let ipv4Parts = 4

/// The 16-bit pieces of an IPv6 address; its trailing IPv4 form stands for two.
private let ipv6Pieces = 8

/// The most hexadecimal digits one IPv6 piece holds.
private let ipv6PieceDigits = 4

/// The characters a host may not hold once its escapes are read.
private let forbiddenHostCharacters = Set(" #%/:<>?@[\\]^|".unicodeScalars)

/// isWebAddress is whether an address, read as written, is a web address the API accepts on a
/// write, so a form shows its field error by it: an absolute `http` or `https` address, the scheme
/// in lower case, two slashes, then a host, and nothing the API's parser refuses.
///
/// Refused are: a control character anywhere, U+0000 to U+001F and U+007F; white space or a
/// backslash before the host ends; no host; a percent sign that two hexadecimal digits do not
/// follow, outside the query, where the API reads the query as written; and an escape in the host
/// that spells an ASCII character. The host is then read as a URL parser reads it: an IPv6 literal
/// in brackets holds a well-formed address, a name holds no character a host may not, its escapes
/// spell UTF-8, and a name ending in a number is a well-formed IPv4 address; a port is a number up
/// to 65,535. The address is read scalar by scalar, so a
/// carriage return before a line feed is a control character of its own. A port, a dotted IPv4
/// address and an escape are read in ASCII digits alone.
///
/// White space at either end is no part of an address, so `  https://refuge.example ` is refused
/// here; `linkedWebAddress(_:)` reads a stored address past it.
public func isWebAddress(_ address: String) -> Bool {
  let scalars = Array(address.unicodeScalars)
  guard let scheme = schemes.first(where: { scalars.starts(with: $0) }) else { return false }
  if scalars.contains(where: { $0.value < 0x20 || $0.value == 0x7F }) { return false }
  let afterScheme = scalars[scheme.count...]
  // The host the API reads runs up to the first `/`, `?` or `#`, and holds no white space or
  // backslash.
  let hostEnd =
    afterScheme.firstIndex { $0 == "/" || $0 == "?" || $0 == "#" } ?? afterScheme.endIndex
  let authority = afterScheme[..<hostEnd]
  if authority.isEmpty || authority.contains(where: { isWhiteSpace($0) || $0 == "\\" }) {
    return false
  }
  if holdsMalformedEscape(scalars) { return false }
  let hostAndPort = Array(
    authority.split(separator: "@", omittingEmptySubsequences: false).last ?? authority[...])
  if holdsAsciiEscape(hostAndPort) { return false }
  return isHostAndPort(hostAndPort)
}

/// Whether a percent sign outside the query opens no escape, two hexadecimal digits following it.
private func holdsMalformedEscape(_ address: [Unicode.Scalar]) -> Bool {
  let hash = address.firstIndex(of: "#")
  let beforeFragment = address[..<(hash ?? address.count)]
  let fragment = hash.map { address[($0 + 1)...] } ?? []
  let beforeQuery = beforeFragment[
    ..<(beforeFragment.firstIndex(of: "?") ?? beforeFragment.endIndex)]
  return isMalformedEscape(Array(beforeQuery)) || isMalformedEscape(Array(fragment))
}

/// Whether a text holds a percent sign that two hexadecimal digits do not follow.
private func isMalformedEscape(_ text: [Unicode.Scalar]) -> Bool {
  text.indices.contains { index in
    text[index] == "%"
      && (index + 2 >= text.count || !isHexDigit(text[index + 1]) || !isHexDigit(text[index + 2]))
  }
}

/// Whether a host holds an escape that spells an ASCII character, `%00` to `%7F`.
private func holdsAsciiEscape(_ host: [Unicode.Scalar]) -> Bool {
  host.indices.contains { index in
    host[index] == "%" && index + 2 < host.count && ("0"..."7").contains(host[index + 1])
      && isHexDigit(host[index + 2])
  }
}

/// Whether a host and port is a host a URL parser reads, then an optional port.
private func isHostAndPort(_ hostAndPort: [Unicode.Scalar]) -> Bool {
  let host: ArraySlice<Unicode.Scalar>
  let port: ArraySlice<Unicode.Scalar>?
  if hostAndPort.first == "[" {
    guard let close = hostAndPort.firstIndex(of: "]"), isIpv6(Array(hostAndPort[1..<close])) else {
      return false
    }
    let rest = hostAndPort[(close + 1)...]
    if let first = rest.first, first != ":" { return false }
    host = hostAndPort[...close]
    port = rest.isEmpty ? nil : rest.dropFirst()
  } else {
    let colon = hostAndPort.firstIndex(of: ":")
    host = hostAndPort[..<(colon ?? hostAndPort.count)]
    port = colon.map { hostAndPort[($0 + 1)...] }
    if !isDomain(Array(host)) { return false }
  }
  return !host.isEmpty && (port.map(isPort) ?? true)
}

/// Whether a port is empty, the scheme's own, or a decimal number up to `maxPort`.
private func isPort(_ port: ArraySlice<Unicode.Scalar>) -> Bool {
  guard port.allSatisfy(isDecimalDigit) else { return false }
  let significant = port.drop { $0 == "0" }
  guard !significant.isEmpty else { return true }
  guard significant.count <= String(maxPort).count,
    let value = Int(String(String.UnicodeScalarView(significant)))
  else { return false }
  return value <= maxPort
}

/// Whether a host is a name a URL parser reads: not empty once its escapes are read, its escapes
/// spelling UTF-8, no character a host may not hold, and, where it ends in a number, an IPv4
/// address.
private func isDomain(_ host: [Unicode.Scalar]) -> Bool {
  guard let decoded = percentDecoded(host), !decoded.isEmpty,
    !decoded.contains(where: forbiddenHostCharacters.contains)
  else { return false }
  return !endsInNumber(decoded) || isIpv4(decoded)
}

/// A text with its escapes read as UTF-8, or nil where they spell none.
private func percentDecoded(_ text: [Unicode.Scalar]) -> [Unicode.Scalar]? {
  guard text.contains("%") else { return text }
  // Read over the UTF-8 bytes: a percent sign and its digits are ASCII, so an escape is three
  // bytes.
  let source = Array(String(String.UnicodeScalarView(text)).utf8)
  var bytes: [UInt8] = []
  bytes.reserveCapacity(source.count)
  var index = 0
  while index < source.count {
    if source[index] == UInt8(ascii: "%"), index + 2 < source.count {
      guard let high = hexValue(source[index + 1]), let low = hexValue(source[index + 2]) else {
        return nil
      }
      bytes.append(UInt8(high * 16 + low))
      index += 3
    } else {
      bytes.append(source[index])
      index += 1
    }
  }
  var decoder = UTF8()
  var iterator = bytes.makeIterator()
  var decoded: [Unicode.Scalar] = []
  while true {
    switch decoder.decode(&iterator) {
    case .scalarValue(let scalar): decoded.append(scalar)
    case .emptyInput: return decoded
    case .error: return nil
    }
  }
}

/// The labels of a host, past one trailing dot.
private func labels(of host: [Unicode.Scalar]) -> [ArraySlice<Unicode.Scalar>] {
  var labels = host.split(separator: ".", omittingEmptySubsequences: false)
  if labels.count > 1, labels.last?.isEmpty == true { labels.removeLast() }
  return labels
}

/// Whether a host ends in a number, as a URL parser reads it: its last label, past one trailing
/// dot, is all decimal digits or a hexadecimal number, `0x` then hexadecimal digits.
private func endsInNumber(_ host: [Unicode.Scalar]) -> Bool {
  guard let last = labels(of: host).last, !last.isEmpty else { return false }
  return last.allSatisfy(isDecimalDigit) || ipv4Number(last) != nil
}

/// Whether a host is an IPv4 address as a URL parser reads one: up to four numbers, the last
/// filling the rest.
private func isIpv4(_ host: [Unicode.Scalar]) -> Bool {
  let parts = labels(of: host)
  guard parts.count <= ipv4Parts else { return false }
  var numbers: [Int] = []
  for part in parts {
    guard let number = ipv4Number(part) else { return false }
    numbers.append(number)
  }
  guard let last = numbers.last, !numbers.dropLast().contains(where: { $0 > maxIpv4Part }) else {
    return false
  }
  var limit = 1
  for _ in 0..<(ipv4Parts + 1 - numbers.count) { limit *= maxIpv4Part + 1 }
  return last < limit
}

/// One part of an IPv4 address: decimal, `0x` hexadecimal, or octal after a leading zero; nil
/// where it is none. A number too long for 64 bits is past every limit an address holds, and still
/// a number.
///
/// Its digits are read as `sdk-kotlin` reads them, any script's decimal digit and a fullwidth
/// letter included (`numberDigitValue(_:)`): a URL parser maps a fullwidth digit to an ASCII one
/// before it reads a host, and refuses a label of Arabic-Indic digits under the bidirectional
/// rule, so a name ending in either is refused here as there.
private func ipv4Number(_ part: ArraySlice<Unicode.Scalar>) -> Int? {
  guard let first = part.first else { return nil }
  let digits: ArraySlice<Unicode.Scalar>
  let radix: Int
  let second = part.dropFirst().first
  if first == "0", second == "x" || second == "X" {
    digits = part.dropFirst(2)
    radix = 16
  } else if part.count > 1, first == "0" {
    digits = part.dropFirst()
    radix = 8
  } else {
    digits = part
    radix = 10
  }
  var value = 0
  for scalar in digits {
    guard let digit = numberDigitValue(scalar), digit < radix else { return nil }
    let (shifted, overflowShift) = value.multipliedReportingOverflow(by: radix)
    let (sum, overflowSum) = shifted.addingReportingOverflow(digit)
    value = overflowShift || overflowSum ? Int.max : sum
  }
  return value
}

/// The value of a scalar as a digit of a number in a host, of a radix up to 36, as Kotlin's
/// `digitToIntOrNull` reads one of the basic plane: a decimal digit of any script, an ASCII
/// letter or a fullwidth Latin letter, the letters from 10. Nil for any other scalar.
private func numberDigitValue(_ scalar: Unicode.Scalar) -> Int? {
  switch scalar.value {
  case 0x41...0x5A: return Int(scalar.value - 0x41) + 10
  case 0x61...0x7A: return Int(scalar.value - 0x61) + 10
  case 0xFF21...0xFF3A: return Int(scalar.value - 0xFF21) + 10
  case 0xFF41...0xFF5A: return Int(scalar.value - 0xFF41) + 10
  case 0...0xFFFF:
    guard scalar.properties.numericType == .decimal, let value = scalar.properties.numericValue
    else { return nil }
    return Int(value)
  default:
    return nil
  }
}

/// Whether a text is an IPv6 address: eight hexadecimal pieces, one run of them compressed, the
/// last two as IPv4.
private func isIpv6(_ text: [Unicode.Scalar]) -> Bool {
  let compressed = firstIndex(of: "::", in: text, from: 0)
  if let compressed, firstIndex(of: "::", in: text, from: compressed + 1) != nil { return false }
  let head = text[..<(compressed ?? text.count)]
  let tail = compressed.map { text[($0 + 2)...] } ?? []
  let pieces =
    (head.isEmpty ? [] : head.split(separator: ":", omittingEmptySubsequences: false))
    + (tail.isEmpty ? [] : tail.split(separator: ":", omittingEmptySubsequences: false))
  var count = 0
  for (index, piece) in pieces.enumerated() {
    if index == pieces.count - 1, piece.contains(".") {
      guard isDottedIpv4(piece) else { return false }
      count += 2
    } else {
      guard !piece.isEmpty, piece.count <= ipv6PieceDigits, piece.allSatisfy(isHexDigit) else {
        return false
      }
      count += 1
    }
  }
  return compressed == nil ? count == ipv6Pieces : count < ipv6Pieces
}

/// The index at which a run of scalars first stands in a text at or after `start`.
private func firstIndex(of run: String, in text: [Unicode.Scalar], from start: Int) -> Int? {
  let pattern = Array(run.unicodeScalars)
  guard text.count >= pattern.count, start <= text.count - pattern.count else { return nil }
  return (start...(text.count - pattern.count)).first {
    text[$0..<($0 + pattern.count)].elementsEqual(pattern)
  }
}

/// Whether a text is four decimal numbers up to 255, dotted, none with a leading zero.
private func isDottedIpv4(_ text: ArraySlice<Unicode.Scalar>) -> Bool {
  let parts = text.split(separator: ".", omittingEmptySubsequences: false)
  return parts.count == ipv4Parts
    && parts.allSatisfy { part in
      guard (1...3).contains(part.count), part.allSatisfy(isDecimalDigit),
        part.count == 1 || part.first != "0",
        let value = Int(String(String.UnicodeScalarView(part)))
      else { return false }
      return value <= maxIpv4Part
    }
}

/// Whether a scalar is an ASCII decimal digit.
private func isDecimalDigit(_ scalar: Unicode.Scalar) -> Bool {
  ("0"..."9").contains(scalar)
}

/// Whether a scalar is an ASCII hexadecimal digit, in either case.
private func isHexDigit(_ scalar: Unicode.Scalar) -> Bool {
  digitValue(scalar).map { $0 < 16 } ?? false
}

/// The value of an ASCII digit or letter as a digit of a radix up to 36, or nil for any other
/// scalar: how an escape and an IPv6 piece are read.
private func digitValue(_ scalar: Unicode.Scalar) -> Int? {
  switch scalar {
  case "0"..."9": Int(scalar.value - 0x30)
  case "a"..."z": Int(scalar.value - 0x61 + 10)
  case "A"..."Z": Int(scalar.value - 0x41 + 10)
  default: nil
  }
}

/// The value of an ASCII hexadecimal digit's byte, or nil for any other byte.
private func hexValue(_ byte: UInt8) -> Int? {
  digitValue(Unicode.Scalar(byte)).flatMap { $0 < 16 ? $0 : nil }
}
