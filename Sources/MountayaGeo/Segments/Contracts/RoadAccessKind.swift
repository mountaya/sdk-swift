/// RoadAccessKind is the kind a restricted stretch of a route is shown as, on a map and in a prompt,
/// each spelled by its contract id (`geo.data.road-access-kinds`).
///
/// The cases are declared most severe first, which is the order `allCases` yields and the order
/// kinds compare in: of two kinds the more severe is the lesser, so a stretch is shown as the least
/// kind, the most severe, among its access values.
public enum RoadAccessKind: String, CaseIterable, Comparable, Sendable {
  /// forbidden is no access at all: `no`.
  case forbidden
  /// private is the owner and their guests alone: `private`.
  case `private`
  /// permit is whoever holds an individual permit: `permit`.
  case permit
  /// service is the vehicles servicing the way or the premises on it: `service`.
  case service
  /// localAccess is traffic to a place on the way alone, never through it: `destination`,
  /// `customers` and `delivery`.
  case localAccess = "local-access"
  /// restricted is a restriction that names no one, or whose nature is not recorded: `restricted`
  /// and `unknown`, and a value the rule's table does not name, so a restriction the vocabulary
  /// gains later is never shown as none.
  case restricted

  /// id is the kind as the contract spells it, `local-access`.
  public var id: String { rawValue }

  /// One kind is before another where it is the more severe.
  public static func < (lhs: RoadAccessKind, rhs: RoadAccessKind) -> Bool {
    lhs.severity < rhs.severity
  }

  /// severity is the kind's place in the declaration order, the most severe at 0.
  private var severity: Int {
    switch self {
    case .forbidden: 0
    case .private: 1
    case .permit: 2
    case .service: 3
    case .localAccess: 4
    case .restricted: 5
    }
  }
}
