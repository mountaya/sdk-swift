/// NavigationError is why the last route request a navigation acted on failed: a Mountaya value,
/// never the error of the engine underneath, which a consumer could only match by importing what
/// that engine keeps hidden.
///
/// A first route that fails leaves a navigation `failed` with one, and a new route that fails
/// leaves it `off-route` on the route it holds, with one. `kind` says which failure it is, and
/// `cause` carries what the route source threw.
///
/// A Swift error is a value with no identity of its own, so a failure is given one where it is
/// recorded: two are equal where they are the same failure, one value and its copies, and two
/// failures are two values even where their sources threw alike, two empty routes among them
/// (`sdk/SPEC.md` §14).
public struct NavigationError: Error, Sendable, Hashable, CustomStringConvertible {
  /// Kind is every reason a route request fails that this build knows.
  ///
  /// The set grows where an engine adds a reason, so a `switch` over it outside this module ends
  /// in `@unknown default`.
  @nonexhaustive
  public enum Kind: Sendable, Hashable {
    /// routeFailed is a route request whose source failed: `cause` is what it threw, a client
    /// error for a request the API refused or a failure of the host's own.
    case routeFailed
    /// emptyRoute is a route request whose source answered a route whose line holds no vertex,
    /// which is no route to follow.
    case emptyRoute
  }

  /// Identity is what tells one recorded failure from another, compared by reference. It is
  /// Sendable: it holds nothing.
  private final class Identity: Sendable {}

  /// kind is which failure it is.
  public let kind: Kind
  /// cause is what the route source threw, for a `routeFailed`, and nil for any other kind.
  public let cause: (any Error)?
  private let identity: Identity

  private init(kind: Kind, cause: (any Error)?, identity: Identity) {
    self.kind = kind
    self.cause = cause
    self.identity = identity
  }

  /// routeFailed is a route request whose source threw `cause`, a failure of its own, unequal to
  /// every other.
  public static func routeFailed(_ cause: any Error) -> NavigationError {
    NavigationError(kind: .routeFailed, cause: cause, identity: Identity())
  }

  /// emptyRoute is a route request whose source answered a route whose line holds no vertex, a
  /// failure of its own, unequal to every other, another empty route included.
  public static func emptyRoute() -> NavigationError {
    NavigationError(kind: .emptyRoute, cause: nil, identity: Identity())
  }

  /// Two errors are equal where they are of one kind and are the same failure.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.kind == rhs.kind && lhs.identity === rhs.identity
  }

  /// hash feeds the kind and the failure's identity.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(kind)
    hasher.combine(ObjectIdentifier(identity))
  }

  /// description is the failure as a developer reads it in a log.
  public var description: String {
    switch (kind, cause) {
    case (.routeFailed, let cause?): "the route request failed: \(cause)"
    case (.emptyRoute, _): "the route answered holds no vertex"
    default: "the route request failed"
    }
  }
}
