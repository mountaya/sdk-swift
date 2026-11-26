import Foundation
import GateSupport
import Testing

/// ConformanceCase is one case of one capability, which is one test.
struct ConformanceCase: Sendable, CustomTestStringConvertible {
  let capability: Registry.Capability
  let name: String

  /// The name a failure is reported under: the capability, then the case.
  var testDescription: String { "\(capability.id) · \(name)" }
}

/// ScopedCapability is one capability this SDK reports as `scoped`.
struct ScopedCapability: Sendable, CustomTestStringConvertible {
  let capability: Registry.Capability
  let rule: Scope.Rule

  var testDescription: String { "\(capability.id) · scoped" }
}

/// Conformance is the contract as this run sees it: the registry, the fixtures, and the
/// runners that answer them.
enum Conformance {
  /// The variable that narrows a run to the capabilities whose id starts with its value.
  static let onlyVariable = "MOUNTAYA_CONFORMANCE_ONLY"

  /// Contract is everything read from the checkout.
  struct Contract: Sendable {
    let checkout: ContractCheckout
    let registry: Registry
    let fixtures: [String: Fixture]
  }

  /// The checkout's contents, nil when there is no checkout, and a failure when there is one
  /// that cannot be read.
  static let contract: Result<Contract?, any Error> = Result(catching: { try load() })

  /// Every runner, from both tables.
  static let runners: [Runner] = PublicRunners.all + InternalRunners.all

  private static var loaded: Contract? {
    (try? contract.get()) ?? nil
  }

  private static var only: String? {
    let value = ProcessInfo.processInfo.environment[onlyVariable] ?? ""
    return value.isEmpty ? nil : value
  }

  /// One entry per case of every capability that has a runner.
  static let cases: [ConformanceCase] = {
    guard let contract = loaded else { return [] }
    let run = Set(runners.map(\.id))
    return contract.registry.capabilities
      .filter { capability in
        run.contains(capability.id) && (only.map { capability.id.hasPrefix($0) } ?? true)
      }
      .flatMap { capability in
        (contract.fixtures[capability.id]?.cases ?? []).map {
          ConformanceCase(capability: capability, name: $0.name)
        }
      }
  }()

  /// One entry per capability the scope table covers.
  static let scoped: [ScopedCapability] = {
    guard let contract = loaded else { return [] }
    return contract.registry.capabilities.compactMap { capability in
      Scope.rule(for: capability).map { ScopedCapability(capability: capability, rule: $0) }
    }
  }()

  private static func load() throws -> Contract? {
    guard let checkout = ContractCheckout.locate() else { return nil }
    guard let text = SourceTree.read(checkout.registryUrl) else {
      throw FixtureError(description: "sdk/registry.yaml cannot be read")
    }
    let registry = try Registry.parse(text)
    var fixtures: [String: Fixture] = [:]
    for capability in registry.capabilities {
      guard let text = SourceTree.read(checkout.fixtureUrl(capability)) else {
        throw FixtureError(description: "sdk/fixtures/\(capability.fixture) cannot be read")
      }
      let fixture = try Fixture.parse(text, path: capability.fixture)
      guard fixture.capability == capability.id else {
        throw FixtureError(
          description:
            "sdk/fixtures/\(capability.fixture) proves `\(fixture.capability)`, and the registry "
            + "names it for `\(capability.id)`"
        )
      }
      fixtures[capability.id] = fixture
    }
    return Contract(checkout: checkout, registry: registry, fixtures: fixtures)
  }

  /// run answers one case and returns every way the answer differs from the fixture's, which
  /// is empty when the case passes.
  static func run(_ item: ConformanceCase) async -> [String] {
    guard let contract = loaded, let fixture = contract.fixtures[item.capability.id],
      let fixtureCase = fixture.cases.first(where: { $0.name == item.name })
    else {
      return ["the fixture holds no such case"]
    }
    let matching = runners.filter { $0.id == item.capability.id }
    guard let runner = matching.first, matching.count == 1 else {
      return ["\(matching.count) runners claim this capability"]
    }
    return await run(runner, fixture: fixture, fixtureCase: fixtureCase)
  }

  /// run answers one case with a given runner. It is the comparison every case goes through,
  /// apart from where the runner and the fixture come from.
  static func run(_ runner: Runner, fixture: Fixture, fixtureCase: FixtureCase) async -> [String] {
    let outcome: RunnerOutcome
    do {
      outcome = try await runner.run(fixture, fixtureCase)
    } catch {
      return ["the runner threw \(error)"]
    }
    let expectedRefusal = Comparison.expectedRefusal(in: fixtureCase.expect)
    switch outcome {
    case .refused(let name):
      guard let expectedRefusal else {
        return ["refused with \(name), expected a value"]
      }
      return name == expectedRefusal ? [] : ["refused with \(name), expected \(expectedRefusal)"]
    case .value(let actual):
      if let expectedRefusal {
        return ["answered a value, expected a refusal with \(expectedRefusal)"]
      }
      return Comparison.mismatches(
        actual: actual,
        expected: fixtureCase.expect,
        tolerance: fixture.tolerance
      )
    case .members(let actual):
      if let expectedRefusal {
        return ["answered values, expected a refusal with \(expectedRefusal)"]
      }
      return Comparison.memberMismatches(
        actual: actual,
        expected: fixtureCase.expect,
        tolerance: fixture.tolerance
      )
    }
  }

  /// statuses answers every capability of the registry: `scoped` where the scope table says
  /// so, `pass` where every case passes, `fail` otherwise, a capability with no runner
  /// included.
  static func statuses(of contract: Contract) async -> [String: ConformanceReport.Status] {
    var statuses: [String: ConformanceReport.Status] = [:]
    for capability in contract.registry.capabilities {
      if Scope.rule(for: capability) != nil {
        statuses[capability.id] = .scoped
        continue
      }
      let matching = runners.filter { $0.id == capability.id }
      guard let runner = matching.first, matching.count == 1,
        let fixture = contract.fixtures[capability.id]
      else {
        statuses[capability.id] = .fail
        continue
      }
      var passed = true
      for fixtureCase in fixture.cases {
        let problems = await run(runner, fixture: fixture, fixtureCase: fixtureCase)
        passed = passed && problems.isEmpty
      }
      statuses[capability.id] = passed ? .pass : .fail
    }
    return statuses
  }
}
