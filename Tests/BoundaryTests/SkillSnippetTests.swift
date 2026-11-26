import Foundation
import GateSupport
import Testing

/// The skill an agent reads to use this SDK, `mountaya-sdk-swift` in the sibling checkout of
/// `mountaya/ai` (SPEC.md section 10): its Swift snippets compile against the real products and
/// the floors it states are the ones `Package.swift` declares. It is read from that checkout at
/// every run, never copied here, so the skill and the API it teaches cannot drift apart unseen.
@Suite("Skill")
struct SkillSnippetTests {
  @Test(
    "the skill's Swift snippets compile for an iPhone app with the Elements trait",
    .enabled(if: SkillCheckout.isPresentOrRequired, SkillCheckout.note))
  func snippetsCompile() throws {
    let skill = try #require(SkillCheckout.locate(), SkillCheckout.missing)
    var documents: [(name: String, fences: [ReadmeSnippets.Fence])] = []
    for document in SkillCheckout.documents(in: skill) {
      let text = try #require(SourceTree.read(skill.appendingPathComponent(document)))
      // A fence never closed, and a skip marker that names no reason or stands above no Swift
      // fence, are refused on every host, the Linux run's included.
      documents.append((document, try ReadmeSnippets.fences(in: text)))
    }
    let compiled = documents.flatMap(\.fences).filter { $0.skipped == nil }

    #expect(compiled.count > 0, "the skill compiles no snippet at all")
    // The products are whole only in an iOS build with the trait, which the macOS run makes.
    #if os(macOS)
      let build = try ConsumerPackage.iosBuild.get()
      try #require(build.status == 0, "the consumer does not build for iOS:\n\(build.log)")
      let prelude = try ConsumerPackage.root().appendingPathComponent(ConsumerPackage.prelude)
      for (document, fences) in documents where fences.contains(where: { $0.skipped == nil }) {
        let path = "../ai/\(SkillCheckout.path)/\(document)"
        let checked = try ConsumerPackage.typecheck(
          ReadmeSnippets.file(fences, document: path, rewrite: nil), against: build,
          for: .iosSimulator, named: "skill-" + document.dropLast(3).replacing("/", with: "-"),
          beside: [prelude])
        let lines = fences.filter { $0.skipped == nil }.enumerated().map {
          "snippet\($0.offset + 1), line \($0.element.line)"
        }

        #expect(
          checked.status == 0,
          """
          \(path) holds a Swift snippet that does not compile against the products: fix it in \
          the skill, or mark a fence that cannot compile with `<!-- swift:skip <reason> -->`. \
          Its snippets, in order: \(lines.joined(separator: "; ")).
          \(checked.diagnostics)
          """
        )
      }
    #endif
  }

  /// A snippet that guards itself for a server, `#if os(macOS) || os(Linux)`, compiles to nothing
  /// in the iOS build above, so the macOS run type-checks each such fence against the consumer
  /// built for macOS too, where the secret key, the admin unit's mint and the receiving of a
  /// webhook exist: the server's code the skill teaches is held to the products as an app's is.
  @Test(
    "the skill's snippets that guard themselves for a server compile on macOS",
    .enabled(if: SkillCheckout.isPresentOrRequired, SkillCheckout.note))
  func serverSnippetsCompile() throws {
    let skill = try #require(SkillCheckout.locate(), SkillCheckout.missing)
    var documents: [(name: String, fences: [ReadmeSnippets.Fence])] = []
    for document in SkillCheckout.documents(in: skill) {
      let text = try #require(SourceTree.read(skill.appendingPathComponent(document)))
      let fences = try ReadmeSnippets.fences(in: text).filter(SkillCheckout.guardsForServer)
      if !fences.isEmpty {
        documents.append((document, fences))
      }
    }

    #expect(!documents.isEmpty, "the skill guards no snippet for a server")
    #if os(macOS)
      let build = try ConsumerPackage.build.get()
      try #require(build.status == 0, "the consumer package does not build:\n\(build.log)")
      let prelude = try ConsumerPackage.root().appendingPathComponent(ConsumerPackage.prelude)
      for (document, fences) in documents {
        let path = "../ai/\(SkillCheckout.path)/\(document)"
        let checked = try ConsumerPackage.typecheck(
          ReadmeSnippets.file(fences, document: path, rewrite: nil), against: build,
          for: .macos, named: "skill-server-" + document.dropLast(3).replacing("/", with: "-"),
          beside: [prelude])
        let lines = fences.map { "line \($0.line)" }

        #expect(
          checked.status == 0,
          """
          \(path) holds a snippet for a server that does not compile on macOS against the \
          products: fix it in the skill. Its server snippets: \(lines.joined(separator: "; ")).
          \(checked.diagnostics)
          """
        )
      }
    #endif
  }

  @Test(
    "the skill states the tools version and the platform floors Package.swift declares",
    .enabled(if: SkillCheckout.isPresentOrRequired, SkillCheckout.note))
  func floors() throws {
    let skill = try #require(SkillCheckout.locate(), SkillCheckout.missing)
    let text = try #require(SourceTree.read(skill.appendingPathComponent("SKILL.md")))
    let manifest = try #require(
      SourceTree.read(try ConsumerPackage.root().appendingPathComponent("Package.swift")))
    let tools = try #require(SkillCheckout.toolsVersion(ofManifest: manifest))
    let platforms = try #require(ConsumerPackage.platforms(in: manifest))
    let statement = try #require(
      text.split(separator: "\n").first { $0.contains(SkillCheckout.toolsPhrase) },
      "SKILL.md states no `\(SkillCheckout.toolsPhrase) <version>`")

    // Every version the statement gives Swift is the floor the manifest's tools version sets.
    let swift = SkillCheckout.versions(after: [SkillCheckout.toolsPhrase, "Swift "], in: statement)
    #expect(!swift.isEmpty && swift.allSatisfy { $0 == tools }, "\(swift), expected \(tools)")
    try #require(!platforms.isEmpty, "Package.swift declares no platform")
    for platform in platforms {
      let (name, version) = try #require(
        SkillCheckout.floor(platform), "`\(platform)` is a platform the check cannot name")
      let stated = SkillCheckout.floor(of: name, in: statement)
      #expect(
        stated == version,
        "SKILL.md states \(name)'s floor as \(stated ?? "nothing"), Package.swift as \(version)")
    }
  }
}

