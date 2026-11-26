import Foundation

/// TrailScenario is the gate that holds Trail, the sample app under `Examples/Trail`, to the
/// contract's `sdk/trail.yaml` (SPEC.md section 7), so the three native SDKs' copies stay one app.
///
/// Apps written apart from one description stay one app only while something holds each of them
/// to it. `sdk/trail.yaml` lists the steps the app does, and the app marks the code that does a
/// step with a comment naming it, `// trail: <id>`, the session server's included. A step no
/// marker names fails, and so does a marker that names no step, so a step dropped from one app, or
/// renamed in the contract, fails here rather than leaving apps that no longer agree.
///
/// No setting is ever committed. A value shaped as a key or a session token in a file under
/// `Examples/` that git commits fails, in the shapes `sdk/SPEC.md` gives them: a credential's
/// prefix followed by 32 lowercase hex characters (its section 1), `pk_` for a publishable key,
/// `sk_` for a secret key and `sess_` for a session token, and a session token as `sess_`, its
/// payload as unpadded base64url JSON, a `.` and its signature (its studio section). The file a
/// developer keeps their own settings in, `Config/Local.xcconfig`, and what a build writes,
/// `.build/`, `.swiftpm/`, `DerivedData/` and `xcuserdata/`, are what `.gitignore` ignores there,
/// and are never read, so a key a developer sets fails nothing.
///
/// Trail ships the contract's demo itinerary, `sdk/trail/itinerary.json`, byte for byte, and the
/// examples carry their own licence, MIT, as `sdk-typescript`'s do.
package enum TrailScenario {
  /// sdk is the name the scenario lists this SDK under.
  package static let sdk = "swift"

  /// sdks is the SDKs the scenario may list.
  package static let sdks = ["typescript", "dart", "swift", "kotlin"]

  /// examples is the directory the examples sit in, relative to the repository's root.
  package static let examples = "Examples"

  /// app is Trail's directory, the session server's among it, where its markers stand.
  package static let app = "Examples/Trail"

  /// itineraryCopy is Trail's copy of the demo itinerary.
  package static let itineraryCopy = "Examples/Trail/Sources/Trail/itinerary.json"

  /// itinerary is the demo itinerary's path in the contract checkout.
  package static let itinerary = "sdk/trail/itinerary.json"

  /// licence is the examples' licence.
  package static let licence = "Examples/LICENSE"

  /// ownSettings is the file a developer keeps their settings in, which git ignores.
  package static let ownSettings = "Examples/Trail/Config/Local.xcconfig"

  /// ignoredDirectories is the directories a build or an editor writes, which git ignores and
  /// the scan never enters.
  package static let ignoredDirectories: Set<String> = [
    ".build", ".swiftpm", "DerivedData", "xcuserdata", ".claude",
  ]

  /// committedProject is the one Xcode project `.gitignore` lets git commit under `Examples/`.
  package static let committedProject = "Examples/Trail/Trail.xcodeproj"

  /// markerPrefix opens a marker's comment.
  package static let markerPrefix = "trail:"

  // MARK: - The scenario

  /// Scenario is what the gate reads of `sdk/trail.yaml`: its version, the SDKs that ship Trail,
  /// and its steps.
  package struct Scenario: Sendable, Hashable {
    package let version: Int
    package let sdks: [String]
    package let steps: [Step]

    package init(version: Int, sdks: [String], steps: [Step]) {
      self.version = version
      self.sdks = sdks
      self.steps = steps
    }
  }

  /// Step is one step of the scenario: its id and the line it starts on.
  package struct Step: Sendable, Hashable {
    package let id: String
    package let line: Int

    package init(id: String, line: Int) {
      self.id = id
      self.line = line
    }
  }

  /// topLevel is the fields the file holds, each a line of its own at the margin.
  static let topLevel: Set<String> = [
    "version", "sdks", "settings", "steps", "accessibility", "journey", "measured",
  ]

  /// parse reads the scenario's text.
  ///
  /// The file has one fixed shape, which the contract's own gate enforces: its fields at the
  /// margin, `version` a whole number and `sdks` a list on one line, `[dart, swift, kotlin]`, and
  /// each of `steps` opening at two spaces with `- id: <id>`. This reader knows that much of it and
  /// passes over the rest of each field. A field it does not know, or a step id that is not
  /// `trail.` and a kebab-case name, is an error naming the line, so a file that outgrows the
  /// reader fails loudly instead of being half read.
  package static func parse(_ text: String) throws(TrailScenarioError) -> Scenario {
    var version: Int?
    var listed: [String]?
    var steps: [Step] = []
    var field: String?

    let lines = text.split(separator: "\n", omittingEmptySubsequences: false)
    for (offset, rawLine) in lines.enumerated() {
      let number = offset + 1
      let line = rawLine.hasSuffix("\r") ? rawLine.dropLast() : rawLine
      let trimmed = line.drop { $0 == " " }
      if trimmed.isEmpty || trimmed.hasPrefix("#") {
        continue
      }
      if line.contains("\t") {
        throw TrailScenarioError(line: number, message: "a tab, where the file indents with spaces")
      }
      let indent = line.count - trimmed.count
      guard indent == 0 else {
        if field == "steps", indent == 2, trimmed.hasPrefix("- ") {
          guard let id = value(of: "id", in: trimmed.dropFirst(2)) else {
            throw TrailScenarioError(line: number, message: "a step opens with `- id: <id>`")
          }
          guard isStepId(id) else {
            throw TrailScenarioError(
              line: number, message: "`\(id)` is no step id, `trail.` and a kebab-case name")
          }
          guard !steps.contains(where: { $0.id == id }) else {
            throw TrailScenarioError(line: number, message: "`\(id)` is listed twice")
          }
          steps.append(Step(id: id, line: number))
        }
        continue
      }
      guard let colon = trimmed.firstIndex(of: ":") else {
        throw TrailScenarioError(line: number, message: "unrecognised line `\(trimmed)`")
      }
      let name = String(trimmed[..<colon])
      guard topLevel.contains(name) else {
        throw TrailScenarioError(line: number, message: "unrecognised field `\(name)`")
      }
      field = name
      let rest = trimmed[trimmed.index(after: colon)...].trimmingCharacters(in: .whitespaces)
      switch name {
      case "version":
        guard let read = Int(rest), read >= 1 else {
          throw TrailScenarioError(line: number, message: "`version` is a whole number from 1")
        }
        version = read
      case "sdks":
        listed = try sdkList(rest, line: number)
      default:
        continue
      }
    }
    guard let version else {
      throw TrailScenarioError(line: lines.count, message: "no `version`")
    }
    guard let listed else {
      throw TrailScenarioError(line: lines.count, message: "no `sdks`")
    }
    guard !steps.isEmpty else {
      throw TrailScenarioError(line: lines.count, message: "no `steps`")
    }
    return Scenario(version: version, sdks: listed, steps: steps)
  }

  /// isStepId is true of `trail.` followed by a kebab-case name.
  static func isStepId(_ id: String) -> Bool {
    guard id.hasPrefix("trail.") else { return false }
    let words = id.dropFirst("trail.".count).split(separator: "-", omittingEmptySubsequences: false)
    guard let first = words.first?.utf8.first, first >= 0x61, first <= 0x7A else { return false }
    return words.allSatisfy { word in
      !word.isEmpty
        && word.utf8.allSatisfy { ($0 >= 0x61 && $0 <= 0x7A) || ($0 >= 0x30 && $0 <= 0x39) }
    }
  }

  /// sdkList reads `[dart, swift]`: one SDK of the four or more, none twice.
  private static func sdkList(_ list: String, line: Int) throws(TrailScenarioError) -> [String] {
    guard list.hasPrefix("["), list.hasSuffix("]") else {
      throw TrailScenarioError(line: line, message: "`sdks` is a list on one line, `[…]`")
    }
    let names = list.dropFirst().dropLast().split(separator: ",").map {
      String($0.trimmingCharacters(in: .whitespaces))
    }
    for (index, name) in names.enumerated() {
      guard sdks.contains(name) else {
        throw TrailScenarioError(
          line: line, message: "`\(name)` is none of \(sdks.joined(separator: ", "))")
      }
      guard !names[..<index].contains(name) else {
        throw TrailScenarioError(line: line, message: "`\(name)` is named twice")
      }
    }
    return names
  }

  /// Returns the scalar after `key: `, or nil when the line is not that key.
  private static func value(of key: String, in line: Substring) -> String? {
    let prefix = key + ":"
    guard line.hasPrefix(prefix) else { return nil }
    return line.dropFirst(prefix.count).trimmingCharacters(in: .whitespaces)
  }

  // MARK: - The markers

  /// Marker is one marker a scan found: the step it names, and where it stands.
  package struct Marker: Sendable, Hashable {
    package let id: String
    package let file: String
    package let line: Int

    package init(id: String, file: String, line: Int) {
      self.id = id
      self.file = file
      self.line = line
    }
  }

  /// markers reads the markers of one Swift file, printed as `file`: each comment, read through
  /// the lexer, whose text opens with `trail:` and the id it names, so a marker written in a
  /// string or a sentence that mentions one counts for nothing.
  package static func markers(in source: String, file: String) -> [Marker] {
    guard source.contains(markerPrefix) else { return [] }
    return SwiftLexer.lex(source).comments.compactMap { comment in
      let text = comment.text.drop { $0 == "/" || $0 == " " || $0 == "*" }
      guard text.hasPrefix(markerPrefix) else { return nil }
      let id = text.dropFirst(markerPrefix.count).drop { $0 == " " }.prefix { !$0.isWhitespace }
      return Marker(id: String(id), file: file, line: comment.line)
    }
  }

  // MARK: - The credentials

  /// Credential is one value a scan found shaped as a key or a session token: what it is shaped
  /// as, and where it stands. The value itself is never kept, so no finding prints it.
  package struct Credential: Sendable, Hashable {
    package let kind: String
    package let file: String
    package let line: Int

    package init(kind: String, file: String, line: Int) {
      self.kind = kind
      self.file = file
      self.line = line
    }
  }

  /// prefixes is each credential's prefix, the kind of value it opens, as `sdk/SPEC.md` section 1
  /// names them.
  static let prefixes: [(prefix: String, kind: String)] = [
    ("pk_", "a publishable key"), ("sk_", "a secret key"), ("sess_", "a session token"),
  ]

  /// credentials reads every value of `text`, printed as `file`, shaped as a key or a session
  /// token: a prefix standing at the start of a word followed by 32 lowercase hex characters, or
  /// `sess_` followed by a payload that decodes as unpadded base64url to a JSON object, a `.` and
  /// a signature.
  package static func credentials(in text: String, file: String) -> [Credential] {
    var found: [Credential] = []
    for (offset, line) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
    {
      let scalars = Array(line.unicodeScalars)
      var index = 0
      while index < scalars.count {
        defer { index += 1 }
        if index > 0, isWordScalar(scalars[index - 1]) { continue }
        for (prefix, kind) in prefixes where matches(prefix, in: scalars, at: index) {
          let after = index + prefix.unicodeScalars.count
          if isKeyShaped(scalars, from: after)
            || (prefix == "sess_" && isTokenShaped(scalars, from: after))
          {
            found.append(Credential(kind: kind, file: file, line: offset + 1))
          }
        }
      }
    }
    return found
  }

  private static func matches(_ prefix: String, in scalars: [Unicode.Scalar], at index: Int)
    -> Bool
  {
    let wanted = Array(prefix.unicodeScalars)
    return index + wanted.count <= scalars.count
      && Array(scalars[index..<(index + wanted.count)]) == wanted
  }

  /// isKeyShaped is whether 32 lowercase hex characters start at `start`.
  private static func isKeyShaped(_ scalars: [Unicode.Scalar], from start: Int) -> Bool {
    guard start + 32 <= scalars.count else { return false }
    return scalars[start..<(start + 32)].allSatisfy {
      ($0 >= "0" && $0 <= "9") || ($0 >= "a" && $0 <= "f")
    }
  }

  /// isTokenShaped is whether a session token's payload starts at `start`: a run of base64url
  /// that decodes to a JSON object, then a `.` and a signature.
  private static func isTokenShaped(_ scalars: [Unicode.Scalar], from start: Int) -> Bool {
    var end = start
    while end < scalars.count, isBase64Url(scalars[end]) {
      end += 1
    }
    guard end > start, end + 1 < scalars.count, scalars[end] == ".",
      isBase64Url(scalars[end + 1])
    else { return false }
    var payload = String(String.UnicodeScalarView(scalars[start..<end]))
      .replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
    payload += String(repeating: "=", count: (4 - payload.count % 4) % 4)
    guard let decoded = Data(base64Encoded: payload) else { return false }
    return decoded.first { !(" \t\r\n".utf8.contains($0)) } == UInt8(ascii: "{")
  }

  private static func isWordScalar(_ scalar: Unicode.Scalar) -> Bool {
    scalar.properties.isAlphabetic || (scalar >= "0" && scalar <= "9") || scalar == "_"
  }

  private static func isBase64Url(_ scalar: Unicode.Scalar) -> Bool {
    (scalar >= "a" && scalar <= "z") || (scalar >= "A" && scalar <= "Z")
      || (scalar >= "0" && scalar <= "9") || scalar == "-" || scalar == "_"
  }

  // MARK: - The scan

  /// Scan is what a walk of `Examples/` found: every committed file it read for a credential, the
  /// Swift files it read for a marker, and what each holds.
  package struct Scan: Sendable {
    package let files: [String]
    package let swiftFiles: [String]
    package let markers: [Marker]
    package let credentials: [Credential]

    package init(
      files: [String], swiftFiles: [String], markers: [Marker], credentials: [Credential]
    ) {
      self.files = files
      self.swiftFiles = swiftFiles
      self.markers = markers
      self.credentials = credentials
    }
  }

  /// scan reads every file under `Examples/` of `root` that git commits: the ignored directories,
  /// an Xcode project but Trail's, `.DS_Store`, a `.env` but its `.example`, and the developer's
  /// own settings left out; each file is named by its path from `root`. A marker is read in the
  /// Swift files of Trail alone.
  package static func scan(root: URL) -> Scan {
    var files: [String] = []
    var swiftFiles: [String] = []
    var markers: [Marker] = []
    var credentials: [Credential] = []
    for path in committedFiles(under: root.appendingPathComponent(examples), prefix: examples) {
      files.append(path)
      guard let data = FileManager.default.contents(atPath: root.appendingPathComponent(path).path)
      else { continue }
      let text = String(decoding: data, as: UTF8.self)
      credentials += self.credentials(in: text, file: path)
      if path.hasSuffix(".swift"), path.hasPrefix(app + "/") {
        swiftFiles.append(path)
        markers += self.markers(in: text, file: path)
      }
    }
    return Scan(files: files, swiftFiles: swiftFiles, markers: markers, credentials: credentials)
  }

  /// isIgnored is whether git ignores the entry `name` at `path`, as `.gitignore` reads it.
  package static func isIgnored(_ path: String, name: String, isDirectory: Bool) -> Bool {
    if isDirectory {
      return ignoredDirectories.contains(name)
        || (name.hasSuffix(".xcodeproj") && path != committedProject)
    }
    if name == ".DS_Store" || path == ownSettings { return true }
    return (name == ".env" || name.hasPrefix(".env.")) && name != ".env.example"
  }

  private static func committedFiles(under directory: URL, prefix: String) -> [String] {
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
      return []
    }
    var found: [String] = []
    for name in names.sorted() {
      let url = directory.appendingPathComponent(name)
      let path = prefix + "/" + name
      var isDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
        !isIgnored(path, name: name, isDirectory: isDirectory.boolValue)
      else { continue }
      if isDirectory.boolValue {
        found += committedFiles(under: url, prefix: path)
      } else {
        found.append(path)
      }
    }
    return found
  }

  // MARK: - The findings

  /// Finding is one way the examples fail to hold the scenario.
  package struct Finding: Sendable, Hashable {
    /// Kind is what the finding says is wrong.
    package enum Kind: Sendable, Hashable {
      /// unmarked is a step the scenario lists for this SDK that no marker names.
      case unmarked
      /// unknownMarker is a marker naming no step of the scenario.
      case unknownMarker
      /// credential is a committed value shaped as a key or a session token.
      case credential
      /// itinerary is a copy of the demo itinerary that is missing or differs by a byte.
      case itinerary
      /// licence is a missing licence.
      case licence
    }

    package let kind: Kind
    package let file: String
    package let line: Int
    package let message: String
  }

  /// findings holds a scan to `scenario`, nil where the contract checkout is absent, which leaves
  /// the markers unread; to the contract's demo itinerary, `itinerary`, nil where it is absent,
  /// and Trail's copy of it, `copy`, nil where Trail holds none; and to the examples' licence,
  /// which `hasLicence` says stands.
  package static func findings(
    scenario: Scenario?, scan: Scan, itinerary: Data?, copy: Data?, hasLicence: Bool
  ) -> [Finding] {
    var findings: [Finding] = []
    if let scenario, scenario.sdks.contains(sdk) {
      let marked = Set(scan.markers.map(\.id))
      for step in scenario.steps where !marked.contains(step.id) {
        findings.append(
          Finding(
            kind: .unmarked, file: "sdk/trail.yaml", line: step.line,
            message:
              "`\(step.id)` is a step no marker under \(app) names: mark the code that does it "
              + "with `// \(markerPrefix) \(step.id)`"))
      }
      let steps = Set(scenario.steps.map(\.id))
      for marker in scan.markers where !steps.contains(marker.id) {
        findings.append(
          Finding(
            kind: .unknownMarker, file: marker.file, line: marker.line,
            message:
              "the marker names `\(marker.id)`, which is no step of sdk/trail.yaml: name the step "
              + "the code does, or drop the marker with the step"))
      }
    }
    for credential in scan.credentials {
      findings.append(
        Finding(
          kind: .credential, file: credential.file, line: credential.line,
          message:
            "a value shaped as \(credential.kind) is committed: Trail reads its settings from "
            + "Config/Local.xcconfig or the environment, which git never commits, and a test "
            + "states a stand-in no credential is shaped as"))
    }
    if let itinerary {
      if copy == nil {
        findings.append(
          Finding(
            kind: .itinerary, file: itineraryCopy, line: 1,
            message: "Trail holds no copy of sdk/trail/itinerary.json: copy it, byte for byte"))
      } else if copy != itinerary {
        findings.append(
          Finding(
            kind: .itinerary, file: itineraryCopy, line: 1,
            message: "the copy differs from the contract's sdk/trail/itinerary.json: copy it "
              + "again, byte for byte"))
      }
    }
    if !hasLicence {
      findings.append(
        Finding(
          kind: .licence, file: licence, line: 1,
          message: "the examples carry no licence: they are MIT-licensed, as sdk-typescript's "
            + "are, and examples/LICENSE there is the text"))
    }
    return findings
  }
}

/// TrailScenarioError names the line of `sdk/trail.yaml` the reader could not read.
package struct TrailScenarioError: Error, Sendable, CustomStringConvertible {
  package let line: Int
  package let message: String

  package var description: String {
    "sdk/trail.yaml line \(line): \(message)"
  }
}
