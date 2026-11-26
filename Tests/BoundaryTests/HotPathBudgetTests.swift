import Foundation
import GateSupport
import Testing

/// The hot paths the contract lists for this SDK, each held by a live budget test (SPEC.md section
/// 7): `sdk/hot-paths.yaml` in the contract checkout names them, and every Swift file under
/// `Tests/` is read for the tests, the Renderer's and the Speech topic's packages included, so a
/// budget the simulator runs is held on every host, Linux's among them.
@Suite("Hot-path budgets")
struct HotPathBudgetTests {
  /// scan is every budget test under `Tests/`, read once for the suite.
  private static let scan: Result<HotPathBudgets.Scan, any Error> = Result {
    guard let root = PackageTree.root else {
      throw PackageTree.Unreadable(description: "no Package.swift above \(#filePath)")
    }
    return HotPathBudgets.scan(root: root, directory: "Tests")
  }

  /// paths is the list the contract checkout holds, read once for the suite.
  private static let paths: Result<[HotPathBudgets.Path], any Error> = Result {
    guard let list = HotPathsCheckout.locate() else {
      throw PackageTree.Unreadable(description: HotPathsCheckout.missing)
    }
    guard let text = SourceTree.read(list) else {
      throw PackageTree.Unreadable(description: "\(list.path) cannot be read")
    }
    return try HotPathBudgets.parse(text)
  }

  /// findings is what the scan breaks of the list, of the kinds given.
  private static func findings(_ kinds: Set<HotPathBudgets.Finding.Kind>) throws -> String {
    try HotPathBudgets.findings(paths: paths.get(), tests: scan.get().tests)
      .filter { kinds.contains($0.kind) }
      .map { "\($0.file):\($0.line): \($0.message)" }
      .joined(separator: "\n")
  }

  @Test(
    "every hot path the contract lists for Swift keeps a live budget test",
    .enabled(if: HotPathsCheckout.isPresentOrRequired, HotPathsCheckout.note))
  func everyPathIsBudgeted() throws {
    let listed = try Self.paths.get().filter { $0.sdks.contains(HotPathBudgets.sdk) }
    let tests = try Self.scan.get().tests
    // Printed before the assertion, so the count is something a reader sees on a red run too.
    print(
      "hot-path-budgets: \(listed.count) checked, 0 exempt "
        + "(\(tests.count) budget test(s) in \(try Self.scan.get().files.count) test files)")

    #expect(!listed.isEmpty, "the contract lists no hot path for Swift")
    let missing = try Self.findings([.missing])
    #expect(missing.isEmpty, "\(missing)")
  }

  @Test(
    "every budget test asserts against its declared constant, and runs",
    .enabled(if: HotPathsCheckout.isPresentOrRequired, HotPathsCheckout.note))
  func everyBudgetHolds() throws {
    let broken = try Self.findings([.unasserted, .undeclared, .switchedOff])

    #expect(broken.isEmpty, "\(broken)")
  }

  @Test(
    "every budget test names a hot path the contract lists for Swift",
    .enabled(if: HotPathsCheckout.isPresentOrRequired, HotPathsCheckout.note))
  func everyBudgetIsListed() throws {
    let unlisted = try Self.findings([.unregistered])

    #expect(unlisted.isEmpty, "\(unlisted)")
  }

  /// The walk's own control: a test package the scan missed would leave its budgets unread, and an
  /// empty set holds no budget and breaks no rule.
  @Test("the scan reads every test target and every test package under Tests/")
  func readsEveryScope() throws {
    let files = try Self.scan.get().files
    let manifest = try PackageTree.manifest.get()
    let scopes =
      manifest.targets.filter { $0.type == "test" }.map { "\($0.path)/" } + [
        "Tests/MountayaElementsTests/Renderer/", "Tests/MountayaNavigationTests/Speech/",
      ]

    #expect(scopes.count > 4)
    for scope in scopes {
      #expect(files.contains { $0.hasPrefix(scope) }, "no Swift file read under \(scope)")
    }
    #expect(try !Self.scan.get().tests.isEmpty, "the scan found no budget test at all")
  }
}

/// HotPathsCheckout is `sdk/hot-paths.yaml` in the contract checkout (`ContractCheckout`), tolerated
/// as absent on a contributor's machine, where the gate is skipped with a note saying so, and
/// refused in CI, so a green CI run always means the list was read.
enum HotPathsCheckout {
  /// The list's path in the checkout.
  static let path = "sdk/hot-paths.yaml"

  /// What a run skipped for want of the list says, and what a run that needs it says.
  static let note = ContractCheckout.note(path)
  static let missing = ContractCheckout.missing(path)

  /// isPresentOrRequired is true where the gate runs: where the list is there, and in CI, where
  /// its absence fails it.
  static var isPresentOrRequired: Bool {
    ContractCheckout.isPresentOrRequired(path)
  }

  /// locate returns the list's address, or nil where the checkout holds none.
  static func locate() -> URL? {
    ContractCheckout.locate(path)
  }
}
