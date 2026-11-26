import Foundation
import Testing

/// ContractCheckout is a file of the contract checkout a gate reads: the sibling `../schemas`, or
/// wherever `MOUNTAYA_SCHEMAS_DIR` points, as the conformance suite reads the registry.
///
/// It is tolerated as absent on a contributor's machine, where the gate is skipped with a note
/// saying so, and refused in CI, so a green CI run always means the file was read.
enum ContractCheckout {
  /// The variable that points at the checkout when it is not the sibling directory.
  static let directoryVariable = "MOUNTAYA_SCHEMAS_DIR"

  /// The variable a CI run sets, which turns an absent checkout into a failure.
  static let requiredVariable = "CI"

  /// note is what a run skipped for want of `path` says.
  static func note(_ path: String) -> Comment {
    Comment(
      rawValue:
        "no \(path) in ../schemas: check mountaya/schemas out there, or point "
        + "\(directoryVariable) at it")
  }

  /// missing is what a run that needs `path` says where it is absent.
  static func missing(_ path: String) -> String {
    "no \(path) in the contract checkout, which a run with \(requiredVariable) set reads: check "
      + "mountaya/schemas out beside this repository, or point \(directoryVariable) at it"
  }

  /// isPresentOrRequired is true where a gate reading `path` runs: where the file is there, and in
  /// CI, where its absence fails it.
  static func isPresentOrRequired(_ path: String) -> Bool {
    locate(path) != nil || !(ProcessInfo.processInfo.environment[requiredVariable] ?? "").isEmpty
  }

  /// locate returns the address of `path` in the checkout, or nil where the checkout holds none.
  static func locate(_ path: String) -> URL? {
    let directory: URL?
    if let variable = ProcessInfo.processInfo.environment[directoryVariable], !variable.isEmpty {
      directory = URL(fileURLWithPath: variable)
    } else {
      directory = PackageTree.root?.deletingLastPathComponent().appendingPathComponent("schemas")
    }
    guard let file = directory?.appendingPathComponent(path),
      FileManager.default.fileExists(atPath: file.path)
    else { return nil }
    return file
  }
}
