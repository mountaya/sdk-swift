import Testing

@testable import MountayaGeo

@Suite("NavigationError")
struct NavigationErrorTests {
  private struct Offline: Error, Equatable {
    let reason: String
  }

  /// A Swift error has no identity, so a failure is given one where it is recorded: one value and
  /// its copies are one failure, and two failures are two, whatever their sources threw.
  @Test("a failed route is the failure it was recorded as, and carries what its source threw")
  func failure() {
    let failure = NavigationError.routeFailed(Offline(reason: "offline"))
    let copy = failure

    #expect(copy == failure)
    #expect(copy.hashValue == failure.hashValue)
    #expect(failure != NavigationError.routeFailed(Offline(reason: "offline")))
    #expect(failure != NavigationError.emptyRoute())
    #expect(failure.kind == .routeFailed)
    #expect(failure.cause as? Offline == Offline(reason: "offline"))
    #expect(failure.description.hasPrefix("the route request failed: "))
  }

  /// An empty route carries nothing, and is a failure of its own all the same (`sdk/SPEC.md` §14):
  /// two recorded apart are two.
  @Test("an empty route is the failure it was recorded as, unequal to another empty route")
  func emptyRoute() {
    let empty = NavigationError.emptyRoute()
    let copy = empty

    #expect(copy == empty)
    #expect(copy.hashValue == empty.hashValue)
    #expect(empty != NavigationError.emptyRoute())
    #expect(empty.kind == .emptyRoute)
    #expect(empty.cause == nil)
    #expect(empty.description == "the route answered holds no vertex")
  }

  /// The kinds are open to ones a later release adds, so a host's `switch` keeps an
  /// `@unknown default`.
  @Test("a host reads the kinds it knows and keeps an unknown default")
  func kinds() {
    func said(_ error: NavigationError) -> String {
      switch error.kind {
      case .routeFailed: "failed: \(error.cause.map { "\($0)" } ?? "")"
      case .emptyRoute: "empty"
      @unknown default: "other"
      }
    }

    #expect(
      said(.routeFailed(Offline(reason: "offline"))) == "failed: Offline(reason: \"offline\")")
    #expect(said(.emptyRoute()) == "empty")
  }
}