/// SkillCheckout is the skill `mountaya-sdk-swift` in the sibling checkout of `mountaya/ai`.
///
/// It is tolerated as absent on a contributor's machine, where its tests are skipped with a note
/// saying so, and refused in CI, as the contract's checkout is, so a green CI run always means the
/// skill was read.
enum SkillCheckout {
  /// The skill's directory in the `ai` checkout.
  static let path = "skills/mountaya-sdk-swift"

  /// The variable a CI run sets, which turns an absent checkout into a failure.
  static let requiredVariable = "CI"

  /// The words that open the skill's statement of the package's floors.
  static let toolsPhrase = "tools version is "

  /// guardsForServer is true of a fence that is compiled and guards itself for a server, a line
  /// of it opening `#if os(macOS)`, which an iOS build compiles to nothing.
  static func guardsForServer(_ fence: ReadmeSnippets.Fence) -> Bool {
    fence.skipped == nil
      && fence.code.contains {
        $0.trimmingCharacters(in: .whitespaces).hasPrefix("#if os(macOS)")
      }
  }

  /// What a run skipped for want of the checkout says, and what a run that needs it says.
  static let note: Comment = "no mountaya-sdk-swift skill in ../ai: check mountaya/ai out there"
  static let missing: Comment =
    "no mountaya-sdk-swift skill in ../ai, where a run with CI set reads it: check mountaya/ai out there"

