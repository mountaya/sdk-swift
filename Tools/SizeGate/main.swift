import Foundation
import GateSupport

// The app-size gate of SPEC.md section 7, run as `mise run size:check` at the repository root, on
// macOS: Trail, the sample app the contract's `sdk/trail.yaml` describes, built in release for an
// iOS device, and what each product adds to its executable, read from the linker's map, held to
// `Tests/BoundaryTests/Size/ios.json` (`AppSize`).

let usage = """
  Builds Trail, the sample app under Examples/Trail, over the four products, in release for an
  iOS device, on macOS alone:

    swift build -c release --package-path Examples/Trail --product Trail --triple arm64-apple-ios \\
      --sdk "$(xcrun --sdk iphoneos --show-sdk-path)" -Xlinker -map -Xlinker <map>

  in .build/trail-ios-release-<swift>, then reads the linker's map module by module and holds
  each product's bytes, and each module the SDK brings, with its package and the version
  Examples/Trail/Package.resolved pins, to Tests/BoundaryTests/Size/ios.json. A share that grows
  past 2% of its baseline or 16 KiB, whichever is larger, fails, and so does a module the baseline
  does not record; a baseline measured to another version of sdk/trail.yaml, read from the
  contract checkout (../schemas, or MOUNTAYA_SCHEMAS_DIR), or with another Xcode or Swift, is
  reported and not compared, and so is a module brought at another version.
  MOUNTAYA_SIZE_BASELINE=write records the figures after a deliberate change.

    swift run SizeGate [--map <file>]

  --map reads a map a build already wrote, in place of a build.
  """

/// Report is what the gate checked and found, printed as the other gates print theirs.
struct Report {
  var checked = "no release build was measured"
  var findings: [String] = []
  var notes: [String] = []

  /// finish prints the report and ends the gate, failing it where it found anything.
  func finish() -> Never {
    Swift.print("size:check: \(checked)")
    for note in notes {
      Swift.print("  · \(note)")
    }
    for finding in findings {
      Swift.print("  ✗ \(finding)")
    }
    if findings.isEmpty {
      Swift.print("✓ size:check passes.")
      exit(0)
    }
    Swift.print(
      "✗ size:check fails: \(findings.count) \(findings.count == 1 ? "finding" : "findings").")
    exit(1)
  }
}

/// refuse prints why the gate cannot run here, and stops it.
func refuse(_ message: String) -> Never {
  FileHandle.standardError.write(Data("size:check: \(message)\n".utf8))
  exit(2)
}

let arguments = Array(CommandLine.arguments.dropFirst())
if arguments.contains("--help") || arguments.contains("-h") {
  print(usage)
  exit(0)
}

