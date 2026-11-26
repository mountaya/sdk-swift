import Foundation
import GateSupport

/// ContractCheckout is the sibling checkout of `mountaya/schemas`, where the registry and
/// the fixtures live.
///
/// It is tolerated as absent on a contributor's machine and refused in CI, so a contributor
/// builds without it and a green CI run always means the fixtures ran.
struct ContractCheckout: Sendable {
  /// The variable that points at the checkout when it is not the sibling directory.
  static let directoryVariable = "MOUNTAYA_SCHEMAS_DIR"

  /// The variable a CI run sets, which turns an absent checkout into a failure.
  static let requiredVariable = "CI"

  let directory: URL

  /// isRequired is true where an absent checkout must fail the run.
  static var isRequired: Bool {
    !(ProcessInfo.processInfo.environment[requiredVariable] ?? "").isEmpty
  }

  /// expectedDirectory is where the checkout is looked for: the variable's path when it is
  /// set, the directory beside this repository otherwise.
  static var expectedDirectory: URL? {
    if let path = ProcessInfo.processInfo.environment[directoryVariable], !path.isEmpty {
      return URL(fileURLWithPath: path)
    }
    return SourceTree.packageRoot(from: #filePath)?
      .deletingLastPathComponent()
      .appendingPathComponent("schemas")
  }

  /// locate returns the checkout, or nil when no registry is found where it is expected.
  static func locate() -> ContractCheckout? {
    guard let directory = expectedDirectory else { return nil }
    let registry = directory.appendingPathComponent("sdk/registry.yaml")
    guard FileManager.default.fileExists(atPath: registry.path) else { return nil }
    return ContractCheckout(directory: directory)
  }

  var registryUrl: URL {
    directory.appendingPathComponent("sdk/registry.yaml")
  }

  var reportUrl: URL {
    directory.appendingPathComponent("sdk/reports/\(ConformanceReport.sdk).json")
  }

  func fixtureUrl(_ capability: Registry.Capability) -> URL {
    directory.appendingPathComponent("sdk/fixtures").appendingPathComponent(capability.fixture)
  }
}
