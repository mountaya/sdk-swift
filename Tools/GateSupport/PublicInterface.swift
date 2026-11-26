import Foundation

/// PublicInterface prints a module's public API from the compiler's symbol graph: one line to a
/// declaration, as the compiler renders it, and one line to the conformances a type declares
/// under one set of constraints, sorted, so a change to the API reads as a diff of Swift.
///
/// It is the baseline SPEC.md section 7 holds the API to. Each declaration is printed whole, its
/// default values, `async`, `throws` and `where` clause included, with the availability it
/// states and the constraints of the extension that declares it, and a property's setter as its
/// declaration writes its access (`settable(_:of:reading:)`).
package enum PublicInterface {
  /// The conformances every type has without declaring them, left out of the listing.
  private static let implied: Set<String> = [
    "Swift.Copyable", "Swift.Escapable", "Swift.SendableMetatype",
  ]

  /// listing prints the public API a symbol graph holds, under a header naming the module.
  package static func listing(_ text: String) throws(SymbolGraphError) -> String {
    try listing([text])
  }

  /// listing prints the public API the symbol graphs of one module hold, its own graph first and
  /// then the graphs of its extensions of other modules' types, under a header naming the module.
  package static func listing(_ texts: [String]) throws(SymbolGraphError) -> String {
    var symbols: [OrderedJSON] = []
    var relationships: [OrderedJSON] = []
    var named: String?
    for text in texts {
      let document: OrderedJSON
      do {
        document = try OrderedJSON.parse(text)
      } catch {
        throw SymbolGraphError(description: "the symbol graph is not JSON: \(error)")
      }
      guard let held = document["symbols"]?.elements,
        let related = document["relationships"]?.elements
      else {
        throw SymbolGraphError(description: "the symbol graph holds no symbols")
      }
      symbols += held
      relationships += related
      named = named ?? document["module"]?["name"]?.stringValue
    }
    let module = named ?? "the module"

    var paths: [String: String] = [:]
    var lines: Set<String> = []
    var sources: [String: LexedSource?] = [:]
    for symbol in symbols {
      // An extension block of another module's type declares nothing: its members are listed.
      guard let precise = symbol["identifier"]?["precise"]?.stringValue,
        let path = symbol["pathComponents"]?.elements?.compactMap(\.stringValue),
        symbol["accessLevel"]?.stringValue != "internal",
        symbol["kind"]?["identifier"]?.stringValue != "swift.extension"
      else { continue }
      let name = path.joined(separator: ".")
      paths[precise] = name
      let spelled = settable(
        spelling(symbol["declarationFragments"]), of: symbol, reading: &sources)
      var line = "\(name)  \(spelled)"
      let availability = available(symbol["availability"])
      if !availability.isEmpty {
        line += "  " + availability
      }
      let constraints = clause(symbol["swiftExtension"]?["constraints"])
      if !constraints.isEmpty {
        line += "  in an extension where \(constraints)"
      }
      lines.insert(line)
    }

    var conformances: [String: Set<String>] = [:]
    for relationship in relationships where relationship["kind"]?.stringValue == "conformsTo" {
      guard let source = relationship["source"]?.stringValue, let name = paths[source],
        let target = relationship["target"]?.stringValue
      else { continue }
      let protocolName = paths[target] ?? relationship["targetFallback"]?.stringValue ?? target
      guard !implied.contains(protocolName) else { continue }
      let constraints = clause(relationship["swiftConstraints"])
      let key = constraints.isEmpty ? "\(name)  :" : "\(name)  : where \(constraints) :"
      conformances[key, default: []].insert(protocolName)
    }
    for (key, protocols) in conformances {
      lines.insert("\(key) \(protocols.sorted().joined(separator: ", "))")
    }

    let header = """
      // The public API of \(module), printed by BoundaryTests from the compiler's symbol graph.
      // Never edit it: a change to the API is printed again with `mise run api:update`, and the
      // diff is the review. A line removed or changed is a break (SPEC.md section 10).

      """
    return header + lines.sorted().joined(separator: "\n") + "\n"
  }

  /// The access levels a setter narrower than a public property's is written with.
  private static let narrowSetters: Set<String> = ["private", "fileprivate", "internal", "package"]

  /// settable is a declaration as the API holds it: one the compiler renders `{ get set }` whose
  /// source writes its setter narrower than public, `private(set)` among them, holds `{ get }`,
  /// since the compiler renders the setter an `@Observable` class's macro writes for every stored
  /// property whatever its access, and a setter made public would otherwise read as no change.
  ///
  /// The source is read at the line the graph locates the declaration's name on, counted from zero,
  /// each file read once into `sources`; a declaration the graph does not locate, or whose source
  /// cannot be read, is held as the compiler renders it.
  private static func settable(
    _ spelled: String, of symbol: OrderedJSON, reading sources: inout [String: LexedSource?]
  ) -> String {
    let suffix = " { get set }"
    guard spelled.hasSuffix(suffix),
      let name = symbol["pathComponents"]?.elements?.last?.stringValue,
      let uri = symbol["location"]?["uri"]?.stringValue, let url = URL(string: uri),
      let row = symbol["location"]?["position"]?["line"]?.numberValue
    else { return spelled }
    if sources[url.path] == nil {
      sources[url.path] = .some(SourceTree.read(url).map(SwiftLexer.lex))
    }
    guard let source = sources[url.path] ?? nil else { return spelled }
    // The tokens of the declaration's line before its name: the modifiers, its setter's among them.
    let line = source.tokens.filter { $0.line == Int(row) + 1 }
    let modifiers = line.prefix { $0.text != name }
    let narrowed = modifiers.indices.contains { index in
      narrowSetters.contains(modifiers[index].text)
        && Array(modifiers[index...].dropFirst().prefix(3).map(\.text)) == ["(", "set", ")"]
    }
    return narrowed ? spelled.dropLast(suffix.count) + " { get }" : spelled
  }

  /// spelling joins a declaration's fragments into the text the compiler renders, the line breaks
  /// it ends some with, a function answering `some View` among them, left out.
  private static func spelling(_ fragments: OrderedJSON?) -> String {
    var spelled = (fragments?.elements ?? []).compactMap { $0["spelling"]?.stringValue }.joined()
    while let last = spelled.unicodeScalars.last, last == "\n" || last == " " {
      spelled.unicodeScalars.removeLast()
    }
    return spelled
  }

  /// available renders what a declaration states of its availability, domain by domain.
  private static func available(_ entries: OrderedJSON?) -> String {
    (entries?.elements ?? []).map { entry in
      var parts = [entry["domain"]?.stringValue ?? "*"]
      if entry["isUnconditionallyUnavailable"]?.boolValue == true {
        parts.append("unavailable")
      }
      if entry["isUnconditionallyDeprecated"]?.boolValue == true {
        parts.append("deprecated")
      }
      for key in ["introduced", "deprecated", "obsoleted"] {
        if let version = entry[key] {
          parts.append("\(key): \(version.versionText)")
        }
      }
      if let message = entry["message"]?.stringValue {
        parts.append("message: \"\(message)\"")
      }
      if let renamed = entry["renamed"]?.stringValue {
        parts.append("renamed: \"\(renamed)\"")
      }
      return "@available(\(parts.joined(separator: ", ")))"
    }
    .joined(separator: " ")
  }

  /// clause renders generic constraints as a `where` clause's terms, the implied ones left out.
  private static func clause(_ constraints: OrderedJSON?) -> String {
    (constraints?.elements ?? []).compactMap { constraint -> String? in
      guard let lhs = constraint["lhs"]?.stringValue, let rhs = constraint["rhs"]?.stringValue
      else { return nil }
      guard !implied.contains("Swift.\(rhs)") else { return nil }
      let relation = constraint["kind"]?.stringValue == "sameType" ? "==" : ":"
      return "\(lhs) \(relation) \(rhs)"
    }
    .joined(separator: ", ")
  }
}

extension OrderedJSON {
  /// versionText renders a symbol graph's semantic version object, such as `14.0`.
  fileprivate var versionText: String {
    let parts = ["major", "minor", "patch"].compactMap { self[$0]?.numberValue.map { Int($0) } }
    return parts.map(String.init).joined(separator: ".")
  }
}
