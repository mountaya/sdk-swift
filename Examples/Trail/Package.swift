// swift-tools-version: 6.2.3
import PackageDescription

// Trail, the sample app every native Mountaya SDK ships, as the contract's `sdk/trail.yaml`
// describes it. You run it from `Trail.xcodeproj` beside this file, on the iOS simulator or an
// iPhone; this manifest builds the same sources, `Sources/Trail/`, as an executable, which the
// size gate builds in release for an iOS device and reads module by module (SPEC.md section 7),
// so the app it measures is the app you run.
//
// It depends on this repository by path and turns the `Elements` trait on, as an app that shows a
// map does, and links the four products such an app links, never `MountayaAdmin`: minting a
// session is the session server's, `Session/`, a package of its own. It builds for iOS alone, so
// nothing but the size gate builds it; its demo itinerary and its Info.plist are the Xcode
// project's to bundle.
let settings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .treatAllWarnings(as: .error),
]

let package = Package(
  name: "trail",
  platforms: [.iOS(.v17)],
  dependencies: [
    .package(path: "../..", traits: ["Elements"])
  ],
  targets: [
    .executableTarget(
      name: "Trail",
      dependencies: [
        .product(name: "MountayaClient", package: "sdk-swift"),
        .product(name: "MountayaGeo", package: "sdk-swift"),
        .product(name: "MountayaNavigation", package: "sdk-swift"),
        .product(name: "MountayaElements", package: "sdk-swift"),
      ],
      exclude: ["itinerary.json"],
      swiftSettings: settings
    )
  ],
  swiftLanguageModes: [.v6]
)
