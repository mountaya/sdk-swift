/// isSearchListShown answers whether a search control shows its result list (`sdk/SPEC.md` §7,
/// which no fixture holds): while the focus stands anywhere in the control, `hasFocus`, its box,
/// its filter chips, its scope's toggle or what its list shows, over a `query` that is not white
/// space alone, as `trimWhiteSpace(_:)` trims it, and the reader has not dismissed the list,
/// `isDismissed`. So focus moving from the box to a filter chip or a retry keeps the list there.
///
/// A pick dismisses the list and takes the focus out of the control, and an edit or the focus
/// coming back to the box lifts the dismissal, which the control itself tracks. Every SDK's search
/// control shows its list by this rule, and a host drawing its own list over a `SearchEngine` reads
/// it too.
public func isSearchListShown(hasFocus: Bool, query: String, isDismissed: Bool) -> Bool {
  hasFocus && !trimWhiteSpace(query).isEmpty && !isDismissed
}
