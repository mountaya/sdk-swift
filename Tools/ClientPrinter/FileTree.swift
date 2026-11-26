import Foundation

/// FileTree reads, compares and writes the printed directory.
package enum FileTree {
  /// files lists every file under a directory by its path relative to it, in path order.
  package static func files(under directory: URL) -> [String] {
    guard
      let enumerator = FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: [.isRegularFileKey]
      )
    else { return [] }
    let base = directory.standardizedFileURL.path + "/"
    var paths: [String] = []
    for case let url as URL in enumerator {
      guard (try? url.resourceValues(forKeys: [.isRegularFileKey]).isRegularFile) == true else {
        continue
      }
      let path = url.standardizedFileURL.path
      if path.hasPrefix(base) {
        paths.append(String(path.dropFirst(base.count)))
      }
    }
    return paths.sorted()
  }

  /// firstDifference names the first way the files on disk differ from the printed ones, or
  /// returns nil where they are the same bytes.
  package static func firstDifference(
    printed: [GeneratedFile],
    onDisk: [String],
    at directory: URL
  ) -> String? {
    let printedPaths = Set(printed.map(\.path))
    if let extra = onDisk.first(where: { !printedPaths.contains($0) }) {
      return "first difference: `\(extra)` is on disk and not printed"
    }
    for file in printed {
      let url = directory.appendingPathComponent(file.path)
      guard let existing = try? String(contentsOf: url, encoding: .utf8) else {
        return "first difference: `\(file.path)` is printed and not on disk"
      }
      if existing != file.text {
        let old = existing.split(separator: "\n", omittingEmptySubsequences: false)
        let new = file.text.split(separator: "\n", omittingEmptySubsequences: false)
        let line =
          zip(old, new).enumerated().first { $0.element.0 != $0.element.1 }.map { $0.offset + 1 }
          ?? min(old.count, new.count)
        return "first difference in `\(file.path)` at line \(line)"
      }
    }
    return nil
  }

  /// write writes every printed file, removes each file on disk it no longer prints, and
  /// removes the directories that leaves empty.
  package static func write(
    _ printed: [GeneratedFile], replacing onDisk: [String], at directory: URL
  )
    throws
  {
    let manager = FileManager.default
    let printedPaths = Set(printed.map(\.path))
    for stale in onDisk where !printedPaths.contains(stale) {
      try manager.removeItem(at: directory.appendingPathComponent(stale))
    }
    for file in printed {
      let url = directory.appendingPathComponent(file.path)
      try manager.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      if (try? String(contentsOf: url, encoding: .utf8)) != file.text {
        try Data(file.text.utf8).write(to: url)
      }
    }
    let directories =
      (manager.enumerator(at: directory, includingPropertiesForKeys: nil)?
      .compactMap { $0 as? URL } ?? [])
      .filter { (try? $0.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true }
      .sorted { $0.path.count > $1.path.count }
    for empty in directories
    where (try? manager.contentsOfDirectory(atPath: empty.path).isEmpty) == true {
      try manager.removeItem(at: empty)
    }
  }
}
