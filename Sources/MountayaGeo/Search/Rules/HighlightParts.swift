/// highlightParts is `title` as the parts a search result draws it in once `query` is matched
/// against it (`highlightRanges(_:query:)`): each run the query matched, and each run between them,
/// as the title writes it, scalar for scalar, in order, so the parts joined are the title. A title
/// with no match, and an empty query, are one unmatched part holding the whole title.
public func highlightParts(_ title: String, query: String) -> [HighlightPart] {
  partsOf(title, ranges: highlightRanges(title, query: query))
}

/// partsOf is `title` split at `ranges`, sorted and disjoint, into matched and unmatched parts, each
/// read through the title's scalars, so a bound inside a `Character` is kept where it falls. A range
/// that starts before the one before it ends, or ends past the title, is passed over, so the title
/// is never read out of its bounds, and a title no range is kept for is one unmatched part.
func partsOf(_ title: String, ranges: [Range<String.Index>]) -> [HighlightPart] {
  let scalars = title.unicodeScalars
  var parts: [HighlightPart] = []
  var cursor = scalars.startIndex
  for range in ranges where cursor <= range.lowerBound && range.upperBound <= scalars.endIndex {
    if range.lowerBound > cursor {
      parts.append(HighlightPart(text: String(scalars[cursor..<range.lowerBound]), match: false))
    }
    parts.append(HighlightPart(text: String(scalars[range]), match: true))
    cursor = range.upperBound
  }
  guard !parts.isEmpty else { return [HighlightPart(text: title, match: false)] }
  if cursor < scalars.endIndex {
    parts.append(HighlightPart(text: String(scalars[cursor...]), match: false))
  }
  return parts
}
