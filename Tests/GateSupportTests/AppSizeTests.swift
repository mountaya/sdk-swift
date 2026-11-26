import Foundation
import GateSupport
import Testing

/// The size gate's reader and its rule, held to an excerpt of the map the linker wrote for Trail's
/// release build for an iOS device: a reader that returned nothing would hold every share at 0
/// against a baseline of 0, and pass on anything.
@Suite("AppSize")
struct AppSizeTests {
  /// products is the directory Swift Build wrote the executable and the prelinked modules to.
  private static let products = "/w/.build/trail-ios-release-6.4/out/Products/Release-iphoneos"

  /// map is lines of the linker's map, cut down: every kind of file the link reads, a section of
  /// each kind, symbols of every file, two in zero-fill sections, and two the linker stripped.
  private static let map = """
    # Path: \(products)/Trail
    # Arch: arm64
    # Object files:
    [  0] linker synthesized
    [  1] /w/.build/trail-ios-release-6.4/out/Intermediates.noindex/trail.build/\
    Release-iphoneos/Trail-p.build/Objects-normal/arm64/TrailApp.o
    [  2] \(products)/MountayaClient.o
    [  3] \(products)/Crypto.o
    [  4] \(products)/MountayaGeo.o
    [  5] \(products)/MountayaNavigation.o
    [  6] \(products)/MountayaElements.o
    [  7] \(products)/MapLibre.framework/MapLibre
    [  8] /Xcode/usr/lib/swift/iphoneos/libswiftCompatibility56.a(Overrides.cpp.o)
    [  9] /Xcode/SDKs/iPhoneOS27.2.sdk/usr/lib/swift/libswiftCore.tbd
    # Sections:
    # Address\tSize    \tSegment\tSection
    0x100004000\t0x0062AD60\t__TEXT\t__text
    0x10062ED60\t0x0000300C\t__TEXT\t__stubs
    0x1006E2010\t0x0001F1A8\t__TEXT\t__unwind_info
    0x10076CFB0\t0x000045B0\t__DATA_CONST\t__got
    0x100779A30\t0x0002D571\t__DATA\t__data
    0x1007A6FA8\t0x000001A0\t__DATA\t__s_async_hook
    0x1007A7200\t0x0006FDB0\t__DATA\t__bss
    0x100816FB0\t0x00006048\t__DATA\t__common
    # Symbols:
    # Address\tSize    \tFile  Name
    0x100000000\t0x00000000\t[  0] __mh_execute_header
    0x100004000\t0x0000030C\t[  1] _$s5Trail0A3AppV4bodyQrvg
    0x10000430C\t0x00000690\t[  1] _$s5Trail0A6ScreenV5modelAcA0A5ModelC_tcfC
    0x100007FF8\t0x00000038\t[  2] _$s14MountayaClient0A0C8languageSSSgvg
    0x100008030\t0x0000002C\t[  2] _$s14MountayaClient0A0C8baseUrlsAA04BaseD0Vvg
    0x10038CEC8\t0x00000064\t[  3] _$s6Crypto18openSSLSafeCompareySbx_q_tlF
    0x10038D1AC\t0x00000004\t[  3] _$s6Crypto19_cryptoModuleAnchoryyF
    0x10038D1B0\t0x0000000C\t[  4] _$s11MountayaGeo22GeolocateControlEngineC3mapvpfi
    0x10038D1BC\t0x00000008\t[  4] _$s11MountayaGeo22GeolocateControlEngineC8fixesOutSivpfi
    0x10047DD90\t0x00000008\t[  5] _$s18MountayaNavigation06DeviceB6EngineC5routevpfi
    0x1004889A4\t0x00000008\t[  6] _$s16MountayaElements12WaypointEditV8positionSaySdGSgvpfi
    0x1004889AC\t0x00000014\t[  6] _$s16MountayaElements9CameraFitV7paddingvpfi
    0x100630140\t0x0000000C\t[  9] _$sSD4KeysVMa.stub
    0x1006312EC\t0x0000000C\t[  7] _MLNAltitudeForZoomLevel.stub
    0x1006E2010\t0x0001F1A8\t[  0] compact unwind info
    0x10076E5B0\t0x00000008\t[  7] _MLNAltitudeForZoomLevel.got
    0x100779A30\t0x00000008\t[  1] _$s7SwiftUI14_TaskModifier2VAcA12ViewModifierAAWL
    0x1007A6FA8\t0x000001A0\t[  8] _Swift56ConcurrencyOverrides
    0x1007A7200\t0x00000010\t[  1] _$s5Trail0A3AppVMl
    0x1007A72A0\t0x00000010\t[  2] _$s14MountayaClient0A0CMl
    0x100816FB0\t0x00000008\t[  2] _$s14MountayaClient0A0C8languageSSSgvpWvd
    # Dead Stripped Symbols:
    #        \tSize    \tFile  Name
    <<dead>>\t0x00000024\t[  2] _$ss12_ArrayBufferV20_consumeAndCreateNewTg5
    <<dead>>\t0x00000068\t[  2] _$sSSSgxSgSEsSERzlWlTm

    """

