import Foundation

/// SourceTree reads the files of a directory, in an order that does not depend on the file
/// system.
package enum SourceTree {
  /// Entry is one file or directory below a root, named by its path relative to that root.
  package struct Entry: Sendable, Hashable {
    package let relativePath: String
    package let isDirectory: Bool

    package init(relativePath: String, isDirectory: Bool) {
      self.relativePath = relativePath
      self.isDirectory = isDirectory
    }

    /// components is the path split at its separators.
    package var components: [String] {
      relativePath.split(separator: "/").map(String.init)
    }
  }

  /// entries lists every file and directory below a root, sorted by path. Hidden entries, a
  /// name starting with a dot, are left out with everything beneath them. A root that does
  /// not exist has no entries.
  package static func entries(under root: URL) -> [Entry] {
    var found: [Entry] = []
    collect(directory: root, prefix: "", into: &found)
    return found.sorted { $0.relativePath < $1.relativePath }
  }

  /// swiftFiles lists the Swift files below a root, sorted by path.
  package static func swiftFiles(under root: URL) -> [String] {
    entries(under: root)
      .filter { !$0.isDirectory && $0.relativePath.hasSuffix(".swift") }
      .map(\.relativePath)
  }

  /// read returns a file's text, or nil when it cannot be read as UTF-8.
  package static func read(_ url: URL) -> String? {
    try? String(contentsOf: url, encoding: .utf8)
  }

  /// packageRoot walks up from a file to the directory holding `Package.swift`.
  package static func packageRoot(from filePath: String) -> URL? {
    var directory = URL(fileURLWithPath: filePath).deletingLastPathComponent()
    while directory.path != "/" {
      if FileManager.default.fileExists(
        atPath: directory.appendingPathComponent("Package.swift").path)
      {
        return directory
      }
      directory = directory.deletingLastPathComponent()
    }
    return nil
  }

  private static func collect(directory: URL, prefix: String, into found: inout [Entry]) {
    guard let names = try? FileManager.default.contentsOfDirectory(atPath: directory.path) else {
      return
    }
    for name in names where !name.hasPrefix(".") {
      let url = directory.appendingPathComponent(name)
      let path = prefix.isEmpty ? name : prefix + "/" + name
      var isDirectory: ObjCBool = false
      guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory) else {
        continue
      }
      found.append(Entry(relativePath: path, isDirectory: isDirectory.boolValue))
      if isDirectory.boolValue {
        collect(directory: url, prefix: path, into: &found)
      }
    }
  }
}