#if os(macOS)
  let root = URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
  guard FileManager.default.fileExists(atPath: root.appendingPathComponent("Package.swift").path)
  else {
    refuse("SizeGate runs at the repository root: `mise run size:check`")
  }

  var given: String?
  var rest = arguments[...]
  while let argument = rest.popFirst() {
    guard argument == "--map", let path = rest.popFirst() else {
      refuse("unknown argument `\(argument)`: `swift run SizeGate --help`")
    }
    given = path
  }

  /// ran is how a command that succeeded ended, or nil where it cannot be run or fails.
  func ran(_ command: [String]) -> Subprocess.Outcome? {
    guard let outcome = try? Subprocess.run(command, in: root), outcome.status == 0 else {
      return nil
    }
    return outcome
  }

  // The scenario the app does, the version of the contract's sdk/trail.yaml, which the baseline
  // records and is compared to.
  let schemas =
    ProcessInfo.processInfo.environment["MOUNTAYA_SCHEMAS_DIR"].flatMap {
      $0.isEmpty ? nil : URL(fileURLWithPath: $0)
    } ?? root.deletingLastPathComponent().appendingPathComponent("schemas")
  let scenario: Int
  do {
    guard let text = SourceTree.read(schemas.appendingPathComponent("sdk/trail.yaml")) else {
      refuse(
        "no sdk/trail.yaml in \(schemas.path), whose version the baseline records: check "
          + "mountaya/schemas out beside this repository, or point MOUNTAYA_SCHEMAS_DIR at it")
    }
    scenario = try TrailScenario.parse(text).version
  } catch {
    refuse("\(error)")
  }

  // The driver prints its own version on the error stream, and the compiler's on the output.
  guard
    let xcode = ran(["xcodebuild", "-version"]).flatMap({ AppSize.xcodeVersion(from: $0.output) }),
    let swift = ran(["swift", "--version"]).flatMap({
      AppSize.swiftVersion(from: $0.output + "\n" + $0.errors)
    }),
    let scratch = AppSize.scratch(swift: swift)
  else {
    refuse("`xcodebuild -version` or `swift --version` named no version: is Xcode selected?")
  }
  let toolchain = AppSize.Toolchain(xcode: xcode, swift: swift)
  let products: [PackageManifest.Product]
  do {
    products = try PackageManifest.load(packageRoot: root).products
  } catch {
    refuse("the package description cannot be read: \(error)")
  }

  var report = Report()
  let built = root.appendingPathComponent(scratch).appendingPathComponent("\(AppSize.app).map")
  let map = given.map { URL(fileURLWithPath: $0, relativeTo: root) } ?? built
  if given == nil {
    guard
      let sdk = ran(["xcrun", "--sdk", "iphoneos", "--show-sdk-path"])?.output
        .trimmingCharacters(in: .whitespacesAndNewlines), !sdk.isEmpty
    else {
      refuse(
        "`xcrun --sdk iphoneos --show-sdk-path` named no SDK: is Xcode's iOS platform installed?")
    }
    let build = AppSize.buildArguments(
      scratch: root.appendingPathComponent(scratch).path, sdk: sdk, map: built.path)
    // The linker writes the map only when it links, and a build with nothing to compile links
    // nothing, so the executable goes with the map an earlier build left: every run links the app
    // again, and the map it reads is this build's.
    try? FileManager.default.removeItem(at: built)
    if let products = ran(build + ["--show-bin-path"])?.output.split(separator: "\n").last {
      try? FileManager.default.removeItem(
        at: URL(fileURLWithPath: String(products)).appendingPathComponent(AppSize.app))
    }
    print("\n▸ size:check: \(AppSize.command(scratch: scratch))")
    // The build's own output streams through, since a release build of the SDK takes minutes, and
    // what this gate printed goes before it, where a pipe would hold it back.
    fflush(nil)
    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
    process.arguments = build
    process.currentDirectoryURL = root
    do {
      try process.run()
    } catch {
      refuse("`swift build` could not be started: \(error)")
    }
    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      report.findings.append(
        "\(AppSize.example): the release build for an iOS device failed with exit code "
          + "\(process.terminationStatus): its output is above")
      report.finish()
    }
  }

  // Each module of another package the build links is held with the package that holds it, read
  // off each package's own description, and the version Trail's Package.resolved pins it at.
  var brought: [String: AppSize.BroughtPackage] = [:]
  do {
    guard
      let tree = ran(
        AppSize.dependenciesArguments(scratch: root.appendingPathComponent(scratch).path))
    else {
      refuse(
        "`swift package show-dependencies` failed in \(scratch): build the app once, without "
          + "--map, so its packages are resolved there")
    }
    let pins = AppSize.pinnedVersions(
      in: SourceTree.read(root.appendingPathComponent("\(AppSize.example)/Package.resolved")) ?? "")
    // This package's own modules are its products', which the gate holds as its shares.
    for package in try AppSize.resolvedPackages(in: tree.output)
    where URL(fileURLWithPath: package.path).standardizedFileURL != root.standardizedFileURL {
      let described = root.appendingPathComponent(scratch)
        .appendingPathComponent("describe").appendingPathComponent(package.identity)
      for target in try PackageManifest.load(
        packageRoot: URL(fileURLWithPath: package.path), scratch: described
      ).targets {
        brought[target.name] = AppSize.BroughtPackage(
          identity: package.identity, version: pins[package.identity] ?? package.version)
      }
    }
  } catch {
    refuse("the packages Trail resolves cannot be read: \(error)")
  }

  let figures: AppSize.Figures
  guard let data = FileManager.default.contents(atPath: map.path) else {
    report.findings.append(
      "\(map.relativePath): no linker map there"
        + (given == nil ? ", though the build passed: did it link \(AppSize.app)?" : ""))
    report.finish()
  }
  do {
    // Decoded leniently: a literal's name in a map may hold bytes that are no UTF-8, and no name
    // is read.
    let text = String(decoding: data, as: UTF8.self)
    figures = AppSize.measure(
      AppSize.linked(try AppSize.parse(text)), products: products, toolchain: toolchain,
      scenario: scenario, packages: brought)
  } catch {
    report.findings.append("\(map.relativePath): it reads as no linker map, at \(error)")
    report.finish()
  }
  report.checked =
    "\(given == nil ? "\(AppSize.app)'s release build for an iOS device" : map.relativePath), "
    + "scenario \(scenario) of sdk/trail.yaml, read module by module from the linker's map "
    + "against \(AppSize.baseline)"

  let baseline = root.appendingPathComponent(AppSize.baseline)
  if ProcessInfo.processInfo.environment["MOUNTAYA_SIZE_BASELINE"] == "write" {
    do {
      try FileManager.default.createDirectory(
        at: baseline.deletingLastPathComponent(), withIntermediateDirectories: true)
      try AppSize.printBaseline(figures, build: AppSize.command(scratch: scratch))
        .write(to: baseline, atomically: true, encoding: .utf8)
    } catch {
      refuse("\(AppSize.baseline) cannot be written: \(error)")
    }
    report.notes =
      [
        "recorded \(AppSize.baseline), measured to scenario \(scenario) of sdk/trail.yaml with "
          + "Xcode \(xcode) and Swift \(swift)"
      ] + AppSize.describe(figures)
    report.finish()
  }

  let comparison = AppSize.compare(figures, baseline: SourceTree.read(baseline))
  report.findings = comparison.findings.map { "\(AppSize.baseline): \($0)" }
  report.notes = comparison.notes
  if !report.findings.isEmpty {
    report.notes.append("the linker's map is kept at \(map.path)")
  }
  report.finish()
#else
  refuse("macOS alone builds the iOS app the gate measures, so `mise run ci` runs it there")
#endif
