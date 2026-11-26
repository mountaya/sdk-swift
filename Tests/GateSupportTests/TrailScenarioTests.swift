import Foundation
import GateSupport
import Testing

/// The scenario gate's reader, its scanners and its rules, held to planted inputs: every rule is a
/// filter over what the scanners return, and a scanner that returned nothing would agree with any
/// scenario at all. A credential is planted by joining its parts as the test runs, so no file of
/// this repository holds one.
@Suite("TrailScenario")
struct TrailScenarioTests {
  private static let scenario = """
    # The scenario, cut down to every field the file holds.
    version: 1

    sdks: [dart, swift, kotlin]

    settings:
      - name: MOUNTAYA_PUBLISHABLE_KEY
        readers: [app, session-server]
        use: >-
          The organization's publishable key.

    steps:
      - id: trail.client
        does: >-
          One `Mountaya` client.

      - id: trail.no-key
        does: >-
          A notice.

    accessibility:
      - id: trail.notice
        marks: The notice.

    journey:
      settings: []
      checks:
        - target: trail.notice
          action: see

    measured:
      MOUNTAYA_PUBLISHABLE_KEY: pk_size_gate
    """

  /// planted is a credential's prefix followed by 32 lowercase hex characters.
  private static func planted(_ prefix: String) -> String {
    prefix + String(repeating: "0a1b", count: 8)
  }

  /// token is a session token as the studio reads one: `sess_`, a JSON payload as unpadded
  /// base64url, a `.` and a signature.
  private static func token() -> String {
    let payload = Data(#"{"surface":"api"}"#.utf8).base64EncodedString()
      .replacingOccurrences(of: "=", with: "").replacingOccurrences(of: "+", with: "-")
      .replacingOccurrences(of: "/", with: "_")
    return "sess_" + payload + ".c2lnbmF0dXJl"
  }

  // MARK: - The scenario

  @Test("it reads the version, the SDKs and the steps, and passes over every other field")
  func readsTheScenario() throws {
    let read = try TrailScenario.parse(Self.scenario)

    #expect(read.version == 1)
    #expect(read.sdks == ["dart", "swift", "kotlin"])
    #expect(read.steps.map(\.id) == ["trail.client", "trail.no-key"])
    #expect(read.steps.map(\.line) == [13, 17])
  }

  @Test("a file it does not recognise is refused at the line it stops on")
  func refusesWhatItDoesNotRead() {
    func refusal(_ text: String) -> TrailScenarioError? {
      do {
        _ = try TrailScenario.parse(text)
        return nil
      } catch {
        return error
      }
    }
    let head = "version: 1\nsdks: [swift]\n"

    #expect(refusal(head + "steps:\n  - id: trail.map\n") == nil)
    #expect(refusal(head + "steps:\n  - id: Trail.Map\n")?.line == 4)
    #expect(refusal(head + "steps:\n  - id: trail.map\n  - id: trail.map\n")?.line == 5)
    #expect(refusal(head + "steps:\n  - does: nothing\n")?.line == 4)
    #expect(refusal(head + "screens:\n  - id: trail.map\n")?.line == 3)
    #expect(refusal("version: 0\nsdks: [swift]\nsteps:\n  - id: trail.map\n")?.line == 1)
    #expect(refusal("version: 1\nsdks: [swift, java]\nsteps:\n  - id: trail.map\n")?.line == 2)
    #expect(refusal("version: 1\nsdks: swift\nsteps:\n  - id: trail.map\n")?.line == 2)
    #expect(refusal("sdks: [swift]\nsteps:\n  - id: trail.map\n")?.message == "no `version`")
    #expect(refusal(head)?.message == "no `steps`")
    #expect(refusal(head + "steps:\n\t- id: trail.map\n")?.line == 4)
  }

  // MARK: - The markers

  @Test("a marker is a comment naming a step, and never a string or a sentence that mentions one")
  func readsTheMarkers() {
    let source = """
      // trail: trail.client
      let client = 1
      /// trail: trail.map
      /* trail: trail.search */
      let text = "// trail: trail.itinerary"
      // A sentence that says trail: trail.profile counts for nothing.
      func start() {
        // trail: trail.navigation and what follows
      }
      """

    #expect(
      TrailScenario.markers(in: source, file: "A.swift") == [
        TrailScenario.Marker(id: "trail.client", file: "A.swift", line: 1),
        TrailScenario.Marker(id: "trail.map", file: "A.swift", line: 3),
        TrailScenario.Marker(id: "trail.search", file: "A.swift", line: 4),
        TrailScenario.Marker(id: "trail.navigation", file: "A.swift", line: 8),
      ])
    #expect(TrailScenario.markers(in: "let x = 1", file: "B.swift").isEmpty)
  }

