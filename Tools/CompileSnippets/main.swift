import Foundation
import GateSupport

// `mise run snippets -- <file.md> [...]`: compile every Swift fence of the Markdown documents named,
// wherever they live, against the products as an app or a server imports them. Each fence is read
// as the README's are, `<!-- swift:skip <reason> -->` on the line above it opting it out, printed
// as a file of its own under `.build/snippets`, and type-checked against the consumer package in
// `Tests/Consumer`: for the iOS simulator, with the `Elements` trait, where it imports a module of
// an app, and for macOS otherwise (DocumentSnippets says which). It names each fence that does not
// compile by its document's path and line, ends on how many it compiled and skipped, and exits 1
// where one failed or a document could not be read.
//
// A relative path is read from the directory `mise run` was started in, or from this one where
// it was not. It runs on macOS, where Xcode builds the products for both platforms.

let usage = "usage: mise run snippets -- <file.md> [<file.md> ...]"
let documents = CommandLine.arguments.dropFirst().filter { $0 != "--" }
guard !documents.isEmpty else {
  FileHandle.standardError.write(Data("\(usage)\n".utf8))
  exit(2)
}

#if os(macOS)
  /// Printed is one fence written to its file, waiting for the compiler.
  struct Printed {
    let document: String
    let fence: ReadmeSnippets.Fence
    let file: URL
    let source: DocumentSnippets.Source
    let platform: ConsumerPackage.Platform
  }

  /// fail writes what stopped the run and exits with its status.
  func fail(_ message: String, status: Int32 = 1) -> Never {
    FileHandle.standardError.write(Data("\(message)\n".utf8))
    exit(status)
  }

  let environment = ProcessInfo.processInfo.environment
  let origin = URL(
    fileURLWithPath: environment["MISE_ORIGINAL_CWD"] ?? FileManager.default.currentDirectoryPath,
    isDirectory: true)
  let root: URL
  do {
    root = try ConsumerPackage.root()
  } catch {
    fail("CompileSnippets could not find its repository: \(error)", status: 2)
  }
  let output = root.appendingPathComponent(DocumentSnippets.directory)
  try? FileManager.default.removeItem(at: output)

  var tally = DocumentSnippets.Tally()
  var printed: [Printed] = []
  for (position, document) in documents.enumerated() {
    let url = URL(fileURLWithPath: document, relativeTo: origin).standardizedFileURL
    guard let text = SourceTree.read(url) else {
      print("\(document): cannot be read at \(url.path)")
      tally.refused += 1
      continue
    }
    let fences: [ReadmeSnippets.Fence]
    do {
      fences = try ReadmeSnippets.fences(in: text)
    } catch {
      print("\(document): \(error)")
      tally.refused += 1
      continue
    }
    tally.documents += 1
    for fence in fences {
      if let reason = fence.skipped {
        print("\(document):\(fence.line): skipped, \(reason)")
        tally.skipped += 1
        continue
      }
      let source = DocumentSnippets.source(of: fence)
      let folder = output.appendingPathComponent(
        DocumentSnippets.folder(position: position + 1, document: document, line: fence.line))
      let file = folder.appendingPathComponent(source.fileName)
      do {
        try FileManager.default.createDirectory(at: folder, withIntermediateDirectories: true)
        try source.text.write(to: file, atomically: true, encoding: .utf8)
      } catch {
        fail("CompileSnippets could not print \(file.path): \(error)")
      }
      printed.append(
        Printed(
          document: document, fence: fence, file: file, source: source,
          platform: DocumentSnippets.platform(of: fence)))
    }
  }

  /// name is how a platform is named to the reader.
  func name(of platform: ConsumerPackage.Platform) -> String {
    platform == .iosSimulator ? "the iOS simulator" : "macOS"
  }

  /// testingOptions finds Swift Testing and XCTest for a platform: they are the platform's own
  /// frameworks, beside its SDK rather than in it, and `@Test` and `#expect` are macros the
  /// toolchain's plugin expands.
  func testingOptions(for platform: ConsumerPackage.Platform, in root: URL) throws -> [String] {
    let platformPath = try Subprocess.run(
      ["xcrun", "--sdk", platform.sdk, "--show-sdk-platform-path"], in: root
    ).output.trimmingCharacters(in: .whitespacesAndNewlines)
    let compiler = try Subprocess.run(["xcrun", "--find", "swiftc"], in: root).output
      .trimmingCharacters(in: .whitespacesAndNewlines)
    let toolchain = URL(fileURLWithPath: compiler).deletingLastPathComponent()
      .deletingLastPathComponent()
    return [
      "-F", "\(platformPath)/Developer/Library/Frameworks",
      "-plugin-path", toolchain.appendingPathComponent("lib/swift/host/plugins/testing").path,
    ]
  }

  // The consumer is built for a platform only where a fence is written for it, each build once.
  var checkers: [ConsumerPackage.Platform: (ConsumerPackage.Checker, [String])] = [:]
  for platform in [ConsumerPackage.Platform.macos, .iosSimulator]
  where printed.contains(where: { $0.platform == platform }) {
    print("Building the consumer package for \(name(of: platform))…")
    do {
      let built =
        platform == .iosSimulator
        ? try ConsumerPackage.iosBuild.get() : try ConsumerPackage.build.get()
      guard built.status == 0 else {
        fail("The consumer package does not build for \(name(of: platform)):\n\(built.log)")
      }
      checkers[platform] = (
        try ConsumerPackage.Checker(against: built, for: platform),
        try testingOptions(for: platform, in: root)
      )
    } catch {
      fail("The consumer package could not be built for \(name(of: platform)): \(error)")
    }
  }

  for snippet in printed {
    guard let (checker, testing) = checkers[snippet.platform] else { continue }
    switch snippet.platform {
    case .iosSimulator: tally.iosSimulator += 1
    default: tally.macos += 1
    }
    let checked: ConsumerPackage.Checked
    do {
      let library = snippet.source.isLibrary ? ["-parse-as-library"] : []
      checked = try checker.check([snippet.file], adding: testing + library)
    } catch {
      fail("The compiler could not be run on \(snippet.file.path): \(error)")
    }
    guard checked.status != 0 else { continue }
    tally.failed += 1
    print(
      "\(snippet.document):\(snippet.fence.line): does not compile for "
        + "\(name(of: snippet.platform)):")
    for line in DocumentSnippets.diagnostics(
      checked.diagnostics, file: snippet.file.path, document: snippet.document,
      fenceLine: snippet.fence.line)
    {
      print("  \(line)")
    }
  }

  print(tally.summary)
  exit(tally.passes ? 0 : 1)
#else
  FileHandle.standardError.write(
    Data(
      """
      CompileSnippets runs on macOS, where Xcode builds the products for macOS and for the iOS \
      simulator.

      """.utf8))
  exit(2)
#endif
