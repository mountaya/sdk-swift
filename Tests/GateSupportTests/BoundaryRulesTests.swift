import GateSupport
import Testing

@Suite("BoundaryRules")
struct BoundaryRulesTests {
  private func scan(target: String, relativePath: String, source: String) -> [String] {
    BoundaryRules.scan(target: target, relativePath: relativePath, source: SwiftLexer.lex(source))
      .map { "\($0.line): \($0.message)" }
  }

  // MARK: Imports

  @Test("an import is read with its access level and its attributes")
  func readsImports() {
    let source = """
      import Foundation
      internal import FerrostarCore
      @testable import MountayaClient
      public import struct MapLibre.MLNMapView
      #if canImport(FoundationNetworking)
        import FoundationNetworking
      #endif
      let text = "import SwiftUI"
      // import UIKit
      """
    let imports = BoundaryRules.imports(in: SwiftLexer.lex(source).tokens)

    #expect(
      imports.map(\.module)
        == ["Foundation", "FerrostarCore", "MountayaClient", "MapLibre", "FoundationNetworking"]
    )
    #expect(imports.map(\.access) == [nil, "internal", nil, "public", nil])
    #expect(imports[2].attributes == ["@testable"])
    #expect(imports.map(\.line) == [1, 2, 3, 4, 6])
  }

  // MARK: The table

  @Test("a file that crosses no boundary passes")
  func cleanFiles() {
    #expect(
      scan(
        target: "MountayaClient", relativePath: "Retry/Rules/RetryBackoff.swift",
        source: "import Foundation\nenum RetryBackoff {}"
      ).isEmpty)
    #expect(
      scan(
        target: "MountayaClient", relativePath: "Seams/Engines/URLSessionSeam.swift",
        source: "import Foundation\nlet s = URLSession.shared"
      )
      .isEmpty
    )
    #expect(
      scan(
        target: "MountayaNavigation", relativePath: "Seams/Engines/DeviceLocationSource.swift",
        source: "import CoreLocation\ninternal import Foundation"
      ).isEmpty
    )
    #expect(
      scan(
        target: "MountayaNavigation", relativePath: "Speech/Engines/SpeechNavigationVoice.swift",
        source: "internal import AVFoundation"
      ).isEmpty
    )
    #expect(
      scan(
        target: "MountayaElements", relativePath: "Renderer/Views/MapView.swift",
        source: "public import MapLibre\npublic import SwiftUI"
      )
      .isEmpty)
    #expect(
      scan(
        target: "MountayaElements", relativePath: "Renderer/Engines/MapRenderer.swift",
        source: "internal import MapLibre\nfunc f(s: MLNStyle, l: MLNStyleLayer) { s.addLayer(l) }"
      )
      .isEmpty)
    #expect(
      scan(
        target: "MountayaElements", relativePath: "Map/Engines/MapEngine.swift",
        source: "func addLayer(_ l: Int) {}"
      ).isEmpty)
  }

  @Test(
    "a planted crossing fails",
    arguments: [
      ("MountayaClient", "Client/Engines/Transport.swift", "import SwiftUI"),
      ("MountayaClient", "Client/Engines/Transport.swift", "import UIKit"),
      ("MountayaClient", "Client/Engines/Transport.swift", "import MapLibre"),
      ("MountayaClient", "Client/Engines/Transport.swift", "internal import FerrostarCore"),
      ("MountayaClient", "Client/Engines/Transport.swift", "let s = URLSession.shared"),
      (
        "MountayaClient", "Client/Engines/Transport.swift",
        "final class D: NSObject, URLSessionDataDelegate {}"
      ),
      ("MountayaGeo", "Search/Engines/SearchEngine.swift", "let s = URLSession.shared"),
      ("MountayaGeo", "Search/Engines/SearchEngine.swift", "import FoundationNetworking"),
      ("MountayaGeo", "Search/Engines/SearchEngine.swift", "func f(client: Mountaya) {}"),
      ("MountayaGeo", "Search/Engines/SearchEngine.swift", "var e: SessionTokenEngine?"),
      ("MountayaGeo", "Search/Engines/SearchEngine.swift", "import SwiftUI"),
      (
        "MountayaNavigation", "Guidance/Engines/DeviceNavigationEngine.swift",
        "internal import FerrostarCore"
      ),
      ("MountayaNavigation", "Adapter/Engines/FerrostarGuidance.swift", "import FerrostarCore"),
      (
        "MountayaNavigation", "Adapter/Engines/FerrostarGuidance.swift",
        "internal import FerrostarCoreFFI"
      ),
      ("MountayaNavigation", "Speech/Engines/SpeechNavigationVoice.swift", "import MapLibre"),
      ("MountayaNavigation", "Guidance/Engines/DeviceNavigationEngine.swift", "let c: Mountaya"),
      ("MountayaElements", "Renderer/Views/MapView.swift", "internal import FerrostarCore"),
      ("MountayaElements", "Renderer/Views/MapView.swift", "import MountayaNavigation"),
      ("MountayaElements", "Renderer/Views/MapView.swift", "import MapKit"),
      ("MountayaElements", "Renderer/Views/MapView.swift", "let s = URLSession.shared"),
      ("MountayaElements", "Map/Engines/MapEngine.swift", "internal import MapLibre"),
      ("MountayaElements", "Map/Engines/MapEngine.swift", "import SwiftUI"),
      ("MountayaElements", "Renderer/Engines/MapRenderer.swift", "import MapLibre"),
      ("MountayaElements", "Renderer/Engines/MapRenderer.swift", "public import MapLibre"),
      (
        "MountayaElements", "Renderer/Engines/MapRequestHook.swift",
        "func f(s: MLNStyle, l: MLNStyleLayer) { s.insertLayer(l, at: 0) }"
      ),
      ("MountayaVideo", "Export/Rules/Frame.swift", "import Foundation"),
    ]
  )
  func plantedCrossings(target: String, path: String, source: String) {
    #expect(!scan(target: target, relativePath: path, source: source).isEmpty)
  }

  /// The admin unit stands on the core and reaches the network through its transport alone, and no
  /// product of the core imports it, so an app that draws a map or navigates links none of it.
  @Test("the admin unit stands on the core alone, and no product of the core imports it")
  func adminUnit() {
    #expect(
      scan(
        target: "MountayaAdmin", relativePath: "Webhooks/Rules/ConstructWebhookEvent.swift",
        source: "import Crypto\nimport Foundation\nimport MountayaClient"
      ).isEmpty)
    #expect(
      scan(
        target: "MountayaAdmin", relativePath: "Webhooks/Rules/X.swift",
        source: "import MountayaGeo")
        == ["1: `import MountayaGeo`: the admin unit stands on the core alone"])
    #expect(
      scan(
        target: "MountayaAdmin", relativePath: "Webhooks/Rules/X.swift",
        source: "import MountayaElements")
        == ["1: `import MountayaElements`: the admin unit stands on the core alone"])
    #expect(
      scan(
        target: "MountayaAdmin", relativePath: "Webhooks/Rules/X.swift", source: "import SwiftUI")
        == ["1: `import SwiftUI`: the admin unit names no UI framework"])
    #expect(
      scan(
        target: "MountayaAdmin", relativePath: "Webhooks/Rules/X.swift",
        source: "let s = URLSession.shared")
        == [
          "1: `URLSession`: the admin unit reaches the network through the core's transport alone"
        ])
    for target in ["MountayaClient", "MountayaGeo", "MountayaNavigation", "MountayaElements"] {
      #expect(
        scan(target: target, relativePath: "Map/Engines/X.swift", source: "import MountayaAdmin")
          == [
            "1: `import MountayaAdmin`: the admin unit depends on the core and no product of the core "
              + "links it, so an app that draws a map or navigates carries none of it"
          ], "\(target)")
    }
  }

  /// MapLibre's requests leave on a session the request hook hands it, whose delegate hears their
  /// redirects: the hook names it, and makes no request of its own.
  @Test("the request hook alone of the elements names a session")
  func requestHookSession() {
    let session = """
      internal import MapLibre
      final class H: NSObject, MLNNetworkConfigurationDelegate, URLSessionTaskDelegate {
        func session(for c: MLNNetworkConfiguration) -> URLSession {
          URLSession(configuration: c.sessionConfiguration, delegate: self, delegateQueue: nil)
        }
      }
      """

    #expect(
      scan(target: "MountayaElements", relativePath: BoundaryRules.requestHook, source: session)
        .isEmpty)
    #expect(
      !scan(
        target: "MountayaElements", relativePath: "Renderer/Engines/MapRenderer.swift",
        source: session
      ).isEmpty)
    #expect(
      !scan(
        target: "MountayaGeo", relativePath: "Search/Engines/SearchEngine.swift", source: session
      ).isEmpty)
    #expect(
      !scan(
        target: "MountayaNavigation", relativePath: "Seams/Engines/ReplayLocationSource.swift",
        source: session
      ).isEmpty)
  }

  @Test("a name that only appears in a comment or a string crosses nothing")
  func mentionsAreNotCrossings() {
    let source = """
      // URLSession is reached through the seam, and Mountaya is never named here.
      let note = "import SwiftUI, then URLSession.shared"
      """

    #expect(
      scan(target: "MountayaGeo", relativePath: "Search/Engines/SearchEngine.swift", source: source)
        .isEmpty)
  }

  // MARK: Determinism

  @Test(
    "an environment read outside Seams fails",
    arguments: [
      "let now = Date()", "let now = Date.now", "let id = UUID()",
      "let d = Double.random(in: 0..<1)",
      "let i = Int.random(in: 0...9)", "var g = SystemRandomNumberGenerator()",
      "let l = Locale.current",
      "let l: Locale = .autoupdatingCurrent", "let z = TimeZone.current",
      "let c = Calendar.current",
      "let u = UserDefaults.standard",
    ]
  )
  func environmentReads(source: String) {
    let lexed = SwiftLexer.lex(source)

    #expect(
      !BoundaryRules.determinism(
        target: "MountayaGeo", relativePath: "Format/Rules/X.swift", source: lexed
      )
      .isEmpty
    )
    #expect(
      BoundaryRules.determinism(
        target: "MountayaGeo", relativePath: "Seams/Engines/X.swift", source: lexed
      )
      .isEmpty
    )
  }

  @Test("a value built from arguments is not an environment read")
  func argumentsAreNotReads() {
    let source = """
      let instant = Date(timeIntervalSince1970: 0)
      let id = UUID(uuidString: text)
      let locale = Locale(identifier: "fr")
      let zone = TimeZone(identifier: "UTC")
      // Date() and Locale.current are refused here.
      """

    #expect(
      BoundaryRules.determinism(
        target: "MountayaGeo",
        relativePath: "Format/Rules/X.swift",
        source: SwiftLexer.lex(source)
      ).isEmpty
    )
  }

  // MARK: Suppressions

  private static let sentence = "The box is only read and written under its lock."

  private func reconcile(_ source: String, ledger: [BoundaryRules.LedgerEntry]) -> [String] {
    let lexed = SwiftLexer.lex(source)
    return BoundaryRules.reconcile(
      suppressions: BoundaryRules.suppressions(file: "A.swift", source: lexed),
      comments: ["A.swift": lexed.comments],
      ledger: ledger
    ).map(\.message)
  }

  @Test("every spelling of a suppression is found")
  func findsSuppressions() {
    let source = """
      final class Box: @unchecked Sendable {}
      nonisolated(unsafe) var shared = 0
      @preconcurrency import Dispatch
      // @unchecked Sendable in a comment is not one.
      """
    let found = BoundaryRules.suppressions(file: "A.swift", source: SwiftLexer.lex(source))

    #expect(found.map(\.kind) == ["@unchecked Sendable", "nonisolated(unsafe)", "@preconcurrency"])
    #expect(found.map(\.line) == [1, 2, 3])
  }

  @Test("a suppression with its ledger entry and its sentence above it passes")
  func ledgerMatches() {
    let source = """
      // \(Self.sentence)
      final class Box: @unchecked Sendable {}
      """
    let ledger = [
      BoundaryRules.LedgerEntry(
        file: "A.swift", kind: "@unchecked Sendable", sentence: Self.sentence)
    ]

    #expect(reconcile(source, ledger: ledger).isEmpty)
  }

  @Test("a suppression with no entry, with no sentence, or an entry with no suppression fails")
  func ledgerMismatches() {
    let bare = "final class Box: @unchecked Sendable {}"
    let ledger = [
      BoundaryRules.LedgerEntry(
        file: "A.swift", kind: "@unchecked Sendable", sentence: Self.sentence)
    ]

    #expect(reconcile(bare, ledger: []).count == 1)
    #expect(reconcile(bare, ledger: ledger).count == 1)
    #expect(reconcile("struct Plain {}", ledger: ledger).count == 1)
  }

  // MARK: The built-artifact walk

  private func walk(_ targets: [PackageManifest.Target], products: [PackageManifest.Product] = [])
    -> [String]
  {
    BoundaryRules.artifactWalk(manifest: PackageManifest(targets: targets, products: products))
      .map(\.message)
  }

  private func library(
    _ name: String,
    targets: [String] = [],
    products: [String] = []
  ) -> PackageManifest.Target {
    PackageManifest.Target(
      name: name,
      path: "Sources/\(name)",
      type: "library",
      targetDependencies: targets,
      productDependencies: products
    )
  }

  @Test("the graph the SPEC draws passes")
  func lawfulGraph() {
    let findings = walk([
      library("MountayaClient", products: ["Crypto"]),
      library("MountayaAdmin", targets: ["MountayaClient"], products: ["Crypto"]),
      library("MountayaGeo", targets: ["MountayaClient"]),
      library("MountayaNavigation", targets: ["MountayaClient", "MountayaGeo"]),
      library(
        "MountayaElements", targets: ["MountayaClient", "MountayaGeo"], products: ["MapLibre"]),
    ])

    #expect(findings.isEmpty, "\(findings)")
  }

  /// The navigation is Swift over Geo's machine, so a path to Ferrostar fails from every product,
  /// the navigation's own included, and one to MapLibre from every product but the elements.
  @Test("a path to Ferrostar, or to MapLibre through a target merely depended on, fails")
  func transitivePaths() {
    let findings = walk([
      library("MountayaClient"),
      library("MountayaGeo", targets: ["MountayaClient", "GeoSupport"]),
      PackageManifest.Target(
        name: "GeoSupport",
        path: "Tools/GeoSupport",
        type: "library",
        productDependencies: ["MapLibre"]
      ),
      library("MountayaNavigation", targets: ["MountayaGeo"], products: ["FerrostarCore"]),
      library("MountayaElements", targets: ["MountayaNavigation"], products: ["MapLibre"]),
    ])

    #expect(
      findings == [
        "MountayaElements -> MountayaNavigation -> FerrostarCore: no product links Ferrostar, the navigation being Geo's machine",
        "MountayaGeo -> GeoSupport -> MapLibre: only `MountayaElements` links MapLibre",
        "MountayaNavigation -> FerrostarCore: no product links Ferrostar, the navigation being Geo's machine",
        "MountayaNavigation -> MountayaGeo -> GeoSupport -> MapLibre: only `MountayaElements` links MapLibre",
      ]
    )
  }
}