  // MARK: - The credentials

  @Test("a key or a session token is found in the shapes sdk/SPEC.md gives them, never echoed")
  func findsTheCredentials() {
    let text = """
      MOUNTAYA_PUBLISHABLE_KEY = \(Self.planted("pk_"))
      let secret = "\(Self.planted("sk_"))"
      token: \(Self.planted("sess_"))
      bearer \(Self.token())
      """

    let found = TrailScenario.credentials(in: text, file: "C.xcconfig")
    #expect(
      found == [
        TrailScenario.Credential(kind: "a publishable key", file: "C.xcconfig", line: 1),
        TrailScenario.Credential(kind: "a secret key", file: "C.xcconfig", line: 2),
        TrailScenario.Credential(kind: "a session token", file: "C.xcconfig", line: 3),
        TrailScenario.Credential(kind: "a session token", file: "C.xcconfig", line: 4),
      ])
  }

  @Test("a stand-in, a placeholder or a word that merely holds a prefix is shaped as none")
  func passesWhatIsShapedAsNone() {
    let text = """
      static let publishable = "pk_trail_test"
      let secret = "sk_trail_test", token = "sess_trail_test"
      MOUNTAYA_PUBLISHABLE_KEY: pk_size_gate
      let key = "pk_live_0a1b", short = "\(Self.planted("pk_").dropLast())"
      let upper = "pk_\(String(repeating: "0A1B", count: 8))"
      let inside = "xpk_\(String(repeating: "0a1b", count: 8))"
      let names = "sess_trail.session", notJSON = "sess_bm90.c2ln"
      """

    #expect(TrailScenario.credentials(in: text, file: "D.swift").isEmpty)
  }

  // MARK: - The scan

  @Test("the scan reads every file git commits under Examples/, and nothing it ignores")
  func scansCommittedFiles() throws {
    let tree = try TemporaryTree()
    defer { tree.remove() }
    try tree.write("Examples/LICENSE", contents: "MIT License")
    try tree.write("Examples/Trail/Sources/Trail/A.swift", contents: "// trail: trail.client\n")
    try tree.write("Examples/Trail/Session/Sources/S/B.swift", contents: "// trail: trail.no-key\n")
    try tree.write(
      "Examples/Trail/Config/Local.xcconfig.example", contents: "MOUNTAYA_PUBLISHABLE_KEY =\n")
    try tree.write("Examples/Trail/Trail.xcodeproj/project.pbxproj", contents: "{}")
    // What git ignores, each holding a key the gate must never read.
    let key = "MOUNTAYA_PUBLISHABLE_KEY = \(Self.planted("pk_"))\n"
    for ignored in [
      "Examples/Trail/Config/Local.xcconfig", "Examples/Trail/.build/x/Key.swift",
      "Examples/Trail/Session/.build/y.json", "Examples/Trail/.swiftpm/z.json",
      "Examples/Trail/DerivedData/w", "Examples/Trail/Trail.xcodeproj/xcuserdata/u.plist",
      "Examples/Other/Other.xcodeproj/project.pbxproj", "Examples/Trail/.DS_Store",
      "Examples/Trail/.env", "Examples/Trail/.env.local",
    ] {
      try tree.write(ignored, contents: key)
    }
    try tree.write("Examples/Trail/.env.example", contents: "MOUNTAYA_PUBLISHABLE_KEY=\n")

    let scan = TrailScenario.scan(root: tree.root)

    #expect(
      scan.files == [
        "Examples/LICENSE", "Examples/Trail/.env.example",
        "Examples/Trail/Config/Local.xcconfig.example",
        "Examples/Trail/Session/Sources/S/B.swift", "Examples/Trail/Sources/Trail/A.swift",
        "Examples/Trail/Trail.xcodeproj/project.pbxproj",
      ])
    #expect(scan.credentials.isEmpty)
    #expect(scan.markers.map(\.id).sorted() == ["trail.client", "trail.no-key"])
    #expect(scan.swiftFiles.count == 2)

    // A key in a committed file is found, by its file and line.
    try tree.write("Examples/Trail/Config/Local.xcconfig.example", contents: key)
    #expect(
      TrailScenario.scan(root: tree.root).credentials == [
        TrailScenario.Credential(
          kind: "a publishable key", file: "Examples/Trail/Config/Local.xcconfig.example", line: 1)
      ])
  }

  // MARK: - The rules

  /// held is a scan holding every step's marker, no credential, and two Swift files.
  private static func held(
    markers: [TrailScenario.Marker] = [
      TrailScenario.Marker(id: "trail.client", file: "A.swift", line: 1),
      TrailScenario.Marker(id: "trail.no-key", file: "B.swift", line: 2),
    ],
    credentials: [TrailScenario.Credential] = []
  ) -> TrailScenario.Scan {
    TrailScenario.Scan(
      files: ["A.swift", "B.swift"], swiftFiles: ["A.swift", "B.swift"], markers: markers,
      credentials: credentials)
  }

  @Test("an app holding the scenario breaks no rule")
  func holds() throws {
    let scenario = try TrailScenario.parse(Self.scenario)
    let itinerary = Data("{}".utf8)

    #expect(
      TrailScenario.findings(
        scenario: scenario, scan: Self.held(), itinerary: itinerary, copy: itinerary,
        hasLicence: true
      ).isEmpty)
  }

  @Test("each way of breaking the scenario is a finding of its own, shown once")
  func eachFinding() throws {
    let scenario = try TrailScenario.parse(Self.scenario)
    let itinerary = Data("{}".utf8)
    func kinds(
      _ scan: TrailScenario.Scan, copy: Data? = Data("{}".utf8), hasLicence: Bool = true
    ) -> [TrailScenario.Finding.Kind] {
      TrailScenario.findings(
        scenario: scenario, scan: scan, itinerary: itinerary, copy: copy, hasLicence: hasLicence
      ).map(\.kind)
    }

    // A step no marker names.
    let unmarked = TrailScenario.findings(
      scenario: scenario,
      scan: Self.held(markers: [TrailScenario.Marker(id: "trail.client", file: "A.swift", line: 1)]
      ),
      itinerary: itinerary, copy: itinerary, hasLicence: true)
    #expect(unmarked.map(\.kind) == [.unmarked])
    #expect(unmarked.first?.file == "sdk/trail.yaml")
    #expect(unmarked.first?.line == 17)
    #expect(unmarked.first?.message.contains("`trail.no-key`") == true)
    // A marker naming no step: renaming one breaks both rules.
    #expect(
      kinds(
        Self.held(markers: [
          TrailScenario.Marker(id: "trail.client", file: "A.swift", line: 1),
          TrailScenario.Marker(id: "trail.nokey", file: "B.swift", line: 2),
        ])) == [.unmarked, .unknownMarker])
    // A committed credential, named by its file and line and never by its value.
    let credential = TrailScenario.findings(
      scenario: scenario,
      scan: Self.held(credentials: [
        TrailScenario.Credential(kind: "a secret key", file: "C.swift", line: 9)
      ]),
      itinerary: itinerary, copy: itinerary, hasLicence: true)
    #expect(credential.map(\.kind) == [.credential])
    #expect(credential.first.map { "\($0.file):\($0.line)" } == "C.swift:9")
    #expect(
      credential.first?.message.hasPrefix("a value shaped as a secret key is committed") == true)
    // An itinerary that differs by a byte, or no copy at all.
    #expect(kinds(Self.held(), copy: Data("{} ".utf8)) == [.itinerary])
    #expect(kinds(Self.held(), copy: nil) == [.itinerary])
    // A missing licence.
    #expect(kinds(Self.held(), hasLicence: false) == [.licence])
  }

  @Test("without the contract checkout the markers and the copy are left unread, the rest held")
  func withoutTheContract() {
    let findings = TrailScenario.findings(
      scenario: nil, scan: Self.held(markers: []), itinerary: nil, copy: nil, hasLicence: false)

    #expect(findings.map(\.kind) == [.licence])
  }

  @Test("a scenario that does not list Swift asks for no marker")
  func scenarioWithoutSwift() throws {
    let scenario = try TrailScenario.parse(
      Self.scenario.replacingOccurrences(of: "[dart, swift, kotlin]", with: "[dart, kotlin]"))

    #expect(
      TrailScenario.findings(
        scenario: scenario, scan: Self.held(markers: []), itinerary: nil, copy: nil,
        hasLicence: true
      ).isEmpty)
  }
}
