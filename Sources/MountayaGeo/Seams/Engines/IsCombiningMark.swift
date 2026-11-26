/// isCombiningMark tells whether a scalar is a combining mark, a character of Unicode's general
/// category M: a nonspacing mark (an accent, an Arabic vowel), a spacing one (an Indic vowel sign)
/// or an enclosing one. Each is drawn on the character before it. The standard library's character
/// database answers it, the one the running Swift carries.
func isCombiningMark(_ scalar: Unicode.Scalar) -> Bool {
  switch scalar.properties.generalCategory {
  case .nonspacingMark, .spacingMark, .enclosingMark:
    return true
  default:
    return false
  }
}
