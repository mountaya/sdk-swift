import Foundation

/// ConsumerPackage is the consumer in `Tests/Consumer`, and its one build per host and toolchain:
/// the outside-in package of SPEC.md section 7, which imports each product as an app does.
///
/// BoundaryTests builds it and compiles the README's snippets in it, and type-checks the skill's
/// against it; `mise run snippets` type-checks the Swift fences of the Markdown documents it is
/// handed against the same builds, so a document outside this repository is held to the products
/// as the README is.
package enum ConsumerPackage {
  /// Unreadable says a file or a directory the consumer needs cannot be read.
  package struct Unreadable: Error, Sendable, CustomStringConvertible {
    package let description: String

    package init(description: String) {
      self.description = description
    }
  }

  /// Build is how a build ended, where it left its products, and the arguments that built it,
  /// which name its products' directory again.
  package struct Build: Sendable {
    package let status: Int32
    package let log: String
    package let scratch: URL
    package let arguments: [String]

    package init(status: Int32, log: String, scratch: URL, arguments: [String]) {
      self.status = status
      self.log = log
      self.scratch = scratch
      self.arguments = arguments
    }
  }

  /// Platform is a platform a module's symbol graph is read for, or a file type-checked for: its
  /// SDK and its target triple.
  package enum Platform: Sendable {
    case macos
    case iosSimulator
    case iosDevice

    package var sdk: String {
      switch self {
      case .macos: "macosx"
      case .iosSimulator: "iphonesimulator"
      case .iosDevice: "iphoneos"
      }
    }

    /// target is the platform's triple at a version, with no version where it is nil, so a
    /// build takes the package's floor.
    package func target(_ version: String?) -> String {
      #if arch(arm64)
        let architecture = "arm64"
      #else
        let architecture = "x86_64"
      #endif
      let at = version ?? ""
      switch self {
      case .macos: return "\(architecture)-apple-macosx\(at)"
      case .iosSimulator: return "\(architecture)-apple-ios\(at)-simulator"
      case .iosDevice: return "arm64-apple-ios\(at)"
      }
    }
  }

  /// compiler names the toolchain this module was built with, which the consumer's scratch
  /// directory is kept apart by: the gate runs two toolchains over one checkout.
  package static let compiler: String = {
    #if compiler(>=6.4)
      "6.4"
    #elseif compiler(>=6.3)
      "6.3"
    #else
      "6.2"
    #endif
  }()

  /// root is the repository's root, the directory holding the package's `Package.swift`.
  package static func root() throws -> URL {
    guard let root = SourceTree.packageRoot(from: #filePath) else {
      throw Unreadable(description: "no Package.swift above \(#filePath)")
    }
    return root
  }

  /// build builds the consumer once, in a scratch directory of its own under this package's
  /// `.build`, since the suite runs inside SwiftPM, which holds the main one.
  ///
  /// A consumer that has resolved nothing yet starts from this package's own pins, so its first
  /// build resolves the versions the gate tests and fetches nothing it need not.
  package static let build: Result<Build, any Error> = Result {
    let root = try ConsumerPackage.root()
    let consumer = root.appendingPathComponent("Tests/Consumer")
    let resolved = consumer.appendingPathComponent("Package.resolved")
    if !FileManager.default.fileExists(atPath: resolved.path) {
      try FileManager.default.copyItem(
        at: root.appendingPathComponent("Package.resolved"), to: resolved)
    }
    let scratch = root.appendingPathComponent(
      ".build/consumer-\(Subprocess.hostName)-\(compiler)")
    let arguments = ["--package-path", consumer.path, "--scratch-path", scratch.path]
    let outcome = try Subprocess.run(["swift", "build"] + arguments, in: root)
    return Build(
      status: outcome.status, log: outcome.output + outcome.errors, scratch: scratch,
      arguments: arguments)
  }

  #if os(macOS)
    /// iosBuild builds the consumer once for the iOS simulator, its Elements trait on as an app
    /// turns it on, which is the build that compiles the voice over the system's speech and the
    /// view over MapLibre from outside.
    package static let iosBuild: Result<Build, any Error> = Result {
      let root = try ConsumerPackage.root()
      let consumer = root.appendingPathComponent("Tests/Consumer")
      let scratch = root.appendingPathComponent(".build/consumer-ios-simulator-\(compiler)")
      let arguments = [
        "--package-path", consumer.path, "--scratch-path", scratch.path,
        "--triple", Platform.iosSimulator.target(nil), "--sdk", try sdkPath(.iosSimulator),
      ]
      _ = try build.get()
      let outcome = try Subprocess.run(["swift", "build"] + arguments, in: root)
      return Build(
        status: outcome.status, log: outcome.output + outcome.errors, scratch: scratch,
        arguments: arguments)
    }

    /// sdkPath is the path of a platform's SDK in the selected Xcode.
    package static func sdkPath(_ platform: Platform) throws -> String {
      try Subprocess.run(
        ["xcrun", "--sdk", platform.sdk, "--show-sdk-path"], in: try ConsumerPackage.root()
      ).output.trimmingCharacters(in: .whitespacesAndNewlines)
    }
  #endif

  /// Checked is what the compiler answered of a file: its exit status and what it said.
  package struct Checked: Sendable {
    package let status: Int32
    package let diagnostics: String
  }

  /// settings are the consumer's own Swift settings, `Tests/Consumer/Package.swift`'s, as the
  /// compiler takes them, so a file is type-checked as strictly as the README's snippets build.
  package static let settings = [
    "-enable-upcoming-feature", "ExistentialAny", "-enable-upcoming-feature",
    "MemberImportVisibility", "-warnings-as-errors",
  ]

  /// Checker type-checks files against the modules one build left, for one platform, as the
  /// consumer's own files are: it reads where the build left its products and the platform's SDK
  /// once, and checks as many files as it is handed.
  package struct Checker: Sendable {
    package let build: Build
    package let platform: Platform
    /// products is the directory the build left its modules and frameworks in.
    package let products: String
    /// sdk is the path of the platform's SDK, and version its version, the target's.
    package let sdk: String
    package let version: String

    /// init reads where a build left its products, and the platform's SDK in the selected Xcode.
    package init(against build: Build, for platform: Platform) throws {
      let root = try ConsumerPackage.root()
      self.build = build
      self.platform = platform
      products =
        try Subprocess.run(["swift", "build"] + build.arguments + ["--show-bin-path"], in: root)
        .output.split(separator: "\n").last.map(String.init) ?? ""
      sdk = try Subprocess.run(["xcrun", "--sdk", platform.sdk, "--show-sdk-path"], in: root)
        .output.trimmingCharacters(in: .whitespacesAndNewlines)
      version = try Subprocess.run(
        ["xcrun", "--sdk", platform.sdk, "--show-sdk-version"], in: root
      ).output.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    /// check type-checks files together as one module, each argument of `adding` handed to the
    /// compiler before them, and answers what the compiler says of them. MapLibre is a framework
    /// among the build's products, which an iOS build with the Elements trait names.
    package func check(_ files: [URL], adding options: [String] = []) throws -> Checked {
      let checked = try Subprocess.run(
        ["xcrun", "swiftc", "-typecheck", "-swift-version", "6"] + settings
          + [
            "-I", products, "-I", "\(products)/include", "-F", products,
            "-target", platform.target(version), "-sdk", sdk,
          ] + options + files.map(\.path),
        in: try ConsumerPackage.root()
      )
      return Checked(status: checked.status, diagnostics: checked.output + checked.errors)
    }
  }

  /// typecheck type-checks a file against the modules a build left, as the consumer's own files
  /// are, beside the files it names, and answers what the compiler says of it.
  ///
  /// The file is written to the build's scratch directory as `<name>-<sdk>.swift`, so two checks
  /// of one build each keep a file of their own.
  package static func typecheck(
    _ source: String, against build: Build, for platform: Platform,
    named name: String = "typecheck", beside files: [URL] = []
  ) throws -> Checked {
    let checker = try Checker(against: build, for: platform)
    let file = build.scratch.appendingPathComponent("\(name)-\(platform.sdk).swift")
    try source.write(to: file, atomically: true, encoding: .utf8)
    return try checker.check(files + [file])
  }
}
