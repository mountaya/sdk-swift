/// readNumber reads a text as a number the way ECMAScript's `Number` reads a string, so a value an
/// author typed reads as one number in every SDK: the white space at its ends, as
/// `trimWhiteSpace(_:)` reads it, is left out; the empty text is 0; a decimal literal, signed or
/// not, with a fraction and an exponent or not, `.5` and `5.` included, is its value; `Infinity`,
/// signed or not, is an infinity; an unsigned `0x`, `0o` or `0b` literal is the whole number its
/// digits state in base 16, 8 or 2; and anything else, `1_000`, `0x1p3`, `nan` and `inf` among
/// them, is `NaN`. A digit is an ASCII digit, never another script's.
func readNumber(_ text: String) -> Double {
  let scalars = Array(trimWhiteSpace(text).unicodeScalars)
  guard !scalars.isEmpty else { return 0 }
  if let whole = prefixedInteger(scalars) { return whole }
  var body = scalars[...]
  var sign: Double = 1
  if let first = body.first, first == "+" || first == "-" {
    sign = first == "-" ? -1 : 1
    body = body.dropFirst()
  }
  if String(String.UnicodeScalarView(body)) == "Infinity" { return sign * .infinity }
  guard isDecimalLiteral(body), let value = Double(String(String.UnicodeScalarView(scalars)))
  else { return .nan }
  return value
}

/// The value of an unsigned `0x`, `0o` or `0b` literal, nil for any other text.
private func prefixedInteger(_ scalars: [Unicode.Scalar]) -> Double? {
  guard scalars.count > 2, scalars[0] == "0" else { return nil }
  let base: Double
  switch scalars[1] {
  case "x", "X": base = 16
  case "o", "O": base = 8
  case "b", "B": base = 2
  default: return nil
  }
  var value: Double = 0
  for scalar in scalars[2...] {
    guard let digit = hexDigitValue(scalar), Double(digit) < base else { return .nan }
    value = value * base + Double(digit)
  }
  return value
}

/// The value of an ASCII hexadecimal digit, nil for any other scalar.
private func hexDigitValue(_ scalar: Unicode.Scalar) -> Int? {
  switch scalar {
  case "0"..."9": Int(scalar.value - 48)
  case "a"..."f": Int(scalar.value - 87)
  case "A"..."F": Int(scalar.value - 55)
  default: nil
  }
}

/// Whether unsigned text is a decimal literal: digits with an optional fraction, or a fraction
/// alone, then an optional exponent of signed or unsigned digits.
private func isDecimalLiteral(_ scalars: ArraySlice<Unicode.Scalar>) -> Bool {
  var index = scalars.startIndex
  func digits() -> Int {
    let start = index
    while index < scalars.endIndex, ("0"..."9").contains(scalars[index]) {
      index += 1
    }
    return index - start
  }
  var mantissa = digits()
  if index < scalars.endIndex, scalars[index] == "." {
    index += 1
    mantissa += digits()
  }
  guard mantissa > 0 else { return false }
  if index < scalars.endIndex, scalars[index] == "e" || scalars[index] == "E" {
    index += 1
    if index < scalars.endIndex, scalars[index] == "+" || scalars[index] == "-" {
      index += 1
    }
    guard digits() > 0 else { return false }
  }
  return index == scalars.endIndex
}
