import Foundation
import GateSupport
import Testing

/// The outside-in suite of SPEC.md section 7 and the README's snippets of section 10: the
/// consumer package in `Tests/Consumer` depends on this one by path, imports each product as an
/// app does, and is built here, the README's Swift snippets with it.
@Suite("Consumer package")
struct ConsumerPackageTests {
  /// The command that prints the README's snippets afresh.
  static let rewrite =
    "MOUNTAYA_README=write swift test --disable-xctest --filter ConsumerPackageTests"

  @Test("the README's Swift snippets are the ones the consumer compiles, printed from it")
  func snippetsArePrinted() throws {
    let root = try ConsumerPackage.root()
    let readme = try #require(SourceTree.read(root.appendingPathComponent("README.md")))
    let fences = try ReadmeSnippets.fences(in: readme)
    let printed = ReadmeSnippets.file(fences, document: "README.md", rewrite: Self.rewrite)
    let url = root.appendingPathComponent(ConsumerPackage.snippets)

    #expect(fences.contains { $0.skipped == nil }, "README.md compiles no snippet at all")
    if ProcessInfo.processInfo.environment["MOUNTAYA_README"] == "write" {
      try printed.write(to: url, atomically: true, encoding: .utf8)
      return
    }
    #expect(
      SourceTree.read(url) == printed,
      "README.md's snippets moved: run `\(Self.rewrite)` and review the diff"
    )
  }

  @Test("the consumer declares the platform floors the package declares")
  func floors() throws {
    let root = try ConsumerPackage.root()
    let package = try #require(SourceTree.read(root.appendingPathComponent("Package.swift")))
    let consumer = try #require(
      SourceTree.read(root.appendingPathComponent("Tests/Consumer/Package.swift")))

    #expect(ConsumerPackage.platforms(in: package) != nil)
    #expect(ConsumerPackage.platforms(in: consumer) == ConsumerPackage.platforms(in: package))
  }

  /// The README's floors table is the one copy in prose of the package's floors (SPEC.md section
  /// 2): each row is held to the file that declares the floor, the manifest's tools version and its
  /// platforms, and iOS's row to Trail's Xcode project too, the app a developer copies from.
  @Test("the README's floors table states the floors Package.swift and Trail's project declare")
  func readmeFloors() throws {
    let root = try ConsumerPackage.root()
    let readme = try #require(SourceTree.read(root.appendingPathComponent("README.md")))
    let manifest = try #require(SourceTree.read(root.appendingPathComponent("Package.swift")))
    let project = try #require(
      SourceTree.read(root.appendingPathComponent(ConsumerPackage.trailProject)))
    var declared = [
      ReadmeFloors.Floor(
        name: "Swift", version: try #require(SkillCheckout.toolsVersion(ofManifest: manifest)),
        file: "Package.swift")
    ]
    for entry in try #require(ConsumerPackage.platforms(in: manifest)) {
      let (name, version) = try #require(
        SkillCheckout.floor(entry), "`\(entry)` is a platform the check cannot name")
      declared.append(ReadmeFloors.Floor(name: name, version: version, file: "Package.swift"))
    }
    let targets = project.split(separator: "\n").filter {
      $0.contains("IPHONEOS_DEPLOYMENT_TARGET = ")
    }
    try #require(!targets.isEmpty, "Trail's project names no deployment target")
    for line in targets {
      let version = line.split(separator: "=").last.map {
        $0.trimmingCharacters(in: CharacterSet(charactersIn: " ;"))
      }
      let floor = ReadmeFloors.Floor(
        name: "iOS", version: version ?? "", file: ConsumerPackage.trailProject)
      if !declared.contains(floor) {
        declared.append(floor)
      }
    }
    let problems = ReadmeFloors.problems(in: readme, declared: declared)

    #expect(problems.isEmpty, "\(problems.joined(separator: "\n"))")
  }

  /// Trail, the sample app, and its session server are packages an app copies, so each declares
  /// only the platforms it runs on, each at the package's floor, and the Xcode project Trail runs
  /// from targets the package's iOS floor.
  @Test("Trail and its session server declare the package's floor for each platform they name")
  func trailFloors() throws {
    let root = try ConsumerPackage.root()
    let rootManifest = try #require(SourceTree.read(root.appendingPathComponent("Package.swift")))
    let package = try #require(ConsumerPackage.platforms(in: rootManifest))
    for example in ["Examples/Trail/Package.swift", "Examples/Trail/Session/Package.swift"] {
      let manifest = try #require(SourceTree.read(root.appendingPathComponent(example)))
      let declared = try #require(ConsumerPackage.declaredPlatforms(in: manifest), "\(example)")

      #expect(!declared.isEmpty, "\(example) declares no platform")
      for platform in declared {
        #expect(package.contains(platform + ","), "\(example) declares \(platform)")
      }
    }
    let project = try #require(
      SourceTree.read(root.appendingPathComponent(ConsumerPackage.trailProject)))
    let floor = try #require(package.first { $0.hasPrefix(".iOS(.v") })
      .dropFirst(".iOS(.v".count).prefix { $0.isNumber }
    let targets = project.split(separator: "\n").filter {
      $0.contains("IPHONEOS_DEPLOYMENT_TARGET")
    }
    #expect(!targets.isEmpty)
    #expect(
      targets.allSatisfy { $0.contains("IPHONEOS_DEPLOYMENT_TARGET = \(floor).0;") },
      "\(targets)")
  }

  @Test("the voice's test package resolves the package's pins but what the Elements trait links")
  func speechPins() throws {
    let root = try ConsumerPackage.pins(of: "Package.resolved")
    let speech = try ConsumerPackage.pins(
      of: "Tests/MountayaNavigationTests/Speech/Package.resolved")
    // The voice's tests turn no trait on, so they resolve no MapLibre, and the rest as the package
    // pins it (SPEC.md section 2).
    let elements: Set<String> = ["maplibre-gl-native-distribution"]

    #expect(
      speech == root.filter { !elements.contains($0.key) },
      """
      the voice's tests resolve other versions than the package pins: copy the pins of \
      Package.resolved but MapLibre's into Tests/MountayaNavigationTests/Speech/Package.resolved
      """
    )
    #expect(speech["swift-crypto"] != nil, "the voice's tests pin nothing the package resolves")
  }

  /// SwiftPM resolves afresh where a file's hash is not its manifest's, and SwiftPM 6.4 then
  /// writes the file without the pins a trait gates (SPEC.md section 2), so a stale hash is caught
  /// here, with no network, before a build rewrites the file.
  @Test(
    "every resolution file carries the hash SwiftPM reads off its manifest",
    arguments: [
      "", "Tests/Consumer/", "Tests/MountayaNavigationTests/Speech/",
      "Tests/MountayaElementsTests/Renderer/", "Examples/Trail/", "Examples/Trail/Session/",
    ])
  func originHashes(of package: String) throws {
    let root = try ConsumerPackage.root()
    let manifest = try Data(contentsOf: root.appendingPathComponent(package + "Package.swift"))
    let resolved = try #require(
      SourceTree.read(root.appendingPathComponent(package + "Package.resolved")))
    let expected = ResolutionFile.originHash(ofManifest: manifest)

    #expect(
      ResolutionFile.recordedOriginHash(in: resolved) == expected,
      """
      \(package)Package.resolved carries a stale originHash, so SwiftPM would resolve it afresh \
      and drop the trait's pins: write "\(expected)", the SHA-256 of \(package)Package.swift, \
      keeping every pin, then `swift package --traits Elements resolve` leaves it
      """
    )
  }

  @Test("the map's test package resolves the versions the package pins")
  func rendererPins() throws {
    let renderer = try ConsumerPackage.pins(
      of: "Tests/MountayaElementsTests/Renderer/Package.resolved")

    // The map's tests turn the Elements trait on, as the package's resolution file is written,
    // so they resolve every pin it holds, MapLibre among them (SPEC.md section 2).
    #expect(
      try renderer == ConsumerPackage.pins(of: "Package.resolved"),
      """
      the map's tests resolve other versions than the package pins: copy the pins of \
      Package.resolved into the Renderer package's Package.resolved
      """
    )
    #expect(renderer["maplibre-gl-native-distribution"] != nil, "the map's tests pin no MapLibre")
  }

  /// Trail turns the Elements trait on, as an app that shows a map does, so its package and its
  /// Xcode project resolve every pin the package holds, MapLibre among them, which SwiftPM 6.4
  /// drops from a file it writes anew and Xcode moves to the newest release where nothing pins it
  /// (SPEC.md section 2); its session server turns no trait on and resolves no MapLibre.
  @Test(
    "Trail's package, its Xcode project and its session server resolve the versions the package pins"
  )
  func trailPins() throws {
    let root = try ConsumerPackage.pins(of: "Package.resolved")
    let elements: Set<String> = ["maplibre-gl-native-distribution"]

    for file in [
      "Examples/Trail/Package.resolved",
      "\(ConsumerPackage.trailProject.dropLast("project.pbxproj".count))"
        + "project.xcworkspace/xcshareddata/swiftpm/Package.resolved",
    ] {
      let pins = try ConsumerPackage.pins(of: file)
      #expect(
        pins == root,
        """
        \(file) resolves other versions than the package pins: copy the pins of Package.resolved \
        into it, keeping its originHash
        """
      )
      #expect(pins["maplibre-gl-native-distribution"] != nil, "\(file) pins no MapLibre")
    }
    let session = try ConsumerPackage.pins(of: "Examples/Trail/Session/Package.resolved")
    #expect(
      session == root.filter { !elements.contains($0.key) },
      """
      Trail's session server resolves other versions than the package pins: copy the pins of \
      Package.resolved but MapLibre's into Examples/Trail/Session/Package.resolved
      """
    )
  }

  @Test("the consumer builds against the public surface alone, the README's snippets with it")
  func builds() throws {
    let build = try ConsumerPackage.build.get()

    #expect(build.status == 0, "the consumer package does not build:\n\(build.log)")
    #expect(
      try ConsumerPackage.pins(of: "Tests/Consumer/Package.resolved")
        == ConsumerPackage.pins(of: "Package.resolved"),
      """
      the consumer resolves other versions than the package pins: copy the pins of \
      Package.resolved into Tests/Consumer/Package.resolved, keeping its originHash, and run \
      `swift package --package-path Tests/Consumer resolve` (SPEC.md section 2: `update` drops \
      the trait's pins)
      """
    )
  }
}

