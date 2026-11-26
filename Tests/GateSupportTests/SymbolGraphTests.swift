import Foundation
import GateSupport
import Testing

@Suite("SymbolGraph")
struct SymbolGraphTests {
  private static let graph = """
    {
      "metadata": {},
      "module": { "name": "MountayaClient" },
      "symbols": [
        {
          "kind": { "identifier": "swift.protocol", "displayName": "Protocol" },
          "pathComponents": ["Sleeper"],
          "accessLevel": "internal",
          "location": {
            "uri": "file:///repo/Sources/MountayaClient/Seams/Contracts/Sleeper.swift",
            "position": { "line": 4, "character": 9 }
          }
        },
        {
          "kind": { "identifier": "swift.method", "displayName": "Instance Method" },
          "pathComponents": ["Sleeper", "sleep(for:)"],
          "accessLevel": "internal",
          "functionSignature": { "parameters": [{ "name": "for", "internalName": "duration" }] }
        }
      ],
      "relationships": []
    }
    """

  @Test("it reads each symbol's kind, path, access level, place and labels")
  func readsSymbols() throws {
    let graph = try SymbolGraph.parse(Self.graph)

    #expect(graph.module == "MountayaClient")
    #expect(graph.symbols.map(\.qualifiedName) == ["Sleeper", "Sleeper.sleep(for:)"])
    let type = try #require(graph.symbols.first)
    #expect(type.isType)
    #expect(!type.isPublished)
    #expect(type.file == "/repo/Sources/MountayaClient/Seams/Contracts/Sleeper.swift")
    #expect(type.line == 5)
    #expect(graph.symbols.last?.parameterLabels == ["for"])
    #expect(graph.symbols.last?.isType == false)
  }

  @Test("a declaration two platforms' graphs both hold is read once, where it was first listed")
  func union() {
    let shared = SymbolGraph.Symbol(kind: "swift.struct", path: ["MapState"], file: "/a.swift")
    let guarded = SymbolGraph.Symbol(kind: "swift.class", path: ["MapRenderer"], file: "/b.swift")
    let host = SymbolGraph(module: "MountayaElements", symbols: [shared])
    let ios = SymbolGraph(module: "MountayaElements", symbols: [guarded, shared])

    #expect(SymbolGraph.union([host, ios]).map(\.qualifiedName) == ["MapState", "MapRenderer"])
  }

  @Test("a binary framework is found in its slice for the simulator, and in no other")
  func simulatorFrameworks() throws {
    let tree = try TemporaryTree()
    defer { tree.remove() }
    try tree.makeDirectory("maplibre/MapLibre.xcframework/ios-arm64/MapLibre.framework")
    try tree.makeDirectory(
      "maplibre/MapLibre.xcframework/ios-arm64_x86_64-simulator/MapLibre.framework")
    try tree.makeDirectory("loose/ios-arm64-simulator/Loose.framework")

    let paths = SymbolGraph.simulatorFrameworkPaths(under: tree.root)

    #expect(paths.count == 1)
    #expect(paths.first?.hasSuffix("MapLibre.xcframework/ios-arm64_x86_64-simulator") == true)
  }

  @Test("an extension block of another module's type is no declaration, its members are")
  func extensionBlocks() throws {
    let graph = try SymbolGraph.parse(
      """
      {
        "module": { "name": "MountayaElements" },
        "symbols": [
          {
            "kind": { "identifier": "swift.extension" },
            "pathComponents": ["CLLocationManager"],
            "accessLevel": "internal"
          },
          {
            "kind": { "identifier": "swift.property" },
            "pathComponents": ["EnvironmentValues", "mountayaScope"],
            "accessLevel": "public"
          }
        ],
        "relationships": []
      }
      """)

    #expect(graph.symbols.map(\.path) == [["EnvironmentValues", "mountayaScope"]])
  }

  @Test("a module's extensions of other modules' types are found in graphs of their own")
  func extensionGraphs() throws {
    let tree = try TemporaryTree()
    defer { tree.remove() }
    for name in [
      "MountayaElements.symbols.json", "MountayaElements@SwiftUI.symbols.json",
      "MountayaElements@Swift.symbols.json", "MountayaGeo@Swift.symbols.json",
      "MountayaElementsExtra@SwiftUI.symbols.json",
    ] {
      try tree.write(name, contents: "{}")
    }

    let found = SymbolGraph.extensionGraphs(of: "MountayaElements", in: tree.root)

    #expect(
      found.map(\.lastPathComponent) == [
        "MountayaElements@Swift.symbols.json", "MountayaElements@SwiftUI.symbols.json",
      ])
    #expect(SymbolGraph.extensionGraphs(of: "Absent", in: tree.root).isEmpty)
  }

  @Test("a file that is not a symbol graph is refused")
  func refusals() {
    #expect(throws: SymbolGraphError.self) { try SymbolGraph.parse("not json") }
    #expect(throws: SymbolGraphError.self) { try SymbolGraph.parse(#"{"symbols": []}"#) }
  }
}
