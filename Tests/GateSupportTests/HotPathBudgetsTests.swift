import Foundation
import GateSupport
import Testing

/// The gate's scanner and its rules, held to planted sources: every rule is a filter over what the
/// scanner returns, and a scanner that returned nothing would agree with any list at all.
@Suite("HotPathBudgets")
struct HotPathBudgetsTests {
  private static let list = """
    # A comment before anything.
    paths:
      # ── every SDK ──
      - id: route-measure
        sdks: [typescript, dart, swift, kotlin]
        holds: >-
          A navigation reading fix after fix measures the route's line once, never once per
          fix.

      - id: channel-queries
        sdks: [dart]
        holds: >-
          A pointer over the live map costs one renderer query per frame.
    """

  /// paths is the planted list, read.
  private static func paths() throws -> [HotPathBudgets.Path] {
    try HotPathBudgets.parse(list)
  }

  // MARK: - The list

  @Test("it reads each path, the SDKs that budget it and the sentence of its budget")
  func readsTheList() throws {
    let paths = try Self.paths()

    #expect(paths.map(\.id) == ["route-measure", "channel-queries"])
    #expect(paths.first?.sdks == ["typescript", "dart", "swift", "kotlin"])
    #expect(
      paths.first?.holds
        == "A navigation reading fix after fix measures the route's line once, never once per fix.")
    #expect(paths.map(\.line) == [4, 10])
  }

  @Test("a list it does not recognise is refused at the line it stops on")
  func refusesWhatItDoesNotRead() {
    func refusal(_ text: String) -> HotPathsError? {
      do {
        _ = try HotPathBudgets.parse(text)
        return nil
      } catch {
        return error
      }
    }
    let entry = "paths:\n  - id: route-measure\n"

    #expect(refusal(entry + "    sdks: [swift, swift]\n    holds: >-\n      Once.")?.line == 3)
    #expect(refusal(entry + "    sdks: [swift, java]\n    holds: >-\n      Once.")?.line == 3)
    #expect(refusal(entry + "    sdks: swift\n    holds: >-\n      Once.")?.line == 3)
    #expect(refusal(entry + "    sdks: [swift]\n    holds: Once.")?.line == 4)
    #expect(refusal(entry + "    sdks: [swift]\n    budget: 3")?.line == 4)
    #expect(refusal(entry + "    sdks: [swift]")?.line == 2, "a path saying nothing it holds")
    #expect(refusal(entry + "    holds: >-\n      Once.")?.line == 2, "a path naming no SDK")
    #expect(refusal("paths:\n  - id: Route_Measure")?.line == 2)
    let twice = "  - id: route-measure\n    sdks: [dart]\n    holds: >-\n      Twice."
    #expect(
      refusal(entry + "    sdks: [swift]\n    holds: >-\n      Once.\n" + twice)?.line == 6,
      "a path listed twice")
    #expect(refusal("version: 1")?.line == 1)
    #expect(refusal("# nothing")?.message == "no `paths`")
  }

  @Test("a path's constant is its id in lowerCamelCase, then Budget")
  func constants() {
    #expect(HotPathBudgets.constant(of: "profile-cursor") == "profileCursorBudget")
    #expect(HotPathBudgets.constant(of: "hover-hit-test") == "hoverHitTestBudget")
    #expect(HotPathBudgets.constant(of: "pins") == "pinsBudget")
  }

  // MARK: - The scanner

  @Test("it finds a planted budget test with its assertion against its declared constant")
  func findsAPlantedTest() {
    // The positive control.
    let planted = """
      import Testing

      private let routeMeasureBudget = 1

      @Suite("Route")
      struct RouteTests {
        @Test("hot-path budget route-measure: sixty fixes measure the line once")
        func measuredOnce() throws {
          let measured = 1
          #expect(measured <= routeMeasureBudget, "measured \\(measured)")
        }
      }
      """

    #expect(
      HotPathBudgets.budgetTests(in: planted, file: "Planted.swift") == [
        HotPathBudgets.BudgetTest(
          id: "route-measure",
          title: "hot-path budget route-measure: sixty fixes measure the line once",
          file: "Planted.swift", line: 7, asserted: true, declared: true, switchedOff: nil)
      ])
  }

  @Test("it reports a planted test that asserts nothing, names another constant, or declares none")
  func reportsUnassertedAndUndeclared() {
    let planted = """
      private let hoverHitTestBudget = 1

      struct PlantedTests {
        private static let routeMeasureBudget = 1

        @Test("hot-path budget route-measure: counts but asserts nothing")
        func countsOnly() {
          let measured = routeMeasureBudget
          #expect(measured > 0)
        }

        @Test("hot-path budget hover-hit-test: asserts another path's constant")
        func another() {
          #expect(1 <= routeMeasureBudget)
        }

        @Test("hot-path budget hover-hit-test: hands its constant to an expectation")
        func held() {
          #expect(1 <= hoverHitTestBudget)
        }
      }
      // @Test("hot-path budget scrub-root: a title in a comment is no test")
      let words = "hot-path budget scrub-root: a string that titles no test"
      """
    let found = HotPathBudgets.budgetTests(in: planted, file: "Planted.swift")

    #expect(found.map(\.id) == ["route-measure", "hover-hit-test", "hover-hit-test"])
    #expect(found.map(\.asserted) == [false, false, true])
    #expect(
      found.map(\.declared) == [false, true, true],
      "a constant inside the suite is no top-level constant")
  }

  @Test("it reads a test switched off by its trait, its suite's, an extension's or a known issue")
  func readsSwitches() {
    let planted = """
      private let scrubRootBudget = 0

      @Suite("Running", .serialized)
      struct Running {
        @Test("hot-path budget scrub-root: runs", .timeLimit(.minutes(1)))
        func runs() { #expect(0 <= scrubRootBudget) }

        @Test("hot-path budget scrub-root: disabled", .disabled("later"))
        func disabled() { #expect(0 <= scrubRootBudget) }

        @Test("hot-path budget scrub-root: on a condition", .enabled(if: Gate.isOn, Gate.note))
        func conditional() { #expect(0 <= scrubRootBudget) }

        @Test("hot-path budget scrub-root: tied to a bug", .bug("https://example.com/1"))
        func bug() { #expect(0 <= scrubRootBudget) }

        @Test("hot-path budget scrub-root: a known issue")
        func known() {
          withKnownIssue { #expect(0 <= scrubRootBudget) }
        }
      }

      @Suite(.disabled("off"))
      struct Off {
        @MainActor
        struct Nested {
          @Test("hot-path budget scrub-root: under a disabled suite")
          func nested() { #expect(0 <= scrubRootBudget) }
        }
      }

      extension Off {
        @Test("hot-path budget scrub-root: in an extension of a disabled suite")
        func extended() { #expect(0 <= scrubRootBudget) }
      }

      extension Running {
        @Test("hot-path budget scrub-root: in an extension of a running suite")
        func alsoRuns() { #expect(0 <= scrubRootBudget) }
      }
      """
    let found = HotPathBudgets.budgetTests(in: planted, file: "Planted.swift")

    #expect(
      found.map {
        [String($0.title.dropFirst("hot-path budget scrub-root: ".count)), $0.switchedOff ?? "-"]
      }
        == [
          ["runs", "-"], ["disabled", ".disabled"], ["on a condition", ".enabled"],
          ["tied to a bug", ".bug"], ["a known issue", "withKnownIssue"],
          ["under a disabled suite", ".disabled"],
          ["in an extension of a disabled suite", ".disabled"],
          ["in an extension of a running suite", "-"],
        ])
    #expect(found.allSatisfy { $0.asserted && $0.declared })
  }

  @Test("a display name that titles no path, or not as kebab case, is no budget test")
  func titles() {
    let planted = """
      private let pinsBudget = 1
      @Test("hot-path budget Pins: capitals") func capitals() { #expect(1 <= pinsBudget) }
      @Test("hot-path budget pins two: a space") func spaced() { #expect(1 <= pinsBudget) }
      @Test("hot-path budget pins") func unclosed() { #expect(1 <= pinsBudget) }
      @Test func untitled() { #expect(1 <= pinsBudget) }
      @Test("hot-path budget pins: global") func global() { #expect(1 <= pinsBudget) }
      """

    #expect(
      HotPathBudgets.budgetTests(in: planted, file: "Planted.swift").map(\.title) == [
        "hot-path budget pins: global"
      ])
  }

  // MARK: - The rules

  /// test is a budget test of `id` as a scan reads it, live unless told otherwise.
  private static func test(
    _ id: String, asserted: Bool = true, declared: Bool = true, switchedOff: String? = nil
  ) -> HotPathBudgets.BudgetTest {
    HotPathBudgets.BudgetTest(
      id: id, title: "hot-path budget \(id): planted", file: "Planted.swift", line: 3,
      asserted: asserted, declared: declared, switchedOff: switchedOff)
  }

  @Test(
    "a path listed for Swift with a live budget test passes, and one for another SDK needs none")
  func passes() throws {
    #expect(
      HotPathBudgets.findings(paths: try Self.paths(), tests: [Self.test("route-measure")]).isEmpty)
  }

  @Test("every way a budget test fails to hold its path is a finding of its own")
  func failures() throws {
    let paths = try Self.paths()
    func kinds(_ tests: [HotPathBudgets.BudgetTest]) -> [HotPathBudgets.Finding.Kind] {
      HotPathBudgets.findings(paths: paths, tests: tests).map(\.kind)
    }

    #expect(kinds([]) == [.missing])
    #expect(kinds([Self.test("route-measure", asserted: false)]) == [.missing, .unasserted])
    #expect(kinds([Self.test("route-measure", declared: false)]) == [.missing, .undeclared])
    #expect(
      kinds([Self.test("route-measure", switchedOff: ".disabled")]) == [.missing, .switchedOff])
    #expect(
      kinds([Self.test("route-measure"), Self.test("dirty-tick")]) == [.unregistered],
      "a path the list does not hold")
    #expect(
      kinds([Self.test("route-measure"), Self.test("channel-queries")]) == [.unregistered],
      "a path the list holds for Dart alone")
    #expect(
      kinds([Self.test("route-measure"), Self.test("route-measure", switchedOff: ".bug")])
        == [.switchedOff], "a second test switched off fails though the first holds the path")
  }

  @Test("it reads every Swift file under the directory it is handed, by its path from the root")
  func walks() throws {
    let tree = try TemporaryTree()
    defer { tree.remove() }
    try tree.write(
      "Tests/A/RouteTests.swift",
      contents: """
        private let routeMeasureBudget = 1
        @Test("hot-path budget route-measure: planted") func once() { #expect(1 <= routeMeasureBudget) }
        """)
    try tree.write("Tests/Renderer/Views/ViewTests.swift", contents: "struct ViewTests {}")
    try tree.write(
      "Tests/Renderer/.build/Built.swift", contents: #"@Test("hot-path budget pins: built")"#)
    try tree.write(
      "Sources/Elsewhere.swift", contents: #"@Test("hot-path budget pins: elsewhere")"#)

    let scan = HotPathBudgets.scan(root: tree.root, directory: "Tests")

    #expect(scan.files == ["Tests/A/RouteTests.swift", "Tests/Renderer/Views/ViewTests.swift"])
    #expect(scan.tests.map(\.file) == ["Tests/A/RouteTests.swift"])
    #expect(scan.tests.map(\.line) == [2])
  }
}
