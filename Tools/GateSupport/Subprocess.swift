import Foundation

/// Subprocess runs a command to its end and returns what it wrote.
package enum Subprocess {
  /// Outcome is a finished command's exit status and its two streams.
  package struct Outcome: Sendable {
    package let status: Int32
    package let output: String
    package let errors: String
  }

  /// hostName tells one host's nested scratch directory from another's. The repository is
  /// mounted into a Linux container by the gate, and a scratch directory shared between two
  /// operating systems holds artifacts neither can use.
  package static var hostName: String {
    #if os(macOS)
      "macos"
    #elseif os(Linux)
      "linux"
    #else
      "host"
    #endif
  }

  /// Failure says a command could not be started at all.
  package struct Failure: Error, Sendable, CustomStringConvertible {
    package let command: String
    package let reason: String

    package var description: String {
      "could not run `\(command)`: \(reason)"
    }
  }

  /// run executes a command found on `PATH`, in a working directory, and waits for it.
  ///
  /// Both streams go to files rather than pipes, so a command that writes more than a pipe
  /// holds cannot block on a reader that is waiting for it to exit.
  package static func run(
    _ arguments: [String],
    in directory: URL,
    environment: [String: String]? = nil
  ) throws(Failure) -> Outcome {
    let command = arguments.joined(separator: " ")
    let scratch = FileManager.default.temporaryDirectory
      .appendingPathComponent("mountaya-gate-\(UUID().uuidString)")
    let outputURL = scratch.appendingPathComponent("stdout")
    let errorsURL = scratch.appendingPathComponent("stderr")
    defer { try? FileManager.default.removeItem(at: scratch) }

    do {
      try FileManager.default.createDirectory(at: scratch, withIntermediateDirectories: true)
      try Data().write(to: outputURL)
      try Data().write(to: errorsURL)
      let output = try FileHandle(forWritingTo: outputURL)
      let errors = try FileHandle(forWritingTo: errorsURL)
      defer {
        try? output.close()
        try? errors.close()
      }

      let process = Process()
      process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
      process.arguments = arguments
      process.currentDirectoryURL = directory
      process.standardOutput = output
      process.standardError = errors
      if let environment {
        process.environment = environment
      }
      try process.run()
      process.waitUntilExit()

      return Outcome(
        status: process.terminationStatus,
        output: SourceTree.read(outputURL) ?? "",
        errors: SourceTree.read(errorsURL) ?? ""
      )
    } catch {
      throw Failure(command: command, reason: "\(error)")
    }
  }
}
