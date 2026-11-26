import GateSupport

/// ConformanceReport is this SDK's report to the contract: one status per capability, keyed on
/// the registry version it was run against and the digest of the model and the elements' data it
/// read, `modelDigest` (`sdk/SPEC.md` §11), and the names its API declares for each capability the
/// registry's `swift` column lists, which the contract's gate holds to that column.
enum ConformanceReport {
  /// The name this SDK reports under, which is also its file name under `sdk/reports/`.
  static let sdk = "swift"

  /// The variable that decides what a run does with the report. Unset, no file is touched, so
  /// a plain test run never writes into another repository.
  static let modeVariable = "MOUNTAYA_CONFORMANCE_REPORT"

  /// Status is what a capability reports.
  enum Status: String, Sendable {
    case pass
    case fail
    case scoped
  }

  /// render writes the report as the contract's tooling reads it: keys sorted, two-space
  /// indentation, one trailing newline. `published` is each capability's names in the column's
  /// order, and `modelDigest` is left out only where it is nil, as a report written before the
  /// contract defined it holds none.
  static func render(
    sdk: String = ConformanceReport.sdk,
    registryVersion: Int,
    modelDigest: String?,
    statuses: [String: Status],
    published: [String: [String]]
  ) -> String {
    let capabilities = statuses.keys.sorted().map { id in
      OrderedJSON.Member(key: id, value: .string(statuses[id]?.rawValue ?? Status.fail.rawValue))
    }
    let names = published.keys.sorted().map { id in
      OrderedJSON.Member(key: id, value: .array((published[id] ?? []).map { .string($0) }))
    }
    var members = [OrderedJSON.Member(key: "capabilities", value: .object(capabilities))]
    if let modelDigest {
      members.append(OrderedJSON.Member(key: "modelDigest", value: .string(modelDigest)))
    }
    members += [
      OrderedJSON.Member(key: "published", value: .object(names)),
      OrderedJSON.Member(key: "registryVersion", value: .number(Double(registryVersion))),
      OrderedJSON.Member(key: "sdk", value: .string(sdk)),
    ]
    return OrderedJSON.object(members).serialized() + "\n"
  }
}
