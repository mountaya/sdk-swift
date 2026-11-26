/// asciiLowercase is a text with each ASCII capital, `A` to `Z`, written as its small letter, and
/// every other scalar as it is.
///
/// Where a rule compares words the contract writes in ASCII, a language subtag or a hex colour,
/// only those letters are folded, since a platform's full case mapping differs by platform and by
/// Unicode version, and folds letters such as the dotted capital I that compare as no ASCII word.
func asciiLowercase(_ text: String) -> String {
  guard text.unicodeScalars.contains(where: { ("A"..."Z").contains($0) }) else { return text }
  return String(
    String.UnicodeScalarView(
      text.unicodeScalars.map { scalar in
        ("A"..."Z").contains(scalar) ? Unicode.Scalar(scalar.value + 0x20) ?? scalar : scalar
      }))
}
