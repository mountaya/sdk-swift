import Foundation
import GateSupport

/// PackageTree is this repository as the boundary suites read it: the package description
/// SwiftPM gives, and the lexed source of every file.
enum PackageTree {
  /// SourceFile is one Swift file of the repository.
  struct SourceFile: Sendable {
    /// path is relative to the repository root, such as `Sources/MountayaClient/Seams/X.swift`.
    let path: String
    let source: LexedSource
  }

  /// ShippedFile is one Swift file of a shipped target, by its path inside the target.
  struct ShippedFile: Sendable {
    let target: String
    let relativePath: String
    let source: LexedSource
  }

  struct Unreadable: Error, CustomStringConvertible {
    let description: String
  }

  static let root: URL? = SourceTree.packageRoot(from: #filePath)

  /// The package description. The target and product lists every suite walks come from it,
  /// never from a list kept here.
  static let manifest: Result<PackageManifest, any Error> = Result(catching: {
    guard let root else {
      throw Unreadable(description: "no Package.swift above \(#filePath)")
    }
    return try PackageManifest.load(packageRoot: root)
  })

  /// shippedFiles lists every Swift file of every library target under `Sources/`.
  static func shippedFiles() throws -> [ShippedFile] {
    guard let root else {
      throw Unreadable(description: "no Package.swift above \(#filePath)")
    }
    var files: [ShippedFile] = []
    for target in try manifest.get().shippedTargets {
      let directory = root.appendingPathComponent(target.path)
      for relativePath in SourceTree.swiftFiles(under: directory) {
        guard let text = SourceTree.read(directory.appendingPathComponent(relativePath)) else {
          throw Unreadable(description: "\(target.path)/\(relativePath) cannot be read")
        }
        files.append(
          ShippedFile(target: target.name, relativePath: relativePath, source: SwiftLexer.lex(text))
        )
      }
    }
    return files
  }

  /// allFiles lists every Swift file under `Sources/`, `Tools/` and `Tests/`, and the manifest.
  static func allFiles() throws -> [SourceFile] {
    guard let root else {
      throw Unreadable(description: "no Package.swift above \(#filePath)")
    }
    var paths = ["Package.swift"]
    for directory in ["Sources", "Tools", "Tests"] {
      paths += SourceTree.swiftFiles(under: root.appendingPathComponent(directory)).map {
        "\(directory)/\($0)"
      }
    }
    return try paths.map { path in
      guard let text = SourceTree.read(root.appendingPathComponent(path)) else {
        throw Unreadable(description: "\(path) cannot be read")
      }
      return SourceFile(path: path, source: SwiftLexer.lex(text))
    }
  }

  static func describe(_ findings: [BoundaryRules.Finding]) -> String {
    findings.map { "\($0.file):\($0.line): \($0.message)" }.joined(separator: "\n")
  }
}