  /// package is the products the package declares, its gates' executables among them.
  private static let package = [
    PackageManifest.Product(name: "MountayaClient", targets: ["MountayaClient"], isLibrary: true),
    PackageManifest.Product(name: "MountayaGeo", targets: ["MountayaGeo"], isLibrary: true),
    PackageManifest.Product(
      name: "MountayaNavigation", targets: ["MountayaNavigation"], isLibrary: true),
    PackageManifest.Product(
      name: "MountayaElements", targets: ["MountayaElements"], isLibrary: true),
    PackageManifest.Product(name: "SizeGate", targets: ["SizeGate"], isLibrary: false),
  ]

  private static let toolchain = AppSize.Toolchain(
    xcode: "27.2 (27B52)", swift: "6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)")

  /// crypto is swift-crypto's `Crypto` at the version Trail pins, `bytes` of it.
  private static func crypto(_ bytes: Int = 1_500, version: String = "5.1.1") -> AppSize.Brought {
    AppSize.Brought(bytes: bytes, package: "swift-crypto", version: version)
  }

  /// figures is a build to scenario 1 whose products weigh 4,500,000 bytes, each with its own
  /// tolerance.
  private static func figures(
    toolchain: AppSize.Toolchain = toolchain, scenario: Int? = 1, geo: Int = 1_400_000,
    elements: Int = 1_000_000, brought: [String: AppSize.Brought] = ["Crypto": crypto()]
  ) -> AppSize.Figures {
    AppSize.Figures(
      toolchain: toolchain, scenario: scenario, linked: 10_000_000,
      products: [
        "MountayaClient": 2_000_000, "MountayaElements": elements, "MountayaGeo": geo,
        "MountayaNavigation": 100_000,
      ],
      brought: brought)
  }

  private static func baseline(_ figures: AppSize.Figures = figures()) -> String {
    AppSize.printBaseline(figures, build: AppSize.command(scratch: ".build/x"))
  }

  // MARK: - The map

  @Test("it reads the map's files, sections and the symbols the link kept")
  func readsTheMap() throws {
    let map = try AppSize.parse(Self.map)

    #expect(map.executable == "\(Self.products)/Trail")
    #expect(map.objects.count == 10)
    #expect(map.objects[0] == "linker synthesized")
    #expect(map.objects[7] == "\(Self.products)/MapLibre.framework/MapLibre")
    #expect(map.sections.map(\.name).last == "__common")
    #expect(map.sections.first?.size == 0x0062_AD60)
    // The stripped symbols are listed apart, and none of them is read.
    #expect(map.symbols.count == 21)
    #expect(map.symbols.allSatisfy { $0.size != 0x24 && $0.size != 0x68 })
  }