/// The API baseline of SPEC.md section 7: the public API of every product, printed from the
/// compiler's symbol graph of the module the consumer built against, and compared with the
/// listing committed beside this suite on every run. There is no release tag to diff against,
/// so the committed listing is the baseline, and its diff is the review of an API change.
@Suite("Public API")
struct PublicAPITests {
  /// rewrite is the task that prints every baseline again, with `MOUNTAYA_API_BASELINE=write`.
  static let rewrite = "mise run api:update"

  #if os(macOS)
    /// The admin unit's is printed from the macOS build, where receiving a webhook is available.
    @Test(
      "the public API of each product is its committed baseline",
      arguments: ["MountayaClient", "MountayaAdmin", "MountayaGeo"])
    func baseline(module: String) throws {
      let build = try ConsumerPackage.build.get()
      try #require(build.status == 0, "the consumer package does not build:\n\(build.log)")
      try Self.hold(
        module, to: try ConsumerPackage.symbolGraph(of: module, built: build, for: .macos))
    }

    /// The voice over the system's speech exists only in an iOS build, so the product's API is
    /// printed from the consumer built for the iOS simulator, which compiles it beside the engine.
    @Test("the public API of MountayaNavigation, built for iOS, is its committed baseline")
    func navigationBaseline() throws {
      let build = try ConsumerPackage.iosBuild.get()
      try #require(build.status == 0, "the consumer does not build for iOS:\n\(build.log)")
      let module = "MountayaNavigation"
      let listing = try Self.hold(
        module, to: try ConsumerPackage.symbolGraph(of: module, built: build, for: .iosSimulator))
      #expect(listing.contains("SpeechNavigationVoice"), "\(listing)")
    }

