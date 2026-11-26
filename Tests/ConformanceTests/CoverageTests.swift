import Foundation
import GateSupport
import Testing

/// The two-way gate between the registry and the runners, and the gate between the names the
/// registry publishes and the public API. Each direction is a test of its own, so a failure says
/// which half broke.
@Suite("Coverage")
struct CoverageTests {
  private func registry() throws -> Registry? {
    try Conformance.contract.get()?.registry
  }

  @Test("every capability has a runner or a scope sentence")
  func everyCapabilityIsRunOrScoped() throws {
    guard let registry = try registry() else { return }
    let missing = Coverage.missingRunners(registry: registry, runners: Conformance.runners)
    let scoped = Conformance.scoped.count
    let run = registry.capabilities.count - scoped - missing.count

    #expect(
      missing.isEmpty,
      """
      \(missing.count) of \(registry.capabilities.count) capabilities have no runner \
      (\(run) run, \(scoped) scoped):
      \(missing.map { "  " + $0 }.joined(separator: "\n"))
      """
    )
  }

  /// A fixture proves what a rule answers and never what it is called, so the names a consumer
  /// calls are held here, as the registry's `swift` column spells them, against the API baselines
  /// BoundaryTests holds to the compiler's (SPEC.md sections 5 and 7).
  @Test("every published name is declared, or its capability scoped")
  func everyPublishedNameIsDeclared() throws {
    guard let registry = try registry() else { return }
    // The control is the read's own: a baseline read to nothing declares nothing.
    let declared = try Coverage.declaredNames()
    let names = Coverage.publishedNames(registry: registry)
    let missing = Coverage.undeclaredNames(registry: registry, declared: declared)

    #expect(!names.isEmpty, "the registry's `swift` column names nothing, so this holds nothing")
    #expect(
      missing.isEmpty,
      """
      \(missing.count) of \(names.count) names the registry's `swift` column publishes are \
      declared by no product's API baseline at that path:
      \(missing.map { "  " + $0 }.joined(separator: "\n"))
      """
    )
  }

  @Test("the registry's `swift` column says `scoped` exactly where the scope table scopes")
  func swiftColumnFollowsTheScopes() throws {
    guard let registry = try registry() else { return }
    let disagreements = Coverage.scopeDisagreements(registry: registry)

    #expect(
      disagreements.isEmpty,
      """
      the registry's `swift` column and the scope table of SPEC.md section 11 disagree:
      \(disagreements.map { "  " + $0 }.joined(separator: "\n"))
      """
    )
  }

  @Test("no capability has two runners")
  func noCapabilityIsRunTwice() {
    let duplicated = Coverage.duplicateRunners(runners: Conformance.runners)

    #expect(duplicated.isEmpty, "claimed by more than one runner: \(duplicated)")
  }

  @Test("every runner proves a capability the registry declares")
  func everyRunnerIsDeclared() throws {
    guard let registry = try registry() else { return }
    let unknown = Coverage.unknownRunners(registry: registry, runners: Conformance.runners)

    #expect(unknown.isEmpty, "runners for ids the registry does not declare: \(unknown)")
  }

  @Test("no runner proves a capability the scope table says is not implemented")
  func noScopedCapabilityIsRun() throws {
    guard let registry = try registry() else { return }
    let scoped = Coverage.scopedRunners(registry: registry, runners: Conformance.runners)

    #expect(scoped.isEmpty, "both scoped and run: \(scoped)")
  }

  @Test("a capability a consumer calls is proven through a plain import")
  func publicCapabilitiesRunThroughThePublicTable() throws {
    guard let registry = try registry() else { return }
    let internalOnes = Coverage.internalRunnersOfPublicCapabilities(
      registry: registry,
      runners: Conformance.runners
    )

    #expect(internalOnes.isEmpty, "`api: true` and run from `Runners/Internal/`: \(internalOnes)")
  }

  @Test("each table holds the runners of its own directory")
  func tablesHoldTheirOwnRunners() {
    #expect(PublicRunners.all.allSatisfy { $0.table == .public })
    #expect(InternalRunners.all.allSatisfy { $0.table == .internal })
  }

  @Test("no file of the public table reaches an internal")
  func publicTableImportsPlainly() throws {
    let root = try #require(SourceTree.packageRoot(from: #filePath))
    let directory = root.appendingPathComponent("Tests/ConformanceTests/Runners/Public")
    let files = SourceTree.swiftFiles(under: directory)
    try #require(!files.isEmpty)

    for file in files {
      let text = try #require(SourceTree.read(directory.appendingPathComponent(file)))
      let tokens = SwiftLexer.lex(text).tokens

      #expect(
        !tokens.contains { $0.text == "@testable" },
        "Runners/Public/\(file) uses `@testable`, which lets it reach what a consumer cannot"
      )
    }
  }
}
