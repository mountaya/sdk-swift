// swift-tools-version: 6.2.3
import PackageDescription

// The tests of `Sources/MountayaNavigation/Speech/`, the voice over the system's speech
// synthesizer, at the mirrored path the layout law reads (SPEC.md section 6). The voice takes the
// audio session, which runs on iOS alone, so these tests run on the iOS simulator, and the package's
// own test target leaves this directory out.
//
// It is a package of its own because `xcodebuild` builds every test target of the root package for
// the simulator, the gate's tools among them, which cannot build for iOS; a package that depends on
// sdk-swift by path builds what its tests name and nothing else. `mise run test:ios` runs it with
// `xcodebuild test`.
let settings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .treatAllWarnings(as: .error),
]

let package = Package(
  name: "speech",
  platforms: [.iOS(.v17)],
  dependencies: [
    .package(path: "../../..")
  ],
  targets: [
    .testTarget(
      name: "SpeechTests",
      dependencies: [
        .product(name: "MountayaNavigation", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaClient", package: "sdk-swift"),
      ],
      path: "Engines",
      swiftSettings: settings
    )
  ],
  swiftLanguageModes: [.v6]
)
