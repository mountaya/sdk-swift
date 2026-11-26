/// The first scalar that can belong to the one before it. Below it there is no combining mark and
/// nothing that composes with a letter before it, so a segment starts there without asking the
/// normalizer.
private let firstJoiningScalar: UInt32 = 0x300

/// The scalars that are no combining mark and still compose with the scalar before them under
/// Unicode 17's canonical compositions: those whose decomposition starts with the second scalar
/// of a composition, the Hangul vowel and final jamo, which complete the syllable before them, and
/// Kirat Rai's vowel sign E and its doubled form AI. A scalar that is no mark and none of these
/// starts a segment of its own without asking the normalizer, and one of these joins only where
/// composing proves it does.
let composingLetters: [ClosedRange<UInt32>] = [
  0x1161...0x1175, 0x11A8...0x11C2, 0x16D67...0x16D68,
]

/// The block of combining diacritical marks a fold drops, the accents a decomposition leaves after
/// a letter.
private let accents: ClosedRange<UInt32> = 0x300...0x36F

/// FoldedText is a text folded for matching, `text`, its scalars, with, for each of them, where
/// the segment it came from starts and ends in the text as written.
struct FoldedText {
  let text: [Unicode.Scalar]
  let starts: [String.Index]
  let ends: [String.Index]
}

/// foldSegment is a segment, a scalar with every scalar joined to it, folded for matching:
/// lowercased, decomposed, stripped of the combining diacritical marks U+0300 to U+036F,
/// recomposed, a final sigma read as a sigma, and a sharp s and a Latin letter with a stroke read
/// as the letters a reader types, since neither lowercasing nor a decomposition says them: a sharp
/// s stands for two letters, and a stroke is no combining mark. One ASCII scalar is only
/// lowercased.
func foldSegment(_ segment: String) -> String {
  let scalars = segment.unicodeScalars
  if scalars.count == 1, let only = scalars.first, only.isASCII {
    return asciiLowercase(segment)
  }
  let stripped = canonicalDecomposition(segment.lowercased()).unicodeScalars.filter {
    !accents.contains($0.value)
  }
  var folded = String.UnicodeScalarView()
  for scalar in canonicalComposition(String(String.UnicodeScalarView(stripped))).unicodeScalars {
    switch scalar {
    case "\u{3C2}": folded.append("\u{3C3}")
    case "\u{DF}": folded.append(contentsOf: "ss".unicodeScalars)
    case "\u{111}": folded.append("d")
    case "\u{127}": folded.append("h")
    case "\u{142}": folded.append("l")
    case "\u{F8}": folded.append("o")
    case "\u{167}": folded.append("t")
    default: folded.append(scalar)
    }
  }
  return String(folded)
}

/// foldForSearch folds `value` one segment at a time, recording where each folded scalar came from.
/// A segment is a scalar and every scalar after it that joins it: a combining mark of any kind, and
/// a letter that composes with the segment under canonical composition, as a Hangul vowel completes
/// the jamo before it. Every folded scalar maps back to its whole segment, so no run of the title
/// ends inside one.
///
/// A segment is never a `Character`: an extended grapheme cluster joins an emoji sequence and the
/// two regional indicators of a flag, which the contract says a run may split.
func foldForSearch(_ value: String) -> FoldedText {
  let scalars = value.unicodeScalars
  var text: [Unicode.Scalar] = []
  var starts: [String.Index] = []
  var ends: [String.Index] = []
  var start = scalars.startIndex

  func close(_ end: String.Index) {
    for scalar in foldSegment(String(scalars[start..<end])).unicodeScalars {
      text.append(scalar)
      starts.append(start)
      ends.append(end)
    }
    start = end
  }

  var index = scalars.startIndex
  while index < scalars.endIndex {
    let scalar = scalars[index]
    if index > start,
      scalar.value < firstJoiningScalar || !joinsSegment(scalars[start..<index], scalar: scalar)
    {
      close(index)
    }
    index = scalars.index(after: index)
  }
  if index > start {
    close(index)
  }
  return FoldedText(text: text, starts: starts, ends: ends)
}

/// Whether `scalar` belongs to `segment` rather than starting one of its own: it is a combining
/// mark, or composing the two writes another text than composing each on its own. A scalar that is
/// no mark composes with nothing unless `composingLetters` holds it, so the platform's composition
/// is asked of those alone, and the segment is written out as a text only for them. The two
/// compositions are compared by their scalars, since `==` would call them one text by canonical
/// equivalence.
private func joinsSegment(_ segment: Substring.UnicodeScalarView, scalar: Unicode.Scalar)
  -> Bool
{
  if isCombiningMark(scalar) { return true }
  guard composingLetters.contains(where: { $0.contains(scalar.value) }) else { return false }
  let written = String(segment)
  let point = String(scalar)
  return !sameText(
    canonicalComposition(written + point),
    canonicalComposition(written) + canonicalComposition(point))
}
