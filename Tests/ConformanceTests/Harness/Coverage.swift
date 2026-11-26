import Foundation
import GateSupport

/// Coverage holds the runners to the registry, in both directions, and the public API to the
/// names it publishes.
///
/// The registry is the port manifest, and there is no other: every capability it declares has
/// exactly one runner here or a scope sentence, every runner and every scope rule names
/// something it declares, every name its `swift` column publishes for a capability this SDK does
/// not scope is a declaration of a product's API baseline, and the column says `scoped` exactly
/// where the scope table scopes.
enum Coverage {
  /// missingRunners lists the capabilities that are neither scoped nor run.
  static func missingRunners(
    registry: Registry,
    runners: [Runner],
    scope: [Scope.Rule] = Scope.rules
  ) -> [String] {
    let run = Set(runners.map(\.id))
    return registry.capabilities
      .filter { Scope.rule(for: $0, in: scope) == nil && !run.contains($0.id) }
      .map(\.id)
  }

  /// publishedNames lists the names the registry's `swift` column publishes for the capabilities
  /// this SDK does not scope, as `<id>: <name>`, each of which a product declares.
  static func publishedNames(registry: Registry, scope: [Scope.Rule] = Scope.rules) -> [String] {
    registry.capabilities
      .filter { Scope.rule(for: $0, in: scope) == nil }
      .flatMap { capability in swiftNames(of: capability).map { "\(capability.id): \($0)" } }
  }

  /// undeclaredNames lists the names of `publishedNames` that no declaration of the API baselines
  /// stands at exactly.
  static func undeclaredNames(
    registry: Registry,
    declared: PublishedNames,
    scope: [Scope.Rule] = Scope.rules
  ) -> [String] {
    registry.capabilities
      .filter { Scope.rule(for: $0, in: scope) == nil }
      .flatMap { capability in
        swiftNames(of: capability).filter { !declared.declares($0) }
          .map { "\(capability.id): \($0)" }
      }
  }

  /// scopeDisagreements lists the capabilities whose `swift` column and scope table disagree, a
  /// column that says `scoped` where the table runs the capability, or that lists names where the
  /// table scopes it, each as `<id>: <what the column says>`.
  static func scopeDisagreements(registry: Registry, scope: [Scope.Rule] = Scope.rules)
    -> [String]
  {
    registry.capabilities.compactMap { capability in
      let scoped = Scope.rule(for: capability, in: scope) != nil
      switch capability.published?.swift {
      case .scoped where !scoped:
        return "\(capability.id): `swift: scoped`, and the scope table runs it"
      case .names where scoped:
        return "\(capability.id): names under `swift`, and the scope table scopes it"
      default:
        return nil
      }
    }
  }

  /// reportedNames is the report's `published` member: for every capability whose `swift` column
  /// is a list, the names of it the API baselines declare, in the column's order, none where they
  /// declare none, so the report equals the column where every name is declared.
  static func reportedNames(registry: Registry, declared: PublishedNames) -> [String: [String]] {
    var reported: [String: [String]] = [:]
    for capability in registry.capabilities {
      guard case .names(let names)? = capability.published?.swift else { continue }
      reported[capability.id] = names.filter(declared.declares)
    }
    return reported
  }

  /// declaredNames reads the five API baselines BoundaryTests holds to the compiler's (SPEC.md
  /// section 7), the admin unit's beside the core's as the contract asks (`sdk/SPEC.md` §9), and
  /// refuses a set of them read to nothing, which would declare nothing and name every name.
  static func declaredNames() throws -> PublishedNames {
    guard let root = SourceTree.packageRoot(from: #filePath) else {
      throw FixtureError(description: "no Package.swift above \(#filePath)")
    }
    let directory = root.appendingPathComponent("Tests/BoundaryTests/Baseline")
    let files = ((try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? [])
      .filter { $0.hasSuffix(".txt") }.sorted()
    let baselines = files.compactMap { SourceTree.read(directory.appendingPathComponent($0)) }
    let declared = PublishedNames(baselines: baselines)
    guard files.count == 5, baselines.count == 5, declared.count > 0 else {
      throw FixtureError(
        description: "\(baselines.count) of the five API baselines under \(directory.path) read")
    }
    return declared
  }

  /// swiftNames is what a capability's `swift` column lists, none where it is scoped or the entry
  /// states no column.
  private static func swiftNames(of capability: Registry.Capability) -> [String] {
    guard case .names(let names)? = capability.published?.swift else { return [] }
    return names
  }

  /// duplicateRunners lists the capabilities more than one runner claims.
  static func duplicateRunners(runners: [Runner]) -> [String] {
    var seen: Set<String> = []
    var duplicated: Set<String> = []
    for runner in runners where !seen.insert(runner.id).inserted {
      duplicated.insert(runner.id)
    }
    return duplicated.sorted()
  }

  /// unknownRunners lists the runners for an id the registry does not declare, each of which
  /// proves a rule the contract does not state.
  static func unknownRunners(registry: Registry, runners: [Runner]) -> [String] {
    let declared = Set(registry.capabilities.map(\.id))
    return Set(runners.map(\.id)).subtracting(declared).sorted()
  }

  /// scopedRunners lists the runners for a capability the scope table says is not implemented.
  static func scopedRunners(
    registry: Registry,
    runners: [Runner],
    scope: [Scope.Rule] = Scope.rules
  ) -> [String] {
    let run = Set(runners.map(\.id))
    return registry.capabilities
      .filter { Scope.rule(for: $0, in: scope) != nil && run.contains($0.id) }
      .map(\.id)
  }

  /// internalRunnersOfPublicCapabilities lists the `api: true` capabilities whose runner
  /// reaches internals, which proves nothing about what a consumer can call.
  static func internalRunnersOfPublicCapabilities(registry: Registry, runners: [Runner])
    -> [String]
  {
    let published = Set(registry.capabilities.filter(\.api).map(\.id))
    return runners.filter { $0.table == .internal && published.contains($0.id) }.map(\.id).sorted()
  }

  /// unusedScopeRules lists the scope rules that scope nothing the registry declares.
  static func unusedScopeRules(registry: Registry, scope: [Scope.Rule] = Scope.rules) -> [String] {
    scope.filter { rule in
      !registry.capabilities.contains { Scope.rule(for: $0, in: [rule]) != nil }
    }.map(\.bullet)
  }
}