  /// isPresentOrRequired is true where the skill's tests run: where the checkout is there, and
  /// in CI, where its absence fails them.
  static var isPresentOrRequired: Bool {
    locate() != nil || !(ProcessInfo.processInfo.environment[requiredVariable] ?? "").isEmpty
  }

  /// locate returns the skill's directory beside this repository, or nil where it holds no
  /// `SKILL.md`.
  static func locate() -> URL? {
    guard
      let directory = SourceTree.packageRoot(from: #filePath)?.deletingLastPathComponent()
        .appendingPathComponent("ai").appendingPathComponent(path),
      FileManager.default.fileExists(atPath: directory.appendingPathComponent("SKILL.md").path)
    else { return nil }
    return directory
  }

  /// documents lists the skill's Markdown documents by their path in it, `SKILL.md` and its
  /// references, sorted.
  static func documents(in skill: URL) -> [String] {
    SourceTree.entries(under: skill)
      .filter { !$0.isDirectory && $0.relativePath.hasSuffix(".md") }
      .map(\.relativePath)
  }

  /// toolsVersion reads the version a manifest's first line declares, `// swift-tools-version:`.
  static func toolsVersion(ofManifest manifest: String) -> String? {
    let prefix = "// swift-tools-version:"
    guard let first = manifest.split(separator: "\n").first, first.hasPrefix(prefix) else {
      return nil
    }
    return version(in: first.dropFirst(prefix.count).drop { $0 == " " })
  }

  /// floor reads one line of a manifest's `platforms:` list, `.iOS(.v17),`, as the name a reader
  /// knows the platform by and its version, `iOS` and `17`; `.v10_15` is `10.15`.
  static func floor(_ entry: String) -> (name: String, version: String)? {
    let names = [
      "iOS": "iOS", "macCatalyst": "Mac Catalyst", "macOS": "macOS", "tvOS": "tvOS",
      "visionOS": "visionOS", "watchOS": "watchOS",
    ]
    guard entry.hasPrefix("."), let open = entry.firstIndex(of: "("),
      let name = names[String(entry[entry.index(after: entry.startIndex)..<open])]
    else { return nil }
    let inside = entry[entry.index(after: open)...].prefix { $0 != ")" }
    guard inside.hasPrefix(".v") else { return nil }
    return (name, String(inside.dropFirst(2)).replacing("_", with: "."))
  }

  /// floor(of:in:) reads the version a statement gives a platform after `floors are`: the first
  /// version after its name, so `iOS and Mac Catalyst 17` gives both 17.
  static func floor(of name: String, in statement: Substring) -> String? {
    guard let floors = statement.firstRange(of: "floors are ") else { return nil }
    var rest = statement[floors.upperBound...]
    while let found = rest.firstRange(of: name) {
      let before = rest[..<found.lowerBound].last
      let after = rest[found.upperBound...].first
      if before?.isLetter != true, after?.isLetter != true {
        let tail = rest[found.upperBound...]
        return tail.firstIndex(where: \.isNumber).flatMap { version(in: tail[$0...]) }
      }
      rest = rest[found.upperBound...]
    }
    return nil
  }

  /// versions reads the version after each occurrence of each phrase in a statement, where a
  /// version follows it.
  static func versions(after phrases: [String], in statement: Substring) -> [String] {
    phrases.flatMap { phrase in
      statement.ranges(of: phrase).compactMap { version(in: statement[$0.upperBound...]) }
    }
  }

  /// version reads the version a text starts with, digits and the dots between them, nil where it
  /// starts with no digit: `6.2.3, so` is `6.2.3`.
  private static func version(in text: Substring) -> String? {
    let run = text.prefix { $0.isNumber || $0 == "." }
    let trimmed = run.reversed().drop { $0 == "." }.reversed()
    return trimmed.first?.isNumber == true ? String(trimmed) : nil
  }
}
