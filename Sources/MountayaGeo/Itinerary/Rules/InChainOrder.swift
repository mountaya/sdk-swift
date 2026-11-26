/// inChainOrder answers the entries of a chain in the order the chain runs, by the ordinal
/// `position` reads off each, two at one position in the order they are listed, since
/// `sorted(by:)` promises no stability.
///
/// An itinerary's segments and its waypoints each carry such a position, and a chain held after a
/// local edit may arrive in another order: a reader that walked it as it came would draw it out of
/// order.
func inChainOrder<Entry>(_ entries: [Entry], position: (Entry) -> Int) -> [Entry] {
  entries.enumerated()
    .sorted { (position($0.element), $0.offset) < (position($1.element), $1.offset) }
    .map(\.element)
}