    /// The map view exists only in an iOS build with the Elements trait, so the product's API is
    /// printed from the consumer built that way, which compiles it.
    @Test(
      "the public API of MountayaElements, built for iOS with its trait, is its committed baseline"
    )
    func elementsBaseline() throws {
      let build = try ConsumerPackage.iosBuild.get()
      try #require(build.status == 0, "the consumer does not build for iOS:\n\(build.log)")
      let module = "MountayaElements"
      let listing = try Self.hold(
        module, to: try ConsumerPackage.symbolGraph(of: module, built: build, for: .iosSimulator))
      // MapLibre is published by the view and its ready callback alone (SPEC.md section 8).
      let naming = listing.split(separator: "\n").filter { $0.contains("MLN") }
      #expect(!naming.isEmpty, "\(listing)")
      #expect(naming.allSatisfy { $0.hasPrefix("MapView") }, "\(naming)")
    }

    /// A consumer who forgets the trait, or builds for another platform, is told what to do by
    /// the compiler, in the view's own name. A symbol graph leaves an unavailable type out, so the
    /// check is the compiler's own diagnostic, for a file that names the view.
    @Test("without its trait, or off iOS, naming the map view is an error that says what to do")
    func elementsWithout() throws {
      let build = try ConsumerPackage.build.get()
      try #require(build.status == 0, "the consumer package does not build:\n\(build.log)")
      let untraited = try ConsumerPackage.untraitedElementsBuild.get()
      try #require(
        untraited.status == 0, "MountayaElements does not build for iOS:\n\(untraited.log)")
      let app = """
        import MountayaElements

        let view: MapView? = nil
        """

