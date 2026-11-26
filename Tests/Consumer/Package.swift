// swift-tools-version: 6.2.3
import PackageDescription

// The outside-in consumer of SPEC.md section 7. It depends on this repository by path, imports
// each product plainly, as an app does, the admin unit in the files that call it as a server does,
// and compiles against the public surface alone, so a
// public type with an internal initializer, or a protocol whose requirement names an internal
// type, fails here where no inside test can see it. `ReadmeSnippets` holds the README's Swift
// snippets, printed from it (SPEC.md section 10). BoundaryTests builds the package.
//
// A consumer's floors reach the package's own, so the list below is the root manifest's, and
// BoundaryTests fails where the two differ.
//
// The Elements trait is turned on as an app turns it on, so the consumer resolves MapLibre and an
// iOS build of it compiles the map view, which BoundaryTests builds on macOS, beside the voice an
// iOS build alone compiles. On Linux, where nothing of the trait builds, it stays off, so a Linux
// run resolves no MapLibre binary.
//
// The app the size gate measures is Trail, the sample app under Examples/Trail (SPEC.md section
// 7), a package of its own.
#if os(Linux)
  let traits: Set<Package.Dependency.Trait> = []
#else
  let traits: Set<Package.Dependency.Trait> = ["Elements"]
#endif

let settings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .treatAllWarnings(as: .error),
]

let package = Package(
  name: "consumer",
  platforms: [
    .iOS(.v17),
    .macCatalyst(.v17),
    .macOS(.v14),
    .tvOS(.v17),
    .visionOS(.v1),
    .watchOS(.v10),
  ],
  dependencies: [
    .package(path: "../..", traits: traits)
  ],
  targets: [
    .target(
      name: "Consumer",
      dependencies: [
        .product(name: "MountayaClient", package: "sdk-swift"),
        .product(name: "MountayaAdmin", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaNavigation", package: "sdk-swift"),
        .product(name: "MountayaElements", package: "sdk-swift"),
      ],
      swiftSettings: settings
    ),
    .target(
      name: "ReadmeSnippets",
      dependencies: [
        .product(name: "MountayaClient", package: "sdk-swift"),
        .product(name: "MountayaAdmin", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaNavigation", package: "sdk-swift"),
        .product(name: "MountayaElements", package: "sdk-swift"),
      ],
      swiftSettings: settings
    ),
  ],
  swiftLanguageModes: [.v6]
)
