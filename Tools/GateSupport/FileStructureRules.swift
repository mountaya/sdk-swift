import Foundation

/// FileStructureRules is the layout law of SPEC.md section 6, as checks over a package's
/// directories.
package enum FileStructureRules {
  /// Finding is one path that breaks the law.
  package struct Finding: Sendable, Hashable {
    package let path: String
    package let message: String
  }

  /// Report is the outcome of one run over a package.
  package struct Report: Sendable {
    /// checked counts the source files the law was applied to.
    package let checked: Int
    package let findings: [Finding]

    /// passes is true when no path breaks the law.
    package var passes: Bool {
      findings.isEmpty
    }
  }

  /// The closed set of kinds. `Rules` is the default, and `Engines` is what a rule is not.
  package static let kinds: Set<String> = ["Contracts", "Engines", "Rules", "Views", "Testing"]

  /// The one target that holds views.
  package static let viewsTarget = "MountayaElements"

  /// The directory the generator lays out, which the law does not read.
  package static let generatedDirectory = "Generated"

  /// The word a rule's file adds to its name where the rule's name, its first letter raised, is
  /// another file's of its target: Swift refuses two files of one name in a target.
  package static let ruleSuffix = "Rule"

  /// check walks `Sources/` and `Tests/` under a package root.
  ///
  /// Every directory under `Sources/` is a target, and inside a target every file sits at
  /// `<Topic>/<Kind>/<Type>.swift`, declares or extends the type its name says, and has a test
  /// at the mirrored path under `Tests/<Target>Tests/`. A file under `Rules/` named
  /// `<Name>Rule.swift` may instead declare the top-level function its name names without the
  /// suffix, where another file of its target is `<Name>.swift`, compared without regard to case,
  /// since a disk that ignores case holds the two files' objects as one.
  package static func check(packageRoot: URL) -> Report {
    var findings: [Finding] = []
    var checked = 0

    let sources = packageRoot.appendingPathComponent("Sources")
    let tests = packageRoot.appendingPathComponent("Tests")
    let sourceEntries = SourceTree.entries(under: sources)
    let testFiles = Set(
      SourceTree.entries(under: tests).filter { !$0.isDirectory }.map(\.relativePath)
    )
    // The stems of each target's files, lowered, which a rule's file name may not repeat.
    var stems: [String: [String]] = [:]
    for entry in sourceEntries where !entry.isDirectory {
      guard let target = entry.components.first, let file = entry.components.last,
        file.hasSuffix(".swift")
      else { continue }
      stems[target, default: []].append(String(file.dropLast(".swift".count)).lowercased())
    }

    for entry in sourceEntries {
      let components = entry.components
      guard let target = components.first else { continue }
      let inside = Array(components.dropFirst())
      let path = "Sources/" + entry.relativePath
      if inside.first == generatedDirectory {
        continue
      }

      if entry.isDirectory {
        findings += directoryFindings(target: target, inside: inside, path: path)
        continue
      }
      guard !inside.isEmpty else {
        findings.append(
          Finding(path: path, message: "a file directly under `Sources/`: it belongs in a target")
        )
        continue
      }

      checked += 1
      guard inside.count == 3, let fileName = inside.last else {
        findings.append(
          Finding(path: path, message: "a source file sits at `<Topic>/<Kind>/<Type>.swift`")
        )
        continue
      }
      guard fileName.hasSuffix(".swift") else {
        findings.append(Finding(path: path, message: "only Swift files live under `Sources/`"))
        continue
      }
      let stem = String(fileName.dropLast(".swift".count))
      guard isUpperCamelCase(stem) else {
        findings.append(
          Finding(path: path, message: "a file is named `UpperCamelCase.swift` after its type")
        )
        continue
      }
      if let text = SourceTree.read(sources.appendingPathComponent(entry.relativePath)) {
        let declared = declaredNames(in: text)
        if !declared.types.contains(stem), !declared.functions.contains(stem),
          !isRuleBesideItsName(
            stem, kind: inside[1], functions: declared.functions, stems: stems[target] ?? [])
        {
          findings.append(
            Finding(
              path: path,
              message:
                "the file declares or extends no type named `\(stem)`, and declares no top-level "
                + "function `\(lowered(stem))`"
            )
          )
        }
      }
      let mirrored = "\(target)Tests/\(inside[0])/\(inside[1])/\(stem)Tests.swift"
      if !testFiles.contains(mirrored) {
        findings.append(
          Finding(path: path, message: "no test at the mirrored path `Tests/\(mirrored)`")
        )
      }
    }

    findings += emptyDirectoryFindings(root: sources, prefix: "Sources/")
    findings += emptyDirectoryFindings(root: tests, prefix: "Tests/")

    return Report(checked: checked, findings: findings.sorted { $0.path < $1.path })
  }

  private static func directoryFindings(target: String, inside: [String], path: String)
    -> [Finding]
  {
    switch inside.count {
    case 0:
      return []
    case 1:
      let topic = inside[0]
      if kinds.contains(topic) {
        return [
          Finding(
            path: path,
            message: "`\(topic)` is a kind, and a kind sits under a topic: `<Topic>/\(topic)/`"
          )
        ]
      }
      if !isUpperCamelCase(topic) {
        return [Finding(path: path, message: "a topic is named in `UpperCamelCase`")]
      }
      return []
    case 2:
      let kind = inside[1]
      guard kinds.contains(kind) else {
        return [
          Finding(
            path: path,
            message: "`\(kind)` is not a kind: " + kinds.sorted().joined(separator: ", ")
          )
        ]
      }
      if kind == "Views", target != viewsTarget {
        return [Finding(path: path, message: "`Views` exists in `\(viewsTarget)` only")]
      }
      return []
    default:
      return [Finding(path: path, message: "nothing nests below `<Topic>/<Kind>/`")]
    }
  }

  private static func emptyDirectoryFindings(root: URL, prefix: String) -> [Finding] {
    let entries = SourceTree.entries(under: root)
    let files = entries.filter { !$0.isDirectory }.map(\.relativePath)
    return entries.filter(\.isDirectory).compactMap { directory in
      let inside = directory.relativePath + "/"
      if files.contains(where: { $0.hasPrefix(inside) }) {
        return nil
      }
      return Finding(path: prefix + directory.relativePath, message: "an empty directory")
    }
  }

  private static func isUpperCamelCase(_ name: String) -> Bool {
    guard let first = name.unicodeScalars.first, first >= "A", first <= "Z" else {
      return false
    }
    return name.unicodeScalars.allSatisfy {
      ($0 >= "A" && $0 <= "Z") || ($0 >= "a" && $0 <= "z") || ($0 >= "0" && $0 <= "9")
    }
  }

  /// isRuleBesideItsName is true of a rule's file named `<Name>Rule.swift` that declares the
  /// top-level function `<name>`, where another file of its target is `<Name>.swift` without
  /// regard to case: the answer type a rule is named after, `profileTotals(_:)` answering a
  /// `ProfileTotals`, or a type spelled with another acronym, `POIPanelRows` beside
  /// `poiPanelRows(_:)`.
  private static func isRuleBesideItsName(
    _ stem: String, kind: String, functions: Set<String>, stems: [String]
  ) -> Bool {
    guard kind == "Rules", stem.hasSuffix(ruleSuffix), stem.count > ruleSuffix.count else {
      return false
    }
    let name = String(stem.dropLast(ruleSuffix.count))
    return functions.contains(name) && stems.contains(name.lowercased())
  }

  /// Returns the names a file may be named after: each type it declares and the type each of its
  /// extensions extends, by the last component of that type's name, and each function it declares
  /// at the top level, its first letter raised, so `haversineMeters(from:to:)` names
  /// `HaversineMeters.swift`. A function inside a type's braces is the type's, and names nothing.
  private static func declaredNames(in text: String) -> (types: Set<String>, functions: Set<String>)
  {
    let tokens = SwiftLexer.lex(text).tokens
    let introducers: Set<String> = ["struct", "class", "enum", "actor", "protocol", "typealias"]
    var types: Set<String> = []
    var functions: Set<String> = []
    var depth = 0
    for (position, token) in tokens.enumerated() {
      if token.kind == .punctuation {
        if token.text == "{" { depth += 1 }
        if token.text == "}" { depth = max(0, depth - 1) }
        continue
      }
      guard token.kind == .identifier else { continue }
      guard position + 1 < tokens.count else { break }
      let next = tokens[position + 1]
      guard next.kind == .identifier else { continue }
      if token.text == "func", depth == 0 {
        functions.insert(raised(next.text))
      } else if introducers.contains(token.text) {
        types.insert(next.text)
      } else if token.text == "extension" {
        var last = next.text
        var cursor = position + 2
        while cursor + 1 < tokens.count, tokens[cursor].text == ".",
          tokens[cursor + 1].kind == .identifier
        {
          last = tokens[cursor + 1].text
          cursor += 2
        }
        types.insert(last)
      }
    }
    return (types, functions)
  }

  /// Returns a name with its first letter raised: `haversineMeters` is `HaversineMeters`.
  private static func raised(_ name: String) -> String {
    name.prefix(1).uppercased() + name.dropFirst()
  }

  /// Returns a name with its first letter lowered, the function a file's name would name.
  private static func lowered(_ name: String) -> String {
    name.prefix(1).lowercased() + name.dropFirst()
  }
}