  @Test("each module is the sizes of its symbols, a zero-fill section's left out")
  func sumsEachModule() throws {
    let linked = AppSize.linked(try AppSize.parse(Self.map))

    // MountayaClient's 56 and 44 bytes, and neither its `__bss` symbol nor its `__common` one.
    #expect(
      linked.modules == [
        "MountayaClient": 100, "Crypto": 104, "MountayaGeo": 20, "MountayaNavigation": 8,
        "MountayaElements": 28,
      ])
    // Every byte kept outside a zero-fill section: the modules', the app's own, MapLibre's and the
    // runtime's stubs, an archive's member and the linker's unwind info.
    #expect(linked.total == 156 + 104 + 2_468 + 20 + 12 + 416 + 127_400)
  }

  @Test("an object's path names its module, in either layout SwiftPM writes")
  func namesTheModule() {
    let release = "/b/.build/arm64-apple-ios/release"

    #expect(
      AppSize.module(ofFile: "\(Self.products)/MountayaGeo.o", products: Self.products)
        == "MountayaGeo")
    #expect(
      AppSize.module(ofFile: "\(Self.products)/Crypto.o", products: Self.products + "/") == "Crypto"
    )
    #expect(
      AppSize.module(ofFile: "\(release)/MountayaGeo.build/Units.swift.o", products: release)
        == "MountayaGeo")
    #expect(
      AppSize.module(ofFile: "\(release)/Trail.build/TrailApp.swift.o", products: release)
        == "Trail")
    for none in [
      "\(Self.products)/MapLibre.framework/MapLibre", "\(Self.products)/PackageFrameworks/X.o",
      "/w/out/Intermediates.noindex/Trail-p.build/Objects-normal/arm64/TrailApp.o",
      "/Xcode/libswiftCompatibility56.a(Task.cpp.o)", "linker synthesized", "\(Self.products)/.o",
      "\(Self.products)/libswiftCore.tbd",
    ] {
      #expect(AppSize.module(ofFile: none, products: Self.products) == nil, "\(none)")
    }
  }

  @Test("a share is a library product's targets or a module the SDK brings, the app's own left out")
  func measuresTheShares() throws {
    let linked = AppSize.linked(try AppSize.parse(Self.map))
    let native = AppSize.Linked(modules: ["MountayaGeo": 20, "Trail": 9_000], total: 9_020)
    let figures = AppSize.measure(
      linked, products: Self.package, toolchain: Self.toolchain, scenario: 1,
      packages: ["Crypto": AppSize.BroughtPackage(identity: "swift-crypto", version: "5.1.1")])

    #expect(
      figures.products == [
        "MountayaClient": 100, "MountayaElements": 28, "MountayaGeo": 20, "MountayaNavigation": 8,
      ])
    #expect(figures.brought == ["Crypto": Self.crypto(104)])
    #expect(figures.scenario == 1)
    #expect(figures.sdk == 156)
    #expect(figures.linked == linked.total)
    #expect(
      figures.shares.map(\.name) == [
        "MountayaClient", "MountayaElements", "MountayaGeo", "MountayaNavigation", "Crypto",
      ])
    // A product the app does not link weighs 0, the app's own module is no share, and a module no
    // package is known for is brought with neither.
    let alone = AppSize.measure(
      native, products: Self.package, toolchain: Self.toolchain, scenario: 1)
    #expect(alone.products["MountayaClient"] == 0)
    #expect(alone.brought.isEmpty)
    let unknown = AppSize.measure(
      linked, products: Self.package, toolchain: Self.toolchain, scenario: 1)
    #expect(unknown.brought == ["Crypto": AppSize.Brought(bytes: 104)])
  }

  @Test("a text that is no map, or a line that reads as none, is refused at its line")
  func refusesWhatIsNoMap() {
    func refusal(_ text: String) -> AppSizeError? {
      do {
        _ = try AppSize.parse(text)
        return nil
      } catch {
        return error
      }
    }
    let head = "# Path: /p/Trail\n# Object files:\n[  0] linker synthesized\n"

    #expect(refusal("")?.message.hasPrefix("it is no linker map") == true)
    #expect(refusal("{\"type\": \"apk\"}")?.message.hasPrefix("it is no linker map") == true)
    #expect(refusal(head)?.message.hasPrefix("it is no linker map") == true, "no symbols at all")
    #expect(refusal(head + "# Sections:\n0x1\t__TEXT\n# Symbols:\n")?.line == 5)
    #expect(refusal(head + "# Symbols:\n0x100004000\t0x10\t_main\n")?.line == 5)
    #expect(refusal(head + "# Symbols:\n0x100004000\t16\t[  0] _main\n")?.line == 5)
    #expect(refusal("# Path: /p/Trail\n# Object files:\nlinker synthesized\n")?.line == 3)
    #expect(refusal(head + "# Symbols:\n0x100004000\t0x10\t[  0] _main\n") == nil)
  }

  // MARK: - The packages the SDK brings

  @Test("the packages the app resolves are read from SwiftPM's tree, each once, the root left out")
  func readsTheResolvedPackages() throws {
    let tree = """
      warning: a notice SwiftPM prints first
      {
        "identity": "trail", "name": "trail", "version": "unspecified", "path": "/w/Examples/Trail",
        "dependencies": [
          {
            "identity": "sdk-swift", "version": "unspecified", "path": "/w",
            "dependencies": [
              {
                "identity": "swift-crypto", "version": "5.1.1", "path": "/s/checkouts/swift-crypto",
                "dependencies": [
                  {"identity": "swift-asn1", "version": "1.7.4", "path": "/s/checkouts/swift-asn1",
                   "dependencies": []}
                ]
              },
              {"identity": "swift-asn1", "version": "1.7.4", "path": "/s/checkouts/swift-asn1",
               "dependencies": []}
            ]
          }
        ]
      }
      """
    let packages = try AppSize.resolvedPackages(in: tree)

    #expect(
      packages == [
        AppSize.ResolvedPackage(identity: "sdk-swift", version: nil, path: "/w"),
        AppSize.ResolvedPackage(
          identity: "swift-crypto", version: "5.1.1", path: "/s/checkouts/swift-crypto"),
        AppSize.ResolvedPackage(
          identity: "swift-asn1", version: "1.7.4", path: "/s/checkouts/swift-asn1"),
      ])
    #expect(throws: AppSizeError.self) { try AppSize.resolvedPackages(in: "no tree") }
    #expect(throws: AppSizeError.self) {
      try AppSize.resolvedPackages(in: #"{"dependencies": [{"identity": "x"}]}"#)
    }
  }

  @Test("a pin's version is read by its identity, and a pin by revision alone pins none")
  func readsThePins() {
    let resolved = """
      {
        "originHash" : "0",
        "pins" : [
          {"identity" : "swift-crypto", "state" : {"revision" : "f8fa", "version" : "5.1.1"}},
          {"identity" : "swift-asn1", "state" : {"revision" : "917b"}}
        ],
        "version" : 3
      }
      """

    #expect(AppSize.pinnedVersions(in: resolved) == ["swift-crypto": "5.1.1"])
    #expect(AppSize.pinnedVersions(in: "not JSON").isEmpty)
  }

  // MARK: - The build and the toolchain

  @Test("the build is the app in release for an iOS device, its linker writing the map")
  func buildsTheApp() {
    let arguments = AppSize.buildArguments(scratch: "/s", sdk: "/sdk", map: "/s/Trail.map")

    #expect(arguments.starts(with: ["swift", "build", "-c", "release"]))
    #expect(arguments.suffix(4) == ["-Xlinker", "-map", "-Xlinker", "/s/Trail.map"])
    #expect(arguments.contains("arm64-apple-ios") && arguments.contains("Trail"))
    #expect(
      AppSize.command(scratch: ".build/trail-ios-release-6.4")
        == "swift build -c release --package-path Examples/Trail --scratch-path "
        + ".build/trail-ios-release-6.4 --product Trail --triple arm64-apple-ios --sdk "
        + #""$(xcrun --sdk iphoneos --show-sdk-path)" -Xlinker -map -Xlinker "#
        + ".build/trail-ios-release-6.4/Trail.map")
    #expect(
      AppSize.dependenciesArguments(scratch: "/s")
        == [
          "swift", "package", "--package-path", "Examples/Trail", "--scratch-path", "/s",
          "show-dependencies", "--format", "json",
        ])
  }

  @Test("the toolchain is read from what Xcode and Swift print, and names the build's directory")
  func readsTheToolchain() {
    let driver = """
      swift-driver version: 1.168.6 Apple Swift version 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)
      Target: arm64-apple-macosx27.0.0
      """

    #expect(AppSize.xcodeVersion(from: "Xcode 27.2\nBuild version 27B52\n") == "27.2 (27B52)")
    #expect(AppSize.xcodeVersion(from: "xcode-select: error: no developer tools") == nil)
    #expect(AppSize.swiftVersion(from: driver) == "6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1)")
    #expect(
      AppSize.swiftVersion(from: "Swift version 6.2.3 (swift-6.2.3-RELEASE)")
        == "6.2.3 (swift-6.2.3-RELEASE)")
    #expect(AppSize.swiftVersion(from: "Target: arm64-apple-macosx27.0.0") == nil)
    #expect(AppSize.scratch(swift: "6.4.2 (swiftlang-6.4.2.1.9)") == ".build/trail-ios-release-6.4")
    #expect(AppSize.scratch(swift: "main (swiftlang-6.5)") == nil)
  }

  // MARK: - The baseline

  @Test("the tolerance is 2% of the baseline or 16 KiB, whichever is larger")
  func tolerance() {
    #expect(AppSize.tolerance(of: 0) == 16_384)
    #expect(AppSize.tolerance(of: 100_000) == 16_384)
    #expect(AppSize.tolerance(of: 819_200) == 16_384)
    #expect(AppSize.tolerance(of: 1_400_000) == 28_000)
  }

  @Test("a baseline reads back what it records, its scenario, build and toolchain beside")
  func roundTrip() throws {
    let text = Self.baseline()
    let document = try OrderedJSON.parse(text)

    #expect(try AppSize.readBaseline(text) == Self.figures())
    #expect(
      document.members?.map(\.key)
        == ["platform", "scenario", "build", "xcode", "swift", "linked", "products", "brought"])
    #expect(document["platform"]?.stringValue == "ios")
    #expect(document["scenario"]?.numberValue == 1)
    #expect(document["xcode"]?.stringValue == "27.2 (27B52)")
    #expect(document["products"]?.members?.first?.key == "MountayaClient")
    #expect(document["brought"]?["Crypto"]?.members?.map(\.key) == ["package", "version", "bytes"])
    #expect(document["brought"]?["Crypto"]?["version"]?.stringValue == "5.1.1")
    #expect(text.hasSuffix("}\n"))
    // A module no package is known for is recorded with neither, and read back so.
    let unknown = Self.figures(brought: ["Crypto": AppSize.Brought(bytes: 7)])
    #expect(try AppSize.readBaseline(Self.baseline(unknown)) == unknown)
  }

  @Test("refuses a baseline of another platform or of another shape")
  func refusesAnotherBaseline() {
    func refusal(_ text: String) -> String? {
      do {
        _ = try AppSize.readBaseline(text)
        return nil
      } catch {
        return error.message
      }
    }
    let text = Self.baseline()

    #expect(
      refusal(text.replacingOccurrences(of: #""ios""#, with: #""android""#))
        == "it records android, not ios")
    #expect(refusal(#"{"platform": "ios"}"#) != nil)
    #expect(refusal("no JSON")?.hasPrefix("it is no JSON") == true)
    #expect(refusal(text.replacingOccurrences(of: #""bytes": 1500"#, with: #""bytes": -1"#)) != nil)
    #expect(
      refusal(text.replacingOccurrences(of: #""bytes": 1500"#, with: #""bytes": 1.5"#)) != nil)
    #expect(
      refusal(text.replacingOccurrences(of: #""scenario": 1"#, with: #""scenario": 0"#))
        == "its `scenario` is no version of sdk/trail.yaml")
    #expect(
      refusal(text.replacingOccurrences(of: #""scenario": 1"#, with: #""scenario": "one""#))
        != nil)
  }

  // MARK: - The rule

  @Test("a share within its tolerance passes, and one grown past it fails, one line each")
  func growth() {
    let within = AppSize.compare(Self.figures(geo: 1_410_000), baseline: Self.baseline())
    #expect(within.findings.isEmpty)
    #expect(
      within.notes == [
        "ios: MountayaClient: 1.91 MiB, +0 B (+0.0%), within tolerance",
        "ios: MountayaElements: 976.6 KiB, +0 B (+0.0%), within tolerance",
        "ios: MountayaGeo: 1.34 MiB, +9.8 KiB (+0.7%), within tolerance",
        "ios: MountayaNavigation: 97.7 KiB, +0 B (+0.0%), within tolerance",
        "ios: Crypto: 1.5 KiB, +0 B (+0.0%), within tolerance",
        "ios: the SDK's products together: 4.30 MiB, +9.8 KiB (+0.2%), reported and not compared",
        "ios: the whole executable: 9.54 MiB, +0 B (+0.0%), never compared",
      ])

    let grown = AppSize.compare(Self.figures(geo: 1_500_000), baseline: Self.baseline())
    #expect(
      grown.findings == [
        "MountayaGeo: 1.43 MiB, +97.7 KiB (+7.1%), past tolerance (27.3 KiB): find what the "
          + "module now keeps, a public declaration, a table or a dependency, and after a "
          + "deliberate change run MOUNTAYA_SIZE_BASELINE=write mise run size:check"
      ])
  }

  @Test("a module the SDK starts to bring fails until it is recorded, and one it grows fails")
  func brought() {
    let asn1 = AppSize.Brought(bytes: 120_000, package: "swift-asn1", version: "1.7.4")
    let new = AppSize.compare(
      Self.figures(brought: ["Crypto": Self.crypto(), "SwiftASN1": asn1]),
      baseline: Self.baseline())
    #expect(
      new.findings == [
        "SwiftASN1 (swift-asn1 1.7.4): 117.2 KiB, a module the SDK now brings that the baseline "
          + "does not record: find what brings it, and after a deliberate change run "
          + "MOUNTAYA_SIZE_BASELINE=write mise run size:check"
      ])

    let grown = AppSize.compare(
      Self.figures(brought: ["Crypto": Self.crypto(401_600)]), baseline: Self.baseline())
    #expect(grown.findings.count == 1)
    #expect(grown.findings.first?.hasPrefix("Crypto: 392.2 KiB, +390.7 KiB (+26673.3%)") == true)
    #expect(grown.findings.first?.contains("past tolerance (16.0 KiB)") == true)
  }

  @Test("a module brought at another version is reported and not compared")
  func broughtAtAnotherVersion() {
    let moved = AppSize.compare(
      Self.figures(brought: ["Crypto": Self.crypto(401_600, version: "5.2.0")]),
      baseline: Self.baseline())

    #expect(moved.findings.isEmpty)
    #expect(
      moved.notes.contains(
        "ios: Crypto: 392.2 KiB at swift-crypto 5.2.0, the baseline 1.5 KiB at swift-crypto "
          + "5.1.1, so it is reported and not compared: MOUNTAYA_SIZE_BASELINE=write mise run "
          + "size:check records it at this version"))
  }

  @Test("a share that shrinks past its tolerance is a note, and one no longer linked is told")
  func shrinking() {
    let smaller = AppSize.compare(Self.figures(elements: 900_000), baseline: Self.baseline())
    #expect(smaller.findings.isEmpty)
    #expect(
      smaller.notes.contains(
        "ios: MountayaElements: 878.9 KiB, -97.7 KiB (-10.0%), past tolerance (19.5 KiB) as it "
          + "shrank: MOUNTAYA_SIZE_BASELINE=write mise run size:check records the smaller figure"))

    let gone = AppSize.compare(Self.figures(brought: [:]), baseline: Self.baseline())
    #expect(gone.findings.isEmpty)
    #expect(
      gone.notes.contains(
        "ios: Crypto is no longer brought, where the baseline records 1.5 KiB of it: "
          + "MOUNTAYA_SIZE_BASELINE=write mise run size:check drops it"))
  }

  @Test("a product the baseline does not record fails, and one the build no longer has is 0")
  func products() {
    var more = Self.figures().products
    more["MountayaRoutes"] = 4_000
    let added = AppSize.compare(
      AppSize.Figures(
        toolchain: Self.toolchain, scenario: 1, linked: 10_000_000, products: more,
        brought: ["Crypto": Self.crypto()]),
      baseline: Self.baseline())
    #expect(
      added.findings == [
        "records no share of MountayaRoutes, which the package declares: run "
          + "MOUNTAYA_SIZE_BASELINE=write mise run size:check"
      ])

    var fewer = Self.figures().products
    fewer["MountayaNavigation"] = nil
    let removed = AppSize.compare(
      AppSize.Figures(
        toolchain: Self.toolchain, scenario: 1, linked: 10_000_000, products: fewer,
        brought: ["Crypto": Self.crypto()]),
      baseline: Self.baseline())
    #expect(removed.findings.isEmpty)
    #expect(
      removed.notes.contains(
        "ios: MountayaNavigation: 0 B, -97.7 KiB (-100.0%), past tolerance (16.0 KiB) as it "
          + "shrank: MOUNTAYA_SIZE_BASELINE=write mise run size:check records the smaller figure"))
  }

  @Test("a baseline measured to another scenario, or to none, is reported, not compared")
  func anotherScenario() {
    let later = AppSize.compare(
      Self.figures(scenario: 2, geo: 2_000_000), baseline: Self.baseline())
    #expect(later.findings.isEmpty)
    #expect(
      later.notes.first
        == "ios: built to scenario 2 of sdk/trail.yaml and the baseline to scenario 1, so the "
        + "figures are reported and not compared: a scenario moves what the app does, and "
        + "MOUNTAYA_SIZE_BASELINE=write mise run size:check records them for this one")
    #expect(later.notes.contains("ios: MountayaGeo: 1.91 MiB"))

    // The baseline the gate recorded before it built Trail: no scenario, and its own shape.
    let before = """
      {"platform": "ios", "build": "…", "xcode": "27.2 (27B52)", "swift": "6.4.2", "linked": 1,
       "products": {"MountayaGeo": 1}, "brought": {"Crypto": 1438}}
      """
    let reported = AppSize.compare(Self.figures(), baseline: before)
    #expect(reported.findings.isEmpty)
    #expect(
      reported.notes.first?.hasPrefix(
        "ios: built to scenario 1 of sdk/trail.yaml and the baseline to none, measured before "
          + "the gate built Trail, so the figures are reported and not compared") == true)
  }

  @Test("a baseline measured with another toolchain is reported, not compared")
  func anotherToolchain() {
    let newer = AppSize.Toolchain(xcode: "27.3 (27C10)", swift: Self.toolchain.swift)
    let result = AppSize.compare(
      Self.figures(toolchain: newer, geo: 2_000_000), baseline: Self.baseline())

    #expect(result.findings.isEmpty)
    #expect(
      result.notes.first?.hasPrefix(
        "ios: built with Xcode 27.3 (27C10) and Swift 6.4.2 (swiftlang-6.4.2.1.9 clang-2100.4.1.1) "
          + "and the baseline with Xcode 27.2 (27B52) and Swift 6.4.2 (swiftlang-6.4.2.1.9 "
          + "clang-2100.4.1.1), so the figures are reported and not compared") == true)
    #expect(result.notes.contains("ios: MountayaGeo: 1.91 MiB, the baseline 1.34 MiB"))
    #expect(
      result.notes.contains(
        "ios: Crypto (swift-crypto 5.1.1): 1.5 KiB, the baseline 1.5 KiB at swift-crypto 5.1.1"))
  }

  @Test("no baseline fails and says how to record one, and so does an unreadable one")
  func noBaseline() {
    let result = AppSize.compare(Self.figures(), baseline: nil)

    #expect(
      result.findings == ["no baseline: run MOUNTAYA_SIZE_BASELINE=write mise run size:check"])
    #expect(
      result.notes == [
        "ios: MountayaClient: 1.91 MiB", "ios: MountayaElements: 976.6 KiB",
        "ios: MountayaGeo: 1.34 MiB", "ios: MountayaNavigation: 97.7 KiB",
        "ios: Crypto (swift-crypto 5.1.1): 1.5 KiB",
        "ios: the SDK's products together: 4.29 MiB, reported and not compared",
        "ios: the whole executable: 9.54 MiB, never compared",
      ])

    let unreadable = AppSize.compare(Self.figures(), baseline: "[]")
    #expect(unreadable.findings.count == 1)
    #expect(unreadable.findings.first?.hasPrefix("is no size baseline, since") == true)
    #expect(
      unreadable.findings.first?.hasSuffix("run MOUNTAYA_SIZE_BASELINE=write mise run size:check")
        == true)
  }

  @Test("sizes read as a person reads them")
  func formatsBytes() {
    #expect(AppSize.formatBytes(512) == "512 B")
    #expect(AppSize.formatBytes(16_384) == "16.0 KiB")
    #expect(AppSize.formatBytes(1_400_000) == "1.34 MiB")
    #expect(AppSize.formatBytes(-2_048) == "-2.0 KiB")
  }
}
