import Foundation

/// SymbolGraph is the compiler's own list of a module's declarations, as
/// `swift package dump-symbol-graph` writes it.
///
/// The naming gate reads names from here because the compiler parsed them: a name is what the
/// compiler says it is, whatever the source text looks like.
package struct SymbolGraph: Sendable {
  package let module: String
  package let symbols: [Symbol]

  /// Symbol is one declaration.
  package struct Symbol: Sendable, Hashable {
    /// kind is the graph's identifier for it, such as `swift.struct` or `swift.method`.
    package let kind: String
    /// path is the declaration's name with the types that enclose it, outermost first.
    package let path: [String]
    package let accessLevel: String
    /// file is the path of the source file that declares it, when the graph gives one.
    package let file: String?
    package let line: Int?
    /// parameterLabels is the argument labels of a function, an initializer or a subscript.
    package let parameterLabels: [String]

    package init(
      kind: String,
      path: [String],
      accessLevel: String = "public",
      file: String? = nil,
      line: Int? = nil,
      parameterLabels: [String] = []
    ) {
      self.kind = kind
      self.path = path
      self.accessLevel = accessLevel
      self.file = file
      self.line = line
      self.parameterLabels = parameterLabels
    }

    /// qualifiedName is the path joined with dots.
    package var qualifiedName: String {
      path.joined(separator: ".")
    }

    /// isType is true for a declaration that introduces a type name.
    package var isType: Bool {
      Symbol.typeKinds.contains(kind)
    }

    /// isPublished is true for a declaration a consumer can name.
    package var isPublished: Bool {
      accessLevel == "public" || accessLevel == "open"
    }

    private static let typeKinds: Set<String> = [
      "swift.struct", "swift.class", "swift.actor", "swift.enum", "swift.protocol",
      "swift.typealias", "swift.associatedtype",
    ]
  }

  package init(module: String, symbols: [Symbol]) {
    self.module = module
    self.symbols = symbols
  }
}

/// SymbolGraphError says why a symbol graph could not be read.
package struct SymbolGraphError: Error, Sendable, CustomStringConvertible {
  package let description: String
}

extension SymbolGraph {
  /// parse reads one `.symbols.json` file.
  package static func parse(_ text: String) throws(SymbolGraphError) -> SymbolGraph {
    let document: OrderedJSON
    do {
      document = try OrderedJSON.parse(text)
    } catch {
      throw SymbolGraphError(description: "a symbol graph that is not JSON: \(error)")
    }
    guard let module = document["module"]?["name"]?.stringValue,
      let symbols = document["symbols"]?.elements
    else {
      throw SymbolGraphError(description: "a symbol graph without a module or symbols")
    }
    return SymbolGraph(module: module, symbols: symbols.compactMap(symbol(from:)))
  }

  private static func symbol(from value: OrderedJSON) -> Symbol? {
    // An extension block of another module's type names no declaration of its own: its name is
    // the module's that declares the type, and its members are read on their own.
    guard let kind = value["kind"]?["identifier"]?.stringValue, kind != "swift.extension",
      let path = value["pathComponents"]?.elements?.compactMap(\.stringValue), !path.isEmpty
    else {
      return nil
    }
    var file: String?
    if let uri = value["location"]?["uri"]?.stringValue {
      file = URL(string: uri)?.path ?? uri
    }
    let labels =
      value["functionSignature"]?["parameters"]?.elements?.compactMap { $0["name"]?.stringValue }
      ?? []
    return Symbol(
      kind: kind,
      path: path,
      accessLevel: value["accessLevel"]?.stringValue ?? "public",
      file: file,
      line: value["location"]?["position"]?["line"]?.numberValue.map { Int($0) + 1 },
      parameterLabels: labels
    )
  }

  /// extensionGraphs is every graph of `module`'s extensions of another module's types in
  /// `directory`, `<module>@<other>.symbols.json`, in name order: the compiler writes a module's
  /// extensions of SwiftUI's `View` and `EnvironmentValues` there, never in the module's own graph.
  package static func extensionGraphs(of module: String, in directory: URL) -> [URL] {
    let names = (try? FileManager.default.contentsOfDirectory(atPath: directory.path)) ?? []
    return names.filter { $0.hasPrefix("\(module)@") && $0.hasSuffix(".symbols.json") }.sorted()
      .map { directory.appendingPathComponent($0) }
  }

  /// union is every symbol the graphs hold, each once, in the order the graphs first list it: a
  /// declaration two platforms' graphs both read is one declaration.
  package static func union(_ graphs: [SymbolGraph]) -> [Symbol] {
    var seen: Set<Symbol> = []
    var symbols: [Symbol] = []
    for symbol in graphs.flatMap(\.symbols) where seen.insert(symbol).inserted {
      symbols.append(symbol)
    }
    return symbols
  }

