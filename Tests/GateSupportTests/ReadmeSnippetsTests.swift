import GateSupport
import Testing

@Suite("ReadmeSnippets")
struct ReadmeSnippetsTests {
  private static let readme = """
    # A package

    ```swift
    import Foundation
    import MountayaClient

    let client = try Mountaya(credential: .publishable(key: "pk_a"))
    print(client)
    ```

    ```sh
    swift build
    ```

    <!-- swift:skip a manifest, which the consumer declares -->
    ```swift
    dependencies: []
    ```

    ```swift
    import MountayaClient
    print(schemaVersion)
    ```
    """

  @Test("every Swift fence is read in order, a skipped one with its reason, and no other language")
  func readsFences() throws {
    let fences = try ReadmeSnippets.fences(in: Self.readme)

    #expect(fences.map(\.line) == [3, 16, 20])
    #expect(fences.map(\.skipped) == [nil, "a manifest, which the consumer declares", nil])
    #expect(fences.first?.code.first == "import Foundation")
  }

  @Test("the file gathers the imports and wraps each compiled snippet in a function of its own")
  func printsTheFile() throws {
    let file = ReadmeSnippets.file(
      try ReadmeSnippets.fences(in: Self.readme), document: "README.md", rewrite: "rewrite")

    #expect(file.hasPrefix("// swift-format-ignore-file\n"))
    #expect(file.contains("// 2 snippets compiled, 1 skipped.\n"))
    #expect(file.contains("// Skipped: a manifest, which the consumer declares.\n"))
    #expect(file.contains("\nimport Foundation\nimport MountayaClient\n\n"))
    #expect(
      file.contains(
        """
          static func snippet1() async throws {
            let client = try Mountaya(credential: .publishable(key: "pk_a"))
            print(client)
          }

          static func snippet2() async throws {
            print(schemaVersion)
          }
        }

        """))
    #expect(!file.contains("dependencies: []"))
  }

  @Test(
    "a fence never closed, a marker naming no reason and a marker above no Swift fence are refused",
    arguments: [
      "```swift\nlet a = 1\n",
      "<!-- swift:skip -->\n```swift\nlet a = 1\n```\n",
      "<!-- swift:skip a reason -->\n```sh\nls\n```\n",
      "<!-- swift:skip a reason -->\nSome prose.\n```swift\nlet a = 1\n```\n",
      "<!-- swift:skip a reason -->\n",
    ]
  )
  func refusals(document: String) {
    #expect(throws: ReadmeSnippets.Refusal.self) { try ReadmeSnippets.fences(in: document) }
  }
}
