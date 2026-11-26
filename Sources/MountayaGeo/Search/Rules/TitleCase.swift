import MountayaClient

/// tokenSeparator is what joins the tokens of a second line, so every kind of result reads with one
/// rhythm: a middle dot between spaces.
let tokenSeparator = " \u{B7} "

/// The first regional indicator symbol, which stands for the letter A.
private let regionalIndicatorA: UInt32 = 0x1F1E6

/// titleCase is `value`, a raw wire or OpenStreetMap value, as a reader reads it: each underscore a
/// space and the first character a capital, so `demanding_mountain_hiking` reads `Demanding
/// mountain hiking`. The first UTF-16 unit is written as the full Unicode capital of it, as every
/// SDK writes one, so a first scalar past the basic plane, half of a surrogate pair there, is kept
/// as it is.
func titleCase(_ value: String) -> String {
  let cleaned = String(
    String.UnicodeScalarView(value.unicodeScalars.map { $0 == "_" ? " " : $0 }))
  let scalars = cleaned.unicodeScalars
  guard let first = scalars.first, first.value <= 0xFFFF else { return cleaned }
  return String(first).uppercased() + String(scalars.dropFirst())
}

/// wordFor is the word `label` reads as for the reader: the host's, or `fallback` where the host
/// has none or an empty one.
func wordFor(_ label: SearchLabel, fallback: String, wording: SearchWording) -> String {
  guard let word = wording.resolveLabel(label), !word.unicodeScalars.isEmpty else {
    return fallback
  }
  return word
}

/// joinTokens is `tokens` that are words, joined by `tokenSeparator`.
func joinTokens(_ tokens: String?...) -> String {
  tokens.compactMap { $0 }.filter { !$0.unicodeScalars.isEmpty }.joined(separator: tokenSeparator)
}

/// suppressIfMatchesName is `token`, or nothing where it would repeat `name`, the row's title,
/// without regard to case: the two are compared lowercased, scalar by scalar.
func suppressIfMatchesName(_ token: String?, name: String) -> String {
  guard let token, !token.unicodeScalars.isEmpty,
    !sameText(token.lowercased(), name.lowercased())
  else { return "" }
  return token
}

/// countryFlag is the flag of the country an ISO 3166-1 alpha-2 `code` names, its two regional
/// indicators, or nothing for a code that is not two ASCII letters.
func countryFlag(_ code: String?) -> String {
  guard let code else { return "" }
  let letters = Array(code.unicodeScalars)
  guard letters.count == 2,
    letters.allSatisfy({ ("a"..."z").contains($0) || ("A"..."Z").contains($0) })
  else { return "" }
  var flag = String.UnicodeScalarView()
  for letter in asciiUppercase(letters) {
    if let indicator = Unicode.Scalar(regionalIndicatorA + letter.value - 0x41) {
      flag.append(indicator)
    }
  }
  return String(flag)
}

/// The ASCII letters given, each small one written as its capital.
private func asciiUppercase(_ letters: [Unicode.Scalar]) -> [Unicode.Scalar] {
  letters.map { ("a"..."z").contains($0) ? Unicode.Scalar($0.value - 0x20) ?? $0 : $0 }
}

/// countryToken is a country as a second line states it: its name then its flag, either alone, or
/// nothing.
func countryToken(_ code: String?, name: String?) -> String {
  let flag = countryFlag(code)
  if let name, !name.unicodeScalars.isEmpty {
    return flag.isEmpty ? name : name + " " + flag
  }
  return flag
}

/// placeOrNil is the `[longitude, latitude]` of `position` where it names a place, else `nil`. An
/// altitude the wire's point carries is no part of the place a payload moves a map to, so it is
/// dropped, as in every SDK.
func placeOrNil(_ position: [Double]?) -> [Double]? {
  guard let position, namesPlace(position) else { return nil }
  return position.count == 2 ? position : [position[0], position[1]]
}

/// boxOrNil is `box` where it is four finite numbers, else `nil`.
func boxOrNil(_ box: [Double]?) -> [Double]? {
  guard let box, box.count == 4, box.allSatisfy(\.isFinite) else { return nil }
  return box
}

/// textSecondary is `text` as a second line, or none where it says nothing.
func textSecondary(_ text: String?) -> SearchRowSecondary? {
  guard let text, !text.unicodeScalars.isEmpty else { return nil }
  return .text(text)
}