      for (build, platform, says) in [
        (
          build, ConsumerPackage.Platform.macos,
          "on this platform, hold the map's state with MapEngine"
        ),
        (untraited, .iosDevice, #"depend on the package with traits: ["Elements"]"#),
      ] {
        let diagnostics = try ConsumerPackage.typecheck(app, against: build, for: platform)
          .diagnostics
        #expect(diagnostics.contains("'MapView' is unavailable: MapView"), "\(diagnostics)")
        #expect(diagnostics.contains(says), "\(diagnostics)")
      }
    }

    /// hold compares a module's listing with its committed baseline, or writes it as the baseline,
    /// and answers the listing.
    @discardableResult
    private static func hold(_ module: String, to symbolGraph: [String]) throws -> String {
      let listing = try PublicInterface.listing(symbolGraph)
      let url = try ConsumerPackage.root().appendingPathComponent(
        "Tests/BoundaryTests/Baseline/\(module).txt")

      if ProcessInfo.processInfo.environment["MOUNTAYA_API_BASELINE"] == "write" {
        try listing.write(to: url, atomically: true, encoding: .utf8)
        return listing
      }
      let committed = SourceTree.read(url) ?? ""
      let before = Set(committed.split(separator: "\n"))
      let after = Set(listing.split(separator: "\n"))
      let removed = before.subtracting(after).sorted().prefix(20)
      let added = after.subtracting(before).sorted().prefix(20)
      #expect(
        committed == listing,
        """
        the public API of \(module) moved from its baseline: run `\(Self.rewrite)` and review \
        the diff. A line removed or changed is a break.
        removed:
        \(removed.joined(separator: "\n"))
        added:
        \(added.joined(separator: "\n"))
        """
      )
      return listing
    }
  #endif
}

/// The consumer's builds, its checker and its root are GateSupport's, which `mise run snippets`
/// type-checks a document's fences against too; what only these suites read is here.
extension ConsumerPackage {
  /// The printed snippets, relative to the repository root.
  static let snippets = "Tests/Consumer/Sources/ReadmeSnippets/ReadmeSnippets.swift"

  /// The snippets' prelude, relative to the repository root: what the README's snippets, and the
  /// skill's after them, name without declaring, an app's own backend among them.
  static let prelude = "Tests/Consumer/Sources/ReadmeSnippets/Prelude.swift"

  #if os(macOS)
    /// untraitedElementsBuild builds this package's `MountayaElements` for iOS with no trait, as a
    /// consumer who forgot the trait builds it, in the scratch directory the gate's platform build
    /// fills, `mise run build:platforms`, so it compiles nothing that build compiled.
    static let untraitedElementsBuild: Result<Build, any Error> = Result {
      let root = try ConsumerPackage.root()
      let scratch = root.appendingPathComponent(".build/platforms/ios")
      let arguments = [
        "--target", "MountayaElements", "--scratch-path", scratch.path,
        "--triple", Platform.iosDevice.target(nil), "--sdk", try sdkPath(.iosDevice),
      ]
      let outcome = try Subprocess.run(["swift", "build"] + arguments, in: root)
      return Build(
        status: outcome.status, log: outcome.output + outcome.errors, scratch: scratch,
        arguments: arguments)
    }
  #endif

