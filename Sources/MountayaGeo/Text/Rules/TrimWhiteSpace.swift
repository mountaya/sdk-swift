/// trimWhiteSpace is a text past the white space at its ends: the tab, the line feed, the line
/// tabulation, the form feed, the carriage return, every space separator (U+0020, U+00A0, U+1680,
/// U+2000 to U+200A, U+202F, U+205F and U+3000), the line and paragraph separators U+2028 and
/// U+2029, and the byte order mark U+FEFF.
///
/// The set is written out rather than read off a platform's notion of white space, which differs
/// between platforms and between the SDKs: Foundation's `whitespacesAndNewlines` holds the next
/// line control U+0085 and not the byte order mark. A value typed with a stray character at either
/// end reads the same everywhere. It is the set ECMAScript's own trim removes, read scalar by
/// scalar, so a carriage return and a line feed are two characters of white space here.
///
/// It is published for the map, which leaves out a credit of white space alone by it
/// (`map.style.attribution`).
public func trimWhiteSpace(_ text: String) -> String {
  let scalars = text.unicodeScalars
  guard let first = scalars.firstIndex(where: { !isWhiteSpace($0) }),
    let last = scalars.lastIndex(where: { !isWhiteSpace($0) })
  else { return "" }
  if first == scalars.startIndex, scalars.index(after: last) == scalars.endIndex {
    return text
  }
  return String(scalars[first...last])
}

/// isWhiteSpace tells whether a scalar is white space as `trimWhiteSpace(_:)` reads it.
func isWhiteSpace(_ scalar: Unicode.Scalar) -> Bool {
  switch scalar.value {
  case 0x0009...0x000D, 0x0020, 0x00A0, 0x1680, 0x2000...0x200A, 0x2028, 0x2029, 0x202F, 0x205F,
    0x3000, 0xFEFF:
    return true
  default:
    return false
  }
}
