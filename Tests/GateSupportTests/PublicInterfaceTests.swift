import Foundation
import GateSupport
import Testing

@Suite("PublicInterface")
struct PublicInterfaceTests {
  private static let graph = """
    {
      "module": { "name": "MountayaClient" },
      "symbols": [
        {
          "identifier": { "precise": "s:R" },
          "pathComponents": ["Response"],
          "accessLevel": "public",
          "declarationFragments": [
            { "kind": "keyword", "spelling": "struct" }, { "kind": "text", "spelling": " " },
            { "kind": "identifier", "spelling": "Response" }
          ]
        },
        {
          "identifier": { "precise": "s:Rs" },
          "pathComponents": ["Response", "status"],
          "accessLevel": "public",
          "declarationFragments": [
            { "kind": "keyword", "spelling": "let" }, { "kind": "text", "spelling": " status: " },
            { "kind": "typeIdentifier", "spelling": "Int" }
          ]
        },
        {
          "identifier": { "precise": "s:Rq" },
          "pathComponents": ["Response", "==(_:_:)"],
          "accessLevel": "public",
          "declarationFragments": [{ "kind": "text", "spelling": "static func == (lhs: Response, rhs: Response) -> Bool" }],
          "swiftExtension": {
            "extendedModule": "MountayaClient",
            "constraints": [
              { "kind": "conformance", "lhs": "Value", "rhs": "Equatable" },
              { "kind": "conformance", "lhs": "Value", "rhs": "Copyable" }
            ]
          }
        },
        {
          "identifier": { "precise": "s:Cs" },
          "pathComponents": ["Credential", "secret(key:)"],
          "accessLevel": "public",
          "declarationFragments": [{ "kind": "text", "spelling": "case secret(key: String)" }],
          "availability": [{ "domain": "iOS", "isUnconditionallyUnavailable": true, "message": "Servers only." }]
        },
        {
          "identifier": { "precise": "s:T" },
          "pathComponents": ["Transport"],
          "accessLevel": "internal",
          "declarationFragments": [{ "kind": "text", "spelling": "struct Transport" }]
        }
      ],
      "relationships": [
        { "kind": "memberOf", "source": "s:Rs", "target": "s:R" },
        { "kind": "conformsTo", "source": "s:R", "target": "s:s8SendableP", "targetFallback": "Swift.Sendable" },
        { "kind": "conformsTo", "source": "s:R", "target": "s:s16SendableMetatypeP", "targetFallback": "Swift.SendableMetatype" },
        {
          "kind": "conformsTo", "source": "s:R", "target": "s:SQ", "targetFallback": "Swift.Equatable",
          "swiftConstraints": [{ "kind": "conformance", "lhs": "Value", "rhs": "Equatable" }]
        },
        { "kind": "conformsTo", "source": "s:T", "target": "s:s8SendableP", "targetFallback": "Swift.Sendable" }
      ]
    }
    """

