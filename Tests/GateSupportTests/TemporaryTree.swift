import Foundation

/// TemporaryTree is a directory a test fills with files and removes when it is done.
struct TemporaryTree {
  let root: URL

  init() throws {
    root = FileManager.default.temporaryDirectory
      .appendingPathComponent("mountaya-gate-tests-\(UUID().uuidString)")
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
  }

  /// Writes a file at a path relative to the root, creating the directories above it.
  func write(_ path: String, contents: String = "") throws {
    let url = root.appendingPathComponent(path)
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(),
      withIntermediateDirectories: true
    )
    try contents.write(to: url, atomically: true, encoding: .utf8)
  }

  /// Creates an empty directory at a path relative to the root.
  func makeDirectory(_ path: String) throws {
    try FileManager.default.createDirectory(
      at: root.appendingPathComponent(path),
      withIntermediateDirectories: true
    )
  }

  func remove() {
    try? FileManager.default.removeItem(at: root)
  }
}
