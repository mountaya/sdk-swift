/// searchLimitMax is the most results a round of a search asks for, the ceiling the Data API holds
/// a search's `limit` to and the one a viewport-restricted search shares.
public let searchLimitMax = 50

/// isSearchLimit tells whether `limit` is a cap a search round may ask for: a whole number from 1
/// to `searchLimitMax`. A search refuses any other before it asks a round, rather than sending one
/// the API refuses; a cap that is no whole number is one an `Int` cannot hold.
public func isSearchLimit(_ limit: Int) -> Bool {
  (1...searchLimitMax).contains(limit)
}