  /// symbolGraph returns the symbol graph of a module a build left, down to its public
  /// declarations, its synthesized members left out.
  ///
  /// The target is the platform's SDK version rather than the package's floor, which a module
  /// built for an older one loads under, so the floor stays written in the manifest alone. The
  /// products' `include` directory holds the module maps of a binary dependency's headers, which
  /// a module importing it internally still loads.
  static func symbolGraph(of module: String, built build: Build, for platform: Platform) throws
    -> [String]
  {
    let root = try ConsumerPackage.root()
    let checker = try Checker(against: build, for: platform)
    let (products, sdk, version) = (checker.products, checker.sdk, checker.version)
    // A directory per module, since the suite prints each product's API in parallel and each
    // extraction empties its directory first.
    let output = build.scratch.appendingPathComponent("public-api-\(platform.sdk)-\(module)")
    try? FileManager.default.removeItem(at: output)
    try FileManager.default.createDirectory(at: output, withIntermediateDirectories: true)
    let extracted = try Subprocess.run(
      [
        "xcrun", "swift-symbolgraph-extract", "-module-name", module, "-I", products,
        "-I", "\(products)/include", "-target", platform.target(version), "-sdk", sdk,
        "-minimum-access-level", "public", "-skip-synthesized-members",
        "-output-dir", output.path,
      ],
      in: root
    )
    guard
      extracted.status == 0,
      let text = SourceTree.read(output.appendingPathComponent("\(module).symbols.json"))
    else {
      throw Unreadable(
        description: "no symbol graph of \(module):\n\(extracted.output)\(extracted.errors)")
    }
    return [text]
      + SymbolGraph.extensionGraphs(of: module, in: output).compactMap { SourceTree.read($0) }
  }

  /// trailProject is the Xcode project Trail runs from, relative to the repository root.
  static let trailProject = "Examples/Trail/Trail.xcodeproj/project.pbxproj"

  /// declaredPlatforms returns the platforms a manifest declares, written on one line,
  /// `platforms: [.iOS(.v17)]`, or one entry to a line, each without its comma, or nil where it
  /// declares none.
  static func declaredPlatforms(in manifest: String) -> [String]? {
    if let listed = platforms(in: manifest) {
      return listed.map { $0.hasSuffix(",") ? String($0.dropLast()) : $0 }
    }
    for line in manifest.split(separator: "\n") {
      let text = line.trimmingCharacters(in: .whitespaces)
      guard text.hasPrefix("platforms: ["), text.hasSuffix("],") else { continue }
      return text.dropFirst("platforms: [".count).dropLast(2).split(separator: ", ").map {
        String($0)
      }
    }
    return nil
  }

  /// platforms returns the `platforms:` list a manifest writes, one entry to a line, or nil
  /// where it writes none.
  static func platforms(in manifest: String) -> [String]? {
    let lines = manifest.split(separator: "\n").map {
      $0.trimmingCharacters(in: .whitespaces)
    }
    guard let start = lines.firstIndex(of: "platforms: [") else { return nil }
    return Array(lines[(start + 1)...].prefix { $0 != "]," })
  }

  /// pins returns every dependency a resolution file pins, by identity, with its version or its
  /// revision.
  static func pins(of path: String) throws -> [String: String] {
    let url = try ConsumerPackage.root().appendingPathComponent(path)
    guard let text = SourceTree.read(url) else {
      throw Unreadable(description: "\(path) cannot be read")
    }
    var pins: [String: String] = [:]
    for pin in try OrderedJSON.parse(text)["pins"]?.elements ?? [] {
      guard let identity = pin["identity"]?.stringValue else { continue }
      pins[identity] =
        pin["state"]?["version"]?.stringValue ?? pin["state"]?["revision"]?.stringValue ?? ""
    }
    return pins
  }
}