  /// dumpForIosSimulator builds each named module for the iOS simulator with every trait the
  /// package declares turned on, and reads its symbol graph down to `internal` declarations, so the
  /// declarations a trait and an `os(iOS)` condition guard, which no host build compiles, are read
  /// too.
  ///
  /// SwiftPM's own `dump-symbol-graph` builds every target, the gate's tools among them, which
  /// cannot build for iOS, so each module is built alone and its graph extracted from what the
  /// build wrote, as the API baselines are; a binary framework a module imports is found in the
  /// slice for the simulator of the build's own artifacts.
  package static func dumpForIosSimulator(
    packageRoot: URL,
    modules: [String]
  ) throws(SymbolGraphError) -> [SymbolGraph] {
    let scratch = packageRoot.appendingPathComponent(".build/nested-ios-simulator").path
    let sdk = try output(
      of: ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-path"], in: packageRoot)
    let version = try output(
      of: ["xcrun", "--sdk", "iphonesimulator", "--show-sdk-version"], in: packageRoot)
    #if arch(arm64)
      let architecture = "arm64"
    #else
      let architecture = "x86_64"
    #endif
    let build = [
      "swift", "build", "--scratch-path", scratch, "--triple",
      "\(architecture)-apple-ios-simulator", "--sdk", sdk, "--enable-all-traits",
    ]
    for module in modules {
      _ = try output(of: build + ["--target", module], in: packageRoot)
    }
    let products =
      try output(of: build + ["--show-bin-path"], in: packageRoot)
      .split(separator: "\n").last.map(String.init) ?? ""
    let frameworks = simulatorFrameworkPaths(
      under: URL(fileURLWithPath: scratch).appendingPathComponent("artifacts"))
    let directory = URL(fileURLWithPath: scratch).appendingPathComponent("symbol-graphs")
    try? FileManager.default.removeItem(at: directory)
    do {
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    } catch {
      throw SymbolGraphError(description: "no directory for the symbol graphs: \(error)")
    }
    var graphs: [SymbolGraph] = []
    for module in modules {
      _ = try output(
        of: [
          "xcrun", "swift-symbolgraph-extract", "-module-name", module, "-I", products,
          "-I", "\(products)/include", "-target", "\(architecture)-apple-ios\(version)-simulator",
          "-sdk", sdk, "-minimum-access-level", "internal", "-skip-synthesized-members",
          "-output-dir", directory.path,
        ] + frameworks.flatMap { ["-F", $0] },
        in: packageRoot
      )
      let url = directory.appendingPathComponent("\(module).symbols.json")
      guard let text = SourceTree.read(url) else {
        throw SymbolGraphError(description: "no iOS symbol graph was written for \(module)")
      }
      graphs.append(try parse(text))
      for url in extensionGraphs(of: module, in: directory) {
        guard let text = SourceTree.read(url) else { continue }
        graphs.append(try parse(text))
      }
    }
    return graphs
  }

  /// simulatorFrameworkPaths is the directory of every binary framework's slice for the
  /// simulator under a build's artifacts, the place a module that imports one finds it.
  package static func simulatorFrameworkPaths(under artifacts: URL) -> [String] {
    guard
      let walk = FileManager.default.enumerator(
        at: artifacts, includingPropertiesForKeys: nil, options: [.skipsHiddenFiles])
    else { return [] }
    var paths: [String] = []
    for case let url as URL in walk
    where url.pathExtension == "framework"
      && url.deletingLastPathComponent().lastPathComponent.hasSuffix("-simulator")
      && url.deletingLastPathComponent().deletingLastPathComponent().pathExtension == "xcframework"
    {
      paths.append(url.deletingLastPathComponent().path)
    }
    return paths.sorted()
  }

  /// output runs a command and answers what it wrote, trimmed, or throws what it said where it
  /// failed.
  private static func output(of arguments: [String], in directory: URL) throws(SymbolGraphError)
    -> String
  {
    let outcome: Subprocess.Outcome
    do {
      outcome = try Subprocess.run(arguments, in: directory)
    } catch {
      throw SymbolGraphError(description: error.description)
    }
    guard outcome.status == 0 else {
      throw SymbolGraphError(
        description:
          "`\(arguments.prefix(3).joined(separator: " "))` exited \(outcome.status):\n"
          + outcome.output + outcome.errors
      )
    }
    return outcome.output.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// dump asks SwiftPM for the symbol graphs of the package at a root, down to `internal`
  /// declarations, and returns the graphs of the named modules.
  ///
  /// The nested build runs in a scratch directory of its own, since the gate that calls this
  /// is itself started by SwiftPM, which holds the main one.
  package static func dump(
    packageRoot: URL,
    modules: [String]
  ) throws(SymbolGraphError) -> [SymbolGraph] {
    let scratch = packageRoot.appendingPathComponent(".build/nested-\(Subprocess.hostName)").path
    let outcome: Subprocess.Outcome
    do {
      outcome = try Subprocess.run(
        [
          "swift", "package", "--scratch-path", scratch, "dump-symbol-graph",
          "--minimum-access-level", "internal", "--skip-synthesized-members",
        ],
        in: packageRoot
      )
    } catch {
      throw SymbolGraphError(description: error.description)
    }
    guard outcome.status == 0 else {
      throw SymbolGraphError(
        description:
          "`swift package dump-symbol-graph` exited \(outcome.status):\n"
          + outcome.output + outcome.errors
      )
    }
    // SwiftPM says where it wrote, and the directory differs by build system and by host.
    let marker = "Files written to "
    let lines = (outcome.output + "\n" + outcome.errors).split(separator: "\n")
    guard let line = lines.last(where: { $0.contains(marker) }),
      let range = line.range(of: marker)
    else {
      throw SymbolGraphError(description: "SwiftPM did not say where it wrote the symbol graphs")
    }
    let directory = URL(fileURLWithPath: String(line[range.upperBound...]))
    var graphs: [SymbolGraph] = []
    for module in modules {
      let url = directory.appendingPathComponent("\(module).symbols.json")
      guard let text = SourceTree.read(url) else {
        throw SymbolGraphError(description: "no symbol graph was written for \(module)")
      }
      graphs.append(try parse(text))
      for url in extensionGraphs(of: module, in: directory) {
        guard let text = SourceTree.read(url) else { continue }
        graphs.append(try parse(text))
      }
    }
    return graphs
  }
}
