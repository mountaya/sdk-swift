import Foundation

/// AppSize is the gate that holds what the SDK adds to an app to a recorded baseline (SPEC.md
/// section 7): Trail, the sample app under `Examples/Trail` that the contract's `sdk/trail.yaml`
/// describes, an iPhone app over the four products, built in release for an iOS device, its
/// executable read module by module through the linker's map.
///
/// ## What it reads
///
/// The linker writes a map of the executable it links, `-Xlinker -map`: every file it read, under
/// an index, every section, and every symbol it kept, with its size and the index of the file it
/// came from. Swift Build, SwiftPM's default build system and the one Xcode links a package into
/// an app with, prelinks each library target into one object, `<Module>.o`, in the directory it
/// writes the executable to; SwiftPM's native build system leaves a target's objects under
/// `<Module>.build/` there. Either way an object's path names its module, and a module's bytes are
/// the sizes of the symbols the map gives its objects. A symbol of a zero-fill section, `__bss`,
/// `__common` or `__thread_bss`, takes memory and no byte of the app, and the symbols the linker
/// stripped, which the map lists apart, take none either.
///
/// Swift marks every public symbol of a module to survive the linker's dead stripping, unless the
/// module is compiled with the frontend's `-internalize-at-link`, which neither SwiftPM nor Xcode
/// asks for. So a module's share is nearly all it compiles to, whatever the app calls: it is what
/// an app pays for linking it.
///
/// What a dynamic library carries, MapLibre's framework and the system's, is no share: a framework
/// ships whole whatever the app calls, and moves with a release the app's own range chooses. Its
/// stubs in the executable count in the executable's total alone, with the app's own code and what
/// the linker synthesizes.
///
/// ## The rule
///
/// Each library product the package declares is a share, the bytes of its targets, and so is each
/// module of another package the build links, which the SDK brings into the app: swift-crypto's
/// `Crypto` on iOS, recorded with the package that holds it and the version Trail's
/// `Package.resolved` pins it at. A share that grows past 2% of its baseline or 16 KiB, whichever
/// is larger, fails; one that shrinks past it is told; a product the baseline does not record
/// fails, and so does a module the SDK starts to bring, until it is recorded; a brought module
/// whose version moved is reported and not compared; a missing baseline fails; and a baseline
/// measured to another version of `sdk/trail.yaml`, or with another Xcode or another Swift, is
/// reported and not compared, since a scenario that moves moves what the app does, and a module's
/// bytes are the compiler's as much as the SDK's.
///
/// ## The report
///
/// One line per share, `<share>: <bytes>, <±change> (<±%>), within tolerance` or
/// `past tolerance`, then the products together, which are reported and not compared, then the
/// whole executable, which is never compared: the report `sdk-dart`'s and `sdk-kotlin`'s size
/// gates print over their own measures.
package enum AppSize {
  /// baseline is the baseline's path, relative to the repository's root.
  package static let baseline = "Tests/BoundaryTests/Size/ios.json"

  /// platform is the platform the gate builds for, which the baseline records.
  package static let platform = "ios"

  /// app is the example's executable target the gate builds and measures.
  package static let app = "Trail"

  /// example is the package the app belongs to, relative to the repository's root.
  package static let example = "Examples/Trail"

  /// record is the command that records the baseline, which every message of the gate names.
  package static let record = "MOUNTAYA_SIZE_BASELINE=write mise run size:check"

  /// zeroFill is the sections whose symbols take memory and no byte of the app.
  package static let zeroFill: Set<String> = ["__bss", "__common", "__thread_bss"]

  // MARK: - The build

  /// scratch is the directory the gate builds the app in, relative to the repository's root:
  /// Trail's build for an iOS device in release, by a compiler at the major and minor of `swift`,
  /// as `scripts/clean.sh` reads it, so a pin that moves frees it. It is nil where `swift` starts
  /// with no version.
  package static func scratch(swift: String) -> String? {
    let numbers = swift.prefix { $0.isNumber || $0 == "." }.split(separator: ".")
    guard numbers.count >= 2 else { return nil }
    return ".build/trail-ios-release-\(numbers[0]).\(numbers[1])"
  }

  /// buildArguments is the build the gate measures: the app in release for an iOS device at the
  /// package's floor, in `scratch`, against the SDK at `sdk`, its linker writing its map to `map`.
  package static func buildArguments(scratch: String, sdk: String, map: String) -> [String] {
    [
      "swift", "build", "-c", "release", "--package-path", example, "--scratch-path", scratch,
      "--product", app, "--triple", "arm64-apple-ios", "--sdk", sdk, "-Xlinker", "-map",
      "-Xlinker", map,
    ]
  }

  /// dependenciesArguments asks SwiftPM, in the build's `scratch`, for every package the app
  /// resolves, with where each is checked out, as JSON (`resolvedPackages(in:)`).
  package static func dependenciesArguments(scratch: String) -> [String] {
    [
      "swift", "package", "--package-path", example, "--scratch-path", scratch,
      "show-dependencies", "--format", "json",
    ]
  }

  /// command is the build as a person types it, which the baseline records.
  package static func command(scratch: String) -> String {
    buildArguments(
      scratch: scratch, sdk: #""$(xcrun --sdk iphoneos --show-sdk-path)""#,
      map: "\(scratch)/\(app).map"
    ).joined(separator: " ")
  }

  // MARK: - The toolchain

  /// Toolchain is what built the app: Xcode's version and build, and the Swift compiler's version.
  package struct Toolchain: Sendable, Hashable {
    package let xcode: String
    package let swift: String

    package init(xcode: String, swift: String) {
      self.xcode = xcode
      self.swift = swift
    }
  }

  /// xcodeVersion reads what `xcodebuild -version` prints, `Xcode 27.2` then `Build version 27B52`,
  /// as `27.2 (27B52)`, or nil where it names no Xcode.
  package static func xcodeVersion(from output: String) -> String? {
    var version: String?
    var build: String?
    for line in output.split(separator: "\n") {
      let text = line.trimmingCharacters(in: .whitespaces)
      if text.hasPrefix("Xcode ") {
        version = String(text.dropFirst("Xcode ".count))
      } else if text.hasPrefix("Build version ") {
        build = String(text.dropFirst("Build version ".count))
      }
    }
    guard let version, !version.isEmpty else { return nil }
    return build.map { "\(version) (\($0))" } ?? version
  }

  /// swiftVersion reads what `swift --version` prints, `Apple Swift version 6.4.2 (swiftlang-…)`,
  /// as what follows `Swift version ` on its line, or nil where it names no Swift.
  package static func swiftVersion(from output: String) -> String? {
    let marker = "Swift version "
    for line in output.split(separator: "\n") {
      guard let range = line.range(of: marker) else { continue }
      let version = line[range.upperBound...].trimmingCharacters(in: .whitespaces)
      if version.first?.isNumber == true { return version }
    }
    return nil
  }

  // MARK: - The map

  /// LinkMap is what a linker map says of one link: the executable it wrote, the files it read by
  /// their index, the executable's sections, and the symbols it kept.
  package struct LinkMap: Sendable {
    /// executable is the path of the file the link wrote, `# Path:`.
    package let executable: String
    /// objects is each file the link read, by the index its symbols name it with.
    package let objects: [Int: String]
    /// sections is each section of the executable, in the order the map lists them.
    package let sections: [Section]
    /// symbols is each symbol the link kept; the ones it stripped are read for nothing.
    package let symbols: [Symbol]
  }

  /// Section is one section of the executable: where it starts, its size, and its name.
  package struct Section: Sendable, Hashable {
    package let address: UInt64
    package let size: Int
    package let segment: String
    package let name: String
  }

  /// Symbol is one symbol the link kept: where it starts, its size, and the index of its file.
  package struct Symbol: Sendable, Hashable {
    package let address: UInt64
    package let size: Int
    package let file: Int
  }

  /// parse reads the map a link wrote. It throws where the text is no map, or where a line of its
  /// files, sections or symbols reads as none, naming the line.
  package static func parse(_ text: String) throws(AppSizeError) -> LinkMap {
    enum Part {
      case header, objects, sections, symbols, stripped
    }
    var part = Part.header
    var executable: String?
    var objects: [Int: String] = [:]
    var sections: [Section] = []
    var symbols: [Symbol] = []
    var sawSymbols = false

    for (offset, raw) in text.split(separator: "\n", omittingEmptySubsequences: false).enumerated()
    {
      let number = offset + 1
      let line = raw.hasSuffix("\r") ? raw.dropLast() : raw
      if line.isEmpty { continue }
      if line.hasPrefix("#") {
        switch line {
        case "# Object files:": part = .objects
        case "# Sections:": part = .sections
        case "# Symbols:":
          part = .symbols
          sawSymbols = true
        case "# Dead Stripped Symbols:": part = .stripped
        default:
          if line.hasPrefix("# Path: ") {
            executable = String(line.dropFirst("# Path: ".count))
          }
        }
        continue
      }
      switch part {
      case .header, .stripped:
        continue
      case .objects:
        guard let (index, rest) = fileIndex(line) else {
          throw AppSizeError(line: number, message: "expected `[<index>] <file>`")
        }
        objects[index] = String(rest.drop { $0 == " " })
      case .sections:
        let fields = line.split(separator: "\t", omittingEmptySubsequences: false).map {
          $0.trimmingCharacters(in: .whitespaces)
        }
        guard fields.count >= 4, let address = hex(fields[0]), let size = hex(fields[1]) else {
          throw AppSizeError(
            line: number, message: "expected `<address> <size> <segment> <section>`")
        }
        sections.append(
          Section(address: address, size: Int(size), segment: fields[2], name: fields[3]))
      case .symbols:
        let fields = line.split(separator: "\t", maxSplits: 2, omittingEmptySubsequences: false)
        guard fields.count == 3,
          let address = hex(fields[0].trimmingCharacters(in: .whitespaces)),
          let size = hex(fields[1].trimmingCharacters(in: .whitespaces)),
          let (file, _) = fileIndex(fields[2])
        else {
          throw AppSizeError(line: number, message: "expected `<address> <size> [<index>] <name>`")
        }
        symbols.append(Symbol(address: address, size: Int(size), file: file))
      }
    }
    guard let executable, !objects.isEmpty, sawSymbols else {
      throw AppSizeError(
        line: 1,
        message: "it is no linker map: it names no `# Path:`, `# Object files:` or `# Symbols:`")
    }
    return LinkMap(executable: executable, objects: objects, sections: sections, symbols: symbols)
  }

  /// fileIndex reads `[  7] rest` as 7 and what follows the bracket, or nil where the line does not
  /// open with a bracketed index.
  private static func fileIndex(_ line: Substring) -> (Int, Substring)? {
    guard line.hasPrefix("["), let close = line.firstIndex(of: "]") else { return nil }
    let digits = line[line.index(after: line.startIndex)..<close]
      .trimmingCharacters(in: .whitespaces)
    guard let index = Int(digits) else { return nil }
    return (index, line[line.index(after: close)...])
  }

  /// hex reads `0x…` as a number, or nil where it is none.
  private static func hex(_ text: String) -> UInt64? {
    guard text.hasPrefix("0x") || text.hasPrefix("0X") else { return nil }
    return UInt64(text.dropFirst(2), radix: 16)
  }

  // MARK: - The modules

  /// module is the module a file of a link holds, read from its path, or nil where it holds none:
  /// an object Swift Build prelinked a library target into, `<Module>.o` in `products`, the
  /// directory the executable was written to, or an object under `<Module>.build/` there, where
  /// SwiftPM's native build system compiles a target. The app's own objects, which Swift Build
  /// compiles elsewhere, an archive's member, a library and what the linker synthesizes hold none.
  package static func module(ofFile path: String, products: String) -> String? {
    let prefix = products.hasSuffix("/") ? products : products + "/"
    guard path.hasPrefix(prefix) else { return nil }
    let rest = path.dropFirst(prefix.count)
    if let slash = rest.firstIndex(of: "/") {
      let directory = rest[..<slash]
      guard directory.hasSuffix(".build"), directory.count > ".build".count else { return nil }
      return String(directory.dropLast(".build".count))
    }
    guard rest.hasSuffix(".o"), rest.count > ".o".count else { return nil }
    return String(rest.dropLast(".o".count))
  }

  /// Linked is what one link holds, module by module.
  package struct Linked: Sendable, Equatable {
    /// modules is each module the link read objects of, with the bytes of the symbols it kept.
    package let modules: [String: Int]
    /// total is every byte the map gives a symbol the link kept: the modules', the app's own, the
    /// linker's, and the stubs into a dynamic library.
    package let total: Int

    package init(modules: [String: Int], total: Int) {
      self.modules = modules
      self.total = total
    }
  }

  /// linked sums the sizes of a map's symbols module by module, a zero-fill section's left out.
  package static func linked(_ map: LinkMap) -> Linked {
    // The directory the executable was written to, which holds the prelinked modules.
    let products = map.executable.lastIndex(of: "/").map { String(map.executable[..<$0]) } ?? ""
    var moduleOf: [Int: String] = [:]
    for (index, path) in map.objects {
      moduleOf[index] = module(ofFile: path, products: products)
    }
    let sections = map.sections.sorted { $0.address < $1.address }
    var modules: [String: Int] = [:]
    var total = 0
    for symbol in map.symbols {
      if let section = section(holding: symbol.address, in: sections),
        zeroFill.contains(section.name)
      {
        continue
      }
      total += symbol.size
      if let module = moduleOf[symbol.file] {
        modules[module, default: 0] += symbol.size
      }
    }
    return Linked(modules: modules, total: total)
  }

  /// section is the section holding an address, among sections sorted by address, or nil where
  /// none does.
  private static func section(holding address: UInt64, in sections: [Section]) -> Section? {
    var low = 0
    var high = sections.count
    while low < high {
      let middle = (low + high) / 2
      if sections[middle].address <= address {
        low = middle + 1
      } else {
        high = middle
      }
    }
    guard low > 0 else { return nil }
    let candidate = sections[low - 1]
    return address < candidate.address + UInt64(candidate.size) ? candidate : nil
  }

  // MARK: - The packages the SDK brings

  /// ResolvedPackage is a package the app resolves, as SwiftPM's `show-dependencies` names it: its
  /// identity, the version it resolved, and where it is checked out.
  package struct ResolvedPackage: Sendable, Hashable {
    package let identity: String
    package let version: String?
    package let path: String

    package init(identity: String, version: String?, path: String) {
      self.identity = identity
      self.version = version
      self.path = path
    }
  }

  /// resolvedPackages reads what `swift package show-dependencies --format json` prints: every
  /// package below the root, each once, in the order the tree first names it, its version nil
  /// where SwiftPM states none, a path dependency's `unspecified`.
  package static func resolvedPackages(in text: String) throws(AppSizeError) -> [ResolvedPackage] {
    // SwiftPM may print a notice before the document, so the document starts at its brace.
    guard let start = text.firstIndex(of: "{") else {
      throw AppSizeError(line: 1, message: "SwiftPM named no dependency tree")
    }
    let tree: OrderedJSON
    do {
      tree = try OrderedJSON.parse(String(text[start...]))
    } catch {
      throw AppSizeError(
        line: error.line, message: "the dependency tree is no JSON: \(error.message)")
    }
    var found: [ResolvedPackage] = []
    var pending = (tree["dependencies"]?.elements ?? []).reversed().map { $0 }
    while let package = pending.popLast() {
      guard let identity = package["identity"]?.stringValue, let path = package["path"]?.stringValue
      else {
        throw AppSizeError(line: 1, message: "a dependency names no identity or no path")
      }
      let version = package["version"]?.stringValue.flatMap { $0 == "unspecified" ? nil : $0 }
      if !found.contains(where: { $0.identity == identity }) {
        found.append(ResolvedPackage(identity: identity, version: version, path: path))
      }
      pending += (package["dependencies"]?.elements ?? []).reversed()
    }
    return found
  }

  /// pinnedVersions reads the version each package a `Package.resolved` pins is pinned at, by its
  /// identity; a pin by revision alone pins no version.
  package static func pinnedVersions(in text: String) -> [String: String] {
    var versions: [String: String] = [:]
    for pin in (try? OrderedJSON.parse(text))?["pins"]?.elements ?? [] {
      guard let identity = pin["identity"]?.stringValue,
        let version = pin["state"]?["version"]?.stringValue
      else { continue }
      versions[identity] = version
    }
    return versions
  }

  /// BroughtPackage is the package a module the SDK brings belongs to, and its version.
  package struct BroughtPackage: Sendable, Hashable {
    package let identity: String
    package let version: String?

    package init(identity: String, version: String?) {
      self.identity = identity
      self.version = version
    }
  }

  // MARK: - The figures

  /// Brought is a module of another package the build links, which the SDK brings into the app:
  /// its bytes, and the package it comes from at its version, nil where neither is known.
  package struct Brought: Sendable, Equatable {
    package let bytes: Int
    package let package: String?
    package let version: String?

    package init(bytes: Int, package: String? = nil, version: String? = nil) {
      self.bytes = bytes
      self.package = package
      self.version = version
    }
  }

  /// Figures is what the SDK adds to one release build of the app, the toolchain that built it,
  /// and the version of `sdk/trail.yaml` the app does.
  package struct Figures: Sendable, Equatable {
    package let toolchain: Toolchain
    /// scenario is the version of `sdk/trail.yaml` the app was built to, nil for a baseline that
    /// records none, measured before the gate built Trail.
    package let scenario: Int?
    /// linked is every byte the executable's map gives a symbol, the app's own and the linker's
    /// included, which is reported and never compared.
    package let linked: Int
    /// products is each library product the package declares, with the bytes of its targets; a
    /// product the app does not link holds 0.
    package let products: [String: Int]
    /// brought is each module of another package the build links, which the SDK brings into the
    /// app, by its name.
    package let brought: [String: Brought]

    package init(
      toolchain: Toolchain, scenario: Int?, linked: Int, products: [String: Int],
      brought: [String: Brought]
    ) {
      self.toolchain = toolchain
      self.scenario = scenario
      self.linked = linked
      self.products = products
      self.brought = brought
    }

    /// sdk is the products' bytes together.
    package var sdk: Int {
      products.values.reduce(0, +)
    }

    /// shares is the figures the gate holds to the baseline: each product's, then each brought
    /// module's, each by its name.
    package var shares: [(name: String, bytes: Int)] {
      products.sorted { $0.key < $1.key }.map { ($0.key, $0.value) }
        + brought.sorted { $0.key < $1.key }.map { ($0.key, $0.value.bytes) }
    }
  }

  /// measure reads a link's figures: each library product's bytes, its targets' together, and each
  /// other module's but the app's own, which the SDK brings in, with its package from `packages`,
  /// by module.
  package static func measure(
    _ linked: Linked, products: [PackageManifest.Product], toolchain: Toolchain, scenario: Int?,
    packages: [String: BroughtPackage] = [:]
  ) -> Figures {
    let libraries = products.filter(\.isLibrary)
    let sdk = Set(libraries.flatMap(\.targets))
    var shares: [String: Int] = [:]
    for product in libraries {
      shares[product.name] = product.targets.reduce(0) { $0 + (linked.modules[$1] ?? 0) }
    }
    var brought: [String: Brought] = [:]
    for (module, bytes) in linked.modules where !sdk.contains(module) && module != app {
      brought[module] = Brought(
        bytes: bytes, package: packages[module]?.identity, version: packages[module]?.version)
    }
    return Figures(
      toolchain: toolchain, scenario: scenario, linked: linked.total, products: shares,
      brought: brought)
  }

  // MARK: - The baseline

  /// printBaseline is the baseline holding `figures`, as `Tests/BoundaryTests/Size/ios.json` keeps
  /// it: the platform, the scenario and the build, the toolchain, the executable's total, each
  /// product, and each module the SDK brings with its package and version.
  package static func printBaseline(_ figures: Figures, build: String) -> String {
    func optional(_ text: String?) -> OrderedJSON {
      text.map(OrderedJSON.string) ?? .null
    }
    let products = OrderedJSON.object(
      figures.products.sorted { $0.key < $1.key }.map {
        OrderedJSON.Member(key: $0.key, value: .number(Double($0.value)))
      })
    let brought = OrderedJSON.object(
      figures.brought.sorted { $0.key < $1.key }.map {
        OrderedJSON.Member(
          key: $0.key,
          value: .object([
            OrderedJSON.Member(key: "package", value: optional($0.value.package)),
            OrderedJSON.Member(key: "version", value: optional($0.value.version)),
            OrderedJSON.Member(key: "bytes", value: .number(Double($0.value.bytes))),
          ]))
      })
    var members = [OrderedJSON.Member(key: "platform", value: .string(platform))]
    if let scenario = figures.scenario {
      members.append(OrderedJSON.Member(key: "scenario", value: .number(Double(scenario))))
    }
    members += [
      OrderedJSON.Member(key: "build", value: .string(build)),
      OrderedJSON.Member(key: "xcode", value: .string(figures.toolchain.xcode)),
      OrderedJSON.Member(key: "swift", value: .string(figures.toolchain.swift)),
      OrderedJSON.Member(key: "linked", value: .number(Double(figures.linked))),
      OrderedJSON.Member(key: "products", value: products),
      OrderedJSON.Member(key: "brought", value: brought),
    ]
    return OrderedJSON.object(members).serialized() + "\n"
  }

  /// recordedScenario is the version of `sdk/trail.yaml` the baseline `text` was measured to, nil
  /// where it records none. It throws where the text is no JSON object, or its scenario no
  /// version.
  package static func recordedScenario(_ text: String) throws(AppSizeError) -> Int? {
    let document: OrderedJSON
    do {
      document = try OrderedJSON.parse(text)
    } catch {
      throw AppSizeError(line: error.line, message: "it is no JSON: \(error.message)")
    }
    guard document.members != nil else {
      throw AppSizeError(line: 1, message: "it is no JSON object")
    }
    guard let recorded = document["scenario"] else { return nil }
    guard let scenario = count(recorded), scenario >= 1 else {
      throw AppSizeError(line: 1, message: "its `scenario` is no version of sdk/trail.yaml")
    }
    return scenario
  }

  /// readBaseline reads the baseline `printBaseline` wrote. It throws where the text is no such
  /// baseline, saying why.
  package static func readBaseline(_ text: String) throws(AppSizeError) -> Figures {
    let scenario = try recordedScenario(text)
    let document: OrderedJSON
    do {
      document = try OrderedJSON.parse(text)
    } catch {
      throw AppSizeError(line: error.line, message: "it is no JSON: \(error.message)")
    }
    guard let recorded = document["platform"]?.stringValue,
      let xcode = document["xcode"]?.stringValue,
      let swift = document["swift"]?.stringValue,
      let linked = document["linked"].flatMap(count),
      let products = document["products"]?.members,
      let brought = document["brought"]?.members
    else {
      throw AppSizeError(
        line: 1, message: "it holds no platform, xcode, swift, linked, products and brought")
    }
    guard recorded == platform else {
      throw AppSizeError(line: 1, message: "it records \(recorded), not \(platform)")
    }
    return Figures(
      toolchain: Toolchain(xcode: xcode, swift: swift), scenario: scenario, linked: linked,
      products: try figures(products), brought: try broughtFigures(brought))
  }

  /// count reads a JSON number that counts bytes: a whole number, zero or more.
  private static func count(_ value: OrderedJSON) -> Int? {
    guard let number = value.numberValue, number >= 0, number == number.rounded(),
      number < 9_007_199_254_740_992
    else { return nil }
    return Int(number)
  }

  private static func figures(_ members: [OrderedJSON.Member]) throws(AppSizeError) -> [String: Int]
  {
    var figures: [String: Int] = [:]
    for member in members {
      guard let bytes = count(member.value) else {
        throw AppSizeError(line: 1, message: "`\(member.key)` holds no count of bytes")
      }
      figures[member.key] = bytes
    }
    return figures
  }

  /// broughtFigures reads each brought module's package, version and bytes; a version or a
  /// package recorded as null is none.
  private static func broughtFigures(_ members: [OrderedJSON.Member]) throws(AppSizeError)
    -> [String: Brought]
  {
    var brought: [String: Brought] = [:]
    for member in members {
      guard let bytes = member.value["bytes"].flatMap(count) else {
        throw AppSizeError(
          line: 1, message: "`\(member.key)` holds no package, version and count of bytes")
      }
      brought[member.key] = Brought(
        bytes: bytes, package: member.value["package"]?.stringValue,
        version: member.value["version"]?.stringValue)
    }
    return brought
  }

  // MARK: - The rule

  /// tolerance is the growth a share may take on `baseline` bytes before the gate fails: 2% of it
  /// or 16 KiB, whichever is larger (SPEC.md section 7).
  ///
  /// One toolchain links one executable from one tree, so the tolerance absorbs no noise. It
  /// absorbs the ordinary growth of a change that adds what an app calls, so such a change does not
  /// record the baseline each time, while what the gate exists for is larger: a dependency the SDK
  /// starts to bring, a table of data every app now carries, a generic surface specialized many
  /// times over. The floor holds a share that is small or 0 at its baseline, where 2% of it is a
  /// few bytes.
  package static func tolerance(of baseline: Int) -> Int {
    max(Int((Double(baseline) * 2 / 100).rounded()), 16 * 1024)
  }

  /// Comparison is what holding a build to its baseline found: each finding fails the gate, each
  /// note is told.
  package struct Comparison: Sendable, Equatable {
    package let findings: [String]
    package let notes: [String]
  }

  /// compare holds `measured` to its baseline, `baseline` being the text of
  /// `Tests/BoundaryTests/Size/ios.json`, or nil where there is none (SPEC.md section 7).
  ///
  /// A share that grows past its tolerance is a finding, and so is a product the baseline does not
  /// record and a module the SDK starts to bring; one that shrinks past it is a note, since a
  /// smaller app is no defect and recording it is the person's choice. A product the baseline
  /// records and the build no longer links is held as 0, and a brought module whose version moved
  /// is reported and not compared, as is one the SDK no longer brings. A baseline measured to
  /// another scenario, or with another toolchain, is reported and not compared.
  package static func compare(_ measured: Figures, baseline: String?) -> Comparison {
    guard let baseline else {
      return Comparison(findings: ["no baseline: run \(record)"], notes: describe(measured))
    }
    // The scenario is read first: a baseline measured to another one, a baseline of another shape
    // made before the gate built Trail among them, is reported and not compared.
    let recorded: Figures
    do {
      let scenario = try recordedScenario(baseline)
      if scenario != measured.scenario {
        let note =
          "\(platform): built to \(describe(scenario: measured.scenario)) and the baseline to "
          + (scenario.map { "scenario \($0)" } ?? "none, measured before the gate built Trail")
          + ", so the figures are reported and not compared: a scenario moves what the app does, "
          + "and \(record) records them for this one"
        return Comparison(findings: [], notes: [note] + describe(measured))
      }
      recorded = try readBaseline(baseline)
    } catch {
      return Comparison(
        findings: ["is no size baseline, since \(error.message): run \(record)"],
        notes: describe(measured))
    }
    if recorded.toolchain != measured.toolchain {
      let note =
        "\(platform): built with \(describe(measured.toolchain)) and the baseline with "
        + "\(describe(recorded.toolchain)), so the figures are reported and not compared: a "
        + "module's bytes are the compiler's as much as the SDK's, and \(record) records them for "
        + "this toolchain"
      return Comparison(findings: [], notes: [note] + describe(measured, baseline: recorded))
    }

    var findings: [String] = []
    var notes: [String] = []
    func hold(_ share: String, bytes: Int, against was: Int) {
      let tolerance = tolerance(of: was)
      let change = bytes - was
      let line = "\(share): \(formatBytes(bytes)), \(moved(change, from: was))"
      if change > tolerance {
        findings.append(
          "\(line), past tolerance (\(formatBytes(tolerance))): find what the module now keeps, a "
            + "public declaration, a table or a dependency, and after a deliberate change run "
            + record)
      } else if -change > tolerance {
        notes.append(
          "\(platform): \(line), past tolerance (\(formatBytes(tolerance))) as it shrank: "
            + "\(record) records the smaller figure")
      } else {
        notes.append("\(platform): \(line), within tolerance")
      }
    }

    // A product the baseline records and the build no longer links is held as 0.
    let gone = recorded.products.keys.filter { measured.products[$0] == nil }.sorted()
    let held =
      measured.products.sorted { $0.key < $1.key }.map { ($0.key, $0.value) } + gone.map { ($0, 0) }
    for (product, bytes) in held {
      guard let was = recorded.products[product] else {
        findings.append("records no share of \(product), which the package declares: run \(record)")
        continue
      }
      hold(product, bytes: bytes, against: was)
    }
    for (module, now) in measured.brought.sorted(by: { $0.key < $1.key }) {
      guard let was = recorded.brought[module] else {
        findings.append(
          "\(describe(module, brought: now)): \(formatBytes(now.bytes)), a module the SDK now brings that "
            + "the baseline does not record: find what brings it, and after a deliberate change "
            + "run \(record)")
        continue
      }
      guard was.package == now.package, was.version == now.version else {
        notes.append(
          "\(platform): \(module): \(formatBytes(now.bytes)) at \(describe(now)), the baseline "
            + "\(formatBytes(was.bytes)) at \(describe(was)), so it is reported and not compared: "
            + "\(record) records it at this version")
        continue
      }
      hold(module, bytes: now.bytes, against: was.bytes)
    }
    for (module, was) in recorded.brought.sorted(by: { $0.key < $1.key })
    where measured.brought[module] == nil {
      notes.append(
        "\(platform): \(module) is no longer brought, where the baseline records "
          + "\(formatBytes(was.bytes)) of it: \(record) drops it")
    }
    notes += totals(measured, baseline: recorded)
    return Comparison(findings: findings, notes: notes)
  }

  /// describe is one line per share of `figures`, with the figure `baseline` records beside it
  /// where one is given, then the products together and the whole executable.
  package static func describe(_ figures: Figures, baseline: Figures? = nil) -> [String] {
    let products = figures.products.sorted { $0.key < $1.key }.map { product, bytes in
      "\(platform): \(product): \(formatBytes(bytes))"
        + (baseline?.products[product].map { ", the baseline \(formatBytes($0))" } ?? "")
    }
    let brought = figures.brought.sorted { $0.key < $1.key }.map { module, now in
      "\(platform): \(describe(module, brought: now)): \(formatBytes(now.bytes))"
        + (baseline?.brought[module].map {
          ", the baseline \(formatBytes($0.bytes)) at \(describe($0))"
        } ?? "")
    }
    return products + brought + totals(figures, baseline: baseline)
  }

  /// totals is the products together, which are reported and not compared, and the whole
  /// executable, which is never compared, each with its move on `baseline` where one is given.
  private static func totals(_ figures: Figures, baseline: Figures?) -> [String] {
    [
      "\(platform): the SDK's products together: \(formatBytes(figures.sdk))"
        + (baseline.map { ", \(moved(figures.sdk - $0.sdk, from: $0.sdk))" } ?? "")
        + ", reported and not compared",
      "\(platform): the whole executable: \(formatBytes(figures.linked))"
        + (baseline.map { ", \(moved(figures.linked - $0.linked, from: $0.linked))" } ?? "")
        + ", never compared",
    ]
  }

  private static func describe(_ toolchain: Toolchain) -> String {
    "Xcode \(toolchain.xcode) and Swift \(toolchain.swift)"
  }

  private static func describe(scenario: Int?) -> String {
    scenario.map { "scenario \($0) of sdk/trail.yaml" } ?? "no scenario"
  }

  /// describe names a brought module with its package and version, `Crypto (swift-crypto 5.1.1)`.
  private static func describe(_ module: String, brought: Brought) -> String {
    brought.package == nil && brought.version == nil ? module : "\(module) (\(describe(brought)))"
  }

  /// describe names a brought module's package and version, or says none is known.
  private static func describe(_ brought: Brought) -> String {
    switch (brought.package, brought.version) {
    case (let package?, let version?): "\(package) \(version)"
    case (let package?, nil): "\(package), at no version"
    case (nil, let version?): version
    case (nil, nil): "no known package"
    }
  }

  /// formatBytes writes bytes as a person reads them: `512 B`, `12.3 KiB`, `1.18 MiB`.
  package static func formatBytes(_ bytes: Int) -> String {
    let kib = 1024
    let mib = kib * 1024
    if abs(bytes) < kib { return "\(bytes) B" }
    if abs(bytes) < mib { return String(format: "%.1f KiB", Double(bytes) / Double(kib)) }
    return String(format: "%.2f MiB", Double(bytes) / Double(mib))
  }

  /// moved writes a change on `baseline` bytes, `+1.2 KiB (+0.4%)`, its share left out where the
  /// baseline is 0.
  private static func moved(_ change: Int, from baseline: Int) -> String {
    let signed = change < 0 ? "-\(formatBytes(-change))" : "+\(formatBytes(change))"
    guard baseline != 0 else { return signed }
    let percent = Double(change) / Double(baseline) * 100
    return signed + " (" + (percent < 0 ? "" : "+") + String(format: "%.1f%%", percent) + ")"
  }
}

/// AppSizeError says why a linker map or a size baseline reads as none, and the line it stopped at.
package struct AppSizeError: Error, Sendable, CustomStringConvertible {
  package let line: Int
  package let message: String

  package init(line: Int, message: String) {
    self.line = line
    self.message = message
  }

  package var description: String {
    "line \(line): \(message)"
  }
}
