/// highlightRanges is every run of `title` that `query` matches without regard to case or accents,
/// left to right and never overlapping, each a range of `title`'s own indexes, on its scalars.
///
/// Both are folded alike, one segment at a time: a scalar with its combining marks and what
/// composes with it, lowercased, stripped of the accents a canonical decomposition leaves (U+0300
/// to U+036F), recomposed, a final sigma read as a sigma, a sharp s as `ss` and a Latin letter with
/// a stroke (đ, ħ, ł, ø, ŧ, small or capital) as the letter under the stroke, on either side:
/// `evian` matches `Évian`, `strasse` matches `Straße` and `lodz` matches `Łódź`. A match is found
/// in the folded title and mapped back onto whole segments of the title as written, so a fold that
/// changes a text's length never moves the emphasis (`stan` in `İstanbul` is `stan`), and a run
/// takes a sharp s whole (`stras` in `Straße` is `Straß`). Two matches inside one segment's fold are
/// one run.
///
/// A run is made of scalars with their marks and never of extended grapheme clusters, so it may end
/// inside an emoji sequence, between the two regional indicators of a flag or inside an Indic
/// conjunct: a bound may fall inside a `Character`, so a run is read through the title's
/// `unicodeScalars`, `String(title.unicodeScalars[range])`, where a subscript of the title itself
/// would round the bound to a `Character`. A mark that is no accent (an Arabic vowel, a Hebrew
/// point) is kept, so an unvowelled word matches no vowelled spelling of it. None for an empty
/// title, an empty query, or a query that folds to nothing, such as a lone accent.
public func highlightRanges(_ title: String, query: String) -> [Range<String.Index>] {
  highlightRanges(title, folded: foldedQuery(query))
}

/// foldedQuery is `query` folded for matching, as `highlightRanges(_:query:)` folds it: what a
/// search round folds once and matches every row's title against. Empty for an empty query and
/// for one that folds to nothing.
func foldedQuery(_ query: String) -> [Unicode.Scalar] {
  query.unicodeScalars.isEmpty ? [] : foldForSearch(query).text
}

/// highlightRanges is every run of `title` that `needle`, a query already folded by
/// `foldedQuery(_:)`, matches, as `highlightRanges(_:query:)` answers for that query; none for an
/// empty title or an empty needle.
func highlightRanges(_ title: String, folded needle: [Unicode.Scalar]) -> [Range<String.Index>] {
  guard !title.unicodeScalars.isEmpty, !needle.isEmpty else { return [] }
  let haystack = foldForSearch(title)
  var ranges: [Range<String.Index>] = []
  var from = 0
  while from <= haystack.text.count - needle.count,
    let at = firstPlace(of: needle, in: haystack.text, from: from)
  {
    let start = haystack.starts[at]
    let end = haystack.ends[at + needle.count - 1]
    if let previous = ranges.last, start < previous.upperBound {
      ranges[ranges.count - 1] = previous.lowerBound..<max(previous.upperBound, end)
    } else {
      ranges.append(start..<end)
    }
    from = at + needle.count
  }
  return ranges
}
