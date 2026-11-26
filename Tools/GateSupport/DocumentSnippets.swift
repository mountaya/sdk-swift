/// DocumentSnippets is how `mise run snippets` compiles the Swift fences of the Markdown documents
/// it is handed, wherever they live: each fence `ReadmeSnippets` reads, the skip marker honoured,
/// is printed into a file of its own exactly as written, as a reader pastes it, and type-checked
/// against the consumer's build of the products for the platform it is written for.
///
/// A fence is a whole file. One with top-level code, an app's statements or a server's, is a
/// `main.swift`; one declaring the app's entry point, `@main`, or a test file, which holds no
/// top-level code, is compiled as a library. Its lines are its file's lines, so the compiler's
/// line `n` is the document's line `n` past the fence's opening.
package enum DocumentSnippets {
  /// The modules a fence written for an app imports and a server's never does. A fence importing
  /// one is type-checked for the iOS simulator, against the consumer built with the `Elements`
  /// trait, the one build where the map's views, the system's voice and UIKit exist; every other
  /// fence is type-checked for macOS, where the secret key and receiving a webhook exist.
  package static let appModules: Set<String> = [
    "MountayaElements", "MountayaNavigation", "SwiftUI", "UIKit",
  ]

  /// The modules a test file imports, whose fence holds no top-level code.
  package static let testModules: Set<String> = ["Testing", "XCTest"]

  /// The directory under the repository's `.build` the fences are printed into, which git ignores
  /// and each run empties first.
  package static let directory = ".build/snippets"

  /// Source is a fence printed as a file: its name, its text, and whether it is compiled as a
  /// library rather than as a program's `main.swift`.
  package struct Source: Sendable, Equatable {
    package let fileName: String
    package let text: String
    package let isLibrary: Bool
  }

  /// The kinds an import of one declaration names before its path, `import struct Foundation.URL`.
  private static let importKinds: Set<Substring> = [
    "class", "enum", "func", "let", "protocol", "struct", "typealias", "var",
  ]

  /// imports lists the modules a fence imports, in order: an attribute before the keyword,
  /// `@testable` or `@preconcurrency`, and a declaration's kind and path after the module's name
  /// are left out.
  package static func imports(of fence: ReadmeSnippets.Fence) -> [String] {
    fence.code.compactMap { line in
      let words = line.split(separator: " ").filter { !$0.hasPrefix("@") }
      guard words.count >= 2, words[0] == "import" else { return nil }
      let path = importKinds.contains(words[1]) && words.count >= 3 ? words[2] : words[1]
      return path.split(separator: ".").first.map(String.init)
    }
  }

  /// platform is what a fence is type-checked for: the iOS simulator where it imports a module
  /// of an app, and macOS otherwise.
  package static func platform(of fence: ReadmeSnippets.Fence) -> ConsumerPackage.Platform {
    imports(of: fence).contains(where: appModules.contains) ? .iosSimulator : .macos
  }

  /// source prints a fence as the file it compiles as, its lines as written.
  package static func source(of fence: ReadmeSnippets.Fence) -> Source {
    let declaresMain = fence.code.contains {
      $0.drop { $0 == " " }.hasPrefix("@main")
    }
    let isLibrary = declaresMain || imports(of: fence).contains(where: testModules.contains)
    return Source(
      fileName: isLibrary ? "Snippet.swift" : "main.swift",
      text: fence.code.joined(separator: "\n") + "\n",
      isLibrary: isLibrary)
  }

  /// folder names the directory, under `directory`, a fence of a document is printed into: the
  /// document's place among the arguments and its file name, then the fence's line, so two
  /// documents of one name never share a folder.
  package static func folder(position: Int, document: String, line: Int) -> String {
    let name = document.split(separator: "/").last.map(String.init) ?? document
    let stem = name.hasSuffix(".md") ? String(name.dropLast(3)) : name
    return "\(position)-\(stem)/line-\(line)"
  }

  /// diagnostics answers what the compiler said of a fence's file as the document's lines: each
  /// line that opens on the file's path, `<file>:<n>:<column>: <what>`, is written as
  /// `<document>:<fence's line + n>:<column>: <what>`, and the excerpts the compiler draws under
  /// it are left out. Where no line opens on the file's path, a module the fence imports that
  /// the build lacks among them, every line the compiler wrote is answered as it wrote it.
  package static func diagnostics(
    _ output: String, file: String, document: String, fenceLine: Int
  ) -> [String] {
    let lines = output.split(separator: "\n").map(String.init)
    let prefix = file + ":"
    let placed = lines.compactMap { line -> String? in
      guard line.hasPrefix(prefix) else { return nil }
      let rest = line.dropFirst(prefix.count)
      let number = rest.prefix { $0.isNumber }
      guard let offset = Int(number), rest.dropFirst(number.count).first == ":" else {
        return nil
      }
      return "\(document):\(fenceLine + offset)\(rest.dropFirst(number.count))"
    }
    return placed.isEmpty ? lines.filter { !$0.isEmpty } : placed
  }

  /// Tally is what one run did with the fences of the documents it read.
  package struct Tally: Sendable, Equatable {
    package var documents = 0
    package var macos = 0
    package var iosSimulator = 0
    package var skipped = 0
    package var failed = 0
    /// refused counts the documents that could not be read, or whose fences could not be.
    package var refused = 0

    package init() {}

    /// compiled counts the fences handed to the compiler, those that failed included.
    package var compiled: Int {
      macos + iosSimulator
    }

    /// passes is true where every fence compiled and every document was read.
    package var passes: Bool {
      failed == 0 && refused == 0
    }

    /// summary is the run's last line.
    package var summary: String {
      var text =
        "\(compiled) \(compiled == 1 ? "fence" : "fences") compiled (\(macos) for macOS, "
        + "\(iosSimulator) for the iOS simulator), \(skipped) skipped, \(failed) failed, "
        + "from \(documents) \(documents == 1 ? "document" : "documents")"
      if refused > 0 {
        text += ", \(refused) refused"
      }
      return text + "; printed under \(DocumentSnippets.directory)"
    }
  }
}
