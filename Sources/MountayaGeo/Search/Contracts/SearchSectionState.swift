/// SearchSectionState is how one section of a search stands: loading while its branch is in
/// flight, settled once it answered, or failed (`geo.search.live-round`).
///
/// It stands per section, since the branches fail apart: the API answers the ones that worked and
/// reports the ones that did not, so a points-of-interest outage leaves the itineraries beside it
/// as they are. It is not `Equatable`, since a failure holds an error.
public enum SearchSectionState: Sendable {
  /// loading is a branch in flight.
  case loading
  /// settled is a branch that answered, with its rows or with none.
  case settled
  /// failed is a branch that failed, holding why: what the search's transport threw, or a
  /// `SearchBranchError` where the Data API answered the branch as failed.
  case failed(any Error)

  /// isLoading is whether the branch is in flight.
  public var isLoading: Bool {
    if case .loading = self { return true }
    return false
  }

  /// isSettled is whether the branch answered.
  public var isSettled: Bool {
    if case .settled = self { return true }
    return false
  }

  /// failure is why the branch failed, or nil for a branch that did not.
  public var failure: (any Error)? {
    if case .failed(let error) = self { return error }
    return nil
  }
}
