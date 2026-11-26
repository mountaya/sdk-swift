/// searchQueryChangeOf is what `typed`, the query in a search box once the reader's typing settles,
/// asks of a search whose last settled query is `settled`, the empty string before any:
///
/// - `SearchQueryChange.unchanged` where `typed`, trimmed of the white space at its ends, is
///   `settled`: white space typed around a settled query asks nothing, nor does an empty box before
///   any query;
/// - `SearchQueryChange.clear` where it trims to nothing: the search settles empty, so the same
///   query typed again after it asks again;
/// - `SearchQueryChange.ask(query:)` otherwise, for the trimmed query, which is the round's identity
///   and the query settled next.
///
/// Letter case is part of the query: `Mont Blanc` asks again after `mont blanc`, and two queries are
/// the same where they are written with the same scalars. The white space is the one set
/// ECMAScript's trim removes, in every SDK. It is `searchQueryChange` in the contract's other SDKs:
/// Swift refuses a second file of the answer type's name.
public func searchQueryChangeOf(settled: String, typed: String) -> SearchQueryChange {
  let query = trimWhiteSpace(typed)
  if sameText(query, settled) { return .unchanged }
  if query.unicodeScalars.isEmpty { return .clear }
  return .ask(query: query)
}
