import Foundation

/// PackageManifest is what `swift package describe --type json` says about this package: its
/// targets, what each depends on, and its products.
///
/// Every gate that walks the package reads its lists from here. A list kept by hand is the one
/// that misses the target added next.
package struct PackageManifest: Sendable {
  package let targets: [Target]
  package let products: [Product]

  /// Target is one target of the package.
  package struct Target: Sendable, Hashable {
    package let name: String
    /// path is relative to the package root, such as `Sources/MountayaClient`.
    package let path: String
    /// type is SwiftPM's own word: `library`, `executable`, `test`.
    package let type: String
    package let sources: [String]
    package let targetDependencies: [String]
    package let productDependencies: [String]

    package init(
      name: String,
      path: String,
      type: String,
      sources: [String] = [],
      targetDependencies: [String] = [],
      productDependencies: [String] = []
    ) {
      self.name = name
      self.path = path
      self.type = type
      self.sources = sources
      self.targetDependencies = targetDependencies
      self.productDependencies = productDependencies
    }
  }

  /// Product is one product of the package.
  package struct Product: Sendable, Hashable {
    package let name: String
    package let targets: [String]
    package let isLibrary: Bool

    package init(name: String, targets: [String], isLibrary: Bool) {
      self.name = name
      self.targets = targets
      self.isLibrary = isLibrary
    }
  }

  package init(targets: [Target], products: [Product]) {
    self.targets = targets
    self.products = products
  }

  /// shippedTargets is the library targets under `Sources/`, the ones a product can carry.
  package var shippedTargets: [Target] {
    targets
      .filter { $0.type == "library" && $0.path.hasPrefix("Sources/") }
      .sorted { $0.name < $1.name }
  }
}

/// PackageManifestError says why the package description could not be read.
package struct PackageManifestError: Error, Sendable, CustomStringConvertible {
  package let description: String
}

extension PackageManifest {
  /// The variable naming a file that already holds the description, for a caller that cannot
  /// run SwiftPM itself.
  package static let describeFileVariable = "MOUNTAYA_PACKAGE_DESCRIBE"

  /// load reads the description of the package at a root.
  ///
  /// It asks SwiftPM, giving the nested call a scratch directory of its own, `scratch` where it is
  /// given and the root's `.build/nested-<host>` otherwise: a gate usually runs under `swift test`
  /// or `swift run`, and a second SwiftPM in the same scratch directory waits for the first one to
  /// finish. Only this package's own description may come from `MOUNTAYA_PACKAGE_DESCRIBE`, so a
  /// call naming a scratch, which reads another package, never does.
  package static func load(packageRoot: URL, scratch: URL? = nil) throws(PackageManifestError)
    -> PackageManifest
  {
    if scratch == nil, let path = ProcessInfo.processInfo.environment[describeFileVariable],
      !path.isEmpty
    {
      guard let text = SourceTree.read(URL(fileURLWithPath: path)) else {
        throw PackageManifestError(description: "\(describeFileVariable) names an unreadable file")
      }
      return try parse(text)
    }
    let nested = packageRoot.appendingPathComponent(".build/nested-\(Subprocess.hostName)")
    let scratch = (scratch ?? nested).path
    let outcome: Subprocess.Outcome
    do {
      outcome = try Subprocess.run(
        ["swift", "package", "--scratch-path", scratch, "describe", "--type", "json"],
        in: packageRoot
      )
    } catch {
      throw PackageManifestError(description: error.description)
    }
    guard outcome.status == 0 else {
      throw PackageManifestError(
        description: "`swift package describe` exited \(outcome.status): \(outcome.errors)"
      )
    }
    return try parse(outcome.output)
  }

  /// parse reads the JSON `swift package describe --type json` prints.
  package static func parse(_ text: String) throws(PackageManifestError) -> PackageManifest {
    // SwiftPM may print a notice before the document, so the document starts at its brace.
    guard let start = text.firstIndex(of: "{") else {
      throw PackageManifestError(description: "the package description holds no JSON object")
    }
    let document: OrderedJSON
    do {
      document = try OrderedJSON.parse(String(text[start...]))
    } catch {
      throw PackageManifestError(description: "the package description is not JSON: \(error)")
    }
    guard let targets = document["targets"]?.elements,
      let products = document["products"]?.elements
    else {
      throw PackageManifestError(description: "the package description lists no targets")
    }
    return PackageManifest(
      targets: try targets.map(target(from:)),
      products: try products.map(product(from:))
    )
  }

  private static func target(from value: OrderedJSON) throws(PackageManifestError) -> Target {
    guard let name = value["name"]?.stringValue, let path = value["path"]?.stringValue,
      let type = value["type"]?.stringValue
    else {
      throw PackageManifestError(description: "a target without a name, a path or a type")
    }
    return Target(
      name: name,
      path: path,
      type: type,
      sources: strings(value["sources"]),
      targetDependencies: strings(value["target_dependencies"]),
      productDependencies: strings(value["product_dependencies"])
    )
  }

  private static func product(from value: OrderedJSON) throws(PackageManifestError) -> Product {
    guard let name = value["name"]?.stringValue else {
      throw PackageManifestError(description: "a product without a name")
    }
    return Product(
      name: name,
      targets: strings(value["targets"]),
      isLibrary: value["type"]?["library"] != nil
    )
  }

  private static func strings(_ value: OrderedJSON?) -> [String] {
    value?.elements?.compactMap(\.stringValue) ?? []
  }
}