  @Test("each public declaration is a line, with its availability and its extension's constraints")
  func declarations() throws {
    let listing = try PublicInterface.listing(Self.graph)
    let lines = listing.split(separator: "\n").filter { !$0.hasPrefix("//") }

    #expect(listing.hasPrefix("// The public API of MountayaClient,"))
    #expect(
      lines == [
        #"Credential.secret(key:)  case secret(key: String)  @available(iOS, unavailable, message: "Servers only.")"#,
        "Response  : Swift.Sendable",
        "Response  : where Value : Equatable : Swift.Equatable",
        "Response  struct Response",
        "Response.==(_:_:)  static func == (lhs: Response, rhs: Response) -> Bool  in an extension where Value : Equatable",
        "Response.status  let status: Int",
      ]
    )
  }

  /// extensions is a graph of a module's extensions of SwiftUI's types, which the compiler writes
  /// apart from the module's own.
  private static let extensions = """
    {
      "module": { "name": "MountayaElements" },
      "symbols": [
        {
          "kind": { "identifier": "swift.extension" },
          "identifier": { "precise": "s:e:V" },
          "pathComponents": ["View"],
          "accessLevel": "public",
          "declarationFragments": [{ "kind": "keyword", "spelling": "extension View" }]
        },
        {
          "identifier": { "precise": "s:V" },
          "pathComponents": ["View", "mountayaTokens(_:)"],
          "accessLevel": "public",
          "declarationFragments": [
            { "kind": "text", "spelling": "func mountayaTokens(_ tokens: ElementTokens) -> some View" },
            { "kind": "text", "spelling": "\\n" }
          ]
        }
      ],
      "relationships": []
    }
    """

  @Test("a module's graphs are listed as one, its extensions of other modules' types among them")
  func extensionGraphs() throws {
    let listing = try PublicInterface.listing([Self.graph, Self.extensions])
    let lines = listing.split(separator: "\n", omittingEmptySubsequences: false)
      .filter { !$0.hasPrefix("//") }

    #expect(listing.hasPrefix("// The public API of MountayaClient,"), "the first graph names it")
    #expect(
      lines.contains(
        "View.mountayaTokens(_:)  func mountayaTokens(_ tokens: ElementTokens) -> some View"))
    #expect(lines.contains("Response.status  let status: Int"))
    #expect(!lines.dropLast().contains(""), "a line break ending a declaration is no line")
    #expect(!lines.contains { $0.hasPrefix("View  ") }, "an extension block declares nothing")
  }

  /// observed is a graph of two properties the compiler renders `{ get set }`, as it renders an
  /// `@Observable` class's stored properties whatever their setter's access, each declared at the
  /// line `source` holds it on, counted from zero as a symbol graph counts.
  private static func observed(source: URL) -> String {
    """
    {
      "module": { "name": "MountayaGeo" },
      "symbols": [
        {
          "kind": { "identifier": "swift.property" },
          "identifier": { "precise": "s:Eq" },
          "pathComponents": ["SearchEngine", "query"],
          "accessLevel": "public",
          "declarationFragments": [{ "kind": "text", "spelling": "@MainActor var query: String { get set }" }],
          "location": { "uri": "\(source.absoluteString)", "position": { "line": 2, "character": 26 } }
        },
        {
          "kind": { "identifier": "swift.property" },
          "identifier": { "precise": "s:Ec" },
          "pathComponents": ["SearchEngine", "camera"],
          "accessLevel": "public",
          "declarationFragments": [{ "kind": "text", "spelling": "@MainActor var camera: Int { get set }" }],
          "location": { "uri": "\(source.absoluteString)", "position": { "line": 4, "character": 13 } }
        }
      ],
      "relationships": []
    }
    """
  }

  /// The compiler renders an observed property whose setter is narrower than the property
  /// `{ get set }`, so a setter made public would read as no change: the listing reads the setter's
  /// access off the declaration the graph locates.
  @Test("a setter narrower than its property is printed as none")
  func setterAccess() throws {
    let tree = try TemporaryTree()
    defer { tree.remove() }
    try tree.write(
      "SearchEngine.swift",
      contents: """
        public final class SearchEngine {
          /// query is the query in the box.
          public private(set) var query: String
          /// camera is the camera a round reads.
          public var camera: Int
        }
        """)
    let listing = try PublicInterface.listing(
      Self.observed(source: tree.root.appendingPathComponent("SearchEngine.swift")))

    #expect(listing.contains("SearchEngine.query  @MainActor var query: String { get }\n"))
    #expect(listing.contains("SearchEngine.camera  @MainActor var camera: Int { get set }\n"))
  }

  @Test("a declaration whose source cannot be read is printed as the compiler renders it")
  func setterUnread() throws {
    let listing = try PublicInterface.listing(
      Self.observed(source: URL(fileURLWithPath: "/nowhere/SearchEngine.swift")))

    #expect(listing.contains("SearchEngine.query  @MainActor var query: String { get set }\n"))
  }

  @Test("a document that is not a symbol graph is refused")
  func refusal() {
    #expect(throws: SymbolGraphError.self) { try PublicInterface.listing("[]") }
    #expect(throws: SymbolGraphError.self) { try PublicInterface.listing("{") }
  }
}
