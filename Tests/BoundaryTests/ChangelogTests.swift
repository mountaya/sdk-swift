import Foundation
import GateSupport
import Testing

/// The changelog of SPEC.md section 10, held to its shape and to the API it describes. It is the
/// one document no generator stands behind and no compiler reads, so a name it gives that no
/// product publishes any more reads as true until a reader looks for it.
@Suite("Changelog")
struct ChangelogTests {
  /// Words the changelog writes in backticks that are no symbol of the API: the package's trait.
  static let notSymbols: Set<String> = ["Elements"]

  static func changelog() throws -> String {
    let root = try ConsumerPackage.root()
    return try #require(SourceTree.read(root.appendingPathComponent("CHANGELOG.md")))
  }

  @Test("an Unreleased section, then each release as its version and its date, newest first")
  func shape() throws {
    let headings = try Self.changelog().split(separator: "\n", omittingEmptySubsequences: false)
      .filter { $0.hasPrefix("## ") }
      .map(String.init)
    let released = headings.dropFirst().compactMap(Self.release(of:))

    #expect(headings.first == "## [Unreleased]", "the first section is \(headings.first ?? "none")")
    #expect(
      released.count == headings.count - 1,
      "a section is no `## [MAJOR.MINOR.PATCH] - YYYY-MM-DD`: \(headings.dropFirst())")
    #expect(
      zip(released, released.dropFirst()).allSatisfy { $0.isNewer(than: $1) },
      "the releases are not newest first")
  }

  @Test("every name it gives in backticks is a product, a trait or a symbol a product publishes")
  func names() throws {
    let root = try ConsumerPackage.root()
    let baselines = root.appendingPathComponent("Tests/BoundaryTests/Baseline")
    var published = Set(try PackageTree.manifest.get().products.map(\.name))
    for file in try FileManager.default.contentsOfDirectory(atPath: baselines.path) {
      let text = try #require(SourceTree.read(baselines.appendingPathComponent(file)))
      for line in text.split(separator: "\n") where !line.hasPrefix("//") {
        let path = line.prefix { $0 != " " }
        for component in path.split(separator: ".") {
          published.insert(String(component.prefix { $0 != "(" }))
        }
      }
    }
    // The control: a baseline read to nothing would wave every name through.
    #expect(published.contains("EventStream") && published.contains("MapView"))

    var unknown: [String] = []
    for token in try Self.changelog().split(separator: "`").enumerated()
    where token.offset % 2 == 1 {
      let name = token.element.prefix { $0 != "(" }
      let components = name.split(separator: ".", omittingEmptySubsequences: false)
      let identifiers = components.allSatisfy { component in
        component.first.map { $0.isLetter || $0 == "_" } == true
          && component.allSatisfy { $0.isLetter || $0.isNumber || $0 == "_" }
      }
      guard identifiers else { continue }
      for component in components.map(String.init)
      where !published.contains(component) && !Self.notSymbols.contains(component) {
        unknown.append(String(token.element))
      }
    }

    #expect(
      unknown.isEmpty,
      """
      CHANGELOG.md names what no product publishes: \(unknown). Rename it, or add a word that is \
      no symbol to ChangelogTests.notSymbols.
      """)
  }

  /// The file the package's version is written in, once, which every request names it from and
  /// `scripts/release.sh` reads it from.
  static let identification = "Sources/MountayaClient/Sending/Rules/ClientIdentification.swift"

  @Test(
    "the version every request names reads as the release reads it, and is no older than the last")
  func identifiedVersion() throws {
    let root = try ConsumerPackage.root()
    let source = try #require(SourceTree.read(root.appendingPathComponent(Self.identification)))
    // The line the release's preflight reads, `static let version = "<version>"`, alone on its
    // line, which it holds the version it releases to.
    let prefix = #"static let version = ""#
    let stated = source.split(separator: "\n").compactMap { line -> String? in
      let trimmed = line.trimmingCharacters(in: .whitespaces)
      guard trimmed.hasPrefix(prefix), trimmed.hasSuffix("\""), trimmed.count > prefix.count
      else { return nil }
      let value = trimmed.dropFirst(prefix.count).dropLast()
      return value.contains("\"") ? nil : String(value)
    }
    try #require(
      stated.count == 1,
      "\(Self.identification) holds \(stated.count) lines `\(prefix)<version>\"`, and the release reads one"
    )
    let version = try #require(Self.version(stated[0]), "\(stated[0]) is no MAJOR.MINOR.PATCH")
    let newest = try Self.changelog().split(separator: "\n").map(String.init)
      .compactMap(Self.release(of:)).first

    #expect(
      newest.map { version.numbers == $0.numbers || version.isNewer(than: $0) } ?? true,
      "every request names \(stated[0]), older than the newest release CHANGELOG.md records")
  }

  /// Release is a released section's version.
  struct Release {
    let numbers: [Int]

    func isNewer(than other: Release) -> Bool {
      numbers.lexicographicallyPrecedes(other.numbers) == false && numbers != other.numbers
    }
  }

  /// release reads `## [MAJOR.MINOR.PATCH] - YYYY-MM-DD`, or nil for any other heading.
  static func release(of heading: String) -> Release? {
    let parts = heading.split(separator: " ")
    guard parts.count == 4, parts[0] == "##", parts[2] == "-", parts[1].hasPrefix("["),
      parts[1].hasSuffix("]")
    else { return nil }
    let date = parts[3].split(separator: "-", omittingEmptySubsequences: false)
    guard date.count == 3, date.map(\.count) == [4, 2, 2],
      date.allSatisfy({ $0.allSatisfy(\.isNumber) })
    else { return nil }
    return version(String(parts[1].dropFirst().dropLast()))
  }

  /// version reads `MAJOR.MINOR.PATCH`, or nil for any other text.
  static func version(_ text: String) -> Release? {
    let numbers = text.split(separator: ".", omittingEmptySubsequences: false).map { Int($0) }
    guard numbers.count == 3, numbers.allSatisfy({ $0 != nil }) else { return nil }
    return Release(numbers: numbers.compactMap { $0 })
  }
}
