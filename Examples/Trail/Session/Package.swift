// swift-tools-version: 6.2.3
import PackageDescription

// Trail's session server, the contract's `trail.session` step (sdk/trail.yaml): a macOS program
// that reads your publishable and secret keys from the shell and answers the app's
// `POST /session` on 127.0.0.1:8787 with the session `postSession` mints, so the secret key stays
// on your machine. `mise run trail:session` runs it from the repository's root.
//
// It depends on this repository by path, as Trail does, and links `MountayaAdmin`, which Trail
// never links: minting a session is a server's. It turns no trait on, so it resolves no MapLibre.
// `TrailSessionServer` answers each request and listens, over Network.framework, and its tests
// answer the client through an `HTTPExchange` of their own, with no network and no live key.
let settings: [SwiftSetting] = [
  .enableUpcomingFeature("ExistentialAny"),
  .enableUpcomingFeature("MemberImportVisibility"),
  .treatAllWarnings(as: .error),
]

let package = Package(
  name: "trail-session",
  platforms: [.macOS(.v14)],
  dependencies: [
    .package(path: "../../..")
  ],
  targets: [
    .target(
      name: "TrailSessionServer",
      dependencies: [
        .product(name: "MountayaClient", package: "sdk-swift"),
        .product(name: "MountayaAdmin", package: "sdk-swift"),
      ],
      swiftSettings: settings
    ),
    .executableTarget(
      name: "TrailSession",
      dependencies: [
        "TrailSessionServer",
        .product(name: "MountayaClient", package: "sdk-swift"),
      ],
      swiftSettings: settings
    ),
    .testTarget(
      name: "TrailSessionTests",
      dependencies: [
        "TrailSessionServer",
        .product(name: "MountayaClient", package: "sdk-swift"),
        .product(name: "MountayaAdmin", package: "sdk-swift"),
      ],
      swiftSettings: settings
    ),
  ],
  swiftLanguageModes: [.v6]
)
