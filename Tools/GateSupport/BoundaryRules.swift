/// BoundaryRules is the boundary table of SPEC.md section 7, as scans over lexed source and
/// over the package description.
///
/// Each is a scan and not a behaviour assertion: a rule that holds only where someone
/// remembered it is a convention.
package enum BoundaryRules {
  /// Finding is one place a boundary is crossed.
  package struct Finding: Sendable, Hashable {
    package let file: String
    package let line: Int
    package let message: String

    package init(file: String, line: Int, message: String) {
      self.file = file
      self.line = line
      self.message = message
    }
  }

  // MARK: - Imports

  /// Import is one import declaration.
  package struct Import: Sendable, Hashable {
    package let module: String
    /// access is the access level written before `import`, or nil for a bare import, which
    /// is public in the Swift 6 language mode.
    package let access: String?
    package let attributes: [String]
    package let line: Int
  }

  /// imports lists a file's import declarations.
  package static func imports(in tokens: [SourceToken]) -> [Import] {
    let accessLevels: Set<String> = ["public", "package", "internal", "fileprivate", "private"]
    let importKinds: Set<String> = [
      "struct", "class", "enum", "protocol", "typealias", "func", "var", "let",
    ]
    var found: [Import] = []
    for (position, token) in tokens.enumerated()
    where token.kind == .identifier && token.text == "import" {
      var cursor = position + 1
      if cursor < tokens.count, importKinds.contains(tokens[cursor].text) {
        cursor += 1
      }
      guard cursor < tokens.count, tokens[cursor].kind == .identifier else { continue }
      // A member access such as `x.import` is not a declaration.
      if position > 0, tokens[position - 1].text == "." { continue }

      var access: String?
      var attributes: [String] = []
      var back = position - 1
      while back >= 0, tokens[back].line == token.line {
        let text = tokens[back].text
        if accessLevels.contains(text) {
          access = text
        } else if text.hasPrefix("@") {
          attributes.append(text)
        } else {
          break
        }
        back -= 1
      }
      found.append(
        Import(
          module: tokens[cursor].text,
          access: access,
          attributes: attributes,
          line: token.line
        )
      )
    }
    return found
  }

  // MARK: - The table

  /// The targets the table knows. A target under `Sources/` that is not one of them fails, so
  /// a target added later cannot ship without a row.
  package static let knownTargets: Set<String> = [
    "MountayaClient", "MountayaAdmin", "MountayaGeo", "MountayaNavigation", "MountayaElements",
  ]

  /// The client's admin unit, which depends on the core and which no product of the core imports,
  /// so an app that draws a map or navigates links none of it (SPEC.md section 2).
  package static let adminUnit = "MountayaAdmin"

  /// The one directory of `MountayaElements` that may import MapLibre or a UI framework.
  package static let mapLibreDirectory = "Renderer"

  /// The one file of `MountayaElements` that imports MapLibre publicly: the view whose ready
  /// callback hands MapLibre's own map over.
  package static let mapLibreEscapeHatch = "Renderer/Views/MapView.swift"

  /// The one file of `MountayaElements` that adds a layer to MapLibre's map, in the order the one
  /// layer registry ranks the layers.
  package static let layerDrawer = "Renderer/Engines/MapRenderer.swift"

  /// The one file of `MountayaElements` that names a session: MapLibre's request hook, which hands
  /// MapLibre the session its own requests leave on and hears their redirects, and makes no
  /// request of its own.
  package static let requestHook = "Renderer/Engines/MapRequestHook.swift"

  /// scan applies a target's row of the table to one of its files.
  ///
  /// `relativePath` is the file's path inside the target, such as `Seams/Engines/X.swift`.
  package static func scan(target: String, relativePath: String, source: LexedSource) -> [Finding] {
    let file = "Sources/\(target)/\(relativePath)"
    guard knownTargets.contains(target) else {
      return [
        Finding(
          file: file,
          line: 1,
          message: "`\(target)` has no row in the boundary table of SPEC.md section 7"
        )
      ]
    }
    let topic = relativePath.split(separator: "/").first.map(String.init)
    var findings: [Finding] = []

    for found in imports(in: source.tokens) {
      if let reason = refusal(of: found, in: target, topic: topic, relativePath: relativePath) {
        findings.append(Finding(file: file, line: found.line, message: reason))
      }
    }

    // A layer reaches the map through the one registry, which ranks it by `geo.layers.order`, and
    // the renderer that draws the registry's order is the one place MapLibre's map is given one.
    if target == "MountayaElements", relativePath != layerDrawer {
      let tokens = source.tokens
      for position in tokens.indices.dropFirst()
      where ["addLayer", "insertLayer"].contains(tokens[position].text)
        && tokens[position - 1].text == "."
      {
        findings.append(
          Finding(
            file: file, line: tokens[position].line,
            message:
              "`.\(tokens[position].text)` outside `\(layerDrawer)`: a layer reaches the map "
              + "through the one registry, which ranks it"
          )
        )
      }
    }

    for token in source.tokens where token.kind == .identifier {
      if isNetworkName(token.text) {
        if target == adminUnit {
          findings.append(
            Finding(
              file: file, line: token.line,
              message:
                "`\(token.text)`: the admin unit reaches the network through the core's transport alone"
            )
          )
        } else if target == "MountayaClient" {
          if topic != seamsTopic {
            findings.append(
              Finding(
                file: file,
                line: token.line,
                message: "`\(token.text)` outside `Seams/`: one type reaches the network"
              )
            )
          }
        } else if target != "MountayaElements" || relativePath != requestHook {
          findings.append(
            Finding(
              file: file, line: token.line,
              message: "`\(token.text)`: this product never reaches the network")
          )
        }
      }
      if target == "MountayaGeo" || target == "MountayaNavigation" {
        if token.text == "Mountaya"
          || (target == "MountayaGeo" && token.text == "SessionTokenEngine")
        {
          findings.append(
            Finding(
              file: file,
              line: token.line,
              message:
                "`\(token.text)`: this product takes the client's data through a function, never the client"
            )
          )
        }
      }
    }
    return findings
  }

  private static func refusal(
    of found: Import, in target: String, topic: String?, relativePath: String
  ) -> String? {
    let module = found.module
    let isFerrostar = module.hasPrefix("Ferrostar")
    let isMapLibre = module.hasPrefix("MapLibre")
    let isUserInterface = module == "SwiftUI" || module == "UIKit" || module == "AppKit"

    if module == adminUnit, target != adminUnit {
      return
        "`import \(module)`: the admin unit depends on the core and no product of the core links it, "
        + "so an app that draws a map or navigates carries none of it"
    }
    switch target {
    case "MountayaClient", "MountayaGeo":
      if isUserInterface { return "`import \(module)`: this product names no UI framework" }
      if isMapLibre || isFerrostar {
        return "`import \(module)`: this product links no renderer and no navigation core"
      }
      if target == "MountayaGeo", module == "Network" || module == "FoundationNetworking" {
        return "`import \(module)`: this product never reaches the network"
      }
    case adminUnit:
      if isUserInterface { return "`import \(module)`: the admin unit names no UI framework" }
      if isMapLibre || isFerrostar {
        return "`import \(module)`: the admin unit links no renderer and no navigation core"
      }
      if module == "Network" || module == "FoundationNetworking" {
        return
          "`import \(module)`: the admin unit reaches the network through the core's transport alone"
      }
      if ["MountayaGeo", "MountayaNavigation", "MountayaElements"].contains(module) {
        return "`import \(module)`: the admin unit stands on the core alone"
      }
    case "MountayaNavigation":
      if isUserInterface || isMapLibre {
        return "`import \(module)`: the navigation engine renders nothing"
      }
      if module == "Network" || module == "FoundationNetworking" {
        return "`import \(module)`: this product never reaches the network"
      }
      if isFerrostar {
        return
          "`import \(module)`: the navigation is Swift over Geo's machine, and links no navigation "
          + "library"
      }
    case "MountayaElements":
      if isFerrostar || module == "MountayaNavigation" {
        return "`import \(module)`: the views render `NavigationState`, which Geo declares"
      }
      if otherMapEngines.contains(where: { module.hasPrefix($0) }) {
        return "`import \(module)`: MapLibre Native is the sole renderer core"
      }
      if isMapLibre || isUserInterface, topic != mapLibreDirectory {
        return
          "`import \(module)` outside `\(mapLibreDirectory)/`: the map's state, engines and rules "
          + "name no renderer and no UI framework, and build everywhere"
      }
      if isMapLibre, found.access == nil {
        return
          "`import \(module)` must state its access: a bare import is public in the Swift 6 "
          + "language mode"
      }
      if isMapLibre, found.access == "public", relativePath != mapLibreEscapeHatch {
        return
          "`public import \(module)` outside `\(mapLibreEscapeHatch)`: MapLibre is published by "
          + "the view's ready callback alone"
      }
    default:
      break
    }
    return nil
  }

  private static let seamsTopic = "Seams"

  private static let otherMapEngines = ["MapKit", "GoogleMaps", "Mapbox", "MapboxMaps"]

  private static func isNetworkName(_ name: String) -> Bool {
    name.hasPrefix("URLSession") || name == "FoundationNetworking"
  }

  // MARK: - Determinism

  /// The reads of the environment that are refused outside `Seams/`, each as the run of
  /// tokens that spells it.
  private static let environmentReads: [(tokens: [String], name: String)] = [
    (["Date", "(", ")"], "Date()"),
    (["Date", ".", "now"], "Date.now"),
    (["UUID", "(", ")"], "UUID()"),
    ([".", "random", "("], ".random("),
    (["SystemRandomNumberGenerator"], "SystemRandomNumberGenerator"),
    (["Locale", ".", "current"], "Locale.current"),
    ([".", "autoupdatingCurrent"], ".autoupdatingCurrent"),
    (["TimeZone", ".", "current"], "TimeZone.current"),
    (["Calendar", ".", "current"], "Calendar.current"),
    (["UserDefaults"], "UserDefaults"),
  ]

  /// determinism finds the reads of the environment in a file that is not under `Seams/`.
  ///
  /// A rule that reads the environment cannot be held to a fixture, so the clock, the random
  /// source, the locale and the stored defaults are reached through a seam and nowhere else.
  package static func determinism(target: String, relativePath: String, source: LexedSource)
    -> [Finding]
  {
    if relativePath.split(separator: "/").first.map(String.init) == seamsTopic {
      return []
    }
    let tokens = source.tokens
    var findings: [Finding] = []
    for position in tokens.indices {
      for read in environmentReads where matches(read.tokens, in: tokens, at: position) {
        findings.append(
          Finding(
            file: "Sources/\(target)/\(relativePath)",
            line: tokens[position].line,
            message: "`\(read.name)` outside `Seams/`: the environment is read through a seam"
          )
        )
      }
    }
    return findings
  }

  private static func matches(_ pattern: [String], in tokens: [SourceToken], at position: Int)
    -> Bool
  {
    guard position + pattern.count <= tokens.count else { return false }
    for (offset, text) in pattern.enumerated() where tokens[position + offset].text != text {
      return false
    }
    return true
  }

  // MARK: - Suppressions

  /// Suppression is one place the compiler's concurrency checking is switched off.
  package struct Suppression: Sendable, Hashable {
    package let file: String
    package let line: Int
    /// kind is `@unchecked Sendable`, `nonisolated(unsafe)` or `@preconcurrency`.
    package let kind: String
  }

  /// LedgerEntry is the claim behind one suppression: where it is, what it suppresses, and the
  /// sentence naming the synchronisation that makes it true.
  package struct LedgerEntry: Sendable, Hashable {
    package let file: String
    package let kind: String
    package let sentence: String

    package init(file: String, kind: String, sentence: String) {
      self.file = file
      self.kind = kind
      self.sentence = sentence
    }
  }

  /// suppressions finds every suppression in a file.
  package static func suppressions(file: String, source: LexedSource) -> [Suppression] {
    let tokens = source.tokens
    var found: [Suppression] = []
    for position in tokens.indices {
      if matches(["@unchecked", "Sendable"], in: tokens, at: position) {
        found.append(
          Suppression(file: file, line: tokens[position].line, kind: "@unchecked Sendable"))
      } else if matches(["nonisolated", "(", "unsafe", ")"], in: tokens, at: position) {
        found.append(
          Suppression(file: file, line: tokens[position].line, kind: "nonisolated(unsafe)"))
      } else if tokens[position].text == "@preconcurrency" {
        found.append(Suppression(file: file, line: tokens[position].line, kind: "@preconcurrency"))
      }
    }
    return found
  }

  /// reconcile holds the suppressions found in the tree to the ledger, in both directions.
  ///
  /// A suppression needs an entry for its file and kind, and the entry's sentence as a comment
  /// in the lines just above it. An entry needs a suppression. Either one alone is a claim
  /// nobody made, or a claim about code that is gone.
  package static func reconcile(
    suppressions: [Suppression],
    comments: [String: [SourceComment]],
    ledger: [LedgerEntry]
  ) -> [Finding] {
    var findings: [Finding] = []
    var unused = ledger

    for suppression in suppressions {
      guard
        let position = unused.firstIndex(where: {
          $0.file == suppression.file && $0.kind == suppression.kind
        })
      else {
        findings.append(
          Finding(
            file: suppression.file,
            line: suppression.line,
            message: "`\(suppression.kind)` with no entry in the suppression ledger"
          )
        )
        continue
      }
      let entry = unused.remove(at: position)
      let above = (comments[suppression.file] ?? [])
        .filter { $0.line < suppression.line && $0.line >= suppression.line - 12 }
        .map(\.text)
        .joined(separator: " ")
      if !normalized(above).contains(normalized(entry.sentence)) {
        findings.append(
          Finding(
            file: suppression.file,
            line: suppression.line,
            message: "`\(suppression.kind)` without its ledger sentence as a comment above it"
          )
        )
      }
    }
    for entry in unused {
      findings.append(
        Finding(
          file: entry.file,
          line: 1,
          message: "a ledger entry for `\(entry.kind)` with no suppression in the file"
        )
      )
    }
    return findings
  }

  private static func normalized(_ text: String) -> String {
    text.split(whereSeparator: { $0 == " " || $0 == "\n" || $0 == "\t" || $0 == "/" })
      .joined(separator: " ")
  }

  // MARK: - The built-artifact walk

  /// artifactWalk follows every shipped target through its target and product dependencies and
  /// fails on a path to Ferrostar from any of them, or to MapLibre from anything but
  /// `MountayaElements`.
  ///
  /// A source scan passes on a target that reaches a forbidden dependency through a target it
  /// merely depends on, which is exactly the shape that puts a renderer into a headless
  /// consumer's binary.
  package static func artifactWalk(manifest: PackageManifest) -> [Finding] {
    let byName = Dictionary(
      manifest.targets.map { ($0.name, $0) }, uniquingKeysWith: { first, _ in first })
    var roots = manifest.shippedTargets.map(\.name)
    for product in manifest.products where product.isLibrary {
      roots += product.targets
    }

    var findings: [Finding] = []
    for root in Set(roots).sorted() {
      var visited: Set<String> = []
      var stack: [[String]] = [[root]]
      while let path = stack.popLast() {
        guard let name = path.last, visited.insert(name).inserted, let target = byName[name] else {
          continue
        }
        for product in target.productDependencies {
          let lowered = product.lowercased()
          let chain = (path + [product]).joined(separator: " -> ")
          if lowered.contains("ferrostar") {
            findings.append(
              Finding(
                file: "Package.swift", line: 1,
                message: "\(chain): no product links Ferrostar, the navigation being Geo's machine")
            )
          }
          if lowered.contains("maplibre"), root != "MountayaElements" {
            findings.append(
              Finding(
                file: "Package.swift", line: 1,
                message: "\(chain): only `MountayaElements` links MapLibre")
            )
          }
        }
        for dependency in target.targetDependencies {
          stack.append(path + [dependency])
        }
      }
    }
    return findings.sorted { $0.message < $1.message }
  }
}
