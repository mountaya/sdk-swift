// swift-tools-version: 6.2.3
import PackageDescription

// The tests of `Sources/MountayaElements/Renderer/`, the one directory that knows MapLibre, at the
// mirrored path the layout law reads (SPEC.md section 6). MapLibre ships for iOS alone, so these
// tests run on the iOS simulator, and the package's own test target leaves this directory out.
//
// It is a package of its own because a root package's trait cannot be turned on from `xcodebuild`,
// and a package that depends on sdk-swift by path can: this one turns `Elements` on, and only it,
// as a map-only app does, and `mise run test:ios:elements` runs its tests. MapLibre is named here
// too, at the package's own range, for its network configuration, which the tests hand a stub of
// the Tile API so no test reaches the network.
let settings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .treatAllWarnings(as: .error),
]

let package = Package(
  name: "renderer",
  platforms: [.iOS(.v17)],
  dependencies: [
    .package(path: "../../..", traits: ["Elements"]),
    .package(
      url: "https://github.com/maplibre/maplibre-gl-native-distribution.git", "7.0.0"..<"8.0.0"),
  ],
  targets: [
    // A stub of the Tile API and of another host, served to MapLibre's own loader, the window a
    // map is drawn in, the pixels of an image drawn, the controls drawn with no window, a map
    // engine a control drives with no renderer, an itinerary a data element reads with no network,
    // and a data element hosted in a window as an app shows one, over a value the test holds.
    .target(
      name: "RendererSupport",
      dependencies: [
        .product(name: "MapLibre", package: "maplibre-gl-native-distribution"),
        .product(name: "MountayaElements", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaClient", package: "sdk-swift"),
      ],
      path: "Support",
      swiftSettings: settings
    ),
    .testTarget(
      name: "RendererContractsTests",
      dependencies: [
        "RendererSupport",
        .product(name: "MountayaElements", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaClient", package: "sdk-swift"),
      ],
      path: "Contracts",
      swiftSettings: settings
    ),
    .testTarget(
      name: "RendererRulesTests",
      dependencies: [
        "RendererSupport",
        .product(name: "MountayaElements", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
      ],
      path: "Rules",
      swiftSettings: settings
    ),
    .testTarget(
      name: "RendererEnginesTests",
      dependencies: [
        "RendererSupport",
        .product(name: "MountayaElements", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaClient", package: "sdk-swift"),
        .product(name: "MapLibre", package: "maplibre-gl-native-distribution"),
      ],
      path: "Engines",
      swiftSettings: settings
    ),
    .testTarget(
      name: "RendererViewsTests",
      dependencies: [
        "RendererSupport",
        .product(name: "MountayaElements", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaClient", package: "sdk-swift"),
        .product(name: "MapLibre", package: "maplibre-gl-native-distribution"),
      ],
      path: "Views",
      swiftSettings: settings
    ),
  ],
  swiftLanguageModes: [.v6]
)
