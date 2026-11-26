// swift-tools-version: 6.2.3
import PackageDescription

// Every target compiles in the Swift 6 language mode with these settings. SwiftPM strips
// warnings-as-errors from a package resolved as a dependency, so a consumer never inherits it.
let settings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .treatAllWarnings(as: .error),
]

let package = Package(
  name: "sdk-swift",
  // One list for the whole package, since SwiftPM has no floor per product. Every platform is
  // written out because an omitted one silently takes SwiftPM's own default. The reason for
  // each number is in SPEC.md section 2, never here.
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v17),
    .macOS(.v14),
    .tvOS(.v17),
    .visionOS(.v1),
    .watchOS(.v10),
  ],
  // A product is added by the change that makes it answer its question in SPEC.md section 1.
  // Every product is under the Mountaya SDK License 1.0, in LICENSE.txt and LICENCE.fr.txt at
  // the root, since a manifest has no field that names one.
  products: [
    .library(name: "MountayaClient", targets: ["MountayaClient"]),
    .library(name: "MountayaAdmin", targets: ["MountayaAdmin"]),
    .library(name: "MountayaGeo", targets: ["MountayaGeo"]),
    .library(name: "MountayaNavigation", targets: ["MountayaNavigation"]),
    .library(name: "MountayaElements", targets: ["MountayaElements"]),
  ],
  // A trait is how a consumer asks for a product's heavy dependency, and it is off by default, so
  // a consumer who names none resolves none of it: a dependency a trait disables is left out of
  // resolution, where a platform condition only keeps it out of the build (SPEC.md section 2). A
  // consumer turns it on in its own manifest, `traits: ["Elements"]`, or in the Xcode project's
  // package settings. MapLibre is the one such dependency: the navigation engine links nothing
  // beyond the platform's own frameworks, so it needs no trait.
  traits: [
    .trait(
      name: "Elements",
      description:
        "Links MapLibre Native into MountayaElements for iOS, where it draws the map view."
    ),
    .default(enabledTraits: []),
  ],
  // Every dependency is at its newest stable release. swift-crypto is Apple's own CryptoKit
  // API, on CryptoKit on Apple platforms and on BoringSSL on Linux, so the persisted-query digest
  // and a webhook delivery's signature have one import on every host the client builds on
  // (SPEC.md section 4). MapLibre is a range,
  // since a consumer's MapLibre is theirs (SPEC.md section 10), linked by an iOS build with the
  // Elements trait alone, from its newest stable release, 7.0.0.
  dependencies: [
    .package(url: "https://github.com/apple/swift-crypto.git", from: "5.1.1"),
    .package(
      url: "https://github.com/maplibre/maplibre-gl-native-distribution.git", "7.0.0"..<"8.0.0"),
  ],
  targets: [
    .target(
      name: "MountayaClient",
      dependencies: [.product(name: "Crypto", package: "swift-crypto")],
      swiftSettings: settings
    ),
    // The client's admin unit: the `admin` group's operations, the types only they and the webhook
    // events reach, and the receiving of a delivery, whose signature swift-crypto computes. It
    // sends through the client's transport, the one place a request leaves, and a target that does
    // not name it links none of it (SPEC.md sections 1 and 2).
    .target(
      name: "MountayaAdmin",
      dependencies: ["MountayaClient", .product(name: "Crypto", package: "swift-crypto")],
      swiftSettings: settings
    ),
    // The geo layer: the contract's rules, the navigation vocabulary, the `NavigationEngine`
    // protocol and the scripted engine an app's tests answer. It reaches the client for its wire
    // vocabulary and calls nothing.
    .target(
      name: "MountayaGeo",
      dependencies: ["MountayaClient"],
      swiftSettings: settings
    ),
    // The navigation engine over Geo's machine and its guidance, which build on every platform,
    // and the seams it takes. A seam that reads the device is compiled where the platform's
    // framework gives it what it reads: the location source where Core Location reads a position,
    // and the voice in `Speech/` where the audio session is the platform's, `#if os(iOS)`.
    .target(
      name: "MountayaNavigation",
      dependencies: ["MountayaGeo", "MountayaClient"],
      swiftSettings: settings
    ),
    // The map: its state and engine, the one layer registry and the `map` layer's rules, which
    // name no MapLibre type and build everywhere, and the view over MapLibre Native, which only its
    // `Renderer/` directory knows of. Every MapLibre file is compiled where the dependency is linked
    // and nowhere else, `#if Elements && os(iOS) && !targetEnvironment(macCatalyst)`, so the target
    // builds on every platform and in every build: without the trait it holds the headless map and
    // a type of the view's name that says what to turn on.
    .target(
      name: "MountayaElements",
      dependencies: [
        "MountayaGeo",
        "MountayaClient",
        .product(
          name: "MapLibre",
          package: "maplibre-gl-native-distribution",
          condition: .when(platforms: [.iOS], traits: ["Elements"])
        ),
      ],
      swiftSettings: settings
    ),

    // The gates. They sit under Tools/, outside the layout law's walk of Sources/, and no
    // product reaches them, so a consumer resolves and builds none of this. swift-crypto takes the
    // model's digest, which the printer prints and the conformance report carries (SPEC.md
    // section 3).
    .target(
      name: "GateSupport",
      dependencies: [.product(name: "Crypto", package: "swift-crypto")],
      path: "Tools/GateSupport",
      swiftSettings: settings
    ),
    .executableTarget(
      name: "LintNaming",
      dependencies: ["GateSupport"],
      path: "Tools/LintNaming",
      swiftSettings: settings
    ),
    .executableTarget(
      name: "LintFileStructure",
      dependencies: ["GateSupport"],
      path: "Tools/LintFileStructure",
      swiftSettings: settings
    ),
    // The size gate, which builds the consumer's app in release for an iOS device, on macOS.
    .executableTarget(
      name: "SizeGate",
      dependencies: ["GateSupport"],
      path: "Tools/SizeGate",
      swiftSettings: settings
    ),
    // `mise run snippets`, which type-checks the Swift fences of the Markdown documents it is
    // handed against the consumer's builds of the products, on macOS.
    .executableTarget(
      name: "CompileSnippets",
      dependencies: ["GateSupport"],
      path: "Tools/CompileSnippets",
      swiftSettings: settings
    ),

    // The printer of the generated surface, as a library its tests call and an executable a
    // contributor runs. Like the gates, no product reaches it.
    .target(
      name: "ClientPrinter",
      dependencies: ["GateSupport"],
      path: "Tools/ClientPrinter",
      swiftSettings: settings
    ),
    .executableTarget(
      name: "GenerateClient",
      dependencies: ["ClientPrinter", "GateSupport"],
      path: "Tools/GenerateClient",
      swiftSettings: settings
    ),

    // Simulated time for the suites that measure a wait, a deadline or a stall: a serial
    // executor whose idleness moves a virtual clock on. Like the gates, no product reaches it.
    .target(name: "Simulation", path: "Tools/Simulation", swiftSettings: settings),

    .testTarget(
      name: "MountayaClientTests",
      dependencies: ["MountayaClient", "Simulation"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "MountayaAdminTests",
      dependencies: ["MountayaAdmin", "MountayaClient"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "MountayaGeoTests",
      dependencies: ["MountayaGeo", "MountayaClient"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "MountayaNavigationTests",
      dependencies: ["MountayaNavigation", "MountayaGeo", "MountayaClient"],
      // The `Speech/` topic's tests speak through the audio session, which runs on iOS alone, so
      // they are a package of their own at the mirrored path, run on the iOS simulator by
      // `mise run test:ios`.
      exclude: ["Speech"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "MountayaElementsTests",
      dependencies: ["MountayaElements", "MountayaGeo", "MountayaClient"],
      // The `Renderer/` topic's tests load MapLibre, which runs on iOS alone, so they are a package
      // of their own at the mirrored path, run on the iOS simulator by `mise run test:ios:elements`.
      exclude: ["Renderer"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "GateSupportTests",
      dependencies: ["GateSupport"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "ClientPrinterTests",
      dependencies: ["ClientPrinter", "GateSupport"],
      // The miniature model and the files it prints, compared byte for byte; read from disk,
      // never compiled.
      exclude: ["Golden"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "BoundaryTests",
      dependencies: ["GateSupport"],
      // The public API's committed listing, compared with the compiler's, and the size gate's
      // baseline; read from disk.
      exclude: ["Baseline", "Size"],
      swiftSettings: settings
    ),
    .testTarget(
      name: "ConformanceTests",
      dependencies: [
        "MountayaClient", "MountayaAdmin", "MountayaGeo", "MountayaElements", "GateSupport",
        "Simulation",
      ],
      swiftSettings: settings
    ),
  ],
  swiftLanguageModes: [.v6]
)
