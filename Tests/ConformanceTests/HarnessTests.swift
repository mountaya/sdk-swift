import Foundation
import GateSupport
import Testing

/// Tests of the harness itself: a gate that cannot fail proves nothing, so each of its
/// decisions is exercised here with a planted disagreement.
@Suite("Harness")
struct HarnessTests {
  private func json(_ text: String) throws -> OrderedJSON {
    try OrderedJSON.parse(text)
  }

  // MARK: Comparison

  @Test("with no tolerance a number compares exactly")
  func exactComparison() throws {
    #expect(Comparison.mismatches(actual: .number(1), expected: .number(1), tolerance: nil).isEmpty)
    #expect(
      Comparison.mismatches(actual: .number(1.000_000_000_1), expected: .number(1), tolerance: nil)
        .count == 1
    )
  }

  @Test("a relative tolerance scales by the expected value, so an expected zero is exact")
  func relativeTolerance() {
    let tolerance = Tolerance(kind: .relative, value: 1e-9)

    #expect(tolerance.accepts(actual: 111_194.926_6, expected: 111_194.926_600_05))
    #expect(!tolerance.accepts(actual: 111_194.93, expected: 111_194.926_6))
    #expect(tolerance.accepts(actual: 0, expected: 0))
    #expect(tolerance.accepts(actual: -0.0, expected: 0))
    #expect(!tolerance.accepts(actual: 1e-300, expected: 0))
    #expect(!tolerance.accepts(actual: .nan, expected: 1))
  }

  @Test("an absolute tolerance is a distance")
  func absoluteTolerance() {
    let tolerance = Tolerance(kind: .absolute, value: 0.5)

    #expect(tolerance.accepts(actual: 10.5, expected: 10))
    #expect(!tolerance.accepts(actual: 10.6, expected: 10))
    #expect(tolerance.accepts(actual: 0.4, expected: 0))
  }

  @Test("an angular tolerance is a distance taken the short way round 360 degrees")
  func angularTolerance() {
    let tolerance = Tolerance(kind: .angular, value: 0.1)

    #expect(tolerance.accepts(actual: 359.95, expected: 0))
    #expect(tolerance.accepts(actual: 0.05, expected: 359.98))
    #expect(tolerance.accepts(actual: 370, expected: 10))
    #expect(tolerance.accepts(actual: -5, expected: 355))
    #expect(tolerance.accepts(actual: 10.05, expected: 10))
    #expect(!tolerance.accepts(actual: 10.2, expected: 10))
    #expect(!tolerance.accepts(actual: 180, expected: 0))
    #expect(!tolerance.accepts(actual: 359.8, expected: 0))
  }

  @Test("a number that is not finite agrees with itself alone, under any tolerance")
  func nonFiniteNumbers() {
    let tolerances: [Tolerance?] = [
      nil, Tolerance(kind: .absolute, value: 1e300), Tolerance(kind: .relative, value: 1),
      Tolerance(kind: .angular, value: 180),
    ]
    for tolerance in tolerances {
      #expect(Comparison.agrees(actual: .nan, expected: .nan, tolerance: tolerance))
      #expect(Comparison.agrees(actual: .infinity, expected: .infinity, tolerance: tolerance))
      #expect(Comparison.agrees(actual: -.infinity, expected: -.infinity, tolerance: tolerance))
      #expect(!Comparison.agrees(actual: -.infinity, expected: .infinity, tolerance: tolerance))
      #expect(!Comparison.agrees(actual: .nan, expected: .infinity, tolerance: tolerance))
      #expect(!Comparison.agrees(actual: 1, expected: .nan, tolerance: tolerance))
      #expect(!Comparison.agrees(actual: .nan, expected: 1, tolerance: tolerance))
      #expect(!Comparison.agrees(actual: 1e308, expected: .infinity, tolerance: tolerance))
    }
    #expect(
      Comparison.mismatches(actual: .number(.nan), expected: .number(.nan), tolerance: nil).isEmpty
    )
  }

  @Test("a number JSON cannot carry is decoded in an input and in an expectation")
  func decodesNonFiniteNumbers() throws {
    let fixture = try Fixture.parse(
      #"{"capability": "geo.sample", "cases": [{"name": "one", "input": {"at": {"$number": "NaN"}, "list": [{"$number": "-Infinity"}, 2]}, "expect": {"$number": "Infinity"}}]}"#,
      path: "geo/sample.json"
    )
    let only = try #require(fixture.cases.first)

    #expect(only.input["at"]?.numberValue?.isNaN == true)
    #expect(only.input["list"]?.elements?.first?.numberValue == -.infinity)
    #expect(only.input["list"]?.elements?.last?.numberValue == 2)
    #expect(only.expect.numberValue == .infinity)
    #expect(fixture.document["cases"]?.elements?.first?["expect"]?.numberValue == .infinity)
  }

  @Test("a declared constant is held to the rule's number or value, and an input to nothing")
  func holdsDeclaredConstants() throws {
    let fixture = try Fixture.parse(
      ##"{"capability": "geo.sample", "constants": {"limit": 5, "ramp": [{"color": "#66BB6A", "degrees": 0}], "referenceDate": "2026-03-14T00:00:00Z"}, "cases": [{"name": "one", "input": {}, "expect": null}]}"##,
      path: "geo/sample.json"
    )
    let ramp = try json(##"[{"color": "#66BB6A", "degrees": 0}]"##)

    try fixture.holdConstants(["limit": 5], values: ["ramp": ramp], inputs: ["referenceDate"])
    #expect(throws: FixtureError.self) {
      try fixture.holdConstants(
        ["limit": 5], values: ["ramp": try json(##"[{"color": "#66bb6a", "degrees": 0}]"##)],
        inputs: ["referenceDate"])
    }
    #expect(throws: FixtureError.self) {
      try fixture.holdConstants(["limit": 5], values: ["ramp": ramp])
    }
    #expect(throws: FixtureError.self) {
      try fixture.holdConstants(
        ["limit": 5], values: ["ramp": ramp], inputs: ["referenceDate", "timeZone"])
    }
  }

  @Test("a tolerance is read from a fixture, and an unknown kind is refused")
  func readsTolerance() throws {
    #expect(
      Tolerance(try json(#"{"kind": "relative", "value": 1e-9}"#))
        == Tolerance(kind: .relative, value: 1e-9)
    )
    #expect(
      Tolerance(try json(#"{"kind": "angular", "value": 0.1}"#))
        == Tolerance(kind: .angular, value: 0.1)
    )
    #expect(
      Tolerance(try json(#"{"kind": "absolute", "value": 1e-9}"#))
        == Tolerance(kind: .absolute, value: 1e-9)
    )
    #expect(Tolerance(try json(#"{"kind": "ulp", "value": 4}"#)) == nil)
    #expect(Tolerance(try json(#"{"kind": "relative"}"#)) == nil)
  }

  @Test("a mismatch is named by its path")
  func namesThePath() throws {
    let expected = try json(#"{"a": [1, {"b": 2.0, "c": null}], "d": "x"}"#)
    let actual = try json(#"{"d": "y", "a": [1, {"b": 2.5, "e": 1}]}"#)
    let found = Comparison.mismatches(actual: actual, expected: expected, tolerance: nil)

    #expect(found.count == 4)
    #expect(found.contains { $0.hasPrefix("$.a[1].b: 2.5, expected 2") })
    #expect(found.contains { $0.hasPrefix("$.a[1].c: absent") })
    #expect(found.contains { $0.hasPrefix("$.a[1].e: 1, expected no such key") })
    #expect(found.contains { $0.hasPrefix("$.d: \"y\", expected \"x\"") })
  }

  @Test("null is not an absent key, and an array compares by position")
  func nullAndOrder() throws {
    #expect(
      Comparison.mismatches(
        actual: try json(#"{"a": null}"#),
        expected: try json("{}"),
        tolerance: nil
      ).count == 1
    )
    #expect(
      Comparison.mismatches(
        actual: try json("[1, 2]"), expected: try json("[2, 1]"), tolerance: nil
      )
      .count == 2
    )
    #expect(
      Comparison.mismatches(actual: try json("[1]"), expected: try json("[1, 2]"), tolerance: nil)
        .count == 1
    )
  }

  @Test("a refusal is read in the one spelling the fixtures use, `refused` and its class")
  func refusalSpellings() throws {
    #expect(
      Comparison.expectedRefusal(in: try json(#"{"refused": "SelectionError"}"#))
        == "SelectionError")
    #expect(Comparison.expectedRefusal(in: try json(#"{"refused": null}"#)) == nil)
    #expect(
      Comparison.expectedRefusal(in: try json(#"{"error": "ConfigurationError", "throws": true}"#))
        == nil
    )
    // A value that happens to carry the key beside others is compared whole, as a value.
    #expect(Comparison.expectedRefusal(in: try json(#"{"headers": {}, "refused": null}"#)) == nil)
    #expect(Comparison.expectedRefusal(in: try json(#"{"headers": {}, "refused": "X"}"#)) == nil)
    #expect(Comparison.expectedRefusal(in: try json(#"{"error": "X", "throws": false}"#)) == nil)
    #expect(Comparison.expectedRefusal(in: try json(#""SelectionError""#)) == nil)
  }

  // MARK: Running a case

  private func fixture(expect: String, tolerance: String? = nil) throws -> (Fixture, FixtureCase) {
    let toleranceMember = tolerance.map { #", "tolerance": \#($0)"# } ?? ""
    let fixture = try Fixture.parse(
      #"{"capability": "geo.sample", "description": "d"\#(toleranceMember), "cases": [{"name": "one", "input": 1, "expect": \#(expect)}]}"#,
      path: "geo/sample.json"
    )
    return (fixture, try #require(fixture.cases.first))
  }

  private func run(_ outcome: RunnerOutcome, expect: String, tolerance: String? = nil) async throws
    -> [String]
  {
    let (fixture, fixtureCase) = try fixture(expect: expect, tolerance: tolerance)
    let runner = Runner(id: "geo.sample", table: .public) { _, _ in outcome }
    return await Conformance.run(runner, fixture: fixture, fixtureCase: fixtureCase)
  }

  @Test("a case passes on the expected value and on the expected refusal")
  func passingCases() async throws {
    #expect(try await run(.value(.number(2)), expect: "2").isEmpty)
    #expect(
      try await run(
        .value(.number(2.000_000_000_1)),
        expect: "2",
        tolerance: #"{"kind": "relative", "value": 1e-9}"#
      ).isEmpty
    )
    #expect(
      try await run(.refused("SelectionError"), expect: #"{"refused": "SelectionError"}"#).isEmpty)
  }

  @Test("a planted disagreement fails the case")
  func failingCases() async throws {
    #expect(try await run(.value(.number(3)), expect: "2").count == 1)
    #expect(
      try await run(.refused("ConnectionError"), expect: #"{"refused": "SelectionError"}"#).count
        == 1)
    #expect(try await run(.refused("SelectionError"), expect: "2").count == 1)
    #expect(try await run(.value(.number(2)), expect: #"{"refused": "SelectionError"}"#).count == 1)
  }

  @Test(
    "values compared as a set pass in any order, and a missing, an extra or a twice-used one fails")
  func memberCases() async throws {
    let one = OrderedJSON.string("a")
    let two = OrderedJSON.string("b")
    #expect(try await run(.members([two, one]), expect: #"["a", "b"]"#).isEmpty)
    #expect(try await run(.members([one]), expect: #"["a", "b"]"#).count == 1)
    #expect(try await run(.members([one, two, two]), expect: #"["a", "b"]"#).count == 1)
    #expect(try await run(.members([one, one]), expect: #"["a", "a", "b"]"#).count == 1)
    #expect(try await run(.members([one]), expect: #""a""#).count == 1)
    #expect(try await run(.members([one]), expect: #"{"refused": "SelectionError"}"#).count == 1)
  }

  @Test("a runner that throws fails the case")
  func throwingRunner() async throws {
    struct Unexpected: Error {}
    let (fixture, fixtureCase) = try fixture(expect: "2")
    let runner = Runner(id: "geo.sample", table: .public) { _, _ in throw Unexpected() }

    #expect(await Conformance.run(runner, fixture: fixture, fixtureCase: fixtureCase).count == 1)
  }

  @Test(
    "a golden file that is not a fixture is refused",
    arguments: [
      "not json",
      #"{"description": "d", "cases": [{"name": "one", "input": 1, "expect": 1}]}"#,
      #"{"capability": "a.b", "cases": []}"#,
      #"{"capability": "a.b", "cases": [{"name": "one", "input": 1}]}"#,
      #"{"capability": "a.b", "cases": [{"name": "one", "input": 1, "expect": 1}, {"name": "one", "input": 2, "expect": 2}]}"#,
      #"{"capability": "a.b", "tolerance": {"kind": "ulp", "value": 1}, "cases": [{"name": "one", "input": 1, "expect": 1}]}"#,
      #"{"capability": "a.b", "cases": [{"name": "one", "input": {"$number": "nan"}, "expect": 1}]}"#,
      #"{"capability": "a.b", "cases": [{"name": "one", "input": 1, "expect": {"$number": 1}}]}"#,
      #"{"capability": "a.b", "cases": [{"name": "one", "input": {"$number": "NaN", "x": 1}, "expect": 1}]}"#,
    ]
  )
  func refusedFixtures(text: String) {
    #expect(throws: FixtureError.self) { try Fixture.parse(text, path: "a/b.json") }
  }

  @Test("an expected null is a value a case can carry")
  func expectedNull() throws {
    let (_, fixtureCase) = try fixture(expect: "null")

    #expect(fixtureCase.expect.isNull)
  }

  // MARK: Coverage

  private static let registry = Registry(
    version: 6,
    capabilities: [
      capability("transport.base-urls", layer: .transport, api: true),
      capability("transport.dates.reviver", layer: .transport, api: false),
      capability("transport.browser.secret-key", layer: .transport, api: true),
      capability("geo.geodesy.haversine", layer: .geo, api: true),
      capability("map.engine.patch", layer: .map, api: false),
      capability("studio.capabilities", layer: .studio, api: true),
    ]
  )

  private static func capability(_ id: String, layer: Registry.Layer, api: Bool)
    -> Registry.Capability
  {
    Registry.Capability(id: id, layer: layer, api: api, rule: "R.", fixture: "x/y.json", line: 1)
  }

  private func runner(_ id: String, table: RunnerTable = .public) -> Runner {
    Runner(id: id, table: table) { _, _ in .value(.null) }
  }

  @Test("a capability with neither a runner nor a scope sentence is missing, a map one included")
  func missingRunners() {
    #expect(
      Coverage.missingRunners(registry: Self.registry, runners: [])
        == [
          "transport.base-urls", "transport.dates.reviver", "geo.geodesy.haversine",
          "map.engine.patch",
        ]
    )
    #expect(
      Coverage.missingRunners(
        registry: Self.registry,
        runners: [
          runner("transport.base-urls"), runner("transport.dates.reviver", table: .internal),
          runner("geo.geodesy.haversine"), runner("map.engine.patch", table: .internal),
        ]
      ).isEmpty
    )
  }

  @Test("the scope table scopes the studio by layer and the browser's secret key by id alone")
  func scopeTable() {
    let scoped = Self.registry.capabilities.filter { Scope.rule(for: $0) != nil }.map(\.id)

    #expect(scoped == ["transport.browser.secret-key", "studio.capabilities"])
    #expect(
      Scope.rules.map(\.subject) == [.layer(.studio), .id("transport.browser.secret-key")]
    )
  }

  @Test("a runner the registry does not declare, a second runner and a scoped one are each found")
  func strayRunners() {
    let runners = [
      runner("transport.base-urls"), runner("transport.base-urls"), runner("geo.dropped"),
      runner("studio.capabilities"), runner("transport.browser.secret-key"),
    ]

    #expect(Coverage.duplicateRunners(runners: runners) == ["transport.base-urls"])
    #expect(Coverage.unknownRunners(registry: Self.registry, runners: runners) == ["geo.dropped"])
    #expect(
      Coverage.scopedRunners(registry: Self.registry, runners: runners)
        == ["transport.browser.secret-key", "studio.capabilities"]
    )
  }

  @Test("an `api: true` capability run from the internal table is found")
  func internalRunnerOfAPublicCapability() {
    let runners = [
      runner("transport.base-urls", table: .internal),
      runner("transport.dates.reviver", table: .internal),
    ]

    #expect(
      Coverage.internalRunnersOfPublicCapabilities(registry: Self.registry, runners: runners)
        == ["transport.base-urls"]
    )
  }

  /// entry is an `api: true` capability whose `swift` column is `swift`, every other column
  /// naming one name.
  private static func entry(
    _ id: String, layer: Registry.Layer, swift: Registry.Column?
  ) -> Registry.Capability {
    Registry.Capability(
      id: id, layer: layer, api: true, rule: "R.", fixture: "x/y.json",
      published: swift.map {
        Registry.Published(
          typescript: .names(["A"]), dart: .names(["A"]), swift: $0, kotlin: .names(["A"]))
      },
      line: 1)
  }

  private static let declared = PublishedNames(baselines: [
    "haversineMeters(from:to:)  func haversineMeters(from: [Double], to: [Double]) -> Double",
    "MapEngine.features(at:)  @MainActor func features(at point: [Double]) -> [QueriedFeature]",
  ])

  @Test("a `swift` name no baseline declares at that path is found, and a scoped one's never")
  func undeclaredNames() {
    let registry = Registry(
      version: 6,
      capabilities: [
        Self.entry(
          "geo.geodesy.haversine", layer: .geo,
          swift: .names(["haversineMeters(from:to:)", "haversineMeters", "earthRadius"])),
        Self.entry("map.query.layers", layer: .map, swift: .names(["MapEngine.features(at:)"])),
        Self.entry(
          "transport.browser.secret-key", layer: .transport, swift: .names(["SecretKeyRefusal"])),
        Self.entry("studio.capabilities", layer: .studio, swift: .scoped),
        Self.entry("transport.dates.reviver", layer: .transport, swift: nil),
      ]
    )

    #expect(
      Coverage.publishedNames(registry: registry)
        == [
          "geo.geodesy.haversine: haversineMeters(from:to:)",
          "geo.geodesy.haversine: haversineMeters", "geo.geodesy.haversine: earthRadius",
          "map.query.layers: MapEngine.features(at:)",
        ])
    // A name is held at its exact path: the function's base name alone is no declaration.
    #expect(
      Coverage.undeclaredNames(registry: registry, declared: Self.declared)
        == ["geo.geodesy.haversine: haversineMeters", "geo.geodesy.haversine: earthRadius"])
  }

  @Test("a `swift` column saying `scoped` where the table runs, or naming where it scopes, fails")
  func scopeDisagreements() {
    let registry = Registry(
      version: 6,
      capabilities: [
        Self.entry("geo.geodesy.haversine", layer: .geo, swift: .scoped),
        Self.entry("map.query.layers", layer: .map, swift: .names(["MapEngine.features(at:)"])),
        Self.entry(
          "transport.browser.secret-key", layer: .transport, swift: .names(["SecretKeyRefusal"])),
        Self.entry("studio.capabilities", layer: .studio, swift: .scoped),
        Self.entry("transport.dates.reviver", layer: .transport, swift: nil),
      ]
    )

    #expect(
      Coverage.scopeDisagreements(registry: registry)
        == [
          "geo.geodesy.haversine: `swift: scoped`, and the scope table runs it",
          "transport.browser.secret-key: names under `swift`, and the scope table scopes it",
        ])
  }

  @Test("the report holds each `swift` list's declared names in order, and no scoped or absent one")
  func reportedNames() {
    let registry = Registry(
      version: 6,
      capabilities: [
        Self.entry(
          "map.query.layers", layer: .map,
          swift: .names(["MapEngine.zones(at:)", "MapEngine.features(at:)"])),
        Self.entry(
          "geo.geodesy.haversine", layer: .geo,
          swift: .names(["haversineMeters(from:to:)", "haversineMeters"])),
        Self.entry("geo.absent", layer: .geo, swift: .names(["absent"])),
        Self.entry("studio.capabilities", layer: .studio, swift: .scoped),
        Self.entry("transport.dates.reviver", layer: .transport, swift: nil),
      ]
    )

    #expect(
      Coverage.reportedNames(registry: registry, declared: Self.declared)
        == [
          "map.query.layers": ["MapEngine.features(at:)"],
          "geo.geodesy.haversine": ["haversineMeters(from:to:)"],
          "geo.absent": [],
        ])
  }

  @Test("a scope rule that scopes nothing is found")
  func unusedScopeRule() {
    let rules = Scope.rules + [Scope.Rule(subject: .id("geo.absent"), bullet: "No such thing.")]

    #expect(Coverage.unusedScopeRules(registry: Self.registry).isEmpty)
    #expect(Coverage.unusedScopeRules(registry: Self.registry, scope: rules) == ["No such thing."])
  }

  // MARK: Report

  @Test("the report is rendered with sorted keys, two spaces and a trailing newline")
  func rendersTheReport() {
    let rendered = ConformanceReport.render(
      registryVersion: 6,
      modelDigest: String(repeating: "0a", count: 32),
      statuses: ["transport.base-urls": .pass, "studio.capabilities": .scoped, "geo.x": .fail],
      published: [:]
    )

    #expect(
      rendered == """
        {
          "capabilities": {
            "geo.x": "fail",
            "studio.capabilities": "scoped",
            "transport.base-urls": "pass"
          },
          "modelDigest": "0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a0a",
          "published": {},
          "registryVersion": 6,
          "sdk": "swift"
        }

        """
    )
  }

  @Test("the report's names sit between its statuses and its version, ids sorted, names in order")
  func rendersThePublishedNames() {
    let rendered = ConformanceReport.render(
      registryVersion: 6,
      modelDigest: nil,
      statuses: ["map.query.layers": .pass],
      published: [
        "map.query.layers": ["MapEngine.zones(at:)", "MapEngine.features(at:)"],
        "geo.absent": [],
      ]
    )

    #expect(
      rendered == """
        {
          "capabilities": {
            "map.query.layers": "pass"
          },
          "published": {
            "geo.absent": [],
            "map.query.layers": [
              "MapEngine.zones(at:)",
              "MapEngine.features(at:)"
            ]
          },
          "registryVersion": 6,
          "sdk": "swift"
        }

        """
    )
  }

  @Test("a report on file in the checkout re-renders to the same bytes")
  func matchesTheContractsOwnFormat() throws {
    guard let contract = try Conformance.contract.get() else { return }
    let url = contract.checkout.directory.appendingPathComponent("sdk/reports/typescript.json")
    guard let onFile = SourceTree.read(url) else { return }
    let document = try OrderedJSON.parse(onFile)
    let version = try #require(document["registryVersion"]?.numberValue)
    var statuses: [String: ConformanceReport.Status] = [:]
    for member in try #require(document["capabilities"]?.members) {
      let name = try #require(member.value.stringValue)
      let status: ConformanceReport.Status = try #require(.init(rawValue: name))
      statuses[member.key] = status
    }
    var published: [String: [String]] = [:]
    for member in try #require(document["published"]?.members) {
      published[member.key] = try #require(member.value.elements).map {
        try #require($0.stringValue)
      }
    }

    #expect(
      ConformanceReport.render(
        sdk: "typescript", registryVersion: Int(version),
        modelDigest: document["modelDigest"]?.stringValue, statuses: statuses, published: published)
        == onFile
    )
  }
}
