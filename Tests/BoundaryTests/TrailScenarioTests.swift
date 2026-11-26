import Foundation
import GateSupport
import Testing

/// Trail held to the contract's `sdk/trail.yaml` (SPEC.md section 7): every step it lists for
/// Swift marked by the code under `Examples/Trail` that does it, every marker naming a step, no
/// value shaped as a key or a session token in a file under `Examples/` git commits, the demo
/// itinerary copied byte for byte, and the examples' licence beside them. The scan runs on every
/// host, Linux's among them; without the contract checkout the markers and the copy are skipped
/// with a note on a contributor's machine and fail in CI.
@Suite("Trail scenario")
struct TrailScenarioTests {
  /// path is the scenario's path in the contract checkout.
  static let path = "sdk/trail.yaml"

  /// scan is every committed file under `Examples/`, read once for the suite.
  private static let scan: Result<TrailScenario.Scan, any Error> = Result {
    guard let root = PackageTree.root else {
      throw PackageTree.Unreadable(description: "no Package.swift above \(#filePath)")
    }
    return TrailScenario.scan(root: root)
  }

  /// scenario is `sdk/trail.yaml` as the contract checkout holds it, read once for the suite.
  private static let scenario: Result<TrailScenario.Scenario, any Error> = Result {
    guard let file = ContractCheckout.locate(path) else {
      throw PackageTree.Unreadable(description: ContractCheckout.missing(path))
    }
    guard let text = SourceTree.read(file) else {
      throw PackageTree.Unreadable(description: "\(file.path) cannot be read")
    }
    return try TrailScenario.parse(text)
  }

  /// findings is what the real tree breaks of the scenario, of the kinds given, the scenario and
  /// the contract's itinerary read where `withContract` asks for them.
  private static func findings(
    _ kinds: Set<TrailScenario.Finding.Kind>, withContract: Bool
  ) throws -> String {
    let root = try #require(PackageTree.root)
    let itinerary = withContract ? ContractCheckout.locate(TrailScenario.itinerary) : nil
    return TrailScenario.findings(
      scenario: withContract ? try scenario.get() : nil, scan: try scan.get(),
      itinerary: itinerary.flatMap { FileManager.default.contents(atPath: $0.path) },
      copy: FileManager.default.contents(
        atPath: root.appendingPathComponent(TrailScenario.itineraryCopy).path),
      hasLicence: FileManager.default.fileExists(
        atPath: root.appendingPathComponent(TrailScenario.licence).path)
    )
    .filter { kinds.contains($0.kind) }
    .map { "\($0.file):\($0.line): \($0.message)" }
    .joined(separator: "\n")
  }

  @Test(
    "every step sdk/trail.yaml lists for Swift is marked by the code under Examples/Trail that does it",
    .enabled(if: ContractCheckout.isPresentOrRequired(path), ContractCheckout.note(path)))
  func everyStepIsMarked() throws {
    let scenario = try Self.scenario.get()
    let scan = try Self.scan.get()
    // Printed before the assertion, so the count is something a reader sees on a red run too.
    print(
      "trail-scenario: \(scenario.steps.count) steps of scenario \(scenario.version), "
        + "\(scan.markers.count) markers in \(scan.swiftFiles.count) Swift files, "
        + "\(scan.files.count) committed files read for a key")

    #expect(scenario.sdks.contains(TrailScenario.sdk), "sdk/trail.yaml does not list Swift")
    let unmarked = try Self.findings([.unmarked], withContract: true)
    #expect(unmarked.isEmpty, "\(unmarked)")
  }

  @Test(
    "every marker names a step of sdk/trail.yaml",
    .enabled(if: ContractCheckout.isPresentOrRequired(path), ContractCheckout.note(path)))
  func everyMarkerNamesAStep() throws {
    let unknown = try Self.findings([.unknownMarker], withContract: true)

    #expect(unknown.isEmpty, "\(unknown)")
  }

  @Test("no file under Examples/ git commits holds a value shaped as a key or a session token")
  func noCredentialIsCommitted() throws {
    let committed = try Self.findings([.credential], withContract: false)

    #expect(committed.isEmpty, "\(committed)")
  }

  @Test(
    "Trail's demo itinerary is the contract's sdk/trail/itinerary.json, byte for byte",
    .enabled(
      if: ContractCheckout.isPresentOrRequired(TrailScenario.itinerary),
      ContractCheckout.note(TrailScenario.itinerary)))
  func theItineraryIsTheContracts() throws {
    _ = try #require(
      ContractCheckout.locate(TrailScenario.itinerary),
      "\(ContractCheckout.missing(TrailScenario.itinerary))")
    let differs = try Self.findings([.itinerary], withContract: true)

    #expect(differs.isEmpty, "\(differs)")
  }

  @Test("the examples carry their licence")
  func theExamplesCarryTheirLicence() throws {
    let missing = try Self.findings([.licence], withContract: false)

    #expect(missing.isEmpty, "\(missing)")
  }

  /// The scan's own control: a scan that read nothing would find no credential and no marker naming
  /// no step, and the files it leaves unread must be the ones git ignores.
  @Test("the scan reads Trail's committed files, and skips only what .gitignore ignores")
  func readsWhatGitCommits() throws {
    let root = try #require(PackageTree.root)
    let scan = try Self.scan.get()
    let gitignore = try #require(SourceTree.read(root.appendingPathComponent(".gitignore")))
    let lines = Set(gitignore.split(separator: "\n").map(String.init))

    for read in [
      TrailScenario.itineraryCopy, "Examples/Trail/Config/Local.xcconfig.example",
      "Examples/Trail/Trail.xcodeproj/project.pbxproj", "Examples/Trail/Package.swift",
      "Examples/Trail/Session/Package.swift", TrailScenario.licence,
    ] {
      #expect(scan.files.contains(read), "the scan does not read \(read)")
    }
    #expect(scan.swiftFiles.contains { $0.hasPrefix("Examples/Trail/Session/") })
    #expect(!scan.files.contains(TrailScenario.ownSettings))
    #expect(!scan.files.contains { $0.contains("/.build/") || $0.contains("/xcuserdata/") })
    // What the scan leaves unread, .gitignore ignores.
    #expect(lines.contains(TrailScenario.ownSettings), "\(TrailScenario.ownSettings) is committed")
    #expect(lines.contains("!\(TrailScenario.committedProject)/"))
    for directory in TrailScenario.ignoredDirectories where directory != ".claude" {
      #expect(lines.contains("\(directory)/"), "\(directory)/ is not ignored")
    }
  }
}
