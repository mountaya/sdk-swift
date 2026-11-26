import GateSupport
import Testing

@Suite("DocumentSnippets")
struct DocumentSnippetsTests {
  /// A page of the docs as their Markdown writes it: a fence inside a code group, a skipped
  /// manifest, an app's view, the app's entry point and a test file.
  private static let page = """
    ---
    title: "A page"
    ---

    {% code-group %}
    {% code-block label="Swift" language="swift" %}
    ```swift
    import Foundation
    import MountayaClient

    let mountaya = try Mountaya(credential: .publishable(key: "pk_your_publishable_key"))
    ```
    {% /code-block %}
    {% /code-group %}

    <!-- swift:skip a Package.swift manifest -->
    ```swift
    dependencies: []
    ```

    ```swift
    import MountayaElements
    import SwiftUI

    struct TrailMap: View {
      let map: MapEngine
      var body: some View { MapView(map) }
    }
    ```

    ```swift
    import SwiftUI

    @main
    struct TrailApp: App {
      var body: some Scene { WindowGroup { Text("Trail") } }
    }
    ```

    ```swift
    @testable import MountayaGeo
    import struct Foundation.URL
    import Testing

    @Test func reads() {}
    ```
    """

  private static func fences() throws -> [ReadmeSnippets.Fence] {
    try ReadmeSnippets.fences(in: page)
  }

  @Test("a fence inside a Markdoc code block is read, and the tags around it are not code")
  func readsInsideACodeBlock() throws {
    let fences = try Self.fences()

    #expect(fences.map(\.line) == [7, 17, 21, 31, 40])
    #expect(fences[0].code.first == "import Foundation")
    #expect(!fences[0].code.contains { $0.hasPrefix("{%") })
    #expect(fences[1].skipped == "a Package.swift manifest")
  }

  @Test("the imports leave out an attribute, a declaration's kind and its path")
  func imports() throws {
    let fences = try Self.fences()

    #expect(DocumentSnippets.imports(of: fences[0]) == ["Foundation", "MountayaClient"])
    #expect(DocumentSnippets.imports(of: fences[4]) == ["MountayaGeo", "Foundation", "Testing"])
  }

  @Test("a fence importing an app's module is checked for the iOS simulator, any other for macOS")
  func platforms() throws {
    let fences = try Self.fences()

    #expect(DocumentSnippets.platform(of: fences[0]) == .macos)
    #expect(DocumentSnippets.platform(of: fences[2]) == .iosSimulator)
    #expect(DocumentSnippets.platform(of: fences[3]) == .iosSimulator)
    #expect(DocumentSnippets.platform(of: fences[4]) == .macos)
  }

  @Test("top-level code is a main.swift, the app's entry point and a test file a library")
  func sources() throws {
    let fences = try Self.fences()
    let program = DocumentSnippets.source(of: fences[0])

    #expect(program.fileName == "main.swift" && !program.isLibrary)
    #expect(program.text.hasPrefix("import Foundation\nimport MountayaClient\n\nlet mountaya"))
    #expect(program.text.hasSuffix("))\n"))
    #expect(DocumentSnippets.source(of: fences[2]).isLibrary == false)
    #expect(DocumentSnippets.source(of: fences[3]).isLibrary)
    #expect(DocumentSnippets.source(of: fences[4]).fileName == "Snippet.swift")
  }

  @Test("each fence of each document has a folder of its own")
  func folders() {
    #expect(
      DocumentSnippets.folder(position: 2, document: "../docs/sdks/swift/errors.md", line: 14)
        == "2-errors/line-14")
    #expect(DocumentSnippets.folder(position: 1, document: "NOTES", line: 3) == "1-NOTES/line-3")
  }

  @Test("the compiler's lines are the document's, and its excerpts are left out")
  func diagnostics() {
    let file = "/repo/.build/snippets/1-errors/line-9/main.swift"
    let output = """
      \(file):3:35: error: type 'Credential' has no member 'nope'
      1 | import MountayaClient
        |                                   `- error: type 'Credential' has no member 'nope'
      \(file):4:1: warning: unused
      """

    #expect(
      DocumentSnippets.diagnostics(output, file: file, document: "errors.md", fenceLine: 9) == [
        "errors.md:12:35: error: type 'Credential' has no member 'nope'",
        "errors.md:13:1: warning: unused",
      ])
    #expect(
      DocumentSnippets.diagnostics(
        "error: no such module 'Trail'\n", file: file, document: "errors.md", fenceLine: 9)
        == ["error: no such module 'Trail'"])
  }

  @Test("the summary counts what was compiled for each platform, skipped, failed and refused")
  func summary() {
    var tally = DocumentSnippets.Tally()
    tally.documents = 2
    tally.macos = 3
    tally.iosSimulator = 1
    tally.skipped = 1

    #expect(tally.passes)
    #expect(
      tally.summary
        == "4 fences compiled (3 for macOS, 1 for the iOS simulator), 1 skipped, 0 failed, "
        + "from 2 documents; printed under .build/snippets")

    tally.failed = 1
    tally.refused = 1
    #expect(!tally.passes)
    #expect(tally.summary.contains("1 failed, from 2 documents, 1 refused;"))
  }
}
