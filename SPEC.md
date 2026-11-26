# `sdk-swift` specification

Mountaya's Swift SDK: one repository, one `Package.swift`, one SPM product per unit.

This document is written against `sdk/SPEC.md` in `mountaya/schemas`, which is the contract.
It is not written against another SDK. `sdk-typescript`, `sdk-dart` and `sdk-kotlin` implement
the same agreement, and writing this one against any of them would make Swift a translation
rather than an implementation. Where a rule here names what the TypeScript SDK does, the name is
corroboration of a rule argued on its own terms, never the reason for it.

## 1. Scope

**Contract tag.** One tag of `mountaya/schemas`, carried by the generated `schemaVersion`
constant in `MountayaClient` and moved only by a regeneration, and beside it `modelDigest`, the
digest `sdk/SPEC.md` §11 defines of the five files the printer reads, `sdk/model.json` and the
elements' data, which names the exact surface a build was printed from where a tag cannot: one
printed from a commit between two tags carries the tag before it and a surface that tag never
held. Both live in the client because the client is the unit the model prints first and the one
every other product links. `MountayaAdmin` and `MountayaGeo` hold printed code too, the admin
unit's surface in `Sources/MountayaAdmin/Generated/` and the elements' words, tokens and glyphs in
`Sources/MountayaGeo/Generated/` (§3), each printed from the same five files in the same run, so the
client's two constants name them as well and neither declares its own. A conformance report is
keyed on the registry's own `version`, which moves with the contract's expected values rather than
with its tag, and carries the digest of the files it ran against (§9).

### The units

| Product | Layer | Is | Calls the network | Renders |
| --- | --- | --- | --- | --- |
| `MountayaClient` | transport, its core | credentials, the session lifecycle, retries, idempotency keys, conditional writes, the error ladder, date decoding, pagination, event streams, field selection, the generated wire surface of every operation but the `admin` group's | yes, from one type | no |
| `MountayaAdmin` | transport, its admin unit | every operation of the contract's `admin` group, declared on the client as `mountaya.admin` once the product is imported, the types only those operations and the webhook events send or receive, `AdminSchema`, and the receiving of a webhook delivery, `constructWebhookEvent` and the printed `WebhookEvent` | only through the client's transport, never a connection of its own | no |
| `MountayaGeo` | geo | the contract's geo layer, the navigation rules, the headless state and engines every view renders, and the navigation vocabulary with its engine protocol | never | no |
| `MountayaNavigation` | geo, as the engine behind that protocol | the engine an app navigates with, `DeviceNavigationEngine`, Geo's machine with the guidance that says each maneuver, and the seams it takes: where positions come from and the voice that says each maneuver | never | no |
| `MountayaElements` | elements binding, and the `map` layer its engines own | the map's state and engine, `MapEngine`, with the one layer registry and the map and editing engines' rules the `map.*` capabilities prove, which build everywhere, and the views an iOS app shows, `MapView`, the map's controls and panels, `MapControls` among them, and the search box, `SearchControl`, in SwiftUI over MapLibre Native behind the package's `Elements` trait | only through the app's `Mountaya`, for the catalogue a terrain is read from, and MapLibre's own requests, which its request hook gives the client's credential; never a connection of its own | yes |

All five are declared: `MountayaClient` and `MountayaGeo`, each once every capability of its layer
had its runner, `MountayaNavigation`, once its engine stood on Geo's navigation rules,
`MountayaElements`, once the `map` layer's two capabilities had their runners and its view stood on
the map's state, and `MountayaAdmin`, once the contract declared the transport two units.

**The transport is two units, the core and the admin unit** (`sdk/SPEC.md`, "The three layers, in
every language"), and `sdk/model.json` states the unit of every REST operation, webhook event and
component as `unit`. `MountayaClient` is the core: every credential, the secret key included, the
transport, the Data API, the Tile API, and the `studio` and `agent` groups. `MountayaAdmin` is the
admin unit: the sixty operations of the `admin` group, `admin.sessions.postSession` among them, the
130 components only those and the webhook events reach, and the receiving of a delivery. It depends
on the core and declares `admin` on the core's `Mountaya` in an extension, so `import MountayaAdmin`
is the whole of what `mountaya.admin.<resource>.<operationId>(…)` asks, as in the contract's other
languages. An app that draws a map, edits an itinerary, queries the Data API or navigates links the
core alone and carries none of it: a product's share of an app is nearly all it compiles to (§7), so
the admin surface the core held cost every such app 1.82 MiB, `MountayaClient`'s share falling from
4.28 MiB to 2.46 MiB once it left, and the admin unit linked on its own measures 1.35 MiB. The
refusal of a delivery, `MountayaError.webhookSignature(WebhookSignatureError)`, stays the core's,
since an app catches every failure of the SDK as a `MountayaError` and a case cannot carry a type of
a target the core does not depend on.

The layer is the row of `sdk/SPEC.md`'s layer table the product implements, and `map` is the
layer the contract's registry names for the rendering engines' own behaviour, which an SDK whose
elements binding drives a renderer reproduces and the renderer-free geo layer cannot. **An SPM product
is the boundary unit**: a consumer writes `.product(name: "MountayaGeo", package: "sdk-swift")`
and links nothing else, and the manifest, not a naming convention, decides what their binary
carries. That is what lets one repository hold every unit and still draw the graph the contract
draws.

### Where each unit runs

| Product | iOS, iPadOS | macOS | Mac Catalyst | tvOS, watchOS | visionOS | Linux |
| --- | --- | --- | --- | --- | --- | --- |
| `MountayaClient` | yes | yes | yes | yes | yes | yes |
| `MountayaAdmin` | the operations | yes | the operations | the operations | the operations | yes |
| `MountayaGeo` | yes | yes | yes | yes | yes | yes |
| `MountayaNavigation` | yes | the engine and the device's position; the voice as an iPad app | yes | the engine; the device's position on watchOS | the engine and the device's position; the voice as an iPad app | the engine |
| `MountayaElements` | yes | as an iPad app | no | no | as an iPad app | no |

**The client and the geo layer run on every Apple platform and on Linux**, because nothing in
them names a UI framework or a binary dependency. So does the admin unit's every operation, which an
admin tool on an iPad calls as a server does; receiving a webhook delivery is a server's alone, on
macOS and Linux, as the secret key is, since the endpoint's signing secret never ships in an app.
**Navigation runs on every platform too**,
because it links nothing but the platform's own frameworks: `DeviceNavigationEngine` is Geo's
machine with its guidance and names no framework, the device's position is read where Core
Location reads one, on every Apple platform but tvOS, and the voice speaks where the audio session
it takes is the platform's, on iOS and in a Mac Catalyst app (§2). **The views are an iOS
product**, because MapLibre's Swift package ships iOS binaries only. `MountayaElements` still
builds everywhere, with or without its trait: elsewhere it holds the map's state and engine,
`MapEngine`, and a `MapView` the compiler refuses with a message naming what to do (§2). An iOS app
still runs unmodified on a Mac with Apple silicon and in visionOS's compatibility mode, and
carries both products there; a native macOS, visionOS or Mac Catalyst target cannot link the map
view, nor a native macOS or visionOS one the voice.

**The limits, plainly.** A native Mac, Apple TV, Apple Watch or Vision Pro app gets the data, the
rules and the navigation engine, draws with the platform's own frameworks, and says each maneuver
through a voice of its own. `sdk-kotlin` reaches iPhone and iPad
through Kotlin/Native, which has no visionOS target and only experimental Mac Catalyst support,
so on those platforms this SDK is the only Mountaya SDK there is.

### What each kind of app gets

| App | Takes from this SDK | Takes from elsewhere |
| --- | --- | --- |
| A Swift app on iPhone and iPad | every product but `MountayaAdmin`, which only an app that runs its organization adds; a UIKit app hosts a view in a `UIHostingController` | nothing |
| A CarPlay app | `MountayaClient`, `MountayaGeo`, `MountayaNavigation`, and `MapView` in the CarPlay window | the templates, which the host fills from `NavigationState`; no CarPlay UI ships here |
| A native Mac, Apple TV, Apple Watch or Vision Pro app | `MountayaClient`, `MountayaGeo`, `MountayaNavigation`'s engine, with the device's position but on Apple TV, and `MountayaElements`'s `MapEngine` for a map's state | the drawing, from the platform's own frameworks over Geo's data and the map's state, and the voice that says each maneuver |
| A Swift server, on Linux or macOS | `MountayaClient` and `MountayaGeo`, the secret key included, and `MountayaAdmin` to mint session tokens, run its organization or receive webhooks | nothing |
| A Kotlin Multiplatform app with a native UI | on iOS, `MountayaClient` for the map's credentials, `MountayaNavigation` and `MountayaElements` | `sdk-kotlin`'s `mountaya-client` and `mountaya-geo`, in its shared code |
| A Compose Multiplatform app | on iOS, `MountayaElements` hosted through Compose's UIKit interop | `sdk-kotlin` for everything else; a Compose Multiplatform map is additive there, later |
| A Flutter app | nothing | `sdk-dart`, whose navigation engine is Dart over its own geo package, its native code reading the device's location and speaking and deciding nothing, and which links no sibling SDK |
| An Android app, a JVM server or a JVM desktop app | nothing | `sdk-kotlin` |

**A Kotlin Multiplatform app draws the seam through its own code.** Its shared Kotlin takes
`sdk-kotlin`; its SwiftUI side takes the map and the navigation engine from here, and constructs
a `Mountaya` of its own for the map's tile credentials. What crosses from Kotlin to Swift crosses
as values the app converts: this SDK never links Kotlin, and a type Kotlin/Native exports to
Swift is not a `MountayaGeo` type, whatever its name.

### How a consumer reads the units

| Product | Answers |
| --- | --- |
| `MountayaClient` | How do I get Mountaya data? |
| `MountayaAdmin` | How do I run my organization, mint a session token or receive a webhook? |
| `MountayaGeo` | What does Mountaya decide about it? |
| `MountayaNavigation` | How do I follow a route? |
| `MountayaElements` | How do I show it? |

A consumer who asks only the first question links only the first product, and each question they
add adds its product and nothing else.

### What a consumer declares

A normal integration declares Mountaya products and nothing else, never MapLibre, turns on the
trait of the product that needs one, `traits: ["Elements"]` (§2, §10), wires navigation's route
source to its own client, and hands the map its client (§8). MapLibre is an implementation choice
behind a Mountaya-owned API, and a dependency the consumer declares is one whose next upgrade
becomes their migration. The one exception is an app that reaches through `MapView`'s ready
callback to MapLibre's own map (§8): it declares MapLibre too, within the range §10 states, and
SPM resolves the one copy both of them link.

### No bridges

MapLibre Native, in C++, is a dependency behind a Mountaya-owned API, not a bridge. A bridge is a
Mountaya rule written in another language and wrapped here, and MapLibre holds none. Navigation
links no library at all: when a traveller is off route, which step they are in and when a prompt
falls due are Mountaya's rules, and each is Swift in this repository (§8). Every rule a fixture
proves is compiled from this repository's Swift.

### Out of scope

- **The studio.** The studio layer and its binding are TypeScript-only. They are Mountaya's
  editor, and a Swift app does not host the editor. A rule a Swift surface needs that the studio
  holds moves down into the geo layer of every SDK at once rather than bringing a studio with it,
  which is how it stays one rule: maneuver phrasing is the first, as
  `geo.navigation.instruction-keys`. Every `studio.*` capability is `scoped` here (§11).
- **A shared core.** Mountaya's rules written once in Kotlin, Rust or C and wrapped here would
  make this SDK a wrapper over another language's implementation, which is the bridge the
  constraint forbids, and a Swift consumer's stack traces, binary and concurrency model would
  stop being Swift's. `sdk-kotlin` publishes no XCFramework, this SDK never links Kotlin, and the
  fixtures are the only thing holding this SDK and `sdk-kotlin` together.
- **UIKit surfaces.** The views are SwiftUI. A UIKit app hosts one in a `UIHostingController`,
  which is one line, where a second view layer is a second implementation of every surface.
- **A transport binding.** The contract allows at most one per UI framework and asks for none.
  SwiftUI's `task` already awaits an async call, and a cache a consumer brings has a retry of its
  own that would repeat what the client already repeated, so a consumer who brings one turns that
  retry off. The TypeScript SDK's query binding does exactly that to its own cache.
- **A WebAssembly target.** A browser build would bring the contract's secret-key defences for
  browsers into scope, for consumers `sdk-typescript` already serves.
- **Permissions and background execution.** Asking for location and keeping a session alive in
  the background are the host's decisions, with review consequences only the host can weigh (§8).
- **Console-only resources.** The contract does not carry them.

### What waits on the contract

What `mountaya/schemas` leaves open at registry 19 is listed for every SDK in
[`CONTRACT-GAPS.md`](CONTRACT-GAPS.md), with what each answers until the contract does, which
`sdk-kotlin` and `sdk-dart` read here and keep no copy of.

## 2. The graph

```
MountayaClient ──┬──(types)──> MountayaGeo ──┬──> MountayaNavigation
                 │                           │
                 │                           └──> MountayaElements <──── MapLibre (public)
                 │
                 └──> MountayaAdmin
```

Arrows point from a dependency to its dependents, third-party packages included.

- **`MountayaAdmin` depends on `MountayaClient`, and nothing depends on it.** It is the client's
  admin unit (§1): the `admin` group's operations, the components only they and the webhook events
  reach, and the receiving of a delivery, each printed from the model's `unit` but the receiving,
  which is written here (§3). It reaches the network through the core's transport alone, and no
  product of the core imports it, which §7's scan holds, so an app links it only by naming it. It
  links swift-crypto's `Crypto` for the signature of a delivery, as the core does for a persisted
  query's digest, and no other package.

- **`MountayaGeo` depends on `MountayaClient` for its wire vocabulary and calls nothing.** Swift
  has no type-only dependency, so the edge links the whole client, and the promise that Geo
  never calls it is held by §7's boundary test rather than by the graph. §11 records the link.
  The wire's timestamp form is part of that vocabulary: Geo reads a timestamp it holds as text by
  the client's published anchor, `parseTimestamp(_:)`, a rule that reads a text and calls nothing
  (§4).
- **`MountayaNavigation` links no third-party package.** Its engine is Geo's machine with its
  guidance, Swift in this repository, and its seams read the platform's own frameworks: Core
  Location for the device's position, where it reads one, and AVFoundation for the voice, where the
  audio session it takes is the platform's. So it needs no trait, builds on every platform the
  package does, and links no navigation library, which §7 holds.
- **`MountayaElements` is the only product that links MapLibre**, its `MapLibre` product alone,
  behind the package's `Elements` trait, and exposes it publicly, by a `public import` in the view
  alone, because the map view's ready callback hands back MapLibre's own map (§8); every other
  file that names MapLibre imports it `internal`, and only `Renderer/` names it (§7).
- **`MountayaElements` owns the `map` layer.** How a patch merges onto what a map holds and where
  an edit's magnet lands are the map and editing engines' own behaviour, which the contract files
  under `map` rather than `geo` because a renderer-free consumer has no map to patch and no edit
  to snap. Their rules name no MapLibre or SwiftUI type, so they sit outside the platform
  condition every MapLibre and SwiftUI file sits behind, and they build, and run their fixtures,
  on macOS and Linux like the rest of the package. So does the map's state and its engine,
  `MapEngine`, with the one layer registry, which name no MapLibre type either; the renderer that
  draws that state on MapLibre's map, the request hook and the view are iOS-only.
- **`MountayaElements` does not depend on `MountayaNavigation`.** It renders `NavigationState`,
  which Geo declares, so a map-only app ships no navigation engine and a navigation app with no map
  ships no MapLibre.
- **`MountayaNavigation` and `MountayaElements` are built on Geo's public API only**, with no
  `@_spi` and two `package` reaches across products, the comparison helpers and the admin unit's
  seam below. The headless promise,
  that a consumer can build their own views and their own engine on Geo, is only worth making if
  Mountaya's own are built the same way: a view or an engine that reached a `package` declaration
  for a rule is one a consumer could not have written. The comparison helpers are no rule a view
  or an engine applies: `sameText(_:_:)`, `sameNumber(_:_:)`, `sameNumbers(_:_:)`, `sameJson(_:_:)`
  and `sameGeometry(_:_:)` are how a value of Geo and of the map is `Hashable`, a text by its
  scalars and a number by the same-number relation, and every such value a consumer holds is
  compared by its own `==`, so they are `package`, which `sdk-dart` keeps package-scoped too and
  `sdk-kotlin`'s data classes need none of. The TypeScript SDK publishes its studio binding's `./headless` entry on
  the same principle. So what the navigation engine needs of Geo is published, deliberately and
  small: the machine every engine stands on, `RouteFollowingEngine`, with one initializer over a
  route source and an inline observer of its states, `onChange`, which follows a route on any
  platform with the positions an app hands it; the off-route rule, `offRouteMeters`,
  `isOffRoute(_:)` and `isOffRouteAt(_:lines:)`, which an engine of an app's own reads a position
  by; a followed route's measure, `FollowedRoute.measured`, taken once as the route is followed,
  which the guidance plan reads every length from rather than measure the line again, and the
  position a distance along a followed route read off that measure, `positionAtMeters(_:meters:)`
  over a `FollowedRoute`, the line's own reading to the last digit, which the replay places each
  tick by, as `sdk-kotlin`'s replay does over the same overload; and the
  guidance's rules, `geo.navigation.prompts`, the plan a speaking engine announces a route's
  maneuvers from, `guidancePlanOf(_:)`, with `GuidancePlan`, `GuidanceStep` and `GuidancePrompt`,
  and the prompt due at a reading, `duePrompt(_:progress:)`, with `promptMeters` and
  `promptSlackMeters`, so an engine of an app's own that speaks says each maneuver at the meter
  `DeviceNavigationEngine` says it.
  The machine's ticketed wiring, `init(send:abandon:)` and
  `answered(ticket:with:)`, stays `internal`: it is the scripted engine's, and a ticket is the route
  requests' own bookkeeping, not a consumer's (§8).
- **The admin unit reaches the core's transport through `package` declarations**, the second reach
  across products. `MountayaAdmin`'s methods are printed exactly as the core's are, so they send
  through the seam the core's send through, and what a printed method and a printed type call is
  `package` rather than `internal`: the seam itself, `OperationSending`, with what its requirements
  name, a stream's `StreamedEvent`, `EventStreamRules` and `EventRole`, and the client's `sender` it
  is reached by; the `OperationRequest` and `OperationBody` a method builds, the
  `OperationFacts` it is declared by with its `SuccessResponse` and `Pagination`, and a query's
  `QueryItem`; the coding a printed type reads and writes itself through, `WireKey`, `WireCoded`
  with `CodedTimestamp` and `CodedURI`, the containers' `decodeMerge`, `decodeWired`,
  `decodeWiredIfPresent`, `decodeWiredMerge`, `encodeMerge`, `encodeNullable`, `encodeWired`,
  `encodeWiredIfPresent`, `encodeWiredNullable` and `encodeWiredMerge`, and `Timestamp`; and
  `SystemWallClock`, the platform's clock `constructWebhookEvent` reads where its caller states
  none. None is a rule a view or an engine applies: each is how a printed call reaches the
  transport, which an app reaches through the published
  `send(_:path:query:headers:body:idempotencyKey:ifMatch:options:)` instead, and none is a name a
  consumer reads, since `package` is no wider than `internal` to a package that depends on this
  one. `sdk-kotlin` marks its unit's seam with an opt-in marker an app is refused, and `sdk-dart`
  imports the core's `lib/src/` under an exemption of its own; the contract leaves the seam to each
  SDK and publishes no name of it.
- **The examples stand outside the graph.** Trail, the sample app (§7), is a package of its own
  under `Examples/Trail` that depends on this one by path and links the four products an app links,
  never `MountayaAdmin`, through their public API alone: no `@testable` import, no `@_spi` and no
  `package` declaration, which a package that depends on this one cannot reach. Its session server,
  `Examples/Trail/Session`, is a package of its own beside it, a macOS program that links the admin
  unit as a server does, so an app copied from Trail carries none of it.
- **One version across the repository.** Every product ships at the same tag. One package has one
  version, so there are no internal pins to express, and a consumer resolving two products at
  different versions is a state SPM cannot represent.
- **A floor lives in `Package.swift`, and the README's floors table is its one copy in prose.** The
  README's Install section states the package's floors in one table, the Swift a consumer builds
  with and the oldest release of each platform, since that is where a developer looks for them,
  and BoundaryTests holds each cell to the file that states it, the manifest's tools version and
  its `platforms:` list, and iOS's row to Trail's Xcode project as well, so a floor raised there
  fails the gate until the table follows; anywhere else, prose names the reason for a floor, never
  its number, since a number no gate holds is a second copy the next bump leaves behind. The check,
  `ReadmeFloors` in `Tools/GateSupport` and `readmeFloors()` in the consumer's suite, reads the one
  table `| Floor | Version |` opens under `## Install`, and fails on a row stating another figure,
  on a floor stated on no row or on two, on a row naming no floor the package declares, and on a
  floor's number stated on any other line of the README's prose; GateSupportTests plant each. The
  platforms' floors are the releases Observation arrived in, which Geo's engines are observed
  through, and the Swift floor is the tools version, which the suites run at in a container (§9).
  The developer skill states the same floors, held by its own suite to the manifest (§10).
- **Every product builds and tests on macOS and Linux from the same package**, and every Apple
  platform builds every product. The iOS-only binary dependency, MapLibre's XCFramework, is linked
  under a condition naming iOS and the product's trait, `.when(platforms: [.iOS], traits:
  ["Elements"])`, and every file that imports it sits behind
  `#if Elements && os(iOS) && !targetEnvironment(macCatalyst)`, since `os(iOS)` alone is also true
  for a Catalyst build and the binary ships no Catalyst slice. Only an iOS build with the trait
  compiles what it links. A file that reads one of the platform's own frameworks sits behind the
  platforms that give it what it reads, and behind no trait: the voice behind `#if os(iOS)`, where
  the audio session is the platform's, and the device's position behind
  `#if canImport(CoreLocation) && !os(tvOS)`.
- **A heavy dependency sits behind a package trait, off by default.** SPM resolves every
  dependency a declared product reaches, whichever product a consumer names, and a platform
  condition keeps one out of the build, never out of resolution; a dependency a trait disables is
  left out of resolution too. Declared without one, MapLibre would make a `MountayaClient`-only
  consumer, a Linux server included, clone its repository and download its XCFramework. Behind a
  trait, a consumer who does not turn it on fetches nothing of it, on macOS, on Linux, from a
  manifest and from an Xcode project alike (probed at SwiftPM 6.4.0 and 6.2.3, Xcode 27).
  MapLibre's is the one trait, `Elements`: the navigation engine links no third-party package, so a
  navigation app resolves nothing it does not run and needs no trait, and a navigation app with no
  map resolves no MapLibre. A second package inside this repository is not a way out, since SPM
  consumes a package from a repository's root, and a repository of its own would be a second
  release train.
- **What a trait costs, and how the gate pays it.** A consumer turns it on with
  `.package(..., traits: ["Elements"])`, which a tools 6.1 manifest or newer can write, or in the
  Xcode project's package settings. No product condition exists, so with the trait off the product
  is still declared, and a consumer who forgets the trait meets the type the product's main
  declaration is named after, `MapView`, unavailable, its message naming the trait, rather than a
  name the compiler cannot find. `xcodebuild` cannot turn a root package's trait on, so the tests
  of the code behind it are a package of their own that depends on this one by path with its trait
  on (§6, §9). This package's `Package.resolved` is written with the trait on, so it pins what an
  app with it resolves; a build with the trait off still clones the pinned repositories and
  downloads no binary, and a consumer never reads a dependency's resolution file. It is written by
  `swift package --traits Elements resolve`, never `update`: SwiftPM 6.4 drops the pins a trait
  gates from any file it writes anew, `update` always and `resolve` wherever a change to the
  manifest's dependencies makes it write the file anew, so such a change keeps the pins as they
  were under the manifest's new `originHash`, and a pin moves by raising its floor in the
  manifest, or by leaving it out of the file, and resolving; `Tests/Consumer` and the Renderer
  package then take the root's pins, and the Speech package the root's but MapLibre's, since it
  turns no trait on, and so do the examples (§7): Trail's package and its Xcode project's
  `Package.resolved`, which turn the trait on, the root's, and its session server's the root's but
  MapLibre's. An `originHash` is the SHA-256 of its own package's manifest, byte for byte,
  a comment included, and of nothing else, so a path dependency's manifest moves no dependent's
  hash; a run that finds a hash stale resolves afresh, and a Linux run, whose trait is off, writes
  the file again without the trait-gated pins. So an edit of any of the six manifests, this one,
  `Tests/Consumer`'s, the Speech package's, the Renderer package's, Trail's and its session
  server's, gives its own file the new hash with its pins kept, and BoundaryTests computes each hash
  from its manifest and fails on a stale one, with no network. An Xcode project's file carries the
  hash Xcode reads off the project's package references instead, which no manifest gives: Xcode
  resolves the newest releases where nothing pins them, so Trail's project keeps the root's pins
  under the hash Xcode wrote, and `test:trail` builds with `-onlyUsePackageVersionsFromResolvedFile`.
  A Linux build with the trait on downloads every binary in the graph, so nothing run on Linux turns
  it on.
- **MapLibre resolves at one release in every graph.** The root's `Package.resolved` pins it, at
  the floor of the range §10 takes; the package of the map's renderer tests,
  `Tests/MountayaElementsTests/Renderer/`, which turns `Elements` on, pins the root's pins; and the
  gate builds the guarded code with the trait, warnings as errors, and runs the renderer's tests
  (§9).

## 3. Generated surface

**Source.** `sdk/model.json` from `mountaya/schemas` at the recorded tag: `openapi/api.yaml`,
`openapi/tiles.yaml` and `graphql/data/*.graphqls` restated as one language-neutral document,
built there and compared byte for byte by that repository's own gate. The bundles and the SDL
remain the description. The model is what a generator reads, so the questions every language
would otherwise settle on its own are settled once: which encoding says a value may be null,
what an inline schema is called, which credentials an operation declares, what a query's full
selection is and in which order.

**Generator.** A printer in this repository, run as `swift run GenerateClient` and writing each
unit's surface into its own target, the core's into `Sources/MountayaClient/Generated/` and the
admin unit's into `Sources/MountayaAdmin/Generated/`. It prints final bytes itself, with no
formatter between it and the file, so no formatter release can move the output, and
`swift run GenerateClient --check` fails on drift. It refuses a `modelVersion` it was not written
for and a `kind` it does not know, and never skips one. It decides only what a language decides: the
Swift type for each shape, how a name is cased and escaped, where a file goes. The printer is a
library under `Tools/ClientPrinter` with the executable beside it, held by golden files a miniature
model prints, one of every kind; `mise run generate` and `mise run generate:check` run it, and the
check is part of the gate. It lays its bytes out the way the repository's formatter keeps them, so
`lint:format` reads the printed tree like any other, with no exclusion. One file holds one type,
under a name that carries its namespace (`RestSchema.Itinerary.swift`), since Swift refuses two
files of one name in a module.

**Two units, split by the model's `unit`.** Every operation, template, webhook event and component
of the two OpenAPI surfaces states its unit, `core` or `admin` (`sdk/SPEC.md`, "The three layers,
in every language"), and the printer splits by that key and by no list of its own. The core's
operations, components and inline types print where they always have. A group whose operations are
the admin unit's prints its accessors into `MountayaAdmin`, with its operations' query and body
types and their facts, and so do the components only the admin unit reaches, each inline type the
walk meets from them, and the webhook event. A component of the admin unit lives in `AdminSchema`, a
namespace of the unit's own, rather than in an extension of `RestSchema`: `sdk-kotlin` cannot reopen
an object across modules, so it prints `AdminSchema` too, and `sdk-dart` prints `admin_schema.dart`,
one word across the natives. A type of the admin unit names a core component in `RestSchema` and its
own in `AdminSchema`, and every file it prints imports `MountayaClient`. The core names nothing of
the admin unit's, since it compiles without it, and a component the core's hand-written code names
is kept in the core by the contract's `CORE_SCHEMAS`, never by a list here. The printer refuses an
entry that states no unit or one it does not know, a group whose operations span both units, whose
accessor is printed in one, a Tile API operation, template or component of the admin unit, webhook
events of both units, whose event is printed in one, and a component, an operation or an inline
type of the core that names a component of the admin unit, each by name.

**Frozen, in every language at once:**

- `operationId` is the method name, verbatim, with no rename table.
- `x-sdk-namespace` is `<group>.<resource>`, the groups being `studio`, `admin` and `agent`.
  Tiles and Data are deliberately un-namespaced.
- An operation marked `x-sdk-ignore` is emitted by no client as a method. The model lists those
  routes under `templates`, apart from the operations, so a printer that binds a method to every
  operation cannot bind one: they are what a map renderer fetches on its own, the tiles and the
  base map's style, TileJSON, sprite and glyph documents. The printer emits each as a
  `URLTemplate`, never as a method a caller awaits: a static member of `TileTemplates`, named by
  its `operationId`, holding the path, the path's parameters in the order the path names them, the
  query's and the media types the route answers in, with `TileTemplates.all` listing every one in
  the model's order. `filled(with:)` places a value in a placeholder as one percent-encoded path
  segment and leaves every other as written, a renderer's `{z}`, `{x}` and `{y}` among them. A
  surface whose model lists no template, REST at this tag, prints no namespace for none. A gate
  holds every template to the model.
- Idempotence is read from each operation's `x-idempotent`, never inferred from its method, and a
  gate compares every emitted operation's flag with the model's, which the contract's own gate holds
  to the bundle byte for byte. The same test holds every other fact the transport reads at request
  time: the method, the path, the six credential facts, the attempt budget (`timeoutMs`), whether
  the operation takes an `Idempotency-Key` and an `If-Match`, its pagination, its success statuses
  with the headers each declares, and its declared error statuses, operation by operation, and the
  count, and beside them the tasks a write triggers, which name the `task` its webhook events carry
  and which no request reads. Each unit prints its own table, the core's REST operations as
  `restOperations` and the admin unit's as `adminOperations`, and the test holds each to the
  operations the model gives its unit. A Data API operation's credential facts and its success are
  read from the model as a REST operation's are, every one requiring a session token, acting as
  nobody and answered 200, with no fact of the printer's own for that surface. A declared header is
  a fact the gate reads and nothing decides on: a `Response` reads its headers wherever an answer
  sent them. A generator that dropped one would ship a client that repeats a write after a dropped
  socket, or sends a write with no key, and nothing else would fail. The TypeScript SDK's
  `contract-checkout` test holds the same comparison over the facts.
- A generated file is never hand-edited. A wrong shape is a defect in the description.

**Nullability, under every encoding.** The bundles are OpenAPI 3.1.1 and say a value may be null
the 3.1 way: a type array carrying `'null'`, or a `oneOf` with a `null` branch. The model reads
both, and 3.0's `nullable: true` beside them, and states one flag, which is the one the
generator reads. A generator reading only the 3.0 flag finds no nullable field in these
bundles, and in Swift that is a non-optional property for a value the server legitimately
sends as null, such as the `description` of a collection that has none: `Decodable` throws on
the first real response, at the decode, with a key path and no explanation. The TypeScript
generator reads both encodings for the same reason: reading only the flag types
`Collection.description` and `Zone.start_at` as always present. A property absent from
`required` is optional, and a property with a `default` stays optional, because applying the
default is the server's job and a generated one is a second copy of it.

**Namespaces.** Generated types live in `RestSchema`, `DataSchema` and `TileSchema`, the names
the TypeScript SDK gives the same surfaces, and the admin unit's REST components in `AdminSchema`,
and never at module scope. Many names exist on more
than one surface, not always with one shape, and at module scope REST's `Collection` would
shadow the standard library's protocol and the Data API's `URL` scalar would shadow Foundation's
type, in every file that imports this module. The Data API's namespace is never a bare `Data`,
which would shadow `Foundation.Data` the same way. The contract's `Error` and `Errors`, components
of both REST surfaces, are printed as no type: the model marks them envelopes, which the printer
leaves out and refuses any reference to, and the transport reads as its own `ErrorEnvelope` and
`ErrorEntry`, as `sdk/SPEC.md` §3 has every SDK read an error body through an envelope of its own,
the components keeping the names the bundles give them. So no printed `Error` shadows the standard
library's protocol inside a namespace.

**Three printed types sit at a module's scope: `TileTemplates`**, the core's routes above, which
name no component either; **`APIErrorCode`**, the core's, the one open vocabulary an error's code
is typed by on every surface (`sdk/SPEC.md` §3): the union of the Map Studio API's and the Tile
API's `ErrorExtensionsCode`, which sit inline in each REST surface's error envelope that no type is
printed for, and the Data API's `ErrorCode`, each code once in that order, printed as every open
enum the model declares is, a `RawRepresentable` struct of `String` with a static member per code,
so a code a later release of the API sends is kept as sent and never refused. It stands at the
module's scope because it belongs to no one surface, under the name the registry's `swift` column
gives it, which the Data API's own `DataSchema.ErrorCode` cannot be taken for. The printer refuses a
model whose surfaces state no such vocabulary, and the miniature model's goldens hold its printing;
**and `WebhookEvent`**, the admin unit's, the event each public type of the
REST surface's `webhooks` is delivered as, which no component is. It has one case to a type, named
by the type with its dots and underscores folded to lowerCamelCase (`organizationMemberUpdated`),
carrying a `WebhookEvent.Payload<Object, PreviousAttributes>` that holds every member of the
contract's envelope but its `type`, with a `data` whose `object` is the component the type names
and whose `previous_attributes` is a printed type holding the fields the type names, each optional
and typed as its object types it, or `Never` for a type that names none; and `unknown`, holding the
envelope, `AdminSchema.WebhookEvent`, for an event this build cannot type: a type a later contract
adds, or a payload the case's types do not read, its object then the envelope union's `unknown`
where the envelope's own types do not read it either. Every member of the envelope but `type` and
`data` is an accessor every case answers, read through an internal protocol the payload and the
envelope conform to. The printer refuses an envelope other than `WebhookEvent`, an object or a
field the model does not declare, a set of types that is not the envelope's `type` enum's, and an
envelope an untyped event could not be held in.

**Names are the contract's.** A type, a property, an operation and a union's case are printed as
the contract writes them, and the generated files carry a header saying so. A casing transform is
a rename table in disguise: graphql-codegen's default turns the contract's `POICategory` into
`PoiCategory`, a name the contract never published. One concept spelled differently per surface,
kebab-case on REST and SCREAMING_SNAKE_CASE on the Data API, stays a type per surface, and a geo
rule that accepts both takes an adapter at its edge so the rule itself speaks one vocabulary.

**An enum member is printed under its words**, by the one rule `sdk/SPEC.md` §9 states for every
SDK and `check:surfaces` holds every name to, so the words are the contract's and not a table of
this printer's. Printed whole, a member repeated its type at every use,
`RestSchema.TileLayerType.TileLayerTypeLine`, and a Data API one shouted,
`DataSchema.ActivitySlug.HIKING_AND_TRAIL`. A member's words are its `x-enum-varnames` name with
its type's name taken off the front, split before each capital, or its Data API name split at each
underscore, and Swift writes them in lowerCamelCase, as its API Design Guidelines write every
member: `TileLayerType.line`, `TileSourceType.rasterDem`, `Language.fr`,
`ActivitySlug.hikingAndTrail` on either surface, `TrailDifficultyType.mtb0` for REST's
`TrailDifficultyTypeMtb0` and the Data API's `MTB_0` alike. A first word that starts with a digit
keeps its type's last word in front of it, since no identifier starts with one:
`TileSourceSize.size512`, `UsageStatusClass.class2xx`, `WebhookHealthWindow.window24h`. A word
Swift reserves is escaped in backticks where the member is declared, as any name is, and is written
bare after a dot, where Swift reads a keyword as a member's name: `ManeuverType.continue`,
`IdempotentReplayed.true`, `RoadAccessRestrictionType.private`, `AgentToolErrorCode.internal`,
`WebhookFailureKind.internal` and `InvoiceStatus.open` at this tag, each declared in backticks,
``static let `continue`: Self``. The type keeps its name and the wire value is untouched, so every
decoder reads by value as it did, and the model carries no key for the words: the printer reads
them off the name it already reads. It refuses a name the rule reads no words off, two members of
one enum named alike without regard to case, as the contract compares their words, and a member
named as the type holds a name of its own, `rawValue`, `init`, `self`, `codingKey`, `encode`,
`hash`, `hashValue`, an associated type its conformances infer, or `allCases`, which a consumer
conforming a set to `CaseIterable` gives it, naming each member it is about; none exists at this
tag. A member a type spells `none`, `DataSchema.TollwayType.none`, is compared with an optional
by its type, since there Swift reads a bare `.none` as the optional's own, and warns. A set the
contract writes inline is named the same way where the model gives its members names, its
`enumNames`: a listing's sort, `GetZonesSort`, prints `-updated_at` as `updatedAtDescending`, a
leading `-` reading `Descending` (`sdk/SPEC.md` §9); a set whose members the model names nothing
prints each under its wire spelling, as `ErrorExtensionsCode` does. The sorts took their names at
registry 13, whose model first names them, in place of their wire spellings, `` `-updated_at` ``,
a break.

**One declared type set for the shared scalars.** The Data API's `GeoJSON`, `DateTime` and `URL`
scalars and REST's `GeoJSON*` components map onto one set of types: GeoJSON types declared once
in `MountayaClient`, since RFC 7946 rather than the bundle is their definition, then `Date` and
`URI`. A geometry read from REST and one read from the Data API are one Swift type, which is what
the TypeScript SDK gets by mapping both onto `@types/geojson`.

**Generated types are the vocabulary.** Geo and Elements alias a generated type, never copy it:
`public typealias DirectionsResult = DataSchema.DirectionsResult`, so a consumer names it from
Geo alone. A hand-written structural twin compiles while missing a field the contract added, and
the divergence surfaces as a request the platform rejects rather than as a type error; the
TypeScript SDK's geo layer says there is no structural copy, and there must never be one. A
hand-written type exists only where the wire's vocabulary stops, for what the SDK derives, such
as an elevation series or a navigation state, and never for what it receives.

**Forward compatibility.** An app in the field outlives the tag it was built against: the server
moves to the next tag while a binary on a phone does not. A keyed decode ignores a key it does not
know, so a property the contract adds decodes. A wire enum is an open vocabulary: a
`RawRepresentable` struct over the wire's own type, `Sendable`, `Hashable` and `Codable`, with a
static member per value the contract names, each named by its words (above), Foundation's own
pattern for an extensible set (`Notification.Name`). The wire's type is `String` for every enum but
the tile-size ones, which are integers on the wire and are structs over `Int`. A value this build
has never seen decodes as itself and a new member is additive, where a Swift `enum` fails the whole
response on the first unknown value and turns every member the contract adds into a source break for
a consumer's exhaustive `switch`. A discriminated union follows the same rule by other means: it
carries an `unknown` case holding what arrived, so a member the contract adds decodes in a binary
built before it. A build printed after the contract adds a member holds it as a case of its own, so
every printed union, a body in more than one media type and `WebhookEvent` are `@nonexhaustive`, as
the error ladder is (§4), and a consumer's `switch` over one ends in `@unknown default`. An open
enum is also `ExpressibleByStringLiteral` (`ExpressibleByIntegerLiteral` over `Int`), so a caller
can write a value this build has never seen, and a string one is `CodingKeyRepresentable`, so a map
the contract keys by it is a JSON object. A union's cases are named by their member types, verbatim,
and a member's discriminator is a constant the member writes itself. A union the contract writes
inline with no discriminator is read by trying its members in the contract's order, the first that
reads winning, and holds `unknown` where none does. GeoJSON is the exception that is closed: RFC
7946 fixes the seven geometries, and the Data API refuses any other `type`.

**Coding is written by the generator.** Every generated type carries its own `init(from:)` and
`encode(to:)`, printed with it. A three-state property (below) has to send `null` for
`.some(nil)` and nothing for `nil`, which synthesis does not promise, and every object a request
body reaches is closed in the contract, so a key the bundle does not declare is a 400: the keys
a request writes are printed from the model and from nowhere else. Printing both halves for
every type keeps one rule where an exception list would grow. A key is the contract's name as a
string, so a name that is not a Swift identifier costs nothing, and a timestamp is read and
written through its wire form, the anchored string, and an address a request carries through its
own, the text held to a scheme, so a generated type writes the same bytes under a consumer's
encoder as under the client's.

**Where a method hangs.** `Mountaya` holds an accessor per group, an accessor per resource
beneath it, and the operations as methods: `studio.itineraries.postItineraryDuplicate(...)` for
`x-sdk-namespace: studio.itineraries`. The Tile API's operations hang on `tiles` and the Data
API's on `data`, named by the model's operation name (`data.directions(input:)`). An accessor's
type is its segment capitalised and nested in `Mountaya` (`Mountaya.Studio.Itineraries`,
`Mountaya.Data`), which is the one place `Data` does not shadow Foundation's. The `admin` group's
accessor is the admin unit's: `MountayaAdmin` declares it on the core's client in an extension,
`extension Mountaya { public var admin: Admin }`, with `Mountaya.Admin` and its resources beside
it, and the core's `Mountaya` declares no `admin` of its own, so importing the unit is the whole of
what a call into it asks, `mountaya.admin.sessions.postSession(body:)`. A Data API method
takes `input:`, then `select: FieldSelection? = nil`, then `options:`.

**A name the contract does not give is synthesized once, and never twice.** An operation's query
is the type `<OperationId>Query` and a body it takes in more than one media type is
`<OperationId>Body`, the operation's name with its first letter uppercased, in its surface's
namespace. A synthesized name a component or an inline type already holds is a printer error,
never a silent rename. A body in more than one media type is an enum with a case per type, in
the contract's order: `.json` for `application/json` and `.multipart` for
`multipart/form-data`, the form being a type whose properties become its parts. The model names
the one inline form the bundle writes, `PostItineraryPreviewMultipartBody`, itself. A file's part
carries the media type the form's `encoding` names for its property in the model, as
`postItineraryPreview`'s `file` names `application/octet-stream`, written into the printed form
as a literal rather than assumed by the printer, and none where the model names none, which RFC
7578 reads as `application/octet-stream`. The printer refuses an encoding for a property the form
does not hold and one for a part it writes as text, since it has no way to send a text part as
another media type, so a form the contract grows that way stops the printer rather than sending
its parts mislabelled.

**A call is written from what the operation declares.** Path parameters are labelled arguments,
named verbatim and in the path's own order. The query parameters are one value passed as
`query:`, and the body is one value passed as `body:`. A value a caller builds takes its
required fields as initialiser arguments, in the contract's order, and sets its optional ones
in a trailing closure:
`.init(activity_id: id, is_private: false, name: "Tour du Mont Blanc") { $0.description = "Seven days." }`.
The split follows the contract's own versioning: a required field added to a request is a
breaking change there, so an initialiser moves only when the contract breaks, and an optional
field the contract adds is one more property a closure may set, which changes no call site.

**The headers a call carries are the client's, never an argument.** `sdk/model.json` lists a
caller's own headers under `headerParameters`, and at this tag it lists none: `Accept-Language`
is the client's configured language, `X-Mountaya-Client` names this SDK and its version on every
request (§4), `Last-Event-ID` is what a stream's reopen sends, and `Idempotency-Key` and
`If-Match` ride a call's own arguments. A write whose operation declares `idempotencyKey` takes
`idempotencyKey: String? = nil`, the key a caller passes to make two of its own calls one write,
and otherwise draws one (§4). A write whose operation declares `conditional` takes
`ifMatch: String? = nil`, the `etag` the caller read the resource under or `"*"`, sent as given on
every attempt and never written for a caller who named none (§4). Every method ends with
`options:`, a `RequestOptions(retry:timeout:)`, which carries what §4 lets a call override: the
retry policy, the wait budget among it, and the attempt budget.

**An operation this build prints no method for is called by its declaration.** An app in the
field outlives the tag it was built against, and the contract adds operations in a minor tag, so
`Mountaya` publishes `send(_:path:query:headers:body:idempotencyKey:ifMatch:options:)`, which
takes an `OperationDeclaration` the caller writes from the contract (its surface, method,
`x-idempotent`, the six credential facts as a `CredentialDeclaration`, `x-timeout-ms`, and
whether it declares `Idempotency-Key` and `If-Match`) and returns the envelope with `data` and
`extensions.metadata` read as the types the caller names, and `events(_:path:query:options:)`,
which opens a stream by its declaration and returns its `EventRecord`s. A call reaches an
operation whatever its body: `body` is a `RequestBody`, `.json` holding any value the client's
encoder writes, a printed type or a `JSONValue`, and `.multipart` holding `MultipartPart`s, each a
field's text, with no media type, or a file's bytes with the file name its part states where it is
given one and the media type it is given, `application/octet-stream` where it is given none, a
quote and a line break in a name percent-encoded, written in the order given
(`transport.request.form-parts`); a header's name that is no field name, a token as RFC 9110
writes one, letters, digits and `!#$%&'*+-.^_|~` or a backtick alone, as `sdk-dart` and
`sdk-kotlin` hold one, and a header's value or a part's media type that no header can carry, one
holding a character outside printable ASCII, are refused with `ConfigurationError` before any
request: a loader refuses a name holding a space, a colon or a bracket, or writes `X-Trace: a` as a
header of its own. A Data API operation this build prints no method for is
called by its declaration too, `query(_:input:select:options:)`, which takes a `DataOperation`
written from the contract (its name, its input's type, its field tree and its `x-timeout-ms`) and
returns the operation's own field read as the type the caller names, sent to the endpoint every
Data API operation is, with the session token, the persisted query's digest and the narrowed
document a printed method sends; the printed trees carry each operation's budget, and a test holds
the facts a declaration of each states to its printed method's. A call made this way is
held to every rule a printed method is, and infers nothing the declaration does not state. Its
`headers` are the caller's own and may name none the client writes itself (the credential's,
`Accept-Language`, `X-Mountaya-Client`, `Idempotency-Key`, `If-Match`, `Last-Event-ID`,
`Cookie`), in any letter case, which is refused with `ConfigurationError`; an `Accept` naming
`text/event-stream` is refused as a buffered call (`transport.events.method-refusal`). A stream
the client knows no vocabulary for is read as a feed: no event ends it, it is reopened after every
close on a collaboration feed's schedule, every record's `id:` moves its position, and only
`reconnect` is read for what it says.

**Three states, and the type says so.** A property that is not required and is nullable, on a
schema a request sends, has three states in the contract's model: left out, a value, and `null`.
It is a `T??`: left `nil` it is not sent and the stored value is untouched, a value replaces it,
and `.some(nil)` sends `null` and clears it. That is why assigning `nil` there does not clear:
`nil` is the absence of an instruction. The rule reaches every such property, a value object a
merge body embeds included, and each one's documentation says so where a caller reads it. Every
other optional property is a plain `T?` whose `nil` is left out.

**What a call returns.** A REST or Tile operation returns a `Response` carrying `data` and,
where the operation declares one, `metadata`, which is the envelope's `extensions.metadata`, and
the answer's `status` and the headers its success declares: `requestId` (`X-Request-Id`),
`location` (`Location`, on a 201) and `etag` (`ETag`), each nil where the answer sent none, and
`headers`, every header of the answer, the ones the contract declares and any a server or a proxy
adds, each name in lowercase and read in any letter case through `header(_:)`. A write
returns the resource whose read it changed, a 201 carries the id of the part it created in its
metadata, a 202 carries what it started, and a `data` the contract types as null is a
`JSONValue` holding `.null`, the envelope coming back whole all the same. A resource's `etag` is read from its body, as the
body states it, and never rebuilt from the header. A Data API operation returns its result type,
and an answer that lacks its operation's field is a `DataError`. The export returns a
`BinaryResponse`: its bytes, the content type the server chose, the status and the `X-Request-Id`. An event stream returns an `AsyncSequence` of frames
that applies `sdk/SPEC.md` §12 itself: it reopens, waits and stops on that section's schedule,
resumes from the last record it handed on, and ends on a `done` or on the error §12 says ends
it, because the registry files that loop under the transport. A paged listing is read through
one walk over any operation the model marks with `pagination`, a `PageWalk`, an `AsyncSequence`
of rows that requests a page only as the rows before it are read (§4); the printer has each such
operation's query conform to `PagedQuery`, the one protocol the walk reads and writes the cursor
and the limit through, and prints beside each such method its walk, `walk` before the operation's
name (`walkGetItineraries`), which takes the same path parameters and typed query, a `pageSize`
defaulting to the `default` the operation's `limit` states, `maxPages` and `options`, and answers
the rows as the listing types them through a `PageWalk` over the method; a paged operation whose
`limit` states no default, or whose walk's name another operation of its accessor holds, is a
printer error. Where an operation declares no
`data`, the value is `JSONValue`, the envelope's own type for it, and where it declares no
metadata, `Metadata` is the envelope's open map, `[String: JSONValue]?`. A method is
`async throws` rather than `throws(MountayaError)`: it throws a `MountayaError`, or
`CancellationError` when its task is cancelled (§4), and a typed throw has no room for the
second. An event stream's method is `throws` alone, as a walk is: it awaits nothing, since the
stream opens as its first frame is asked for and not before, and it throws only what it refuses
before any request, a credential the operation does not take or a header no request carries, so
a caller writes `for try await frame in try client.agent.runs.getAgentRunEvents(run_id:)`, the
one `await` the loop's. That is how `sdk-kotlin`'s `Flow` and `sdk-dart`'s `Stream` are cold, and
how a walk already reads.

**Formats.** `format: date-time` is a `Date` (§4) and `format: uri` is a `URI`, as the Data
API's scalars of the same meaning are: a web address kept as the text the wire sent
(`sdk/SPEC.md` §4), the type `sdk-kotlin` and `sdk-dart` call `Url`, a name Foundation holds here.
An answer's address is read as it was written, whatever it holds, one with no scheme, one holding
a letter outside ASCII or a bare percent sign, and one Foundation's `URL` would rewrite, its letter
case, a default port or a dot segment, and none fails the answer it arrives in; `URL` would
rewrite or refuse each, which is why no printed type holds one. A type a request carries writes
its addresses through `CodedURI`, which holds each to the least RFC 3986 calls a URI, a letter,
then letters, digits, `+`, `-` or `.`, a colon and at least one more character, none a line break,
and refuses one with no scheme, `/v1/x` or `www.example.com`, in the encode of the body, a
`ConfigurationError` before any request; a type only an answer carries writes each back as read,
so an answer a caller keeps writes as it arrived. `URI(_:)` builds one from a text or from
Foundation's `URL`, and `url` answers Foundation's reading of the text where it reads one. Every
other string format stays a `String`, identifiers included: the Data API types the same
identifiers as `ID`, so a string is the one type an identifier has on every surface, and
Foundation prints a `UUID` in a spelling the contract does not use. `int64` is an `Int64`, since
`Int` is 32 bits on some watches; every other integer is an `Int` and every number a `Double`.

**A secret is never printed.** A property the model marks `secret` (`sdk/SPEC.md` §1), a session
token, a webhook endpoint's signing secret, a setup intent's client secret and a share link's
token, makes the printed type that holds it `CustomDebugStringConvertible` and
`CustomReflectable`: its `debugDescription`, which `print`, `String(describing:)`, string
interpolation and `dump` all write where a type is not `CustomStringConvertible`, states every
property but the secrets, each `<redacted>`, and its mirror has no children, so a debugger's
variable view shows the redacted text too. The value stays readable at its property. It is the
debug description rather than `description` because a wire member may be named `description`, as
a webhook endpoint's is, and the printer refuses a property named `debugDescription` or
`customMirror` beside a secret. The SDK's own holders of a token print it by its prefix alone, a
`Credential`, a `SessionToken` and a `SessionSnapshot` among them (§4).

**Deprecation.** An operation or field marked `deprecated: true` becomes
`@available(*, deprecated, message:)` carrying the description's first sentence, and stays for as
long as the contract holds it before removal. A deprecated property is stored beneath an internal
`_name`, so the type's own initializer and coding use no deprecated declaration and only a
consumer's use warns.

**`schemaVersion` and `modelDigest` are generated**, each a `public let` in `MountayaClient`
beside the surface it describes, written in lowerCamelCase as every Swift constant is (§5).
`modelDigest` is the lowercase hexadecimal SHA-256 `sdk/SPEC.md` §11 defines, which the printer
takes over the bytes of the five files it reads, as the checkout holds them, `sdk/model.json`,
`sdk/elements/words.json`, `tokens.json`, `glyphs.json` and `NOTICE`, in that order, each framed
by its path and its length. Every printed file's header names it beside the tag, the client's, the
admin unit's and Geo's alike, so a file read on its own says what it was printed from, and
`--check` holds the digest as it holds every other byte it prints: a model or an elements file
that moves fails it until the surface is printed again.

**The elements' data is printed too, into `Sources/MountayaGeo/Generated/`.** The contract holds
three tables no fixture carries beside the model, under `sdk/elements/`: the words the elements
put on screen, their design tokens and the glyph table, with the notice the glyphs' markup
carries. The same printer reads them, a second printer of the library (`ElementsPrinter`), and
writes `WordBundle.elements` and `languageEndonyms` from `words.json`, `ElementTokens` and the
`layout` group's measures, `ElementLayout`, a `package` enum of constants the panels, the readout
and the watermark are laid out by, a count of columns an `Int` and every other measure a length,
from `tokens.json`, `GlyphSet.marker`, `GlyphSet.control` and `GlyphDrawing.artwork`, each
drawing with its opacity, its drop shadow and its shapes' gradients where it states them, from
`glyphs.json`, and `THIRD-PARTY-NOTICES.txt` at the root from `NOTICE`; `--check` holds all of
it. They print into Geo, renderer-free, since the rules that read them are Geo's
(`geo.i18n.bundle-resolution`, `geo.icons.glyph-parse`, and the reading of a token under a
scheme, `geo.style.theme-tokens`), and Geo builds and tests everywhere. The types the data is
made of are written by hand beside those rules, `GlyphSet`, `GlyphDrawing`, `HexColor` and
`ThemeToken`, and only `ElementTokens` is printed whole, since its members are the table's:
each token is a member spelled in camel case, `control-bg` as `controlBg`. A printed file is a
long literal of markup or words no formatter may break without changing it, so each opens with
`// swift-format-ignore-file`, as the README snippets' file does, and every file printing glyph
markup carries the notice's licences in its comments. The printer refuses any member a table
holds that it has no place for, a word that is no string, counted word or section, a colour
that is no `#rrggbb` at an opacity from 0 to 1, a drawing's token naming no colour of the tokens
table, a measure that is no number or a count of columns that is no whole number from 1, a
drawing's opacity outside (0, 1], a shadow with no blur from 0 or no offset, a gradient of fewer
than two stops or of offsets that fall, and a paint stating a gradient beside a colour, a glyph set that could not be drawn (`geo.icons.glyph-set`), and a notice with no ISC and
MIT licence, so a table the contract grows is printed whole or not at all. A bundled set is
printed under the table's name for it, `marker` or `control`, through `GlyphSet`'s internal
initializer, since the printer has held it to the bounds every set is drawn within. Its golden files are miniature tables' (`Tests/ClientPrinterTests/Golden/
elements/`), and `Tests/ConformanceTests/ElementsDataTests.swift` holds every printed word,
endonym, token, glyph and drawing to the checkout's tables.

## 4. Transport behaviour

Everything here is `sdk/SPEC.md` §1 to §6, §12 and §13 resolved to Swift. A rule the contract
states is named by its capability and not restated; what follows is what it means in this
language. Every target compiles in the Swift 6 language mode, so a data race is a compile error
rather than a report. Every network call is an `async` function and there is no
completion-handler API beside it: a second surface is a second thing to keep in step, and it
hands cancellation back to the consumer.

**The client is `Mountaya`.** A type named after its module shadows the module: with a
`MountayaClient` type inside the `MountayaClient` module, a consumer's `MountayaClient.Credential`
names a member of the type instead of the module's `Credential`, in every file that imports it.
SE-0491's module selectors exist to get code out of that trap, which is a reason not to walk into
it. The TypeScript client carries the same name, so one README sentence reads the same in both.

**A client is built from its credential and its seams.**
`Mountaya(credential:language:baseUrls:retry:timeout:onResponse:exchange:clock:random:wallClock:)`
checks the credential's members and the language and refuses a timeout of zero or less with
`ConfigurationError`, so a client set up wrong fails where it is built rather than on its first
call. `exchange` is the `HTTPExchange` every attempt leaves through. `clock` is the standard
library's `Clock`, which every wait, every attempt budget, every stream's silence and the two
minutes an agent run's stream holds its opens answered 503 to are measured on, `ContinuousClock`
where none is given; `random` is a `RandomSource`, which every wait's draw
and every drawn `Idempotency-Key` come from, the platform's where none is given; `wallClock` is a
`WallClock`, the current instant a `Retry-After` date, a spent monthly allowance's renewal and an
event stream's token expiry are read against, the platform's where none is given. `exchange` is
`SystemExchange`, over `URLSession`, where none is given. Each is a seam a consumer's own test
substitutes as this repository's runners do, and `try Mountaya(credential:)` is a whole client.

**Base URLs.** Each surface has its own default origin, and a client overrides each one
independently (`transport.base-urls`). Each is an absolute address: `Mountaya(credential:...)`
refuses one with no scheme as it is built, a path a page would read against its own origin,
`/tiles`, or a host alone, `tiles.example.com`, with `ConfigurationError`, since an address relative
to a page is a browser's alone and an app or a server has no page (`sdk/SPEC.md` §1).

**Language.** A client is configured with its language once, and no method takes one: it rides
every request as `Accept-Language`, an operation that takes no credential included, and every
event stream's open, held to the same header rules as a credential (`transport.credentials`).
A client given none asks for no language in particular: its credential's projection carries
`Accept-Language: *`, which RFC 9110 reads as no language in particular, on every request and
every stream's open (`sdk/SPEC.md` §1, `transport.credentials`), because both platform loaders
write one of their own otherwise, the device's preferred languages on Apple platforms and the
process's locale under FoundationNetworking. `Credential.headers(for:language:method:)` answers it, and
`SystemExchange` writes no language of its own. The language an answer comes back in is then the
client's configuration and never the host's, the same on a phone and on a server, and an app that
wants the user's passes `Locale.preferredLanguages.first`. A map given no label language of its
own takes this one (§8).

**Every request names the SDK that made it.** It carries
`X-Mountaya-Client: mountaya-swift/<version>`, `<version>` being this package's own version and
never the contract tag `schemaVersion` records (`sdk/SPEC.md` §1). The transport writes it on
every attempt it sends, beside the credential's headers and no part of their projection, so an
operation that takes no credential, an event stream's open and its every reopen carry it too, and
`mapRequestHeaders(for:)` answers it beside a map's credential for every request a map makes to
the Tile API (§8). It is the client's, as `Accept-Language` is: no method takes it, and a call made
by its declaration that names it is refused with `ConfigurationError`. The version is written
once, `ClientIdentification.version`, internal to `MountayaClient`, and the release refuses a
version other than the one it states (§10), so the tag and what every request says are one
version.

**Credentials.** One `enum Credential`, a case per shape, so a combination prose cannot prevent
is unrepresentable:

| Case | Sends | Carries | Why this shape |
| --- | --- | --- | --- |
| `.publishable` | `pk_` as `X-API-Key`, and `sess_` as `X-Session-Token` where a session token is given | the key, and optionally a `SessionToken`: `.value`, `.minted`, a session as `postSession` answered it, which names the user it was minted for, `.function`, a synchronous function answering one per request (MapLibre's request hook cannot await, §8), or `.source`, a `SessionTokenSource` such as the engine that keeps one fresh | a session token ACCOMPANIES a publishable key, so it rides here; sent alone it is a 401 |
| `.secret` | `sk_` as `X-API-Key` | the key | minting session tokens, server-side only; unavailable on app platforms, below |
| `.share` | `share_` as `X-Share-Token` | the token, and optionally a `CookieSource`, a synchronous function that answers the visitor's own `Cookie` header for a request's URL | a share token REPLACES a key, so it is a case of its own with nothing beside it: sent both, the server reads the key and ignores the token |

- **No header names a user.** The user an operation acts as is the one its session token was
  minted for, and an `X-User-Id` a client sends is ignored, so none is sent. Each operation's
  generated facts carry its `x-acting-user`, `required`, `optional` or `none`. Where the client is
  told whom its token names, because the token is a minted session or comes from
  `SessionTokenEngine`, whose snapshot reports the `user_id` each token was minted for, an
  operation declaring `required` called under a token minted without `user_id` is refused with
  `ConfigurationError` before any request. A token given as a value or a function does not tell
  the client whom it names, so that request goes out for the server to decide.
- **What an operation declares decides what it refuses, never its method.** A secret key where a
  secret key does not authenticate the operation, a share token where it declares none, reads
  included, and no session token where every requirement names one are each refused with
  `ConfigurationError`; an operation that takes no credential is sent none and refuses none. A
  share token that asks for the visitor's cookies is the one exception on a read: such a read
  rides the visitor's own session alone, with no `X-Share-Token`, as
  `transport.browser.cookie-mode` describes, one of an operation that requires a session token
  included, since the session a visitor's cookie holds is plain to the server alone, and a write
  under it is still refused. A read is an operation declared one, `CredentialDeclaration.isRead`,
  which every printed Data API query declares, its document being a query, and a caller-declared
  Data API operation too, or a request sent with `GET`, `HEAD` or `OPTIONS`, its ASCII letters
  folded, so `get` is a read and `ＧＥＴ` is not; `Credential.headers(for:language:method:)`
  answers by the call's method, `GET` where it names none, and the declaration, one method as
  `sdk-kotlin` and `sdk-dart` have one (`transport.credentials`). A key or a token that
  is empty or whitespace is a missing credential, and a member holding any character outside
  printable ASCII, U+0020 to U+007E, a control character, a letter of Latin-1 such as `é` or one
  past it, is refused on every platform, since the loaders do not carry one alike: Apple's writes a
  Latin-1 character as its one byte and FoundationNetworking's as two UTF-8 bytes a server reads as
  two other characters (`sdk/SPEC.md` §1). Every header the client writes is held to the same rule,
  the language, an `Idempotency-Key`, an `If-Match`, a caller's own header's name and value and the
  visitor's cookie a `CookieSource` answers. `transport.credentials` proves the projection and
  every refusal.
- **The local check is the prefix, never the length.** A wrong prefix on any credential is a
  `ConfigurationError` before a request leaves the process. A length check would be a second copy
  of the server's format, and the day the format widens it refuses a key the server accepts.
- **A credential prints each key and token by its prefix alone** (`Credential.secret(key: sk_…)`),
  through `description`, `debugDescription` and a mirror with no children, so interpolating it,
  `dump` and a debugger all show the same redacted text. An enum's synthesized description prints
  its associated values, and a credential is what a developer logs while setting a client up.
- **A public initializer from the separate parts** (publishable key, session token, share token)
  applies "a share token replaces the key" itself. A caller holding a key from configuration and
  a share token from a link does not write the precedence rule, so no two apps write it
  differently; the fixture's `share-token-wins-over-a-key-beside-it` runs through it. Its
  overload that also takes a secret key carries the same unavailability as `.secret`.
- **The secret key cannot be constructed on an app platform.** `.secret` is
  `@available(..., unavailable)` on iOS, tvOS, watchOS, visionOS and Mac Catalyst, so an app
  target for any of them has no symbol to call: a compile-time barrier, where a runtime check
  would ship the credential and hope. An unavailable case needs no arm in an exhaustive `switch`
  on those platforms, so the barrier costs a consumer nothing. macOS and Linux keep the case,
  because servers run there: the contract's app build is a build for a phone, a tablet, a watch,
  a headset or a TV, or a page a browser loads, and a desktop or server process is none and may
  hold the secret key and verify a delivery (`sdk/SPEC.md` §1), so a macOS desktop app constructs
  one as the contract allows.
- **The secret key is the core's, and the one operation it authenticates is the admin unit's.**
  A credential is the core's whatever it authenticates, since the core reads every one, refuses
  each where it does not authenticate an operation and projects it into headers (`sdk/SPEC.md`
  §1). `postSession`, the one operation a secret key authenticates, is an operation of the `admin`
  group, so a server mints a session token through `MountayaAdmin`,
  `mountaya.admin.sessions.postSession(body:)` on a client built with `.secret(key:)`, and the
  answer it hands its app is the core's `RestSchema.Session`, which `SessionToken.minted` and
  `SessionTokenEngine` read.
- **A request waits for a first session token on its way.** A request made while the source
  holds no token and reports a mint in flight, to an operation a session token can ride on,
  waits for it on the source's subscription, inside its attempt budget and bounded by its task's
  cancellation, which ends it with `CancellationError` and never as a request gone out with no
  token, and is sent with the token once there is one. A source is `SessionTokenSource`, a
  snapshot read synchronously and a `subscribe()` that yields the snapshot now and each change:
  `SessionTokenEngine` is one, and an application with a session machine of its own conforms
  that. Once the engine reports none on its way, the request goes out under
  the key alone, and an operation that requires a session is refused with `ConfigurationError`
  carrying the failed mint's error as its underlying error; a wait the budget ends is a
  `ConnectionError` (`transport.session.first-token`).
- **No cookie rides a key, and none is ambient.** `URLSession`'s default configuration sends
  what `HTTPCookieStorage` holds for the API's host, and a cookie's broader session would outrank
  the key, so `SystemExchange`'s session has no cookie storage, accepts none and sets none, and
  every request turns cookie handling off, which still sends a `Cookie` header the client wrote. A cookie is sent only where `transport.browser.cookie-mode` says a request asks
  for one, under a share token that carries a cookie source, and then the source answers the
  `Cookie` header for that request; nothing is sent where the operation takes no credential. The
  read a share token's cookies ride alone is told from a write by its declaration or its method,
  `GET`, `HEAD` or `OPTIONS` in any letter case, the one place the client reads a method, since
  the contract names reads and writes there. A
  native app holds the visitor's web session wherever it chose to keep it, a web view's store or
  its own, which is why the source is the app's to give rather than a jar the client reads. The
  capability is run, not scoped: its name says browser, and the rule it holds is the same here.
  `sdk-kotlin` resolves it the same way.

**Session engine.** `SessionTokenEngine` in `MountayaClient`. It never mints itself: minting
exchanges a secret key, so the engine takes a `mint` function that calls the application's own
endpoint, which answers what `postSession` answers, a `RestSchema.Session`: the token, its expiry
and the `user_id` it was minted for. It publishes `snapshot`, `subscribe()`, `mint` (settable),
`refresh()`, which mints now, and `disable()` and `enable()`. `SessionTokenEngine(mint:clock:wallClock:)`
takes the two seams its schedule reads, a client's own: `clock`, which every wait toward the next
mint is measured on, and `wallClock`, which the instant a token arrives at and the one its expiry
leaves are read from, each the platform's where none is given, so a consumer's test pins both and
holds the schedule to them.

- **Refresh happens before expiry, never after a 401**, because the request that discovers an
  expiry is the one the user is waiting on, and because an event stream opened with a token ends
  when that token expires (§12): the stream is reopened with the next one.
- **One writer, and a snapshot readable from any thread.** MapLibre asks for a tile's request on
  a thread of its own and cannot await (§8), so the snapshot is a synchronous read. It carries
  the token, its expiry, the user it names, whether a mint is in flight and the last error, as
  one value replaced on every change rather than mutated.
- **Each subscription gets its own `AsyncStream`**, because an `AsyncStream` is built for one
  reader, and two readers sharing one split its elements between them. It yields the snapshot as
  it is when it subscribes, then each change, keeping the newest for a reader that has not read
  the last, so a reader that falls behind reads the newest and never a value it missed
  (`sdk/SPEC.md` §6). Subscribe plus snapshot is the shape `transport.session.observable` proves.
- **The subscriptions are the lifecycle.** Minting runs only while something is subscribed, and
  the last subscription ending parks it: a credential nothing holds is not worth a call to the
  application's endpoint. A `Mountaya` whose credential carries the engine is a subscriber
  itself for as long as it lives, so a headless app that never renders still keeps its session
  fresh.
- **Disabling clears the token, its expiry, its user and the last error**, so a signed-out user's
  credential cannot be read off the snapshot.
- **A failed mint keeps the token it held** and records the failure as the last error, and it is
  minted again as a spent token is, the schedule's floor and each consecutive failure doubling
  the wait up to the margin, so a refresh that fails while the token still lives does not sign
  the user out. A timeout the application set on its own call is a failed mint like any other
  (`sdk/SPEC.md` §6), whatever error it arrives as, the loader's `URLError.timedOut` or one of the
  application's own; how long the engine waits before minting again is its own (§1).
- **A mint the application cancels is never minted again** (`sdk/SPEC.md` §6), as the transport
  never repeats a cancellation: one that throws `CancellationError`, or a `URLError` of code
  `cancelled` its loader reports, ends that run of minting as the last error, with the token, its
  expiry and its user kept and nothing minting, so a request awaiting a first token goes on at
  once and an operation that requires a session is refused with it as the cause; a `refresh()`,
  an `enable()` or the next subscription starts the next mint. The engine's own cancellation, a
  refresh, a disable or the last subscription ending, ends the run and the mint in flight with it,
  the snapshot left to the next run. `transport.session.refresh` proves both endings.
- **Replacing `mint` does not re-mint.** A SwiftUI view builds a new closure on every body
  evaluation, and an engine that re-minted on each one would call the endpoint on every render.
- **The schedule is the contract's** (`transport.session.refresh`). The margin is proportional and
  capped; a delay under the floor is not armed, and each consecutive spent token doubles the wait
  up to the margin; an expiry that does not parse takes the flat margin; the wait is an absolute
  instant walked down in hops that re-read the wall clock, and a hop is not a mint. The clock and
  the wall clock are published seams.
- **The schedule reads the expiry the mint returns.** A token lives at most five minutes, and
  one minted moments earlier for the same key may come back with less of that left, so a
  schedule that assumed a full lifetime would refresh late.
- **Resuming is the hop rule's job.** The Data API needs a token on every request, so an app
  suspended past a token's expiry wakes with a spent one. A timer armed for that deadline
  measures time the process may not have been running; the next hop re-reads the wall clock,
  sees the deadline passed and mints.
- **The transport reads the snapshot on every request**, so a refreshed token reaches the next
  request without rebuilding the client.

**Retries.** `sdk/SPEC.md` §2 exactly, proven by `transport.retry.eligibility`,
`transport.retry.backoff`, `transport.retry.timeout`, `transport.timeout.budget` and
`transport.idempotency.*`.

- **What is repeated.** A 429 always but a ceiling's, coded `LIMIT_REACHED`, which names no wait
  and settles at once whatever the operation declares; a 409 coded `IDEMPOTENCY_KEY_IN_USE` where
  the request carried a key, counted against no attempt; a 502, 503, 504 or a network failure where the
  operation declares itself idempotent, which on REST is its `x-idempotent` and on the Data API
  is every operation, or where the request carried a key. A 412 and a 409 coded
  `IDEMPOTENCY_ANSWER_UNAVAILABLE` are never repeated.
- **One `Idempotency-Key` per write call.** A call to an operation that declares the header
  sends the key its caller passed, or else a version 4 UUID drawn once, before the first attempt,
  in its lowercase canonical form, and the same key on every attempt. The draw is
  `RandomSource.cryptographicUuid()`, whose platform implementation is Foundation's `UUID()`, a
  cryptographic source on every host this package builds on, since `UUID()` is refused outside
  `Seams/` (§7); a source that answers none sends no key. A key passed to an operation that
  declares none is not sent and not read, and a key no header can carry is refused before any
  request.
- **The delay is a uniform draw from zero to a capped exponential**, and a `Retry-After` value,
  read in both of its spellings and ignored where it is neither (`transport.errors.retry-after`),
  replaces it with its whole seconds plus a uniform draw of up to one second: a date's distance is
  rounded up, the seconds the error carries (below), so the wait the transport takes is the one a
  caller reads off the error, and neither asks again before the instant the server named, as
  `sdk-dart`'s parser rounds it. The client honours one wherever it comes from and never waits for
  one that does not come.
- **Every wait of a call comes out of one budget.** A wait is taken only where it fits what the
  waits before it left; one that does not fit is not taken, and the attempt settles with the
  error its status maps to, carrying the seconds the answer named.
- **Each attempt has its own budget**: the call's own where it names one, else the larger of the
  client's and the operation's `timeoutMs` plus five seconds, so a Data API attempt waits 35
  seconds by default. The transport holds it as a deadline of its own, because a
  `URLRequest.timeoutInterval` is an idle interval rather than a deadline. An attempt that spends
  it is a `ConnectionError`, repeated as one.
- **The defaults are the contract's**: two attempts after the first, a 500 ms base, a 30 s
  ceiling, a 60 s wait budget and a 30 s attempt budget. The first four are a `RetryPolicy`, the
  client's `retry` and a call's `RequestOptions.retry`; the attempt budget is the client's
  `timeout` and a call's `RequestOptions.timeout`, since a call that names one is the one case
  that overrides the operation's own.
- **A key in use is asked again at least a second apart.** The wait is the `Retry-After` the 409
  names plus its draw, or the schedule's where it names none, and never under one second, so
  every repeat spends the wait budget that alone ends it.
- **The wait is `Task.sleep`**, which throws the moment its task is cancelled, so a cancellation
  settles during the delay rather than after it, and a task cancelled before the wait never arms
  one (`transport.retry.interruptible`).

**Limits are reported, never counted against.** `RateLimit-Policy` and `RateLimit` are read into
a `RateLimitState`, one `RateLimitPolicy` per String member, in the order the answer lists them,
each with its `name`, `quota`, `window`, what is `remaining` and when it will `reset`, the counts
an `Int64` since a Structured Field integer outgrows 32 bits, and a field that does not parse as
RFC 9651 has a recipient parse one is ignored whole (`transport.ratelimit.parse`). The hook is
`onResponse`, told a `ResponseReport` of every attempt an answer came back to. The state rides every error the API answered and reaches the
`onResponse` hook a client may be given, which is told of every attempt an answer came back to:
the operation, the surface, the status, the attempt, whether the answer was replayed for a key,
the request id and the rate-limit state. The hook is a non-throwing `@Sendable` function, so
nothing it does changes what the call answers. A client delays no request on what the state
says, since an organization's figures are its agreement's and the API is what holds them.

**Errors.** `sdk/SPEC.md` §3's ladder, as one `enum MountayaError: Error`:

| Contract class | Swift |
| --- | --- |
| `ApiError`, and every row that carries a status, `DataError` included | `.api(APIError)`, whose `kind` names the row, `.other` being a status with no class of its own, its `name` the contract's `ApiError` |
| `ConnectionError` | `.connection(ConnectionError)` |
| `ConfigurationError` | `.configuration(ConfigurationError)` |
| `SelectionError` | `.selection(SelectionError)` |
| `WebhookSignatureError` | `.webhookSignature(WebhookSignatureError)`, whose `reason` is the contract's: the core's, though `constructWebhookEvent`, which raises it, is the admin unit's, since a case can carry no type of a target the core does not depend on, and an app catches every failure of the SDK, a delivery's refusal among them, by the one `catch let error as MountayaError` |

- **Catching `.api` catches every error the API answered**, which is the contract's base class:
  it separates a failure of the API from a bug in the calling program. A `DataError` is one, an
  error the API answered under a 200, so it is a kind of `APIError` rather than a case beside it.
- **The kinds are the contract's rows.** Each 4xx has its own, the whole 5xx range has one, a
  402 is one `BillingError` and a 429 one `RateLimitError` whatever their entries carry, and the
  two 409s that answer an `Idempotency-Key` are kinds of their own. A ceiling, the seats, the
  published itineraries or the published zones an arrangement allows, the invitations an
  organization may have waiting or the itineraries a personal space keeps, is the 429 coded
  `LIMIT_REACHED`: its `metadata` names the ceiling with what it allows and what is held, it
  names no wait, so its `retryAfter` is nil, and a caller tells it from a spent window by its
  `code`. A subclass edge of the ladder is a predicate on the kind, so a caller asking whether an
  error is a conflict is answered yes for both idempotency kinds, as a caller catching
  `ConflictError` is in a language with classes.
- **Every kind declares the contract's class name as data** (`"PreconditionFailedError"`), which
  is what a fixture's `expect` names and what the runner compares. A Swift caller
  pattern-matches instead, the cheaper structural discriminator the contract allows, and the two
  predicates the contract asks an SDK to publish, whether a value is an error of the family and
  whether it is one the API answered, read the declared name rather than the type
  (`transport.errors.structural`). The name is declared through a published protocol,
  `NamedError`, its `name`, which `MountayaError` conforms to and a type of another module may
  conform to as well, so a failure rebuilt on the far side of a boundary the client's own types
  did not cross, by a second copy of the SDK or by code that never linked it, is recognised by the
  name it declares as one of the client's own is (`sdk/SPEC.md` §3).
- **The ladder is `@nonexhaustive`**, `MountayaError` and `APIError.Kind` both, so a consumer's
  `switch` ends in `@unknown default`: the contract grows its classes in a minor tag, and a case
  added to an exhaustive enum breaks every `switch` written against it. So are the kinds of `NavigationError` and `MapError`, and every printed union with
  `WebhookEvent` (§3). A client compiled with the Swift the floor names still reads such an enum
  as exhaustive and must list every case beside the default, so a case added breaks its `switch`
  there: the consumer package lists every case, and BoundaryTests builds it at the floor (found
  when `MapError` grew four kinds).
- **What an error carries is the contract's list** (`transport.errors.envelope`,
  `transport.errors.request-id`, `transport.errors.idempotency-key`). An `APIError` carries the
  status, every envelope entry, the classifying code (the first entry's), `extensions.metadata`
  exactly as sent, the whole seconds a `Retry-After` named, the `X-Request-Id` exactly as sent and
  the rate-limit state, each absent where the answer carries none: `APIError`'s `status`,
  `errors`, `code`, `metadata`, `retryAfter`, `requestId`, `rateLimit` and `etag`. The code,
  `ErrorEntry.code` and `APIError.code`, is an `APIErrorCode`, the one open vocabulary of every
  surface the printer prints (§3), so a caller branches on `.limitReached` or
  `.idempotencyKeyInUse` rather than on a string, and a code no surface declares is kept exactly as
  sent. `APIError.hasCode(_:)` answers whether any entry carries a code, the first or another, since
  a refusal may name several at once (`transport.errors.envelope`); `code` stays the first entry's,
  the one the ladder classifies by. `sdk-kotlin` and `sdk-dart` type it the same way, as
  `ApiErrorCode`. A `Retry-After`
  given as a date is carried rounded up to whole seconds, the wait the transport takes before it
  asks again too, so a caller never comes back early. A field path is a list of keys
  and indices, and an index stays an `Int`. A precondition failure carries the resource's tag now,
  an answer that cannot be given again carries that answer's status, `Location` and `ETag` as
  `APIError.unavailableAnswer`, and a key still in use carries the key. Every error a keyed call
  raises carries its key, whatever the error, so the key lives on `MountayaError` itself, as
  `idempotencyKey`, read off the `APIError`, the `ConnectionError` or the `ConfigurationError` it
  holds. It is carried from the moment the key is fixed, before the first attempt, so a refusal
  of the credential on any attempt carries it too.
- **An error's message ends on what a caller can do about it**, where its status names a step,
  and its description is its message: `APIError.message`, `ConnectionError.message` and
  `ConfigurationError.message`, as `sdk-kotlin`'s and `sdk-dart`'s exceptions carry theirs. The
  step is the credential, the member's token or the secret key to check on a 401, where a 402's
  remedies are taken, the scope, the member's role or the key and user a mint names on a 403, the
  write made or the key still running on a 409 that answers a key, a stale tag on a 412, and on a
  429 a ceiling's remedies, the instant a spent monthly allowance renews, or the wait, with what a
  mint is limited by. Each is the first SDK's sentence word for word, so a log reads alike in every
  SDK, and what the call's operation declares sharpens it.
- **The two predicates are `isMountayaError(_:)` and `isAPIError(_:)`**, functions taking any
  `Error?`, each reading the contract's name the value declares, the `name` of any `NamedError`,
  against the family's names and the API's; a value that declares no name of the family is none of
  its errors, whatever status it carries.
- **An underlying `URLError` or `DecodingError` may ride along** for diagnostics, as the error's
  `cause`, never as the type a caller matches on, since matching it would tie a caller
  to how this SDK happens to be built. A success whose body does not decode raises the base
  `APIError`, kind `.other`, carrying the answer's status, its request id and its rate-limit
  state, with the decoder's error beneath it, from one function of the transport, on every
  surface (`sdk/SPEC.md` §3, `transport.errors.ladder`). What §4 reads forward is no such failure:
  a member the contract does not declare, a value of a closed set or a union the build does not
  know, and a web address, which a printed type reads whatever it holds (§3).
- **Cancellation is `CancellationError`**, never wrapped: structured concurrency reads
  cancellation by that type, and a wrapped one reads as a failure. `URLSession` reports a
  cancelled task as `URLError(.cancelled)`, which `SystemExchange` turns into
  `CancellationError`, whether the head or the body was being waited on, rather than letting it
  be read as a dropped connection, because a `ConnectionError` is retried and a retry after the
  caller left is a request nobody is waiting for. The transport reads a `CancellationError` any
  exchange throws before it reads a request that never arrived, so the call ends with it as it
  is, never repeated, whether or not its own task was cancelled; a stream's open and read, and a
  walk's page, end their sequence with it the same way, nothing opened or requested after it, as
  in `sdk-kotlin`.

**Dates.** `sdk/SPEC.md` §4's anchored rule, decided by declared type as the contract decides it:
a property the bundle declares `format: date-time`, and the Data API's `DateTime` scalar, are a
`Date`, and every other string stays a string, nothing inside an object the contract leaves open
included. The anchor is checked before any formatter sees the value: what a formatter accepts is
the platform's decision and can move with an OS release, where the anchor is the contract's.
`transport.dates.reviver` runs against that one parse. A fraction of a second keeps at least its
milliseconds, and the digits a `Date` cannot hold are dropped, never rounded. A declared value
the anchor does not take, a date-only value or the thirtieth of February among them, fails the
decode of the answer it arrived in, raising the base `APIError` a body that does not decode
raises, as the contract asks (`sdk/SPEC.md` §4), and `transport.dates.reviver` answers whether
each such answer decodes. The anchor is published as
`parseTimestamp(_:)`,
so a timestamp the contract carries as text outside a declared property, a waypoint's `date`
field, is read by the same parse (§8). Like `mapRequestHeaders(for:)`, it is published rather than
reached by a `package` declaration across products.

**Field selection.** The field tree is generated beside the operations, in the SDL's order. A
selection is validated against it before the request is built, and a field outside it throws
`SelectionError` at the call rather than failing at the server; an absent selection sends the
generated full document unchanged. Swift cannot compute a result type from a selection, so
`select` narrows the document and not the type (§11): the result type is returned whole, which is
why every field of a Data API result type is optional in Swift, since a field the caller did not
select is absent from the response and a non-optional property would throw at the decode.

A selection is a `FieldSelection`, written the way the contract writes one, `true` selecting a
field whole: `["routes": ["distance": true]]`. One type serves the generated tree and the
caller's narrowing, and `DataOperation` carries an operation's name, input type and tree and
prints its document from them, which a test holds to every document `sdk/model.json` carries.
The narrowed document is printed in the tree's order, whatever order the caller wrote, so two
selections of the same fields send the same bytes and the same digest
(`transport.data.selection`). An object selected with `true`, a value given fields, and a
selection that names nothing are refused with `SelectionError` as a field outside the tree is.

**Persisted queries.** The digest is SHA-256 over the document's exact UTF-8 bytes, hex-encoded
in lowercase, from swift-crypto's `Crypto` module, which is CryptoKit on Apple platforms and
BoringSSL on Linux, so one import serves both hosts the client builds on
(`transport.data.apq-digest`). A digest-only request's refusal is read before the rule that a
200 carrying errors is a failure, and before a failing status makes an answer one, since the Data
API with the extension turned off refuses such a request under 422, or 400 under
`application/graphql-response+json`. A server answering "not implemented" opts the transport out
for its lifetime, an answer carrying both that and a request to register the document reads as
"not implemented", and `GRAPHQL_VALIDATION_FAILED` with the message `no operation provided` reads
so only on a digest-only attempt; a rejected digest is dropped rather than remembered, because
memoising a failure turns one bad moment into a permanent opt-out
(`transport.data.apq-refusal`).

**One walk reads a paged listing.** Every operation the model marks with `pagination` is read
through one generic walk, an `AsyncSequence` of rows that requests a page only as the rows before
it are read. It replaces the `limit` and `cursor` of the caller's `query`, sends the rest of it,
filters and `sort` included, on every request, and resumes from a `cursor` the caller's `query`
holds. It follows a page that holds fewer rows than asked, or none, for as long as a
`next_cursor` names one; it stops at a null `next_cursor`, at a ceiling on requests the caller
states, which raises nothing, or at a cursor it has already sent, which raises the base
`APIError`. A page size outside 1 to 100 or a ceiling under 1 is a `ConfigurationError` before
any request, and a cancelled task requests no further page and ends the sequence with
`CancellationError` (`transport.pagination.walk`), as a page that throws one does. The walk is
`PageWalk(query:pageSize:maxPages:page:)`, which throws its refusal where it is built and is
handed the paged method as a closure: `try PageWalk(query: query) { try await
client.studio.itineraries.getItineraries(query: $0) }`. It needs no client of its own, since a page
is one call like any other. Every paged method this build prints has its walk printed beside it,
which builds that one: `try client.studio.itineraries.walkGetItineraries(query: query)` walks the
listing at the page size the operation's `limit` states, 50 at this tag, its rows typed as the
listing types them (§3). The rows of a page that names a cursor already sent are answered
before the `APIError` is raised, whose status is that page's. A listing this build prints no
method for is walked by its declaration,
`Mountaya.walk(_:path:query:headers:pageSize:maxPages:options:)`, as `sdk-kotlin` and
`sdk-dart` walk one: each page is a `send` of the caller's query, its own
`cursor` first and its `limit` the page size, beside the caller's headers, its rows read as the
caller's `Decodable` type and its next cursor off the envelope's `pagination.next_cursor`, any
other metadata read as none. It is synchronous as a printed walk is, refusing a page size or a
ceiling where it is called, and answers an `AsyncThrowingStream` of rows, the form `sdk-kotlin`'s
`Flow` and `sdk-dart`'s `Stream` take here, which asks for each page only as the rows before it
are read; a reading task that is cancelled requests no further page, and the stream ends as
every `AsyncThrowingStream` ends then, with nothing more, where a `PageWalk` throws
`CancellationError`.

**A conditional write sends the tag its caller names.** `ifMatch:` is sent as `If-Match` exactly
as given, on every attempt of the call, and the client never writes a tag the caller did not
name, whatever tag it has seen. A tag no header can carry is a `ConfigurationError` before any
request. A 412 is a `PreconditionFailedError` carrying the resource's current `ETag`, and it is
never repeated: the caller reads the resource again and decides what the write should be now
(`transport.conditional.if-match`).

**An event stream is a stream, from open to end.** The generated stream methods, and `events`
for a stream this build prints no method for, are the only ways to open one, and the transport
refuses a buffered request whose `Accept` names
`text/event-stream` before its first attempt (`transport.events.method-refusal`). A frame is read
by the Server-Sent Events rules the contract states, a line split into its field and its value on
its bytes, as those rules read it by code point, so a combining mark after the colon or its one
space is the value's own first character, and UTF-8 decoded across reads
(`transport.events.framing`). The open waits one attempt budget, and once the answer has
arrived a stream that delivers nothing for 45 seconds is a `ConnectionError`; the time a
consumer's own loop holds a frame is the consumer's, so the silence clock runs only while the
sequence is waiting on the network (`transport.events.stall`). A failed open is an error of the
ladder, carrying its request id (`transport.events.open-errors`). When a stream ends, when it is
reopened, after how long and from which record are §12's (`transport.events.terminal`,
`transport.events.reconnect`): the sequence applies them itself, waits for a first session token
before a reopen as a request does, sends the position of the last record it handed on as
`Last-Event-ID`, and ends when the consuming task is cancelled, throwing `CancellationError`. A
position no header can carry, an `id:` holding a character outside printable ASCII, ends the stream
with a `ConfigurationError` before it is opened again, as `sdk-dart` and `sdk-kotlin` end theirs:
Apple's loader would send a Latin-1 letter as one byte and Linux's as two, so the server would read
another position, and a loader that refused the header would have a feed, which never stops on its
own, open again forever.

- **A record is read by its stream's own rules.** The record's `event:` name is folded into its
  data as the `type` discriminator before it is decoded, as the generated unions document. A
  record naming an event this build does not know, which decodes as the union's `unknown`, or
  carrying data that does not decode, is passed over: it is handed to nobody and moves no
  position, so a reopen has it sent again. A `reconnect` is read by the reader and handed to
  nobody either, since nothing a consumer does with it changes what follows.
- **Each stream's rules are written by hand beside its generated union**, and a reader reads by
  those of the stream its operation opens, since one union is read by streams of more than one
  kind. An agent run's stream ends on `done` and stops after six reopens in a row without
  progress, every handed-on event moving its position. A collaboration feed's change frames move
  its position and its live frames do not, the roster and lock snapshots its open begins with are
  no progress, and its reader never stops on its own. An itinerary's and a zone's feeds,
  `getItineraryEvents` and `getZoneEvents`, are editor streams, and an organization's,
  `getOrganizationEvents`, is a list stream, as is a stream opened by its declaration. A member the
  contract adds to either union is a compile error there until its part is decided; an operation a
  later contract adds to the collaboration union is read as a list stream until it is named an
  editor stream there.
- **Progress counts the frames an open delivered**, every record that carried data but a
  `reconnect`, passed over or not: more than one on an agent run's stream, and on a collaboration
  feed any past the snapshots each kind of which leads an open once, and on an editor stream any
  but the `presence.join` of the reader's own member, wherever it comes. That member is the user
  the session token names as the open is made, a minted session's `user_id` or a source's
  `userId`, and where the token names none, a token given as a value or a function, the user the
  stream is told it is read as, by `reading(asUser:)` on an `EventStream` of the collaboration
  union. A reader that can name neither counts every `presence.join`.
- **A reopen waits on §12's schedule, or what its open named.** A 429 or a 503 naming its wait in
  `Retry-After` is waited out with a draw of up to a second above it, the draw alone for 0 seconds,
  on either stream, and it still doubles the ceiling. An agent run's open answered 503 neither adds
  to the six nor clears them: those opens are held to two minutes from the first since the last
  progress or `reconnect`, measured on the client's `clock`, an open that failed otherwise in
  between neither restarting that time nor counted toward it, and an open answered 503 two minutes
  or more after that first stops the reader, which throws its `ServerError`. Progress and a
  `reconnect` reset both the count and the two minutes.

**A webhook delivery is verified before it is read** (`transport.webhooks.verify-signature`), by
the admin unit: `import MountayaAdmin` brings
`constructWebhookEvent(rawBody:signatureHeader:secret:tolerance:now:)` and the printed
`WebhookEvent`, and the refusal it throws, `MountayaError.webhookSignature`, is the core's (above),
so a receiver catches it as it catches every failure of the SDK. It takes the body as
`Data` or as a `String`, read as its UTF-8 bytes, the request's `Mountaya-Signature` or nil, the
endpoint's secret, a tolerance, a `Duration`, of 300 seconds unless the caller names another, and
the receiver's clock, the machine's wall clock unless the caller states one, as the contract's
receiver may (`sdk/SPEC.md` §3); it is synchronous, since
nothing it does waits. It is unavailable on iOS, tvOS, watchOS, visionOS and Mac Catalyst, as the
secret key is: a delivery is received by a server, and the endpoint's secret never ships in an app,
so macOS and Linux keep it. A secret not opening with `whsk_`, which the refusal never quotes, a
tolerance below 0, refused as "no number of seconds from 0", the wording `sdk-dart` writes, and a
clock that is no finite instant are `ConfigurationError`s before the header is read. A `Duration`
is always finite, so the refusal of a tolerance that is not a number, which a `Double` could hold,
has no case here. Then the header is read, then the signature, then the time: a header
missing or white space alone, one that is no `t=<seconds>,v1=<signature>`, a signature no `v1`
equals and a `t` further from the clock than the tolerance are each a `WebhookSignatureError` of
its own `reason`. The signature is `HMAC<SHA256>` from swift-crypto, keyed by the secret's UTF-8
bytes and signing `<t as written>.` and the body's bytes, in lowercase hexadecimal, and every `v1`
is compared with it byte for byte reading every byte, so the time taken says neither how much of a
forged signature was right nor which secret of a rotation signed. A body that verifies is decoded
as the printed `WebhookEvent`, its instants `Date`s. An event this build cannot type, of a type a
later contract adds or whose payload its types do not read, is `unknown`, holding the envelope, its
object the union's `unknown` where the envelope's own types do not read it either, so a receiver
still acknowledges it and deduplicates it by its `id`; every member of the envelope is an accessor
every case answers. Only a body that holds no envelope at all is a `ConfigurationError` carrying the
decoder's error, as `sdk/SPEC.md` §3 has it, since no answer and no status stands behind it
(`transport.webhooks.verify-signature`).

**One type reaches the network.** `URLSession` appears in the transport and nowhere else, and the
transport is the seam a test substitutes to run the retry, credential and error fixtures without
a server. The seam is the published `HTTPExchange`: one attempt in, an `ExchangeRequest` whose
every header the client has written, and its `ExchangeResponse` out, the status and the headers
as soon as they arrive and the `ExchangeBody` read a chunk at a time, a buffered answer's
included. The client holds every deadline itself and an exchange decides nothing: it follows no
redirect, keeps no cookie and adds no header that changes what an answer says. The TypeScript SDK
reaches `fetch` from exactly one module for the same reason; §7 holds the rule.

- **`SystemExchange` is the platform's exchange, and it is published.** It sits in
  `Seams/Engines/`, and a consumer wraps it in an exchange of its own to watch or trace every
  attempt, since the client records nothing; `init()` is the whole of its surface. Every value
  shares one `URLSession` per process, so every client shares its connections, and its delegate
  refuses every redirect, so a `3xx` is answered as it arrived and read as the error it is.
- **An attempt prints no header.** An `ExchangeRequest` prints its method and its address alone,
  `ExchangeRequest(GET https://…)`, and an `ExchangeResponse` its status alone,
  `ExchangeResponse(200)`, through `description`, `debugDescription` and a mirror with no
  children, so interpolating one, `dump` and a debugger show the same text, as `sdk-kotlin`'s
  `toString` does. An attempt's headers carry the credential, and an exchange that wraps
  `SystemExchange` to trace every attempt is where one would otherwise reach a log.
- **A header's name is compared with `A` to `Z` folded alone**, `HeaderLookup.asciiLowercase`,
  since RFC 9110 names are ASCII, as Geo's own `asciiLowercase` folds every word a geo rule
  compares, a language subtag or a colour, and as `sdk-kotlin` folds both. Unicode's case mapping
  lowers the Kelvin sign to `k`, so under `lowercased()` a name spelled with it would read as a
  header the client writes. The same fold reads a media type and an `Idempotent-Replayed: true`.
  An answer's headers are folded once, as the answer arrives, into one map of lowercase names,
  `HeaderLookup.folded(_:)`, two spellings of a name joined by a comma and a space in the order of
  the names as a lookup of the set joins them, so each header the transport reads off an answer,
  its request id, its tag, its rate limit, its `Retry-After`, is one lookup rather than a pass over
  every header, and a `Response`'s `headers` are that map: one answer of twenty headers cost 72 µs
  of header work and costs 7 µs (`sdk-kotlin` folds its own the same way).
- **A Data API answer is decoded once.** Its `errors` and its `extensions`, which the entries and
  the metadata are read from, are decoded as JSON values, and the operation's field as its type,
  never the whole body as JSON values first; an answer carrying errors is read for them from that
  same decode rather than decoded again. What the entries say is what a read of the whole body
  says: a 6,000-position directions answer of 321 KiB decoded in 66 ms and decodes in 7.8 ms,
  129 ms and 7.7 ms where it carries errors, in a release build on macOS. The one body read otherwise is
  one the API never sends: a number past a `Double`'s range in a member the operation's type does
  not read, which the decode of the whole body as JSON values refused as undecodable, and which is
  read past now.
- **One name is one header.** A caller's header replaces one of its name the call holds in another
  case, and a body's own `Content-Type` stands over the caller's, as `sdk-dart` and `sdk-kotlin`
  write them: a dictionary keeps `content-type` and `Content-Type` apart, and the platform, which
  reads names without regard to case, would send whichever it met last, which differs from one
  process to the next, in a request an `Idempotency-Key` is compared against among others.
- **The session holds nothing for a request**: no cookie storage, no cache
  (`reloadIgnoringLocalCacheData` and no `URLCache`), no stored HTTP credential, and on Apple
  platforms no wait for connectivity, since a request made offline fails at once and the
  client's own retries decide what follows. Its idle and resource timeouts, and each request's,
  are a week, set out of the way: an attempt's budget, a stream's silence window and a retry's
  wait are the client's deadlines, and the only ones an attempt has.
- **A body is read as the platform delivers it.** FoundationNetworking publishes no
  `bytes(for:)`, so on every host the exchange reads one data task through its session's
  delegate, handing the head over once it arrives and each chunk as it is read, a buffered
  answer's and an event stream's alike. A body nobody holds any longer cancels its task, so a
  stream the reader closes, or a consumer abandons, lets its connection go.
- **The platform writes the request's own headers**, `Host`, `Content-Length`, `Accept-Encoding`,
  whose coding it undoes, and `User-Agent`, and the client writes every other one.
- **An answer names its content type.** Apple's loader holds back the head of an answer that
  names none until it has read enough to guess one, which an event stream that stays open never
  gives it. Every answer the API sends names its type, and the stub the exchange's tests run on
  names one where a script does not.

## 5. The naming law

`sdk/SPEC.md` §9, in Swift.

| Rule | Swift spelling |
| --- | --- |
| `<Subject><Widget>` | the view's last token is what it is on screen, and its subject is the domain entity its properties ACCEPT: `ItineraryProfile`, `ItinerarySegmentTable`. A view whose properties name no entity takes no subject: `MapView`, `MapControls`. |
| One subject, one spelling | an environment value `MountayaElements` publishes leads with the package subject `mountaya`: `\.mountayaClient`. The same subject never appears under two spellings across the products. |
| Noun-symmetric controlled pair | a `Binding<T>` is the pair, and a view taking one takes nothing else for that value. Where the value and its handler are separate, the pair is `x` with `onXChange`, matched on TYPE as well as name: a value may widen by an `Optional` the view never emits, and may not be a different type wearing the same word. |
| Closed handler verbs | `onChange` `onClose` `onError` `onHover` `onSelect` `onTap` `onToggle` `onReady` `onDestroy`, plus compounds built from them (`onQueryChange`, `onTogglePanel`). A synonym of one already in the set is refused. |
| `Engine` for a machine | `SessionTokenEngine`, `SearchEngine`, `NavigationEngine`. A machine is what the layout law files under `Engines` (§6), and a type there never ends in Controller, Manager, Session, Service or Coordinator, which all mean Engine; `Manager` is the one worth saying in Swift, where the platform's own naming invites it. Outside `Engines` the words are the domain's: a value describing an edit in progress may be an edit session. |
| `inert` for a null object | `InertLocationSource`. The other words for it are refused as the first whole word of a type or a top-level value: null, noop, nop, dummy, never, silent and a bare no, so `NullableValue` passes and `NoopClock` does not. `memory` does NOT mean `inert`: an implementation that keeps values for its own lifetime is a memory implementation that forgets, which is a different promise from a seam that does nothing. |
| A type says what it is | it never ends in Helper or Util, singular or plural. |

**`onTap` is this SDK's one substitution.** TypeScript and Kotlin say `onClick`, as the DOM and
Compose do; a touch surface is tapped and SwiftUI names the gesture that way, as Flutter does for
`sdk-dart`, so here `onClick` is refused as `onTap`'s synonym, the mirror of the TypeScript gate
refusing `Tap` as `Click`'s. The contract leaves the idiom to each ecosystem and holds the set
closed in every one.

**An acronym is capitals in a type's name and a word in a member's.** A type spells each acronym
it holds in capitals, as Foundation and the standard library spell theirs: `APIError`, `BaseURLs`,
`URLTemplate`, `HTTPExchange`, `JSONValue`, `GeoJSONPoint`, `POIPanel`, `QueriedFeature.ID`. A
member, a property, a method, a case or an argument label, writes it as a word, `baseUrls`,
`requestId`, `bookingUrl`, `directionsGeoJson(_:)`, so a run of capitals never hides where one word
ends and the next begins: `loadHttpUrl`, never `loadHTTPURL`. `LintNaming` holds both, a type's
word read against the acronyms the SDK's names hold, `Api`, `Url`, `Uri`, `Http`, `Json`, `Poi`,
`Id`, `Uuid`, `Sse`, `Html`, `Svg`, `Xml`, `Sdk` and `Dem`, a plural's `s` included. A member that
names a type spells the type as it is declared, and the gate records it as an exemption with that
sentence: `isAPIError(_:)` asks whether an error is an `APIError`, as `isMountayaError(_:)` asks
whether it is a `MountayaError`. Printed names are the contract's and outside the law (§3).

**A published view never shadows a name its UI framework publishes.** A consumer imports SwiftUI
beside this SDK in every file that uses it, and a shadowed name makes the framework's own type
ambiguous there.

**A published type never shadows Foundation's either, and the other SDKs' name is recorded where
it differs.** A `format: uri` value, a web address kept as the text the wire sent, is `Url` in
`sdk-kotlin` and `sdk-dart`; Swift spells the acronym in capitals, and `URL` is Foundation's
address type, which rewrites and refuses what this one keeps, so here it is `URI`, the format's
own name (§3).

| `sdk-kotlin`, `sdk-dart` | Swift |
| --- | --- |
| `Url` | `URI` |
| `LocationException` | `LocationError` |
| `SpeechException` | `SpeechError` |
| `LocationException.Kind` in `sdk-kotlin`, `LocationExceptionKind` in `sdk-dart` | `LocationError.Kind` |
| `SpeechException.Kind` in `sdk-kotlin`, `SpeechExceptionKind` in `sdk-dart` | `SpeechError.Kind` |

A failure a navigation seam tells is an `Error`, Swift's word for what Kotlin and Dart call an
exception, and a nested `Kind` names which, a value over the kind's name, so its kinds are spelled
as every SDK spells them, `providerDisabled` and `audioRefused`, and the set stays open (§8).

**One concept has one word in the three SDKs.** Where `sdk-dart`, `sdk-kotlin` and this SDK spell
one concept apart and no idiom stands between them, the word two of them write stands, and where
each writes its own, the contract's. So the instance a configuration type is built from where
nothing is stated is `standard`, `BaseURLs.standard` as `RetryPolicy.standard`, `MapPaint.standard`
and `ElementsScope.standard` are, never `default`; the contract tag the client was printed from is
`schemaVersion`, a constant written in lowerCamelCase as every Swift constant is; what an error
carries of the failure beneath it is its `cause`, on `APIError`, `ConfigurationError` and
`ConnectionError` as on `NavigationError`, `LocationError` and `SpeechError`, and a map's failure,
`MapEvent.failure`, carries one too; a camera inside its zoom window is `ZoomWindowEnd.none`, the
contract's own word, written in full wherever it is compared with an optional, which
`Optional.none` would answer otherwise; `PanelControl(_ panel:label:glyph:help:content:)`
names the `MapPanel` it opens `panel`, as the other two do, and what it shows `content`; and what
writes an instant for a reader, its date, its time of day or both, is
`formatDateTime(_:locale:timeZone:dateLength:timeLength:)` over a `DateLength` and a `TimeLength`,
the word of the fixture's `dateTime` kind and of `sdk-typescript`'s `dateTimeFormat`, never a word
for a date alone, which a time of day written alone would belie.

**Kept differences.** Each row is a concept the three SDKs spell apart on purpose, each for the
reason it gives, and none is renamed to match another. The table is the same, row for row and
cell for cell, in `sdk-dart`'s and `sdk-kotlin`'s SPEC.md, so a change to one is made in all three.

| Concept | Dart | Kotlin | Swift | Why kept |
| --- | --- | --- | --- | --- |
| Member casing | lowerCamelCase: `cursorMarkerGlyph`, `searchLimitMax`, `schemaVersion`, `TileLayerType.line` | UpperCamelCase for an enum's and an open vocabulary's members, `MapException.Kind.LayerNotFound`, `LayerRank.Chrome`; SCREAMING_SNAKE_CASE for a top-level `const val`, `CURSOR_MARKER_GLYPH`, `SEARCH_LIMIT_MAX`, `SCHEMA_VERSION`, `MODEL_DIGEST` | lowerCamelCase: `cursorMarkerGlyph`, `searchLimitMax`, `schemaVersion` | each language's casing |
| Acronyms | words: `Url`, `UrlTemplate`, `PoiPanel`, `PoiStyle`, `GeoJsonPoint` | words: `Url`, `UrlTemplate`, `HttpExchange`, `PoiPanel`, `GeoJsonPoint` | capitals in a type, `URI`, `URLTemplate`, `APIError`, `BaseURLs`, `HTTPExchange`, `JSONValue`, `POIPanel`, `POIStyle`, `GeoJSONPoint`, and a word in a member, `baseUrls`, `requestId` | each language's acronym rule, Swift's set by the kind of declaration |
| A tap | `onTap`, `onZoomInTap`, `MapEventTap`, `longTap` | `onClick`, `onZoomInClick`, `MapEvent.Click`, `MapEvent.FeatureClick`, `MapEvent.LongClick`, `ScriptedMapSurface.longClick` | `onTap`, `onZoomInTap`, `MapEvent.tap(_:)`, `longTap` | each platform's word for a finger on a screen |
| A failure's type | `…Exception`: `ApiException`, `MapException` | `…Exception`: `ApiException`, `MapException` | `…Error`: `APIError`, `MapError`, `SearchBranchError` | each language's word for what is thrown, which `sdk/SPEC.md` §3 allows |
| A name the standard library holds | `QueriedFeature.id`, an `Object?` | `QueriedFeature.Id.Text`, since a nested `String` would shadow `kotlin.String` inside `Id` | `QueriedFeature.ID.string(_:)` | read as a reserved word |
| Argument labels | `featuresAt(point)`, `haversineMeters(a, b)` | `featuresAt`, `haversineMeters` | `features(at:)`, `haversineMeters(from:to:)`, `Glyph(_:in:)`, `layerIds(forKey:)` | Swift's labels, which the registry records |
| A constructor that may refuse | `SearchLimit.of`, `SearchPause.of`, `GlyphSet.of` | `SearchLimit.of`, `SearchPause.of`, `GlyphSet.of` | `init?(_:)`, `init?(name:…)`, `init?(chaining:)` | Swift's failable `init?` |
| A second form of a call | a name of its own: `PixelPadding.all`, `ProfilePlace.of`, `MapLayer.fromTile`, `MapSource.fromTile`, `roadAccessKindOfDataApi`, `addDirectionsResult` | overloads | overloads: `init(_:)`, `addDirections(_:fit:)` over an input or a result | Dart has no overloading |
| A position along a followed route | `positionAtMetersRoute(route, meters)`, beside `positionAtMeters(line, meters)` | `positionAtMeters(route, meters)`, overloaded on a `FollowedRoute` | `positionAtMeters(_:meters:)`, overloaded on a `FollowedRoute` | Dart has no overloading, so the second input takes the input's word, `Route` |
| The layers panel's time and pictures, through the stack | `MapControls(offersTime:, thumbnail:)` | `MapControls(…, offersTime, thumbnail)` | `MapControls(_:…offersTime:thumbnail:)` | the three take each as an argument of the stack's own, where `sdk-typescript`'s `MapControls` takes them in its `layersPanel` props bag, React's way of handing a child its props |
| An instant written with neither length named | `formatDateTime(instant, locale, timeZone)` writes the long date, `DateLength.long` | `formatDateTime(instant, locale, timeZone)` writes the long date, `DateLength.Long` | `formatDateTime(_:locale:timeZone:)` writes the long date, `DateLength.long` | every case of `geo.format.locale-services` names a length, so the three keep the default `formatDate` wrote, where `sdk-typescript`'s `dateTimeFormat` handed no style writes ECMA-402's numeric date, `Intl.DateTimeFormat`'s own default |
| The error ladder | a class per row, `ApiException.of`, `IdempotentAnswerUnavailableException.answer`, `MapException.reason` | a class per row, `ApiException.of`, `IdempotentAnswerUnavailableException.answer`, `MapException.reason` | one `APIError` with a `Kind` per row, `APIError.IdempotentAnswer`, `APIError.unavailableAnswer`, `MountayaError.api(_:)`; `MapError.Kind.fixRefused(_:)` carrying its reason | Swift writes one error type for each family |
| A kind | top-level: an exception's `MapExceptionKind`, `LocationExceptionKind` and `SpeechExceptionKind`, and `WebhookSignatureReason`, `ActingUser`, `CameraMotionKind`, `ItineraryStrokeKind`, `SearchLabelKind`, `MapSourceKind` | nested `Kind`, `Reason`, `ActingUser` | nested `Kind`, `Reason`, `ActingUser` | Dart nests no type, so an exception's kind writes its owner before `Kind`, as the natives' words read, and every other keeps its spelling |
| A nested type | top-level, the owner's words and the variant's in one name: `MapEventFailure`, `FunctionSessionToken`, `MultipartFile`, `ItineraryResourceIdle` | nested classes: `MapEvent.Failure`, `SessionToken.Function`, `MultipartPart.File`, `ItineraryResource.Idle` | nested cases: `MapEvent.failure(url:status:cause:)`, `SessionToken.function(_:)`, `MultipartPart.Content.file(_:filename:contentType:)`, `ItineraryResource.idle` | Dart nests no type; `sdk-dart`'s §5 lists every one it writes at the top level |
| A wire spelling's reader | `id` (an enum's that has one, and `MapExceptionKind`'s, which wraps its `name`), `value` (an open vocabulary's, `WebhookSignatureReason`, `LocationExceptionKind` and `SpeechExceptionKind` among them), `name` (`MapPanel`) | `id` (an enum's, `BadgeSurface`, `GeolocationPermission` and `ThemeScheme` among them), `value` (an open vocabulary's), `name` (`MapPanel`) | `rawValue` | Swift's `RawRepresentable` |
| A set of options | `Set<ProfilePart>`, `ProfilePart.standard` | `Set<ProfilePart>`, `ProfilePart.standard` | `ProfileParts`, an `OptionSet`, `.standard` | Swift's `OptionSet` |
| A span spanned again | `ProfileSpan.spanning(from, to)` | `ProfileSpan.spanning(from, to)` | settable `from` and `to` | Swift changes a copy |
| An engine observed | `state` and `subscribe()` | one `StateFlow`, an engine's `state`, the session's `snapshot` and `DeviceLocationSource.standing` | `state` and `subscribe()`, a seam `@Observable` | Kotlin's `StateFlow` is the read and the stream at once |
| A stream read | `listen` | `collect` | `makeAsyncIterator` | each language's |
| A value copied | `copyWith` | `copy`, and a `Builder`: `MapPaint.Builder`, `FieldSelection.Builder` | `var` and a change | each language's |
| A function handed in | a `typedef` | a `fun interface`, `SearchFetch`, `NavigationRouteSource`, `ItinerarySource`, or a function type a `typealias` names, `CookieSource` | a `typealias`: `SessionTokenEngine.Mint`, `CookieSource` | each language's |
| A location source over a stream | `LocationSource.fromStream` | `FlowLocationSource` | `StreamLocationSource` | each platform's stream |
| The HTTP seam | `httpClient:`, package:http's `Client` | `exchange`, `HttpExchange`, and `MapView(okHttpClient)` | `exchange:`, `HTTPExchange`, `SystemExchange` | each ecosystem's client |
| Time and chance | a zone's `Timer`, `random:` | `clock`, `random`, `dispatcher`, `scope`, `timeSource` | `clock:`, `wallClock:`, `sleep:`, `random:` | each SDK's seams |
| Cancellation | `AbortSignal`, `AbortedException`, `RequestOptions.signal` | a coroutine's | a task's | each language's |
| A cause's stack trace | `MountayaException.causeStackTrace` | none, a `Throwable`'s own | none | a Dart exception carries none |
| A client closed | `Mountaya.close()` | `Mountaya.close()` | none, a client freed with its last reference | Swift counts references |
| A JSON value | `Object?` | `JsonElement` | `JSONValue` | each language's |
| A page's metadata | the printed `ListMetadata` | `RestSchema.ListMetadata` | `PageMetadata`, a protocol | Swift's generic constraint |
| A paged query | `PagedQuery`, each printed `Get…Query` | `PagedParameters`, each printed `…Parameters` builder | `PagedQuery`, each printed `Get…Query` | each printer's structure: Kotlin's builds every operation's parameters in one builder |
| A form's parts | `MultipartBody(fields:, files:)`, `MultipartFile` | `List<MultipartPart>` | `[MultipartPart]` | package:http's `MultipartRequest` |
| A JSON error's path | `List<Object>?`, each a `String` or an `int` | `List<ErrorEntry.PathComponent>` | `[ErrorEntry.PathComponent]` | JSON's own key and index |
| A matched range | `HighlightRange` | `IntRange` | `Range<String.Index>` | Dart has no range type |
| A layer's patch | `MapPatch` | a map | `[String: JSONValue?]` | Dart has no undefined |
| An operation called by its declaration | `send(…, pathParameters:, query:, decodeData:, decodeMetadata:)`, its facts on `OperationDeclaration` | `send(operation, path, data: KSerializer, metadata, query: List<Pair>…)`, the printed `OperationTable` | `send(_:path:query:…)` over `Decodable`, the printed `OperationFacts` | each SDK's decoding and printed facts |
| A seam with no class of its own | `Geolocation.fromFunctions` | `object :` | a struct | Dart has no anonymous class |
| The UI framework's binding | `asValueListenable()`, on an `Engine<S>` and on a `NavigationEngine` | none | none | Flutter's `ValueListenable` |
| A scope stated | `MountayaScope(statement:, tokens:, scheme:, child:)`, `MountayaScope.of` | `MountayaScope(statement, scheme, content)`, `LocalMountayaScope`, `LocalMountayaTokens`, `themeSchemeInForce()` | `.mountayaScope(_:)`, `.mountayaTokens(_:)`, `\.mountayaScope` | each framework's accessor |
| A view's children | `child`, `children` | `content` | `content:`, a `@ViewBuilder` | each framework's |
| A view disabled | `enabled:` | `enabled` | `.disabled(_:)` | SwiftUI's modifier |
| A platform's arguments | none | `modifier`, `scope`, `Context` | none | Compose and Android |
| One SDK's arguments | `photoBuilder`, `onLinkTap`, `requestRules` with `MapRequestRule`, `queryFeaturesAt` | `photo`, `transformRequest` with `MapRequest` | `photo:`, `transformRequest` with `MapRequest` | Flutter's idiom |
| A handler's tense | `onChanged`, `onSelected`, `onToggled`, `onCameraChanged`, `onGroupToggled` | `onChange`, `onSelect`, `onToggle`, `onCameraChange`, `onToggleGroup` | `onChange`, `onSelect`, `onToggle`, `onCameraChange`, `onToggleGroup` | `sdk/SPEC.md` §9 holds the set closed and leaves each SDK its tense |
| A value a view and the app share | the value and `onXChanged`: `window`, `picked`, `query`, `isConfined` | a `MutableState`: `window`, `picked`, `query`, `isConfined` | a `Binding`: `window`, `picked`, `query`, `isConfined` | each framework's |
| A map view's plumbing | none | `ComposableSingletons` | `MapView.Coordinator`, `makeUIView(context:)` | each framework's |
| A position refused | `ConfigurationException` | `ConfigurationException` | `PositionError`, which `setPosition(_:)` throws | Swift's typed throw |
| A device source closed | `DeviceLocationSource.close()` | none | none | a Dart stream must end |
| A double's refusal | `ScriptedAnswerError` | `IllegalStateException`, from `check` | `ScriptedAnswerError` | Kotlin's `check` |
| A voice readied ahead of its first sentence | `SpeechNavigationVoice.prepare()`, a `Future<void>` that completes once the platform reports whether the engine started | `SpeechNavigationVoice.prepare()`, a `suspend fun` that returns once the platform reports whether the engine started | `SpeechNavigationVoice.prepare()`, `async`, which returns once the voice of the host's language is found or known to be missing | one name, each language's wait, so the first maneuver is never held while the platform readies its speech, and an app learns before it what its voice holds, `engineUnavailable` among it where an engine can fail to start; `sdk-typescript` ships no voice |
| The reserved word `continue` | `continue_`: `NavigationInstructionKey.continue_`, `ManeuverType.continue_`, as `dart:io` writes `HttpStatus.continue_` | `Continue`: `NavigationInstructionKey.Continue`, `RestSchema.ManeuverType.Continue`, which a member's UpperCamelCase keeps clear of the keyword | `` `continue` ``: `NavigationInstructionKey.continue`, `RestSchema.ManeuverType.continue`, escaped where it is declared and read as `.continue` | each language reserves it and writes the word itself where its grammar lets it; `sdk-typescript` writes the wire's string, `"continue"` |
| Where a large body is decoded | off the caller's isolate above a size the client takes, `decodeOffIsolateAbove`, 256 KiB unless another is passed | off the caller's thread, on the client's `dispatcher`, `Dispatchers.Default` unless another is passed, every body alike, with no option | off the caller's actor, in the transport's own asynchronous work, with no option | a Dart isolate shares no memory, so moving a body costs a copy only a large one repays |
| The secret credential | `SecretCredential(key)`, on the Dart VM alone, and `Credential(…)` from parts takes no secret key | `Credential.Secret(key)`, and `Credential(…, secretKey = …)` from parts, both on the jvm alone | `.secret(key:)`, and `Credential(secretKey:publishableKey:sessionToken:shareToken:)` from parts, unavailable on every app platform | each language's form of a credential's case, refused in an app at compile time where the language can, as `sdk-typescript`'s browser build refuses `{ secretKey }` |
| A previous value stated or absent | the value, and `moved`, the set of the fields the change moved, which tells a null held from a field not moved | `Stated<T>?`: null where the field did not move, a `Stated` holding null where it held null | `T??`: `nil` where the field did not move, `.some(nil)` where it held null | each language's way to tell absent from null; `sdk-typescript` leaves the key out where the field did not move |
| A webhook event's variant | a class per type, `<Type>Event`: `CollectionDeletedEvent`, `OrganizationMemberUpdatedEvent` | a class per type nested in `WebhookEvent`: `WebhookEvent.CollectionDeleted`, `WebhookEvent.OrganizationMemberUpdated` | a case per type of the `WebhookEvent` enum, `.collectionDeleted(_:)`, carrying a `WebhookEvent.Payload` | Dart nests no type, so it writes the type before `Event`; Swift's `switch` reads an enum's cases; `sdk-typescript` narrows one union by its `type` |
| A data element over an engine or an id | named constructors: `ItineraryProfile(cache:, itineraryId:)` and `ItineraryProfile.engine(engine:)`, the same for the two tables | overloads: `ItineraryProfile(itineraryId, cache, …)` and `ItineraryProfile(engine, …)`, the same for the two tables | overloads: `ItineraryProfile(itineraryId:cache:…)` and `ItineraryProfile(engine:…)`, the same for the two tables | Dart has no overloading; `sdk-typescript`'s `<ItineraryProfile itineraryId>` reads through the provider's client alone |
| What a map tells | a method, `MapEngine.events()`, a `Stream<MapEvent>` | a method, `MapEngine.events()`, a `Flow<MapEvent>` | a method, `MapEngine.events()`, an `AsyncStream<MapEvent>` | one name, each language's stream: a method, since each call hands a listener a stream of its own, as `subscribe()` does; `sdk-typescript`'s map tells by MapLibre's `on(type, listener)` |

`sdk-dart` writes each nested type of this SDK as a type of its own, since Dart nests none, with
the natives' words: `CredentialDeclaration.ActingUser` is its `ActingUser`,
`NavigationError.Kind.emptyRoute` its `EmptyRouteNavigationError`, `SearchRowPayload.place` its
`SearchPlacePayload`, and a nested `Kind` its owner's name before `Kind`, `MapExceptionKind`. Its
own §5 records each.

**Refused by name, and what stands instead:**

| Refused | Because | Instead |
| --- | --- | --- |
| `MountayaNavigationView` | a type prefix the module already says; shadows SwiftUI's `NavigationView`; fuses the engine with a screen | `NavigationEngine`, rendered by `MapView` |
| `MountayaElevationProfileView` | a type prefix; `View` is the protocol every view conforms to, not what it is on screen; its input is an itinerary, so that is its subject | `ItineraryProfile` |
| `MountayaRoutePresentation` | a type prefix; a route is data the map draws, not a widget | `MapView`, drawing the route |
| `MountayaNavigationController` | a type prefix; `Controller` means `Engine` | `NavigationEngine` |

**The entity vocabulary** is the set of types `MountayaClient` and `MountayaGeo` publish. A name
claiming a subject outside it fails the gate.

**The law reads every name another file can name**, `internal` as much as `public`, since an
internal name is one modifier away from being published and a contributor reads the same
vocabulary a consumer does. The component, accessor, controlled-pair and handler rules are the
exception: they describe what a consumer is handed and read published declarations only. This is
`sdk/SPEC.md` §9, held the same way by every SDK's gate.

**The law stops at the generated boundary.** Generated names are the contract's (§3) and the gate
does not read them. An enum member among them is the contract's words in lowerCamelCase, the casing
Swift gives every member, so a printed member and a hand-written case read alike where they are
used, `RestSchema.TileLayerType.line` beside `APIError.Kind.preconditionFailed`, and neither
repeats its type's name; the printer, not the gate, refuses a member its words cannot name (§3).

**A published name is contract, and the registry records it as Swift spells it.** Every
`api: true` entry of the registry's transport, geo and map layers states under `published` the
declarations a consumer calls for it once for each SDK (`sdk/SPEC.md` §9), in four columns,
`typescript`, `dart`, `swift` and `kotlin`, each the exact spellings that SDK's own record of its
API prints, or `scoped` where that SDK does not carry the capability. Each SDK keeps its idiom and
the registry writes it down, so a consumer moving between languages finds a name where the
registry says it is. This SDK's column is written as the paths of its API baselines (§7), argument
labels and case included: a method a label completes, `MapEngine.features(at:)`, `pois(at:)` and
`elevation(at:)` among them; the ladder rows Swift models as cases of `APIError.Kind`,
`APIError.Kind.preconditionFailed`, `idempotencyKeyInUse` and `idempotentAnswerUnavailable`; a
member an initializer's label names, `GlyphSet.init(chaining:)`; an acronym as Swift spells it,
`POIStyle`; a type where it is nested, `APIError.IdempotentAnswer`; a top-level function with its
labels, `haversineMeters(from:to:)`. A coverage test holds each name of the column, for every
capability this SDK does not scope, to a declaration of the baselines at exactly that path, and
the column's `scoped` to the scope table of §11 both ways (§9). No idiom stands between a name and
its declaration, so the gate compares two strings and decides nothing: a declaration renamed, or a
label changed, moves its name in the column in `schemas`, and a name Swift cannot carry is raised
there.

**Swift's own guidelines, where Mountaya is stricter:** clarity at the point of use over brevity
(`pointAt(meters:on:)`, not `point(_:_:)`), so an argument after the first takes a label unless
the arguments are interchangeable, a symmetric relation such as `sameNumber(_:_:)`, in every
function a call names, a private helper, a printed one and a test's included, and a closure's
argument too, which a trailing call leaves unwritten, while a function handed only as a value is
read at no call; no type prefixes, since a module namespaces; every
published value type `Sendable`, and every reference type an `actor`, main-actor-bound, or a
`final class` whose `Sendable` the compiler checks, and documented so, since a type that is none
of the three surfaces as a warning in a consumer's strict-concurrency build that they cannot fix;
no force-unwrap, `try!` or `as!` in shipped source, tests included, since each is an assertion
with no message that traps where a value is read rather than where the invariant broke. Two
classes take the third form: `Mountaya`, whose stored properties are constants of `Sendable`
types, and `SessionTokenEngine`, whose state sits behind the platform's lock because its snapshot
is read synchronously from any thread (§4), which an actor cannot offer. One value type is not
`Sendable`, and says so: `EventStream.Iterator`, one task's cursor over one opening of a stream,
which no other task may share, as the standard library's `AsyncStream.Iterator` is not; its
sequence, `EventStream`, is.

**`MountayaError` is the one prefixed type**, and the gate records it as an exemption with its
sentence: a bare `Error` would shadow the standard library's protocol in every file that imports
this SDK.

**The gate** is `swift run LintNaming`, run once at the repository root. An exemption is keyed by
name and valued by the sentence that justifies it, and the gate prints "N checked, M exempt" so a
reviewer sees the exemptions move. It reads the compiler's symbol graph of every shipped target,
and the graphs the compiler writes apart for a target's extensions of another module's types,
`MountayaElements@SwiftUI.symbols.json` holding `mountayaScope` and `mountayaTokens`, an
extension block itself naming no declaration of the SDK's, on the host, and on macOS also the
graph of each built for the iOS simulator with every trait on, the way the API baselines read the
products behind a trait, so a declaration only an iOS build compiles, the map's renderer, its
request hook and its view behind the trait, and the navigation's voice, is held to the law like
any other. A name an Apple framework gives a requirement such a declaration implements,
`makeUIView(context:)`, is an exemption with its sentence, kept apart with the graph that holds
it, so a host that reads no iOS graph holds none of them stale.

## 6. The layout law

One kind of file per directory, the topic being the directory above it:

```
Sources/MountayaGeo/Profile/Rules/
Sources/MountayaGeo/Search/Engines/
Sources/MountayaGeo/Navigation/Contracts/
Sources/MountayaGeo/Navigation/Testing/
Sources/MountayaElements/Profile/Views/
Sources/MountayaElements/Edit/Rules/
```

| Kind | Holds |
| --- | --- |
| `Contracts` | protocols and the value types they exchange |
| `Engines` | machines that hold state across time, and a seam's platform implementation, which reads the platform and decides nothing |
| `Rules` | pure functions that decide something; the default |
| `Views` | SwiftUI views, in `MountayaElements` only |
| `Testing` | published test doubles, such as the scripted `NavigationEngine` |

The kinds are closed. `Rules` is the default for anything that decides something, and `Engines`
is what a rule is not.

**`Seams` is a topic, not a kind**, with kinds beneath it like any other, and it is the only topic
in which the environment is read (§7).

**The generated directories are outside the law.** `Sources/MountayaClient/Generated/`,
`Sources/MountayaAdmin/Generated/` and `Sources/MountayaGeo/Generated/` are laid out by the printer,
and a regeneration would undo any other layout; a target's `Generated/` is the one directory the law
does not read, and the naming law stops there too (§5).

**A rule in `MountayaElements` names a MapLibre, SwiftUI or UIKit type, or belongs to the `map`
layer, or it belongs in Geo.** The elements binding holds no rule the geo layer could hold, and a
rule that names none of them is one `sdk-kotlin` needs too. The one exception is the contract's
own: a rule of the map and editing engines, which a `map.*` capability proves, is the binding's
even where it names no renderer type, because the contract gives it to the engines that drive a
renderer and the renderer-free geo layer has no map to apply it to. It sits under the topic of
the engine it serves, `Edit/Rules/` for the magnet that `map.edit.snap` proves and `Map/Rules/`
for the images a map draws.

Swift has no module system below a target, so visibility does the work: everything is `internal`
unless a consumer needs it, and `public` is the friction that makes an accidental export visible
in review.

**A script-mode file's top level is its body.** A package manifest, `Package.swift`, and a
program's `main.swift` hold no declaration a `///` comment could document: their top level is
statements a run executes, so the header saying what the package or the program is for, and every
comment among its statements, is a line comment inside that body. SwiftPM's
`// swift-tools-version:` line opening every manifest is a machine-read marker, as `// trail: <id>`
is (§7).

**A file is named after its primary declaration**: the type it declares or extends, or the
top-level function it declares, its first letter raised, so `HaversineMeters.swift` holds
`haversineMeters(from:to:)` and the constants that rule states. A rule is a function, and Swift
names a function at the module's top level as the contract's other SDKs name theirs (§8), under
the name the registry publishes where it publishes one (§5). Swift refuses two files of one name
in a target, and a disk that ignores case holds the objects of `PoiPanelRows.swift` and
`POIPanelRows.swift` as one, so a rule whose name, its first letter raised, is another file's of
its target keeps its name and adds the word of its kind to its file's: `ProfileTotalsRule.swift`
holds `profileTotals(_:)`, which answers a `ProfileTotals`, and `profileCharacteristics`,
`profileReadout`, `segmentRowCell`, `waypointRowCell`, `amenityFilter`, `searchListState`,
`layersPanelPress`, `poiPanelRows` and `preferencePress` are filed the same way beside the type
each answers. The gate accepts `<Name>Rule.swift` under `Rules/` alone, holding the function
`<name>`, and only where another file of the target is `<Name>.swift` without regard to case, so
the word never stands where the plain name is free. A rule the registry publishes under a word of
its own keeps it:
`slopeAspectFromNeighbours` answers a `SlopeAspect`, `searchQueryChangeOf` a `SearchQueryChange`
and `wordOverridesOf` reads a value into its answer's type, as `overlayKindOf` does. Navigation's
two such rules are `followedRouteOf`, answering a `FollowedRoute`, and `navigationProgressAt`,
answering a `NavigationProgress`.

The controls' and panels' rules sit in Geo by the topic each serves (family 8d): the locate
control's engine and its target under a topic of its own, `Controls/` (`GeolocateControlEngine`,
`GeolocateControlTarget`, `GeolocateControlState`); the layers selection's engine, its target and
its state, the layers and points-of-interest pickers' models, and the time's rules and their
values (`overlayInstant`, `timestampedSources`, `TimestampedSource`, `timeSliderWindow`,
`TimeSliderWindow`, `timeSliderTicks`, `TimeSliderTick`, `timeSliderRelease`,
`TimeSliderRelease`, `timeSliderReadout`, `TimeSliderReadout`, and the package's `namesInstant`)
under `Layers/`, the three rules named as their answers filed as `TimeSliderWindowRule.swift`,
`TimeSliderReleaseRule.swift` and `TimeSliderReadoutRule.swift`; the preferences picker's under
`Units/`; a nested scope and the counted and filled words under `I18n/`; and a
token's value under a scheme under `Style/`. Each engine stands over a target protocol Geo
declares and `MapEngine` conforms to, as `sdk-typescript`'s engines stand over a structural
target, so Geo names no map and a test's double stands in for one.

The embed's parity fills two topics of Geo's and grows two more. `Organization/` holds what a map
follows of its organization, its watermark alone: the read's standing and the mark under
`Contracts/` (`OrganizationRead`, public, since a host reads where its map's read stands in the five
states the contract names, and `MapWatermark`), and under `Rules/` `watermarkOf`, the frame it
stands in from the map's safe area, `watermarkFrame`, filed with the frame's extent a host keeps its
own interface clear of, the public `watermarkWidth`, `watermarkHeight`, `watermarkInset` and
`watermarkClearance`, a map's safe area read off its window, `mapSafeArea`, and as a rectangle of
the map, `safeAreaBounds`, and what keeps clear of the frame inside the safe area by the smallest
move, `clearOfWatermark`, each rule `package`, since the elements' views read them and no consumer
calls them; and whether the frame is held as the read stands, `isWatermarkKeptClear(_:)`, public,
since a host keeps its own views clear of the mark by it, which every part of the SDK's own
interface reads too. The registry marks `geo.organization.watermark` `api: false`, so the rule's
description of the mark and its type stay each SDK's own: this SDK's `watermarkOf` and
`MapWatermark` are `package`, where `sdk-dart` publishes `organizationWatermark` and `Watermark` and
`sdk-kotlin` `watermarkOf` and `MapWatermark`. All three publish `isWatermarkKeptClear` and the
frame's four extents under one set of names, each SDK's predicate over its own `OrganizationRead`:
this one's `answered(whiteLabel:)` carries the white label, so it takes the read alone, where
`sdk-dart`'s takes the read and the organization's `white_label` beside it. `Readout/` holds a readout's facts, its measure and its rows under `Contracts/`
(`ReadoutFacts`, `ReadoutMeasure`, `ReadoutRow`) and `readoutRows` with its tables, where it
stands, `readoutPlacement`, and how its aspect is written, `formatAspect`, under `Rules/`.
`Controls/` takes a rectangle on a map's screen, `ScreenRect`, where a panel opens beside its
toggle, `PanelPlacement` and `panelPlacement`, filed as `PanelPlacementRule.swift`, and where the
label of the marker tapped last stands, `markerLabelPlacement`, with how far past its pin it
starts, `markerLabelOffset`, and whether it is drawn at all, `isMarkerLabelShown`, each `package`. `Terrain/` takes the terrain read off the elevation
tiles, `ElevationSource`, `ElevationTile`, `ElevationEncoding`, `TerrainReading` and
`AspectCardinal` under `Contracts/` and `decodeElevation`, `elevationTilesAt`,
`terrainFromElevationTiles` and `aspectCardinal`, filed as `AspectCardinalRule.swift`, under
`Rules/`; and `Controls/` a panel's layout, `PanelLayout` and `panelLayout`, filed as
`PanelLayoutRule.swift`. `MountayaElements` holds what a map does of them: `MapReadout` under
`Map/Contracts/`, `OrganizationReads`, the reads every map of the process shares, and
`ElevationReads`, the elevation source and tiles a readout reads, under `Map/Engines/`; the image
decoder's seam, `ElevationImageDecoding`, and the platform's, `PlatformElevationDecoder`, and the
time zone the device keeps, `deviceTimeZone()`, which a readout writes its moments in and a time
slider's thumb reads its moment in, under `Seams/`; and under `Renderer/` the views `MapCanvas`, `MapChrome`, `WatermarkLink`,
`WatermarkDrawing`, `MarkerLabel`, `ReadoutCard` and `PreferenceCard`, and the label shown,
`MarkerCallout`, under `Engines/`.

The search fills three of Geo's kinds under `Search/` (family 8e): its values under `Contracts/`
(`SearchSnapshot`, `SearchSection`, `SearchSectionState`, `SearchBranchError`, `SearchListState`,
`SearchListStatus`, `SearchPick`, `SearchPickCamera`, `SearchHighlight`, `SearchLimit`,
`SearchPause`, `SearchConfiguration` and the `SearchFetch` seam), its rules under `Rules/` (`searchListState`,
`pickTarget`, the three `describe` rules, and the internal `searchFocus`, `searchSectionOf`,
`enabledTargets`, `shownSearchSnapshot` and `unansweredSearchSnapshot`), and the one machine,
`SearchEngine`, under `Engines/`. It takes the Data API handed in, `SearchFetch`, and the camera
stated, so Geo names no client and no map. `searchListState` is filed as
`SearchListStateRule.swift`, its answer being a `SearchListState`, and when a control shows its
list, `isSearchListShown(hasFocus:query:isDismissed:)`, is public beside it, as `sdk-dart`'s Geo
publishes it, so a host drawing its own list over a `SearchEngine` shows it by the same rule.

The data elements' rules fill Geo's `Profile/` topic beside milestone 6's (family 8f): their values
under `Contracts/` (the window and every stretch, `ProfileSpan`, `ProfileRange`, `CurveColor` and
`ProfileClass`; the scale, `ElevationDomain`, `ProfileAnchor`, `DomainRoundingStep`, `PlotPoint`,
`PlotCommand` and `CurveStop`; the places, `ProfilePlace`, `CurvePlacement`, `CurvePin`,
`CurveDivider`, `CurveCutoff`, `AxisLabelBox` and `PlacedSpan`; the strip, the card at the cursor and
the chips, `ResolvedCharacteristics`, `StatStripStat`, `StatStripCursor`, `StatStripCell`,
`ReadoutStat`, `ReadoutCell`, `ProfileReadout`, `SectionChipStat`, `SectionChipCell` and
`AmenityStack`; and the two tables, `ItinerarySegmentRow`, `ItinerarySegmentRowMetrics`,
`ItineraryWaypointRow`, `ItineraryWaypointRowMetrics`, `AltitudeRange`, `SegmentTableColumn`,
`SegmentRowCell`, `WaypointTableColumn`, `WaypointRowCell` and `AmenityFilter`), and their rules
under `Rules/`, each named after the function it declares. A rule named as its answer type is
filed with the word of its kind: `profileReadout`, `segmentRowCell`, `waypointRowCell` and
`amenityFilter` in `ProfileReadoutRule.swift`, `SegmentRowCellRule.swift`,
`WaypointRowCellRule.swift` and `AmenityFilterRule.swift`. A place's card is `Waypoints/`'
(`WaypointCardFacts` and `WaypointField` under `Contracts/`, `waypointCard`,
`waypointPropertyValue` and `waypointPropertyLink` under `Rules/`), the card's model taking
TypeScript's name since the SwiftUI view is `WaypointCard`; an altitude band is `Units/`'
(`formatAltitudeRange`, the internal `rangePatterns` table, and `formatDistanceTick`, a stop of the
distance axis); the order two words sort in is a seam's (`Seams/Engines/`,
`localeCollated(_:before:languageTag:)`), and a field's number is read by the internal
`readNumber` under `Numbers/Rules/`.

`MountayaAdmin` has one topic beside what it prints. `Webhooks/` holds the receiving of a delivery
under `Rules/`, moved from the core with the unit:
`constructWebhookEvent(rawBody:signatureHeader:secret:tolerance:now:)`, the reading of a
`Mountaya-Signature` header, `SignatureHeader`, and the signature every `v1` is compared with,
`WebhookSignature`. The `admin` accessors, the `AdminSchema`
types, their facts and `WebhookEvent` are printed (§3), and the refusal of a delivery,
`WebhookSignatureError`, stays the core's `Errors/Contracts/` (§4). Its tests mirror it under
`Tests/MountayaAdminTests/`, with its printed surface's under `Generated/`, as the core's are.

Navigation fills all four of Geo's kinds: its vocabulary and the `NavigationEngine` protocol under
`Navigation/Contracts/`, the seven rules under `Navigation/Rules/`, the one machine under every
engine, `RouteFollowingEngine`, under `Navigation/Engines/`, and the scripted engine an app's
tests answer, with the request and the error it hands them, under `Navigation/Testing/`.

`MountayaNavigation` has three topics. `Seams/` holds the location source and the voice, their
protocols under `Contracts/` with the values the device's source answers and reads at
(`LocationStanding`, `LocationAuthorization`, `LocationAccuracy`, `LocationRate`) and the failures
the device's source and the system's voice tell (`LocationError`, `SpeechError`), and under
`Engines/` the platform's location source, the replay, the one over an app's own sequence
(`StreamLocationSource`) and the inert ones. `Guidance/` holds the engine an app navigates with, the engine over Geo's machine,
`DeviceNavigationEngine`, under `Engines/`; what it guides by, the plan, its step and its prompt
(`GuidancePlan`, `GuidanceStep`, `GuidancePrompt`), the plan of a route, `guidancePlanOf(_:)`,
and the prompt due at a reading, `duePrompt(_:progress:)`, are Geo's, beside the machine, since
`geo.navigation.prompts` is a capability of the geo layer the conformance suite runs on every
host. `Speech/` holds the voice over the system's speech
synthesizer, `SpeechNavigationVoice`, under `Engines/`, which an iOS build alone compiles, a Mac
Catalyst one among them, since the audio session it takes is theirs (§2). Its tests speak through
that audio session, which runs on iOS alone, so they sit at the mirrored path as a package of
their own, `Tests/MountayaNavigationTests/Speech/`, which the package's test target leaves out and
`mise run test:ios` runs on the iOS simulator (§9). The voice is a topic of its own, where the
location source reading the platform is one of `Seams/`' engines, because a package of its own
cannot sit inside the test target's `Seams/`, and `xcodebuild` cannot run the root package's
tests on the simulator: it builds every test target for it, the gate's tools among them, which
cannot build for iOS.

`MountayaElements` has four topics. `Map/` holds the map's state, its values under `Contracts/`
(`MapState`, `MapLayer`, `MapSource`, `MapMarker`, `MapTap`, `MapError`, the camera's
`CameraTarget`, `CameraMotion`, `CameraFit` and `ZoomLimit`, a query's `QueriedFeature`, the events
a map tells, `MapEvent`, the geometry slots, `GeometrySlot` and `SlotGeometry`, a Data API result's
`AnalysisHandle`, the maps a data element writes its links to, `CursorMarkerTarget` and
`LegEmphasisTarget`, and what its cursor marker is drawn with and where, `CursorMarkerPin` and
`CursorMarkerPoint`, and the internal values of what the map holds, `ContentSlot`, `MapContent`,
`AnalysisKind` and `HeldAnalysis`, and of the images a map draws, `MarkerSprite`, `MarkerImage`,
`StripePattern` and `MarkerPin`, with `MapSurface`, the internal protocol of what draws the map,
and the values the engine reads off it), the `map` layer's rules under `Rules/` (`statedMembers(_:)`,
which `map.engine.patch` proves; `describeMarkerSprite(_:color:in:)`, `readMarkerImageId(_:in:)` and
`roadAccessStripePattern(_:)`, which `map.icons.marker-sprite`, `map.icons.missing-image` and
`map.icons.stripe-pattern` prove; the rules of family 8c, `readCameraTarget(_:)`,
`readCameraFit(_:)`, `zoomWindowAfter(_:min:max:renderer:)`, `controlMoveTarget(_:window:move:)`,
`queryLayerIds(_:placed:isLive:)`, `accessRefusalStatus(_:)`,
`refusesSupersededCredential(_:superseded:)`, `layersManifestAddress(_:)`,
`accessStandingAfter(_:answer:holdsSource:)`, `mapCredits(_:)` and
`relabelledBaseLabels(_:isPlaced:language:)`, which the `map.camera.*`, `map.query.*`,
`map.events.*` and `map.style.*` capabilities prove through the engine; and the rules of family 8b,
`baseMapOf(_:slug:variant:)`, `terrainVariantOfStyle(_:style:)`, `roadAccessLayersOf(_:isShown:)`,
`analysisLayers(_:sourceId:paint:)`, `geometrySlotLayers(_:color:paint:)` and
`describeMarkerPin(color:glyph:in:)`, which the `map.basemap.*`, `map.road-access.*`,
`map.analysis.*`, `map.geometry.*` and `map.marker.*` capabilities prove, with
`readRoadAccessStripeImageId(_:)`, the stripe image the renderer answers; and the rule of family
8e, `searchHighlightLayers(_:accent:hasPointGlyph:)`, which `map.search.result-highlight` proves
through the engine; and the rules of family 8f, `showCursorMarker(on:pinned:point:)`,
`hideCursorMarker(on:pinned:id:)` and `writeLegEmphasis(on:isLit:stretch:color:)`, which
`map.profile.cursor-marker` and `map.profile.emphasis` prove through the engine), the engine, the one
layer registry, the requests each slot holds and a query's abort under `Engines/` (`MapEngine`,
`MapLayerRegistry`, `SlotRequests`, `QueryAbort`), and under `Testing/` the published
double an app's tests drive the engine through with no renderer, `ScriptedMapSurface`. `Edit/` holds
the editing engine's magnet: the projection it measures through, its answer and the waypoint being
placed, `WaypointEdit`, under `Contracts/`, and the rule under `Rules/`
(`snapToActiveSegments(_:segments:projection:thresholdPx:)`, which `map.edit.snap` proves). `Seams/`
reads the device's language and its position: the `Geolocation` protocol and the values it answers
under `Contracts/`, and under `Engines/` the platform's, `DeviceGeolocation`, and `InertGeolocation`.
`Renderer/` is the one directory that knows MapLibre, SwiftUI and UIKit (§7): the views under
`Views/` (`MapView`, `Glyph`, the controls `MapControls`, `ZoomControl`, `CompassControl`,
`GeolocateControl`, `PanelControl`, `DownloadControl` and `DirectionsControl`, the panels
`LayersPanel`, `POIPanel` and `PreferencesPanel`, the search box `SearchControl`, the data
elements `ItineraryProfile`, `ItinerarySegmentTable`, `ItineraryWaypointTable`,
`ItinerarySparkline` and `WaypointCard`, and the internal pieces they stand on, `ControlButton`,
`ControlChip`, `CompassRose`, `PanelSurface`, `LayersPanelTime`, `SearchList`, `SearchResultRow`, `ProfileChart`,
`ProfileDistanceAxis`, `ProfileNavigator` and `TouchTarget`, which pads a smaller look to the
platform's touch target, and the modifiers that place a control stack and its panel,
`StackPlacement`, and the panel of a panel control out of any stack, `AlonePanel`, each holding
what it places by apart from the generic view it modifies), under `Engines/` the renderer
that draws the state on MapLibre's map and is the surface the engine asks, the process's
request hook, `MapLink`, what a data element points at and writes to the map beside it,
`FailureRelay`, what hands each failure a data element's engine shows to its `onError`,
`GlyphFigureCache`, the figures each glyph is read into, kept for every later drawing of it,
`ProfileCurves`, a profile chart's curve and the image of its layer across its renders,
`ProfileCursor`, where a profile's cursor stands, held apart from the profile's root, `PanelPress`,
what a panel's rows press through, `HardwareKeyboard`, whether a keyboard is connected, which the
time's caption reads, `WindowProbe`, where a view stands in its window and the part of the window
the device leaves visible, which a control stack and a panel control read their space's safe area
through, `WindowPlacement` under `Contracts/`, and `RenderProbe`, what a hot path's budget test
counts the renderer's work with (§7), and
under `Contracts/` and `Rules/` what a data element is drawn by (`ProfileColoring`, `ProfileParts`,
the internal `ItineraryDrawing` and `MapTarget`, `plotPath(_:in:)` and
`textWidth(_:style:size:)`) and what draws a glyph, the map's images and its
credits on the platform, and what the views read: a glyph's shapes as SwiftUI paths
(`GlyphFigure`, `glyphFigures(_:in:)`, `shapePath(_:)`, `svgTransform(_:)`), a marker sprite, a
marker's pin and a stripe tile as UIKit images (`markerSpriteImage(_:figures:)`,
`markerPinImage(_:accent:in:)`, `stripePatternImage(_:)`), the sheet the credit button opens
(`creditSheet(_:open:)`), a token as a SwiftUI colour (`tokenColor(_:in:)`), the environment's
scope and tokens (`EnvironmentValues`), the tokens and the scope, each held by one reference the
views read it through (`SharedTokens`, `SharedScope`), a view's own words laid over the scope (`ViewScope`), how a data element
reads its itinerary (`ItineraryReading`), a panel's name (`MapPanel`), a stack's corner
(`MapCorner`) and its places (`ControlSlot`). Its tests load MapLibre, so they sit
at the mirrored path as a package of their own, `Tests/MountayaElementsTests/Renderer/`, which the
package's test target leaves out and `mise run test:ios:elements` runs on the iOS simulator (§9).

**The gate** is `swift run LintFileStructure`, run once at the repository root. It enforces the
directory kinds, an `UpperCamelCase.swift` filename matching its primary declaration, no empty
directory, and a test at the mirrored path under `Tests/`.

## 7. Boundary rules

| Product | Never |
| --- | --- |
| `MountayaClient` | imports SwiftUI, UIKit, MapLibre or Ferrostar; imports `MountayaAdmin`, which depends on it; names a product concept; reaches `URLSession` outside the transport |
| `MountayaAdmin` | imports SwiftUI, UIKit, MapLibre or Ferrostar; imports `MountayaGeo`, `MountayaNavigation` or `MountayaElements`, since it stands on the core alone; reaches the network but through the core's transport; reads the environment outside `Seams/` |
| `MountayaGeo` | reaches the network; names `Mountaya`, the transport or `SessionTokenEngine`; imports SwiftUI, UIKit, MapLibre, Ferrostar or `MountayaAdmin`; reads the environment outside `Seams/` |
| `MountayaNavigation` | reaches the network; names `Mountaya` or anything of the client beyond its wire types, the generated ones and GeoJSON; imports SwiftUI, UIKit, MapLibre, Ferrostar or `MountayaAdmin` |
| `MountayaElements` | imports `MountayaAdmin`, since a map is an app's and links the core alone; calls `URLSession`, but for the one session MapLibre's own requests leave on, which its request hook (`Renderer/Engines/MapRequestHook.swift`) hands MapLibre and hears their redirects through, making no request of its own (§8); imports Ferrostar or `MountayaNavigation`; imports a map engine other than MapLibre; imports MapLibre, SwiftUI or UIKit outside `Renderer/`, MapLibre with no stated access, or MapLibre publicly outside the view (`Renderer/Views/MapView.swift`); adds a map layer anywhere but through the one registry that reads `geo.layers.order`, which the renderer alone draws on MapLibre's map; holds a rule that names no MapLibre or SwiftUI type and that no `map.*` capability proves |

**Source scans, not behaviour assertions.** A rule that holds only where someone remembered it is
a convention. Each suite scans its product's tree, and the product and target lists it walks are
read from `swift package describe --type json`, never kept by hand: a hand-kept list is the one
that misses the product added next.

**The built-artifact walk is the half that cannot be skipped.** `swift package describe --type
json` gives each target's target and product dependencies, and the walk follows each product's
targets through them. The package-level tree cannot serve, since every product shares one
package and so one list of package dependencies. The walk fails on a path to MapLibre from
anything but `MountayaElements`, or to Ferrostar from anything at all. A source
scan passes on a product that reaches a forbidden dependency through a target it merely depends
on, and that is exactly the shape that puts a renderer into a headless consumer's binary.

**Navigation links no library, and the scan and the walk hold it so.** Every product refuses an
import of Ferrostar, `MountayaNavigation` as much as the others, and the built-artifact walk a
path to it from any target: the navigation is Geo's machine with its guidance, Swift in this
repository (§8), so no library beside it decides a step, a prompt or a deviation the contract
decides.

**MapLibre is published by the view alone, and the scan and the public interface hold it so.**
`Renderer/Views/MapView.swift` imports it with `public import`, since `onReady` hands an app
MapLibre's own `MLNMapView`; every other file of `Renderer/` imports it `internal`, and no file
outside `Renderer/` imports it, SwiftUI or UIKit, so the map's state, engines and rules build on
every platform and name no renderer. The scan refuses a bare import of MapLibre, which is public in
the Swift 6 language mode, and a call that adds a layer to MapLibre's map outside the renderer, which
draws the one registry's order. The API dump carries no MapLibre symbol outside `MountayaElements`,
and BoundaryTests holds `MountayaElements`'s listing to name MapLibre on `MapView`'s lines alone.

**The public API has a baseline.** `Tests/BoundaryTests/Baseline/<Module>.txt` is each product's
public API as the compiler's symbol graphs render it, its extensions of another module's types read
from the graphs the compiler writes them to, one line to a declaration, printed whole with its
default values, `async`, `throws`, `where` clause and availability, and one line to the conformances
a type declares under one set of constraints, sorted. A property's setter is printed as its
declaration writes its access: the compiler renders every stored property an `@Observable` class's
macro rewrites `{ get set }`, its setter `private(set)` or not, so the printer reads the declaration
the graph locates and prints `{ get }` for a setter narrower than public, and a setter made public
is a change the listing shows. A BoundaryTests suite prints it from the module the consumer package
built, on macOS, and fails where it differs from the committed listing; `mise run api:update` prints
it again, and the diff is the review: a line removed or changed is a break, which needs the version
bump §10 names. The listing is committed because no release tag exists to diff against, which is
what `swift package diagnose-api-breaking-changes` needs, and it is printed from the symbol graph
rather than from `swift-api-digester`, whose dump of this module is thirteen megabytes of JSON and
records no `async` in its API mode. Once a tag exists, the digester's diagnosis against it runs
beside the listing. `MountayaAdmin` and `MountayaGeo` are listed beside `MountayaClient`, from the
macOS build, where `constructWebhookEvent` is available, the admin unit's `admin` accessor and its
types under `Mountaya` read from the graph the compiler writes its extensions of the client to, and
`MountayaNavigation` and `MountayaElements` are listed from an iOS build, the second with its trait
on, whose public surface exists whole only there: the consumer package built for the iOS simulator,
which compiles the voice over the system's speech and the view over MapLibre from outside.
`mise run api:update`, on macOS, prints all five: it runs
`swift test --disable-xctest --filter PublicAPITests` with `MOUNTAYA_API_BASELINE=write`, the switch
the suite reads. A symbol graph leaves an unavailable declaration out, so the type a consumer
without the trait meets is held by the compiler instead: BoundaryTests type-checks a file naming
`MapView` against the macOS build and against an iOS build with no trait, and holds each diagnostic
to its message.

**Suppressions are counted.** `@unchecked Sendable`, `nonisolated(unsafe)` and `@preconcurrency`
appear only as exemptions the gate counts, each with the sentence naming the synchronisation that
makes it true. A suppression with no sentence is a claim nobody made; the TypeScript SDK's
`no-suppressions` test holds its own the same way.

**An outside-in suite.** The consumer package in `Tests/Consumer` depends on this one by path and
compiles against the public surface only, with no `@testable import`, using each product as an app
would: every credential shape, every seam conformed from outside, one call of every kind, the admin
unit's through `import MountayaAdmin` in the files that call it, and every error read. It fails on
what an inside test cannot see: a public type with an internal initializer, a protocol whose
requirement names an internal type. BoundaryTests builds it on every host the gate runs on, warnings
as errors, in a scratch directory per host and toolchain; its platform floors are held to the root
manifest's, and its resolved versions to the package's own pins, so it builds what the gate tests.
It builds the navigation engine on every host, and turns the `Elements` trait on as an app does,
except on Linux, where nothing of it builds and it would download MapLibre's binary for nothing, and
on macOS BoundaryTests builds it for the iOS simulator too, which compiles the voice, the map view
and the README's navigation and map code. The TypeScript SDK's `tests/consumer` is the same idea.

**Determinism is a boundary too.** `Date()`, `UUID()`, random numbers, `Locale.current`,
`TimeZone.current` and `UserDefaults` are refused outside `Seams/`. A rule that reads the
environment cannot be held to a fixture, and `Locale.current` in a formatter is the specific case
that makes a conformance run pass on one machine and fail on another. `Tools/Simulation`, a
library only test targets link, reads `Date()` in its executor's stall watchdog alone, which
bounds the real time a simulation may wait on work from outside it, as a test may bound real time,
and decides no case's outcome; a conformance runner reads none of the environment (§9).

**Every hot path keeps a budget, and a gate keeps every budget.** A hot path is work that runs per
pointer frame, per camera frame or per fix: a hit-test a hovering pointer pays for, a redraw a scrub
causes, a measurement a fix repeats. Its failure is the one no correctness test sees, the output
staying right while the count of work grows, one reasonable change at a time. The contract lists
the hot paths, `sdk/hot-paths.yaml`, each with the SDKs that budget it and the sentence saying what
its budget holds, and lists this SDK for nine: `route-measure`, `replay-measure`,
`hover-hit-test`, `profile-cursor`, `scrub-root`, `panel-rows`, `zoom-threshold`, `source-pushes`
and `pin-images`. Each has a test beside its subject, titled `hot-path budget <id>:`, that drives
the path through a realistic burst (sixty fixes and a reroute, sixty ticks of a replay along a
route of 2,000 vertices, sixty hover frames of five moves, sixty frames of a scrub, sixty camera
frames, twenty redraws of a panel's host), counts the work, and asserts the
count against a constant its file declares at its top level, the id in lowerCamelCase followed by
`Budget` (`profileCursorBudget`), the number a reviewer argues with, beside an assertion that the
work it budgets still happened, since a count of zero passes over a path the test never reached.
The numbers live beside the tests and never in the contract: a SwiftUI body, a Compose
recomposition and a React render are different units of work.

A count no API shows is read through an internal probe that nothing installs in an app. Geo's
`MeasureProbe` is a task-local value `cumulativeMeters(_:)` records each line it measures to, so
two tests running at once count apart. The renderer's `RenderProbe` is an environment value,
`renderProbe`, each view a budget reads reports the evaluation of its body to, since SwiftUI tells
nobody when it evaluates one, and a property `MapRenderer` reports each source it sends MapLibre
and each reading of its claims to, as the request hook reports each hop to the main actor; it
also holds the curve store of the profile chart drawn last, whose builds and draws a test reads,
and that chart's scrub, which a test plays as a pointer would, since no test drags a finger
across a view. Without a probe a report reads a value that is nil, builds no name and allocates
nothing.

BoundaryTests holds the tests to the list, `Tools/GateSupport/HotPathBudgets.swift` reading the
list from the contract checkout as the conformance suite reads the registry, `../schemas` or
wherever `MOUNTAYA_SCHEMAS_DIR` points, and every Swift file under `Tests/` through the lexer, the
Renderer's and the Speech topic's packages included, so a title in a comment or a constant named
only in prose counts for nothing. It fails on a path listed for Swift with no live budget test, on
a budget test naming a path the list does not hold for Swift, on one handing its constant to no
`#expect` or `#require`, on one whose file declares no such constant at its top level, and on one
switched off: by a `.disabled`, `.enabled(if:)` or `.bug` trait on it or on a suite around it, or by
a `withKnownIssue` in its body, which records its failure as expected. Planted sources in
GateSupportTests prove the scanner finds a budget test and refuses each of those. The gate is a
scan, so it runs on every host, both Linux legs included, though six of the budgets run on the iOS
simulator alone; like the skill's snippets, a missing checkout skips it with a note on a
contributor's machine and fails it in CI.

**Trail is the sample app, and the app the size gate measures.** The contract's `sdk/trail.yaml`
describes the one sample app every native SDK ships: the settings it reads, the steps it does, the
identifiers its journey finds an element by and the journey every SDK's device test walks, with its
demo itinerary, `sdk/trail/itinerary.json`, beside it. This SDK ships it under `Examples/`, outside
the layout law (§6), which walks `Sources/` and `Tests/` alone, and MIT-licensed as
`sdk-typescript`'s examples are, `Examples/LICENSE` a copy of theirs that BoundaryTests holds to
their bytes, so a developer copies it freely; what follows is this SDK's mechanics, and
`trail.yaml` is what the app does.

- `Examples/Trail/Sources/Trail/` is the app, in SwiftUI, over the four products an app links (§2).
  A developer runs it from `Examples/Trail/Trail.xcodeproj`, whose app target reads that folder as
  a synchronized folder and depends on this repository as a local package with the `Elements`
  trait on, `traits = ( Elements, )`, as the README tells an Xcode app to; its Info.plist,
  `Config/Info.plist`, asks for the device's location while the app is in use, loads local
  addresses over plain HTTP so the simulator reaches the session server, and declares no
  `UIBackgroundModes`, the README saying how an app opts in. `Examples/Trail/Package.swift` builds
  the same folder as an executable, `Trail`, which the size gate builds and nothing else does,
  since it builds for iOS alone. Its types are named by their role, `AppModel`, `MapScreen` or
  `NavigationRun`, never with the module's name, which already namespaces them (§5), so they are
  named otherwise than the types of `sdk-dart`'s and `sdk-kotlin`'s Trails, each named by its own
  language's law; its entry point alone, `TrailApp`, keeps the prefix, since its bare name would
  be SwiftUI's `App`.
- Its settings are read once, as it starts, into the one value its root takes, `LaunchSettings`:
  the build writes each into the Info.plist from `Config/Local.xcconfig`, which git ignores, beside
  a committed `Config/Local.xcconfig.example` that `Config/Trail.xcconfig` includes as
  `#include? "Local.xcconfig"`, and an environment variable of the same name stands over it, an
  empty one read as none, so the journey hands in none whatever a developer set, and its replay
  speed, `TRAIL_REPLAY_METERS_PER_SECOND`. Each is read at run time, so the compiler folds no
  setting, and the size gate's build needs none of `trail.yaml`'s `measured` placeholders: it keeps
  every screen a key shows. Its demo itinerary is `Sources/Trail/itinerary.json`, the contract's
  copy byte for byte, which its one `ItineraryResourceCache` answers for its own id.
- Trail keeps its own interface clear of the map's watermark by the extent Geo publishes, as every
  native SDK's Trail does: its search box starts `watermarkClearance` and 8 points below the top of
  the screen's visible part, and its sheet never rises into the frame, its top capped at that
  part's top plus `watermarkClearance` however much it holds, `MapScreen.aboveTheSheet`, the room
  kept over it, so the tables it opens onto scroll inside what is left; the journey's suite holds
  the cap with the sheet opened onto its tables, `trail.sheet`. It keeps no copy of the engine's
  refusal of access: its notice reads `MapState.isAccessRequired`, which the engine sets for a
  catalogue or a source the API refuses and clears once a source it refused loads again.
- Trail writes each cut-off and the arrival by `formatDateTime` in the device's time zone,
  `TimeZone.current`'s name, and where the locale services know no zone of that name it leaves
  them out, as every SDK's readout and Trail do (`CONTRACT-GAPS.md`): the arrival is then no part
  of the progress line, and the profile and the waypoint table are handed no cut-off formatter,
  `AppModel.cutoff` nil, so neither writes a cut-off, never one in UTC, as an ISO string or in a
  form of Foundation's own. The zone iOS keeps is always one they know, so on a device both are
  written.
- `Examples/Trail/Session/` is the session server `mise run trail:session` runs, a macOS program
  over Network.framework that reads both keys from the shell, refusing to start with one sentence
  naming each one missing, and answers `POST /session` on `127.0.0.1:8787` with the `Session`
  `MountayaAdmin`'s `postSession` mints for the publishable key without `user_id`, so the secret key
  never reaches a device; another path answers 404, another method 405, and a failed mint 502 with
  no key and no token. `mise run test:trail:session`, which `mise run ci` runs after the host
  suites, tests it with the client answered through an `HTTPExchange` of the test's own, on the
  loopback address, with no network and no live key. It holds the one `DispatchQueue` written
  outside the products, `trail-session`, serial, since Network.framework tells a listener's states
  and a connection's bytes on a queue it is handed and on nothing else.
- Each step's code is marked `// trail: <id>`, and BoundaryTests' scenario suite,
  `TrailScenarioTests` over `Tools/GateSupport/TrailScenario.swift`, as the hot-path budgets are
  held, reads `trail.yaml` from the contract checkout and fails on a step it lists for Swift that no
  marker under `Examples/Trail` names, the session server's included, on a marker that names no
  step, on a value shaped as a key or a session token in a file under `Examples/` git commits, in
  the shapes `sdk/SPEC.md` gives them, a credential's prefix and 32 lowercase hex characters (its
  §1) and a session token's `sess_`, unpadded base64url JSON, a `.` and a signature, on a copy of
  the demo itinerary that differs by a byte, and on a missing licence. It reads committed files
  alone, as the contract's rule asks: `Config/Local.xcconfig` and what a build writes, `.build/`,
  `.swiftpm/`, `DerivedData/` and `xcuserdata/`, are never read, so a key a developer sets fails
  nothing, and the suite holds `.gitignore` to ignore each. The scan runs on every host, Linux's
  among them; like the hot-path budgets, a missing checkout skips the markers and the copy with a
  note on a contributor's machine and fails them in CI. Planted inputs in GateSupportTests prove the
  scanners find each failure.
- The journey is `Examples/Trail/TrailUITests`, `trail.yaml`'s `journey` with its checks in order:
  no setting, the demo itinerary, Replay at 100 m/s, a waypoint instruction naming one of its
  `waypoints`, and the arrival within 30 s of the press on Start; beside it, the same suite opens
  the sheet onto its tables and holds its top below the watermark's frame. It is an Xcode UI test, which
  reads the app from outside as a person does, so the words it expects come from `Words.swift`,
  which the project compiles into the test bundle beside the demo itinerary. `mise run test:trail`
  runs it with `xcodebuild test`, and `mise run test:device` runs it after the other device suites
  (§9).

**The app's size has a baseline.** Trail, built in release for an iOS device, is the app the gate
measures: an iPhone app that shows a map with its controls and a search box, an itinerary's profile
and tables, and navigates the itinerary aloud, linking the four products such an app links as it
links them, and never `MountayaAdmin`. What each product adds to its executable is compared with a
recorded figure, so a change that makes every app carry more fails the gate rather than a
consumer's store review. The gate is `Tools/SizeGate`, run as `mise run size:check`, which
`mise run ci` runs after `test:device`, on macOS alone, since it builds for a device:
`swift build -c release --package-path Examples/Trail --product Trail --triple arm64-apple-ios`,
at the package's floor, against the iOS SDK, its linker writing a map of the executable,
`-Xlinker -map`, in `.build/trail-ios-release-<major.minor>`, which `mise run clean` frees once
the pin moves. Each run links the app again, so the map it reads is that build's.

The map lists every symbol the executable keeps, its size and the object it came from. Swift Build,
the build system SwiftPM uses by default and the one Xcode links a package into an app with,
prelinks each library target into one object, `<Module>.o`, beside the executable, and
`Tools/GateSupport/AppSize.swift` reads a module's bytes as the sizes of the symbols the map gives
that object (or the objects under `<Module>.build/`, where SwiftPM's native build system leaves
them). A zero-fill section's symbols are left out, since `__bss` and `__common` take memory and no
byte of the app, and so are the symbols the linker stripped. Swift marks every public symbol to
survive the linker's dead stripping unless a module is compiled to internalize its symbols at the
link, which neither SwiftPM nor Xcode asks for, so a product's share is nearly all it compiles to,
whatever the app calls: what an app pays for linking it. An app that calls more of a product moves
its share only by what the linker coalesces into the app's own objects, a literal both hold, and
the table entries the app's references add. The gate holds shares of the executable and never of
the app's bundle: MapLibre is a dynamic framework, shipped whole whatever an app calls and at the
release a consumer's own range chooses, as the system's libraries are, and its stubs in the
executable count in no share.

Each library product the package declares is a share, its targets read from the package description
and never from a list kept here. `MountayaAdmin`'s is recorded as 0, since an app that draws a map
and navigates links the core alone (§1): a share that grows from it is Trail starting to carry the
admin unit, 1.35 MiB, which the split took out of every such app. Beside them stands each module of
another package the build links, which the SDK brings into an app: swift-crypto's `Crypto`, on iOS a
thin layer over the system's CryptoKit. Each is recorded with the package that holds it, read from
the description of each package `swift package show-dependencies` names, and the version Trail's
`Package.resolved` pins it at. A module the SDK starts to bring is a share the baseline does not
record, and fails until it is recorded, and one brought at another version is reported and not
compared. `Tests/BoundaryTests/Size/ios.json` records each share with every byte the executable
links, the app's own and the linker's included, which is reported and never compared, the Xcode and
the Swift the build was made with, and the scenario it was made to, `trail.yaml`'s `version`, read
from the contract checkout; `MOUNTAYA_SIZE_BASELINE=write mise run size:check` records them after a
deliberate change, and a missing baseline fails.

A share that grows past 2% of its baseline or 16 KiB, whichever is larger, fails, the rule
`sdk-dart` and `sdk-kotlin` hold their shares to. One toolchain links one executable from one tree,
the map byte for byte, so the tolerance absorbs no noise: it absorbs the growth of a change that
adds what an app calls, so that such a change does not record the baseline each time, while what the
gate exists for is larger, a dependency or a table of data every app would carry. The floor holds a
share that is small at its baseline, where 2% of it is a few bytes. A share that shrinks past the
tolerance is told and not failed, since a smaller app is no defect, and a product the build no
longer links is held as 0. A baseline measured to another scenario, or to none, is reported and not
compared, since a scenario that moves moves what the app does, and so is one recorded with another
Xcode or Swift: a module's bytes are the compiler's as much as the SDK's, so one toolchain's figures
are no baseline for another's, and the change that moves the pin records the baseline again. Each
share is told on a line of its own, `name: bytes, ±change (±%), within tolerance` or
`past tolerance`, then the products together, which are reported and not compared, then the whole
executable, which is never compared: the report `sdk-dart`'s and `sdk-kotlin`'s gates print. Since
each SDK measures its own kind of bytes, Dart's snapshot, R8's dex and Swift's linked code, the
three are compared step by step of the scenario and never as totals. GateSupportTests hold the reader
and the rule to an excerpt of a real map: both layouts, the zero-fill sections, the stripped
symbols, and every way a share passes, grows, shrinks, moves its version or goes unrecorded.

**What keeps `MountayaClient`'s share is the printed surface, whatever of it an app calls.** The
compiler marks every public declaration of a module as one the linker may not strip, `[no dead
strip]` in the object's symbol table, so every method, accessor and witness a product publishes is
linked into an app, and Swift's runtime records of each type and each conformance, which a dynamic
cast reads, keep each printed type's `Codable` and `Hashable` witnesses, its value witnesses and its
metadata linked even where that mark is lifted. In the linker map of Trail as it calls the client,
the printed namespaces hold 1.34 MB of the client's 2.05 MB of code, `RestSchema` 849 KB,
`DataSchema` 392 KB and `TileSchema` 98 KB. Two settings of an app's own build cut it, and neither
is the package's to set: `-Xfrontend -internalize-at-link`, which lifts the mark, takes the share
from 2,579,207 bytes to 2,207,616, and building for size, `-Osize`, to 1,845,638, Geo's from
1,276,773 to 1,020,074 and the elements' from 1,662,035 to 1,340,585. A package passes a compiler
flag only as `unsafeFlags`, which SwiftPM refuses in a package resolved by version, so the gate
measures the build an app makes by default. `sdk-dart`'s and `sdk-kotlin`'s shares are a fraction of
this one because their compilers drop a type an app never reaches with its serializer, which
Swift's runtime records keep; the printed types keep every conformance they publish, so no printer
change that holds the API cuts the rest. Marking the printed surface `@_optimize(size)`, an
underscored attribute no release of Swift promises to keep, was weighed and not taken: on
2026-11-24 the user accepted `MountayaClient`'s share as it stands, so the gate holds it to its
baseline like every other share, and nothing about it is open.

## 8. The elements family and navigation

The contract's geo layer, the headless state over it, the navigation engine, the map engines and
the views. One question places every piece: would `sdk-kotlin` need it too? If it would, it is
not in a view, because a behaviour inside a SwiftUI view is one only this SDK has and no fixture
can reach.

### The geo layer

Every rule is a pure function over data, and every `geo.*` capability is one of them. The rules
are `sdk/SPEC.md` §7 and §14, proven by the `geo.*` fixtures, and are not restated here; what
follows is what they mean in Swift.

- **A rule is a function at the module's top level**, named as `sdk-kotlin` and `sdk-typescript`
  name it, with Swift's argument labels: `haversineMeters(from:to:)`, `convertLength(_:from:to:)`,
  `formatLngLat(_:)`. A position is the wire's `[Double]`, `[longitude, latitude]` with an
  optional altitude, as `GeoJSONPoint.coordinates` carries one, so a position the API answers is
  handed to a rule as it arrived; a value Geo derives holds one the same way
  (`MapViewport.center`), and a generated type a rule reads is named as the client prints it,
  never copied nor aliased (`RestSchema.Boundaries`). A position names a place where its first two values are finite, and a rule
  handed one that names none answers rather than throws: a distance is `NaN`, a printed position
  `nil`, the distance to a route `Double.infinity` and a map's center held by no boundary. No
  rule of the geo layer throws.
- **A box is the wire's `[Double]`, `[west, south, east, north]`**, as a boundary's or an RFC 7946
  `bbox` carries one, and a pan lock's longitudes are the pair `[west, east]`. A box across the
  antimeridian is written with its east edge past 180, and `normalizeBoundingBox(_:)` never reads
  a west edge greater than the east one as one. A box that is not four numbers answers four
  `NaN`s, and `boundsOf(_:)` answers `nil` where no position names a place.
- **Distance is the great-circle distance** on the radius `geo/geodesy.json` declares, and every
  other distance is that function or a sum of it. `CLLocation.distance(from:)` is never used: its
  earth model is undocumented, and a distance a user reads has to agree with the other SDKs to the
  fixture's tolerance. Ground resolution is the one exception the contract makes, Web Mercator's
  sphere on 512-pixel tiles, and it is one function too.
- **Numbers, dates and times of day go through Foundation's locale services with an explicit
  `Locale`**, never `Locale.current` and never assembled digits, which are Latin digits by
  construction (`geo.format.locale-services`). The seam is `Seams/Engines/`, and nothing else in
  Geo reads the platform's locale data.
  - A tag is read into a `Locale` from its parsed components, `Locale.Components`, never through
    `Locale(identifier:)`: Foundation on macOS 27 reads a `nu` value equal to the language's
    script code as that script and drops it, `bn-BD-u-nu-beng`, `th-TH-u-nu-thai` and
    `en-US-u-nu-latn` alike, whatever digits the locale writes by default, where
    `en-US-u-nu-arab` is kept, and its formatters then write nothing, while `DateFormatter` on
    Linux traps on `bn-BD-u-nu-beng`, and on any numbering system the platform does not carry.
    Such a system is dropped, so the locale writes its own digits, and a numbering system a tag
    names is written on every host: `bn-BD-u-nu-beng` writes `১,৫৩১` on macOS and in both Linux
    containers. A tag is parsed once and its `Locale` kept in a cache of 64 under a lock, as the
    date formatters are, so a list of figures in one language parses its tag once rather than at
    every number.
  - A number is written by `FloatingPointFormatStyle`, a `Sendable` value that needs no lock
    under strict concurrency and whose ICU formatter Foundation caches per locale and shape. It
    writes what `NumberFormatter` writes on Apple platforms, and it is the one of the two that
    writes the same on Linux, where `NumberFormatter` drops the Indian grouping
    (`1,23,45,678`). It is handed a value already rounded half away from zero on its decimal
    value, so 850 m is `0.9 km` and 2.675 to two places `2.68`, before it sees it: Foundation's
    own rounding is half to even on the binary value, and is never asked to decide.
  - An instant is written by `DateFormatter` at the locale's own styles,
    `formatDateTime(_:locale:timeZone:dateLength:timeLength:)`: its date at the `dateStyle` of a
    `DateLength`, its time of day at the `timeStyle` of a `TimeLength`, `short`, the hour and the
    minute, or `medium`, the second too, or both, and the long date where neither is named, as
    `sdk-kotlin` and `sdk-dart` write it. One formatter per locale, pair of lengths and zone is
    built once and kept in a cache of 64 under a lock. The format style is not used because it
    writes the short and the medium date from a field template, `3/14/2026` and `14. März 2026`,
    where the locale's styles are `3/14/26` and `14.03.2026`, and a length means the locale's own
    style of that length in the three SDKs. A date with a time is joined by the formatter as ICU
    joins the two styles, by the locale's join for a date of that length (`sdk/SPEC.md` §7), never
    by a separator of Geo's: French joins a short date and a medium time with a space,
    `14/03/2026 05:45:00`, and German a medium date and a short time with a comma,
    `13.03.2026, 20:00`. A time keeps the locale's hour cycle, `13:00` in German and `오후 1:00` in
    Korean for one instant, whatever clock the device is set to: the person's 12- or 24-hour
    setting is a preference `Locale.current` carries, which a formatter handed that locale writes
    by, and a locale read from a tag carries none. A time names no zone, so `TimeLength` has no long
    or full case, the two styles that name one in words each platform chooses. An hour cycle a tag
    names of its own, `-u-hc-`, is outside the contract (`sdk/SPEC.md` §7), and Foundation reads it
    as any other keyword of the tag: `en-US-u-hc-h23` writes a 24-hour clock, where `java.text` and
    `package:intl` write English's 12-hour one. The calendar is always the Gregorian one, set on
    the formatter after its locale, whatever calendar the locale keeps or a `-u-ca-` extension of
    its tag names (`sdk/SPEC.md` §7): `th-TH` writes `14 มีนาคม ค.ศ. 2026` for 2026-03-14, naming
    the Christian era as its Gregorian long date does, and never the Buddhist 2569,
    `th-TH-u-ca-buddhist` alike, and `fa-IR` `۱۴ مارس ۲۰۲۶`, its digits still its own. A zone the
    platform's zone data does not hold answers `nil` (`sdk/SPEC.md` §7), and the data is the one
    the formatter writes from. On Apple platforms it holds every name `TimeZone(identifier:)`
    answers, a legacy alias the tz database keeps in its `backward` file included, so
    `Asia/Calcutta` writes as `Asia/Kolkata` does. On Linux, swift-corelibs-foundation's
    `TimeZone` answers such a name from ICU's data while its `DateFormatter` hands CoreFoundation
    the zone by that name, which CoreFoundation loads from the system's zone files and traps where
    it loads none: the Swift images carry `tzdata` and no `tzdata-legacy`, so `Asia/Calcutta` and
    `US/Eastern` stopped the process, a date alone as much as a time. So a zone is handed to a
    formatter only where CoreFoundation creates it by that name, `CFTimeZoneCreateWithName`, the
    call the formatter makes, and one it cannot create answers `nil`: on Linux without
    `tzdata-legacy` a legacy alias writes nothing, where an abbreviation CoreFoundation maps and an
    offset name, `PST` and `GMT+0530`, write as they do on Apple platforms. No list of names stands
    in for the data, which a host's packages decide, as `sdk/SPEC.md` §7 states. The
    formatter's calendar takes the zone written in, never the process's own, which CoreFoundation
    loads by name too, so a server whose `TZ` names a legacy alias writes every zone it is asked.
  - A measurement is the number set in a unit pattern of Geo's own table, CLDR 48's for the
    seven `Locales` languages, the table `geo.profile.unit-formatting` declares in its constants,
    the same as `sdk-kotlin`'s and `sdk-dart`'s, read by the primary subtag.
    Geo decides whether a number is grouped, from the table's minimum grouping digits, so a
    Spanish 1531 is `1531` whatever grouping the platform's data holds; where Geo groups, the
    locale's own data spaces the groups, and a language outside the table keeps its own minimum
    grouping, so a Polish 1531 is `1531`, as `sdk-kotlin` and `sdk-dart` write it from their
    table of CLDR 48's figures (`geo.profile.unit-formatting`). A pace per
    distance is the `m:ss` clock, Latin in every language.
  - A position printed for a reader is the contract's one exemption: its digits and decimal
    point are the same in every language (`geo.format.lnglat`), and they come from no formatter,
    since Foundation on Darwin and on Linux are two implementations of one. Each coordinate's
    four places are its binary value rounded half away from zero by integer arithmetic, so
    6.86525, held as 6.865249..., prints `6.8652` and 0.03125, exactly halfway, `0.0313`; every
    finite coordinate is written in full, never with an exponent.
- **A unit converts through the exact value that defines it**, never a rounded factor, and the
  unit ids are the contract's, ECMA-402's with its stated exceptions. Geo computes every
  conversion from those values itself and never reads one off a platform's conversion table,
  `Measurement`'s included, whose factors are the platform's to choose. Each quantity is a closed
  `enum` whose raw value is the contract's id (`LengthUnit.mile.id` is `mile`), and one function
  per quantity converts between two of its units, so a conversion across quantities does not
  compile. `TemperatureUnit` spells the same two scales as the printed `RestSchema.UnitTemperature`,
  which a reader's preferences hold, and stands beside it on purpose: the printed type is an open
  wrapper that keeps a scale this build has never seen, and a conversion needs the closed set its
  exhaustive `switch` reads. A pair of whole magnitudes is reduced before it is applied, so a factor that is a whole
  number or a whole fraction is one exact operation: a mile is 5,280 feet, never 5,280.0002.
- **Text is matched by Unicode scalar, never by `Character`.** The contract's search emphasis is a
  run of code points with their combining marks, never an extended grapheme cluster, and a Swift
  `String` iterates graphemes by default, so the search rules read `unicodeScalars` and fold
  each one as the contract folds it (`geo.search.highlight`). A run is a
  `Range<String.Index>` of the title on its scalars, where `sdk-kotlin` answers the UTF-16 ranges
  Compose counts in: a bound may fall inside a `Character`, between the two regional indicators
  of a flag, so a run is read through `title.unicodeScalars`, and `highlightParts(_:query:)` cuts
  the parts that way, the same parts in both SDKs; a row carries its title cut at its own runs,
  `SearchRow.parts`, as `sdk-dart`'s row does, so a list of an app's own draws a row ready-made. A
  round folds its query once and matches every row of every section against that fold. A scalar
  that is no combining mark joins the segment before it only where a table holds it, the scalars
  that compose with the one before them under Unicode 17 (the Hangul vowel and final jamo, Kirat
  Rai's vowel sign E and its doubled form), and composing proves it does, so the platform's
  composition is asked of those alone, and a test holds the table to the host's own canonical
  mappings. The fold's character data is the host's: the
  standard library's general category, Unicode 17's on macOS 27 and at the pinned Swift and
  Unicode 16's at the floor, and Foundation's canonical mappings, which on Linux lack the
  decompositions Unicode 16 added, which the contract allows (`sdk/SPEC.md` §7: a fold reads its
  host's character data, whatever Unicode version, and no case stands where the versions part).
  Two texts a rule compares are compared by their scalars, `sameText`, never by `==`, which is
  canonical equivalence, as `sdk/SPEC.md` §7 has two spellings of one text read as two texts: a
  query and the one settled, a slug, a source layer, a word a bundle restates and two highlight
  parts are one where they are written alike, and the conformance harness compares two strings by
  their scalars too. A carriage return and a line feed
  are one `Character`, so a web address and a pace clock are read scalar by scalar too
  (`geo.profile.web-address`, `geo.profile.pace-clock`); a digit they read is an ASCII digit,
  never `Character.isNumber` or a regular expression's `\d`, which take every script's; and the
  white space at a text's ends is one written-out set, ECMAScript's, never Foundation's
  `whitespacesAndNewlines`, which holds U+0085 and not the byte order mark.
- **A time zone is an argument**, its IANA name as a `String`, never a `TimeZone` and never a read
  of the ambient zone, and a zone is read under the name the platform reports for it, a link the
  tz database keeps included (`geo.timezone.viewport`), since a device reports the name a zone was
  set under. The rule reads no tz database, so it answers the same on macOS and in the Linux
  containers whatever data each carries. The name is matched exactly, letter case included, and
  the table is the one `geo/timezone-viewport.json` publishes in its constants, every zone of a
  country, 408, and every name a runtime reports in another form, 28.
- **A value Geo derives compares by what it holds, each number as the same number.**
  `MapViewport`, `CameraPose`, `ZoomBounds`, `PixelPadding`, `SlopeAspect`, `TerrainNeighbours`,
  `RouteGeometry`, the elements' `HexColor`, `GlyphSet` and `GlyphDrawing`, and the profile's
  values, from `ElevationSeries` to `DistanceTick`, are equal
  where every field holds the same numbers in the same order, an absent figure the same only as
  another absent one, `NaN`
  the same as `NaN` and 0 another than -0, the relation `geo.camera.route-content` states for a
  route. A synthesized `Equatable` compares by IEEE `==`, under which a value differs from itself
  and the two zeros are one value with two hashes, and `[Double]`'s `==` does the same, so each
  type writes its `==` and `hash(into:)` over the bit pattern, every `NaN` read as one, and equal
  values hash alike. An analysis band and a `ThemeToken` are generic over their value, and a value
  that is a number compares as one too, a list of numbers number by number, so two bands of slope
  `NaN` are one value and merge, and a dash token compares as its numbers do.
- **Floating point is spelled out where Swift and the other SDKs part.** A longitude wraps by
  the truncated remainder, `truncatingRemainder(dividingBy:)`, never the IEEE `remainder`. The
  standard library's `min` and `max` answer whichever side a comparison with `NaN` leaves them,
  and `min(max(value, lower), upper)` reads `NaN` as a bound, so a rule takes the lesser, the
  greater and the clamped value through Geo's own, which keep `NaN` unknown and put -0 below 0.
  A chain is sorted by its position and then its listed order, since `sorted(by:)` promises no
  stability, and waypoints by their distance in total order, so -0 stands before 0 as Kotlin's
  `compareTo` reads them. A whole figure summed from the wire wraps, `&+`, where a Swift `+`
  would trap and Kotlin's wraps; a count of minutes past `Int` saturates as Kotlin's `toLong`
  does; and a distance axis stops where a double counts no further multiple of its step rather
  than loop.
- **Ground resolution is one function, `groundMetersPerPixel(zoom:latitude:)`**, on Web
  Mercator's sphere and 512-pixel tiles, whose three constants are published.
  `altitudeToZoom(_:latitude:viewportHeightPixels:)` and its inverse take the canvas height, the
  nominal 800 pixels where the caller names none or one that is not a finite number above zero,
  and the zoom an altitude converts to is held within [4, 16], the floor and the ceiling
  `geo.camera.zoom-altitude` declares, through a camera one and a half canvas heights from the
  screen, the field-of-view factor it declares too.
- **A fly-through's route is a `RouteGeometry`**, which `itineraryRoute(_:segmentId:)` builds from
  an itinerary's segments as the REST API answers them, `RestSchema.ItinerarySegment`, or from the
  one its id names. Its elevations and jumps are arrays, empty where the route states none, so no
  list and an empty one are one route by construction, and a jump is an `Int` vertex index. A
  line is measured by `cumulativeMeters(_:)`, `routeLengthMeters(_:)` and
  `positionAtMeters(_:meters:)`, a vertex that names no place bridged as every walk of a line
  reads it, and a line that names no place has no position along it, `[NaN, NaN]`. Each
  measurement is recorded by the `MeasureProbe` a test holds, under `Route/Engines/`, a task-local
  value that is nil in an app (§7).
- **A profile rule reads the wire's own types.** A segment and a waypoint are the REST API's,
  `RestSchema.ItinerarySegment` and `RestSchema.ItineraryWaypoint`, a unit preference the wire's
  open `RestSchema.UnitLength` and its siblings, held in `UnitPreferences`, and a figure keeps the
  wire's type, an `Int` ascent an `Int`. An elevation series is the input every other profile
  rule takes; a climb is read on kilometers as the samples carry them, `RouteProfilePoint`,
  because the contract's windows are differences of kilometers (`geo.profile.climbs`). A place's
  summary takes its words as a `WaypointSummaryWords` of `@Sendable` clauses, which Swift does not
  compare, and a cut-off formatter the caller supplies, since only the caller knows the zone.
- **What a consumer only observes stays `internal`**, until an engine of `MountayaElements`
  applies it. `package` would reach `MountayaElements`, which §2 builds on Geo's public API alone,
  so such a rule is published, deliberately, when that engine is written: the pan-lock refusal,
  `refusesMaxBounds(_:)` (`geo.camera.max-bounds-refusal`), is public, since `MapEngine` refuses a
  lock with it, and so is the reading of what a pointer is over, `hoveredItineraryOf(_:)` and
  `HoveredItinerary` (`geo.layers.hovered-itinerary`), which `ItinerarySegmentTable` lights a
  hovered leg's row by. The comparison helpers the map's values compare their texts, numbers,
  positions, JSON and geometries by, `sameText(_:_:)`, `sameNumber(_:_:)`, `sameNumbers(_:_:)`,
  `sameJson(_:_:)` and `sameGeometry(_:_:)`, are no rule and are `package`, the one reach §2
  allows across products. The ground distance a reader is told (`geo.camera.ground-meters`)
  stays `internal` and runs from the internal table of runners.
- **A tile layer draws at the rank its source layer declares**, and the table is a record a
  consumer can patch, never a frozen map: `tileSourceLayerRanks` is a `[String: Int]` handed to
  `tileLayerRank(_:ranks:)`, and `LayerRank` names all twelve bands, ten apart from 10 to 100 but
  for the focus on an itinerary at 52, the preview and the emphasis just above its line, and its
  restricted stretches at 55, over its line and beneath its direction, so the elements' one layer
  registry ranks every layer alike in every SDK, and a consumer's own band between the points of
  interest and the waypoints takes `LayerRank.poi.rank + 2`, 82, as `sdk-typescript`'s example
  does.
- **A camera frames a box by a rule of Geo's own** (`geo.camera.fit`): `cameraForBounds(_:canvas:
  padding:maxZoom:window:)` answers the `MapViewport` that fits a box in canonical form on a canvas,
  facing north, at the highest zoom at which its Web Mercator projection on 512-pixel tiles fits the
  canvas less its padding, held under the fit's ceiling and then within the window, centred on the
  box's projected middle moved by half the difference of opposite paddings at the zoom it lands at,
  and nil where the padding leaves no room. MapLibre's own fit takes no ceiling and may keep the
  bearing, so the renderer computes the camera with this rule on its own canvas and moves there. A
  drawn itinerary is framed on `itineraryBounds(_:)`, the box of its segments' stored geometries, and
  a collection on `specificationBounds(_:)`, its specification's `bbox` read across the antimeridian
  where its west edge lies east of its east one (`geo.camera.content-bounds`); a camera outside the
  window a specification paints across moves to `zoomIntoRange(_:window:)`
  (`geo.camera.zoom-into-range`); and a device fix is framed on `accuracyBounds(_:radiusMeters:)` at
  `locateMaxZoom` at most (`geo.camera.accuracy-bounds`), published because the map engine applies
  them. Which end of its window a camera stands at, `zoomLimitReached(_:window:)`
  (`geo.camera.zoom-limit-reached`), answering a `ZoomWindowEnd`, and the zoom controls each end
  disables, `zoomControlsDisabled(at:)`, answering each `ZoomStep`, are published, since
  `ZoomControl` reads them; what a pointer over an itinerary is over, `hoveredItineraryOf(_:)`
  (`geo.layers.hovered-itinerary`), stays `internal` until a data element of `MountayaElements`
  reads it.
- **A stretch's road access reads as one kind** (`geo.data.road-access-kinds`):
  `roadAccessKindOf(_:)`, one overload over REST's access values and one over the Data API's, each
  value's ASCII capitals folded and nothing else, answers the most severe `RoadAccessKind` among
  them, a closed enum declared most severe first and ordered so, or nil; the published
  `roadAccessValueKinds` maps each value REST spells to its kind, nil for a value of no kind, and a
  value it does not name reads as `restricted`, the kind the rule keeps to itself. A collapsed
  segment group carries its members' road access ranges moved on as its analysis ranges are, nil
  where no member states them and `[]` where one states `[]`. `roadAccessFeatures(_:info:)` cuts
  REST's `road_access_info` ranges from the lines `linesOf(_:)` reads, at any depth of a
  collection, each piece a LineString feature whose `kind` property is the `RoadAccessKind` id the
  tiles' `itinerary_restrictions` features carry, so one pair of layers stripes both
  (`geo.data.road-access-stretches`).
- **A map's paint is a value restyled on a copy** (`geo.style.map-paint`). `MapPaint.standard` is
  the shipped paint, and a patch is Swift's own mutation, `var paint = MapPaint.standard;
  paint.itinerary.casingColor = "#1b1b1b"`: a list set replaces the shipped one whole, a nested
  member set leaves its siblings, and `paint.layerRanks["acme_avalanche"] = 40` adds a band. Like
  `ElementTokens` it has no public initializer, so a member the contract adds breaks no caller,
  and it compares by `==` alone. Its ranks, default colour and palette are
  `tileSourceLayerRanks`, `defaultSegmentColor` and `livelyPalette` themselves. An itinerary's
  stroke is a line layer's style (`geo.style.itinerary-stroke`): `itineraryStrokeStyle(_:paint:)`
  takes an `ItineraryStroke`, `.line(color:)`, `.dashed(color:)` or `.casing`, its colour a
  `JSONValue` literal or expression, and answers a `LineLayerStyle`, the `layout` and `paint` a
  style document writes, the width interpolated over the paint's table as it is held; the layer's
  id, source and filter are the caller's.
- **A point of interest is drawn by its category.** `poiStyleOf(_:)` reads `poiCategoryStyles`,
  a `POIStyle` of a marker glyph's name and a `HexColor`, matched by scalars with letter case, and
  nil for a category the table does not name (`geo.layers.poi-style`); `poiCategoryOf(_:)` reads a
  tile's category through `poiTileCategories`, only the ASCII capitals folded
  (`geo.layers.poi-category`). An isochrone band below zero takes the ramp's first stop
  (`geo.layers.isochrone-color`), and a matrix connector's width is read off its cost by
  `matrixLineWidth` (`geo.layers.matrix-width`).
- **An element handed an itinerary's id reads it through `ItineraryResourceEngine`**
  (`geo.data.itinerary-resource`), main-actor bound and `Observable`. Its `state` is an
  `ItineraryResource`: `idle`, `resolving`, `resolved` holding a `ResolvedItinerary` with its four
  projections at once, or `failed` with what the source threw. It asks as soon as it holds a
  question, in its initializer or `configure(cache:itineraryId:surface:)`, since Observation tells
  an engine nothing of its readers, and `close()` ends it; an empty id is none, a question asked
  again asks nothing, an answer to a question it no longer asks never lands, and an answer its
  cache holds is shown before the call returns.
- **Answers are a cache's, one per client** (`geo.data.itinerary-cache`). A Swift function has no
  identity to key a shared table on, so the app makes one `ItineraryResourceCache` over its
  `ItinerarySource`, `@Sendable (String, RestSchema.ReadSurface?) async throws ->
  RestSchema.ItineraryWithDetails`, `getItinerary` in one line, and hands it to every engine.
  Answers are kept by cache, id and surface, the `capacity`, 16, most recently read kept, reads in
  flight counted, and a failure dropped at once. `invalidate(itineraryId:)` drops an id on every
  surface, or every answer, and asks again for each engine watching it, in the order each began
  to, each showing what it showed until the new answer lands. Reads run in main-actor tasks, and a
  cache let go of cancels its reads in flight.
- **An itinerary's projections are rules over the wire's types**: `itineraryGeometry(_:)`, a
  collection of each segment's stored geometry in chain order (`geo.data.itinerary-resource`),
  `profileCharacteristics(_:waypoints:)`, `itinerarySegments(_:groups:)` answering each
  `ItineraryLeg` with its six section figures and no running total
  (`geo.data.itinerary-segments`), and `itineraryWaypoints(_:)` answering each `ItineraryPlace`
  with its `WaypointDetails` (`geo.data.itinerary-waypoints`). Every chain is read by `position`,
  ties in the order listed. The place is never called `Waypoint`, a name FerrostarCoreFFI
  publishes, which an app importing both would find ambiguous.
- **A rule takes the wire's generated types.** A label language is the REST bundle's
  `RestSchema.Language`, the seven `Locales` is keyed by; the layer rules take the Tile API's
  `TileSchema.TileLayer`, `TileSource`, `Layers` and `Overlay`, since the map draws from
  `getTileLayers`, never the REST bundle's identical twins; a search row and a drawn feature take
  the Data API's `DataSchema` results, every member nullable by selection, and decide each `nil`:
  a result with no identity is no row, and a datum with no place a feature with no geometry.
- **A JSON value Geo reads or writes is the client's `JSONValue`**: a style's `text-field`, a
  bundle's words and a feature's properties, an object as `[String: JSONValue]`. Its members keep
  no order, which no fixture reads and a renderer does not need, where `sdk-kotlin`'s
  `JsonObject` keeps the order its rule writes. Two values compare as `sameJson` reads them, a
  number by the same-number relation and a string by its scalars, so `GeoJSONFeature`,
  `WordBundle` and `WordOverrides` compare as every Geo value does. `JSONValue` is
  `ExpressibleByNilLiteral`, so a rule that answers no label returns `nil` on its own, never
  `cond ? nil : value`, which would answer JSON's `null`. A label nested past
  `maxLabelDepth` is refused, and the depth and two labels are read with a stack of their own.
- **A drawn layer's names follow the naming law**: the types keep the client's spelling,
  `GeoJSONFeature` and `GeoJSONFeatureCollection`, and the rules a member's,
  `isochronesGeoJson(_:)`, `matrixGeoJson(_:result:)`, `waypointSpriteId(icon:color:)`. An icon's
  markup is read by a scanner of Geo's own, scalar by scalar, never by `XMLParser`, which
  refuses markup that is not well formed and expands entities.
- **A glyph set is a value that can always be drawn.** `GlyphSet` holds its name, its paint, its
  width, its box and its markup by glyph name, every member read-only, and its two initializers
  are the contract's two rules about sets, each answering nil, the refusal, as no rule of the geo
  layer throws: `init?(name:paint:strokeWidth:viewBox:markup:)` builds a host's own set, drawn at a
  width of 2 in a box of 24 unless it states others (`geo.icons.glyph-set`), and
  `init?(chaining:)` chains sets, each glyph from the first that holds it, drawn as the first is
  (`geo.icons.glyph-set-chain`), so a renderer handed a set never meets one it cannot draw. A
  paint that is neither `fill` nor `stroke` is refused by the closed `GlyphSet.Paint` before any
  set is built, and a chain's name is its sets' joined by `+`, as `sdk-typescript` names one.
  `glyphPaint(_:in:)` answers how one shape is painted (`geo.icons.glyph-paint`), a `ShapePaint`
  whose fill and stroke are each in the current colour or not, `isFilled` and `isStroked`, and
  whose cap, join and fill rule are closed enums spelled as SVG spells them; it reads a shape's own
  values through the parse's own reading, so a value the parse drops is no statement. What a
  surface draws in place of a glyph its set cannot draw, the fallback pin for a place and words for
  an amenity's badge, `placeGlyph(_:in:)` and `badgeFallback(_:on:)` (`geo.icons.glyph-fallback`),
  stays `internal` until a view of `MountayaElements` draws it; a badge's first letter is its first
  `Character`, the extended grapheme cluster the contract names, written in capitals by Unicode's
  own case mapping, which reads no locale. A set's markup is a dictionary by glyph name, so it
  reads two names that are canonically equivalent as one, as a bundle's words and a patch's
  members, dictionaries by key too, read two such keys: an exception to the scalar reading of text
  above, where `sdk/SPEC.md` §7 reads two spellings of one text, a key among them, as two texts.
  Every name the contract's table and vocabularies hold is ASCII, where the two readings agree,
  and no case writes a key in two spellings.
- **A token reads the consumer's value first** (`geo.style.theme-tokens`). `themeTokenValue(_:in:)`
  reads a `ThemeToken` under a `ThemeScheme`, `light` or `dark`, never SwiftUI's `ColorScheme`,
  whose name a consumer's file would find twice: the dark value under the dark scheme where the
  token states one, and the light value otherwise. A consumer states a value of its own by setting
  the token whole on a copy of `ElementTokens.standard`, `ThemeToken(light: ...)`, which states no
  dark value, so its value stands in both schemes as the contract's does; one that wants a value of
  its own under each scheme states both, which the contract's override cannot say.
- **A nested scope inherits what it does not state** (`geo.i18n.nested-scope`). An
  `ElementsScope` holds a language, the locale its figures are written in, its words resolved from
  the elements' own (`WordBundle.elements`, French included, so no translation is handed over),
  and its control and marker glyph sets; `ElementsScope.standard` is English in the locale `en`,
  and `scopeOf(_:stating:)` nests an `ElementsScopeStatement` in it, every member optional. Its words
  are the outer scope's while the statement states no words and no language other than the outer
  one, a language restating the outer one keeping them (C31), and resolve afresh otherwise; its
  locale follows a language other than the outer one, read as its own tag, unless a locale is
  stated; and a control set stated never stands in for the marker set. A scope has no public
  initializer, so a member the contract adds breaks no caller. `word(_:)` reads a word by its
  dotted path, the English word of the elements' own where an override left text out, and the
  path itself where neither holds text.
- **A counted word takes its language's form** (`geo.i18n.counted-words`). `countedText(_:count:
  language:)` reads the table's object of forms: French takes `one` for zero and one, and English,
  as every language the table does not hold, `one` for one alone (`geo.i18n.counted-words`), so a count
  below zero takes the other form in both, by this rule and never by a platform's plural rules;
  its first `{count}` takes the count written by `formatNumber(_:locale:)` in the words' language,
  so 1234 is `1,234` in English and `1 234` in French, grouped by U+202F, the same bytes on macOS
  and in both Linux containers. `filledText(_:value:)` fills a template's first `{name}`, whatever
  it is named, read scalar by scalar, with the value exactly as handed, `$&` and all, and any
  placeholder after it is text; nil is the refusal of a word that is no counted word.
- **The pickers' models are Geo's** (`geo.layers.picker-rows`, `geo.layers.poi-rows`,
  `geo.units.preference-choices`), published since the panels of `MountayaElements` read them.
  `layersPanelSections(_:language:isLocked:picked:offersTime:)` lists a `LayersSelection`'s
  catalogue in the four sections of the map studio's layers panel, in its order: the terrains, the
  enrichments but the points of interest, `poisOverlaySlug`, which their own picker drives, the
  classic overlays of the one category the section opens on, and the time where the host offers
  it, `offersTime`, each a `LayersPanelSection` making its `LayersPanelChoice`, `time` among them,
  headed by a `LayersPanelHeading`, the path of a word of the `layers` section, `layers.terrain`.
  The overlays' section offers every classic category holding an overlay as a
  `LayersPanelCategory`, its slug and its name, and opens on `picked`, the category the reader
  picked last, where it names one offered, else on the first holding the selected overlay, else on
  the first, a category's name and each `LayersPanelRow` named through `localizedName`, checked by
  the selection's slugs compared by scalars, and marked `lock` in place of `tick`;
  `layersPanelPress(_:row:)` answers a `LayersPanelPress`, the command of the row's choice or the
  report of a locked entry. `poiPanelRows(drawn:isKeyVisible:keys:groups:activeGroups:labels:)`
  answers `POIPanelRows`, its `POIPanelRow`s and the master row, over curated `POIPanelGroup`s, and
  `poiPanelNoteZoom(_:)` the zoom below which the note stands. `preferenceChoices(_:)` answers the
  five `PreferenceChoice`s over a `UnitPreferences`, each `PreferenceOption` a `PreferenceValue` in
  the wire's own types, labelled by a `PreferenceLabel`, a language checked as `labelLanguage(_:)`
  reads the held tag; `preferencePress(_:pressing:)` answers the `PreferencePress`, the set with one
  preference changed and the language the map relabels in. A rule named as its answer type is
  filed with the word of its kind, as §6 says.
- **A layers selection drives a map it does not mirror** (`geo.layers.selection`,
  `geo.layers.selection-outcome`). `LayersSelectionEngine` stands over a `LayersSelectionTarget`,
  the terrain the map shows, its catalogue read and its five commands, each `async throws`, which
  `MapEngine`'s own members witness, its synchronous ones included. It holds a `LayersSelection`, the catalogue, the
  terrain, the classic overlay, the enrichments in the order turned on, and the refusal of the
  latest command or catalogue read to settle, not `Equatable` since it holds an error; it drives
  each command at once in a main-actor task, an outcome owed to an earlier map landing nowhere, the
  same map brought back included. It reads the catalogue when it is handed a map, and again where
  the same map is handed while its read failed, a read that fails being reported as a refusal; a
  landing states the terrain the map reports where none is selected, and ends a refusal standing.
  It holds the instant a reader pins, `LayersSelection.instant`, the sixth command,
  `setInstant(_:)`, driving the map's `setInstant(_:)` at once, the instant already held asked
  again, a refusal reported as any command's, the pin standing through every other command and a
  map handed in place of the one driven starting with none pinned
  (`geo.layers.selection-instant`). A `Date` of no number, or one past the 8.64e15 milliseconds
  from the epoch an ECMAScript or a Dart instant holds, pins none (`namesInstant(_:)`, the
  package's): Swift's `Date` holds both, so this SDK reads them as the pins that name no instant
  the fixtures write, where `sdk-kotlin` and `sdk-dart` refuse them by their types.
- **The time is Geo's, and reads no clock** (`geo.layers.overlay-instant`,
  `geo.layers.tile-timestamp`, `geo.layers.time-window`, `geo.layers.time-slider`,
  `geo.layers.time-readout`): each rule is handed the clock's reading. `overlayInstant(pinned:now:)`
  answers a pin as it is, else the reading floored to its minute, nil under a reading of no
  instant. `timestampedSources(_:overlay:at:)` answers the selected classic overlay's sources,
  `TimestampedSource`, where the server stamps it, each address edited as text, byte by byte, its
  `timestamp` pair written as `Timestamp.string(from:)` writes an instant and percent-encoded as
  ECMAScript's `encodeURIComponent` encodes one. `timeSliderWindow(now:)` lays the track out,
  `TimeSliderWindow`, held to the microsecond in 64 bits, so a half hour places an instant at the
  later stop exactly whatever binary error a `Date` carries, `date(at:)` nil for a value that is no
  stop and `value(at:)` comparing the track's ends before it counts, so no instant overflows; a
  reading of no number, or one whose track would reach past the 8.64e15 milliseconds, lays out a
  track of no instant, which Swift states by `start` nil. `timeSliderTicks(_:)`,
  `timeSliderRelease(_:at:)`, a `TimeSliderRelease` or nil for nothing committed, and
  `timeSliderReadout(_:at:)`, a `TimeSliderReadout` of the instant, the path of the offset's word
  and its count, as `sdk-kotlin` and `sdk-dart` shape it, close the slider. A tick's and a
  readout's word is a path, as a heading's is, which `ElementsScope.word(_:)` reads.
- **A locate control says what the permission says** (`geo.controls.geolocate-state`).
  `GeolocateControlEngine` stands over a `GeolocateControlTarget`, a fix it asks for and
  `isLocationRefused()`, which reads the standing permission without asking anyone and throws where
  it cannot say, read as nothing refused. Its `GeolocateControlState` is busy until every fix it
  asked for settles, blocked while the latest read answers refused, and live while it stands over
  a map; each read is numbered, so an earlier one's answer, and one from a map replaced, lands
  nowhere. `locate(onError:)` hands on each failed fix, never after `close()`. `MapEngine` reads
  `denied` alone as refused, so a fix refused while the permission was never asked, `prompt`, is
  no block (Q7).
- **A search row is `Identifiable` by its kind and its own id**, so a SwiftUI list keys it as
  the contract keys it, and `SearchWording`'s host words are a `@Sendable` closure, so the type
  is not `Equatable`.
- **A row's payload position is `[longitude, latitude]`**, a place's or a point of interest's
  point, a way's anchor, an itinerary's start and a zone's anchor, in all three SDKs: an altitude
  the wire's point carries is dropped there, since the payload is where a map goes, and a row is
  still built from such a point. A way's `coordinates` are its line as the wire traced it.
- **A search is one engine** (`geo.search.section-order`, `geo.search.typing-pause`,
  `geo.search.live-round`, `geo.search.broaden`, `geo.search.viewport-refresh`). `SearchEngine` is
  main-actor bound and `Observable`, and its `state` is what a result list shows for the query in
  the box: its own answer where it answers that query, trimmed, and the skeleton of the round the
  query is owed otherwise. `setQuery(_:)` waits out the typing pause, 150 ms unless it is handed
  another, a `SearchPause`, and a query the engine starts with owes none; `setConfined(_:)`, a `configure(_:)` changing the language, the
  cap, the branches, whether there is a transport or the units' language or length system, and
  `retry()` each ask a fresh round. A round sends one request per branch of its configuration's
  targets, each in a main-actor task started in their order, every flag stated and the branch's
  alone true; a branch listed twice is asked once and one the build cannot enable none. A round a
  later one replaced is abandoned: its tasks are cancelled, so a request out is withdrawn, and
  nothing it answers or throws lands, a round abandoned before its task ran sending nothing. The
  pauses are waited out by a main-actor `sleep` the engine is handed, `Task.sleep` unless a test
  hands its own. A typing pause below zero is refused as the search is built, as `sdk/SPEC.md` §7
  has it refused with a cap outside 1 to 50: `SearchPause`'s failable initializer refuses it, as
  `SearchLimit`'s refuses such a cap, so no engine holds one, and a refresh pause below zero is
  none. The camera is stated as it rests,
  `setCamera(_:)`, a `MapViewport`; while the list is open, the round confined and a query held,
  a rest asks the round again after 350 ms, its rows kept in place under a busy flag and never
  broadened. `isSettled` is "a round counted and none in flight", the snapshot's own word where
  `sdk-typescript` counts rounds (C37). The engine starts unconfined, as the contract's engine
  does (Q21). A cap is a `SearchLimit`, whose failable initializer refuses one outside 1 to 50, so
  no engine holds a cap the API refuses. A failed section holds what the transport threw, or a
  `SearchBranchError` where the Data API answered the branch as failed; only a thrown failure
  reaches the configuration's `onError`.
- **A round is ranked around the camera's centre** (`geo.search.focus`): the internal
  `searchFocus(_:)` brings its longitude within [-180, 180], one within it kept as written, and
  its latitude within the poles, and answers nil for a centre that names no point, which then
  confines nothing either; a zoom that is no number confines nothing.
- **A result list's state is Geo's** (`geo.search.list-state`): `searchListState(_:filter:)`,
  published since `SearchControl` reads it, answers the rows under a filter, each failed section a
  line of its own, whether nothing was found, whether the fall back is noted, and a
  `SearchListStatus` named by the key of its word in the `search` section, `resultCount` counted
  through `countedText`. A result's second line is `describePlace(_:wording:)`,
  `describePoi(_:wording:)` and `describeWay(_:wording:)` (`geo.search.describe`), published, in
  English titles and metric figures where no wording is handed, every figure rounded half away
  from zero on its decimal value. `dataLanguageFor(_:)` reads a tag into the language the Data API
  answers in, the map's label language in capitals.
- **Picking a result frames it, then marks it** (`geo.search.pick`): `pickTarget(_:)`, published
  since the control reads it, answers a `SearchPick`, a `SearchPickCamera` framing an extent as
  written or flying to a point at `pointZoom`, 13, and the `SearchHighlight` the map's search
  highlight is handed, nil where a result marks nothing, which takes the mark before down. A point
  of interest is marked with its category, nil where it states none.
- **A profile is drawn in a 100-unit square, and every figure in it is a rule of Geo's**
  (`geo.profile.plot-scale`, `domain`, `chart-path`, `curve-stops`, `stretch-at`,
  `slope-stretches`, `grade-at`, `scrub-grid`, `window-clamp`, `curve-placement`,
  `axis-label-culling`, `window-spans`). `profileX(_:totalDistance:window:)` and
  `profileY(_:domain:)` place a distance and an altitude, `profileViewBox` 100 wide, the curve
  between `profileTopInset` and `profileBaseline`; the scale is `profileDomain(_:window:)`, or
  `anchoredDomain(_:anchor:window:)` anchored on the route, on sea level or on the window, rounded by
  `extentDomain(min:max:)` and lined at `domainTicks(_:)`. The curve is values, never path text:
  `profilePolyline` answers `[PlotPoint]` and `profileAreaPath` `[PlotCommand]`, rounded to a
  thousandth a half up; a renderer stretches the square over its own size. A stretch is a
  `ProfileSpan`, so `stretchAt`, `placeSpans` and `rowAt` keep each stretch's own members through
  them, the later of two at the meter they share. A scrub reads a window through
  `profileScrubColumns`, 240 columns, each standing for the sample nearest its centre
  (`scrubGrid(_:window:)`, `scrubDistance(column:window:)`), and a window is held to the itinerary
  and to `minRangeSpanMeters` by `clampRange(_:totalDistance:)`, the handles swapping rather than
  inverting it. A place is a `ProfilePlace`, at a position or at a distance, pinned on the curve, its
  name dividing the itinerary under the axis and its cut-off marked (`placeOnCurve`), a place the
  itinerary passes twice placed twice; crowded names between the first and the last are left out
  (`cullCrowdedLabels`).
- **The strip, the card at the cursor and the chips read the itinerary's figures**
  (`geo.profile.stat-strip`, `cursor-readout`, `section-chips`, `amenity-stacks`).
  `resolveCharacteristics(_:stated:)` folds the server's figures over the ones the geometry gives,
  figure by figure, into `ResolvedCharacteristics`, each a `Double?`; `statStripCells` states them,
  or the cursor's distance, altitude and grade; `profileReadout` states what the cursor stands on
  and the stretch it stands in; `sectionChipCells` a leg's length, climb, loss and grade; and
  `amenityStacks` the services above a pin, four shown and the rest counted. Each cell is an enum
  with a case per figure, so a view writes each by its case.
- **The two tables' rows are the itinerary's legs and its places' passes**
  (`geo.profile.segment-rows`, `waypoint-rows`, `segment-table-cells`, `waypoint-table-cells`,
  `row-match`, `line-between`). `itinerarySegmentRows(_:legs:stated:)` spans each leg on the
  distance axis, its figures `stated[leg.id]` over the leg's own over the cumulative scan, the
  running totals following a stated running figure; `itineraryWaypointRows(_:geometry:places:)`
  states each pass of a place, the figures a place states applying on its primary pass alone. A cell
  is `segmentRowCell` and `waypointRowCell`, a band an `AltitudeRange`, never a `ClosedRange`,
  which traps on an inverted band; a place's glyph is its own where the table's set holds it, else
  the fallback pin. A row stands for a segment id, its own or a member's (`rowStandsFor`), and a
  leg's stretch of the series is `lineBetween(_:from:to:)`, the line the chart drew.
- **A place's services are named in the reader's words and sorted in the reader's order**
  (`geo.profile.amenity-filter`). `amenityName(_:in:)` reads the scope's `amenities` word, else the
  elements' English one, else the value; `amenityFilter(_:picked:scope:)` answers the chips, each
  service offered, collated in the scope's locale through `localeCollated(_:before:languageTag:)`,
  a seam's, since collation is locale data, and the rows offering every service picked;
  `toggleAmenity(_:in:)` adds a service at the end or takes it out wherever listed.
- **A place's card is a model of Geo's** (`geo.profile.waypoint-card`,
  `geo.profile.waypoint-property-value`). `waypointCard(_:scope:units:formatCutoffAt:)` answers
  `WaypointCardFacts`: the headline, the services by name, the timing, the contact, the fields, the
  links and the photos, each line labelled in the scope's `waypointCard` words. A phone, an email, a
  website and a booking page are anchored only where `isWebAddress` reads a website's or a booking
  page's address, so no script is ever a link, and a photo is kept only at a web address. A
  place's addresses, `WaypointDetails.Contact.website` and `bookingUrl`, a photo's and a link's
  `url`, are `String`s, the text the wire answers, read off the printed `URI` as it was written
  (`sdk/SPEC.md` §7, `geo.data.itinerary-waypoints`): one with no scheme, a bare percent sign or a
  host Foundation would write in Punycode is kept, and Foundation's `URL(string:)`, which
  percent-encodes a text with a space and refuses one with white space at its ends, never reads it
  on the way, so the card states it as written and links it as written or not at all. A field is `WaypointField`, its value written by `waypointPropertyValue(_:units:formatInstant:)`,
  a number read as ECMAScript's `Number(string)` reads it and a date read by the client's anchor,
  `parseTimestamp(_:)`, and written only through the app's formatter, and its link
  `waypointPropertyLink(_:)`. A date that names no real instant is written as it stands: the
  thirtieth of February, month 13, the hour 24, a second of 60, minute 61, an offset past 23:59 or
  one without its colon, or anything after the zone. Foundation's `Date.ISO8601FormatStyle` is not
  the reader: it carries such a day, hour, minute or second into a later instant, takes an offset
  without its colon and a trailing space, and refuses every offset past 18 hours, which the anchor
  reads to 23:59. Geo never reads a cut-off from text: it is the `Date` the client decoded by the
  same anchor, which the card, the waypoint table and the curve hand the app's formatter.
- **An altitude band is the language's own range** (`geo.format.altitude-range`).
  `formatAltitudeRange(min:max:units:)` writes each bound whole by the locale services and the unit once,
  through a separator and an approximation of Geo's own table, CLDR 48's for the seven `Locales`
  languages as ICU 78.3 writes them, since Foundation publishes no range formatting of numbers on
  either host: two bounds written alike read approximately, and a first bound below zero takes a
  space either side of the separator. A stop of the distance axis is `formatDistanceTick(_:units:)`,
  its fraction digits kept even where they are zeros.
- **A place's mark and a badge's fallback are published** for the views that draw them:
  `placeGlyph(_:in:)`, `badgeFallback(_:on:)` and `BadgeSurface`. A surface's colours are
  `surfaceColor(_:)` and `wayTypeColor(_:)` over `surfaceColors` and `wayTypeColors`, a value the
  open vocabulary adds painted in `unclassifiedColor` (`geo.profile.classification-colors`).

### Engines and seams

**The headless state is the promise.** Every view `MountayaElements` publishes renders state an
engine holds, Geo's for navigation and the map's own, `MapEngine`, for a map, which names no
MapLibre or SwiftUI type and builds on every platform, so a consumer who wants a different screen
takes the same engine and draws their own.

- **An engine is an `@Observable` class, bound to the main actor.** Observation is its own module,
  not SwiftUI, so Geo imports no UI framework; the main actor is where SwiftUI reads the state, so
  an engine anywhere else would hop on every read. A consumer outside SwiftUI subscribes to an
  `AsyncStream` of its own, one per subscription.
- **What makes a thing an engine is state, not size.** A rule is a pure function however large; an
  engine holds something across time, a query in flight or a session in progress, however small.
- **Data arrives through the narrowest seam**: a function type the app wires to its client in one
  line, such as a search fetch or a route source, or plain data. Geo never names `Mountaya`, so an
  engine that needs Mountaya data takes a function, which is what the TypeScript SDK's
  `SearchFetch`, `SegmentRouteFn` and `TerrainSampler` are.
- **Nothing below the app constructs a client.** The map takes the app's `Mountaya` because it
  needs the Tile API's catalogue and the credentials to fetch tiles with; the TypeScript `MapView`
  takes its client the same way. To publish what the map's own requests carry without a `package`
  declaration across products, the client publishes two members: `language`, the tag it sends as
  `Accept-Language`, and `mapRequestHeaders(for:)`, the headers a request a renderer makes for itself
  carries where it is the Tile API's, and nil where it is not (below).
- **A seam is a protocol with an implementation that reads the platform and an `Inert` one**
  that does nothing and is still total, so a host can decline it.
  `InertLocationSource` is a location that never moves, and `InertNavigationVoice` a voice that
  says nothing.
- **A native seam decides nothing the SDKs differ on, and the decisions it keeps are admitted
  here.** A seam's native code reads the device and hands it on; a choice it makes that a reader
  can hear or see is one every SDK makes alike, `sdk-kotlin`'s and `sdk-dart`'s SPECs admitting the
  same ones with the same reasons, and a choice not listed here is a defect. Four are kept:
  - **Both geolocation seams ask the platform for the precision their purpose reads**, the same in
    every SDK: a map's one fix about a hundred metres, `kCLLocationAccuracyHundredMeters`, under a
    full-accuracy permission alone, and a navigation's fixes the satellites' finest at the rate the
    host chooses (`LocationRate`). A locate control frames the box a fix's accuracy spans
    (`map.camera.locate`), which a hundred metres answers without waiting on a satellite fix, and a
    reader who turned precise location off is located nowhere rather than kilometres away.
  - **The voice holds the audio half a second after a sentence ends**, 500 ms
    (`SpeechNavigationVoice`), and lets it go at once where it is hushed: a maneuver's prompts come
    in quick succession near a junction, and an app whose music ducked would otherwise come back up
    and duck again between two sentences of one maneuver.
  - **The voice is hushed where another app takes the audio from it**, an interruption of the
    audio session on iOS, `AUDIOFOCUS_LOSS` and `AUDIOFOCUS_LOSS_TRANSIENT` on Android: a call or
    another app's own speech takes precedence over guidance, and a sentence said over it is heard by
    nobody, so the voice stops rather than talking over the reader's call; the next prompt due is
    said as it falls due.
  - **A location source tells `providerDisabled` once each time the device's location goes off**,
    not once per fix the platform withholds, which is Android's decision alone: Android reports a
    provider disabled on every request and on every check while it stays off, and a host told the
    same failure each second would show the reader the same notice again and again. Core Location
    names no provider a reader switches off, a refusal reaching this SDK's sources as the
    permission they read, so its seams hold nothing in that decision's place.

### Navigation

**The rules are contract, and they are written in `schemas` before the engine is.** Step
normalisation (`geo.navigation.steps`), the stepless route (`geo.navigation.stepless-route`),
instruction keys (`geo.navigation.instruction-keys`), the progress numbers a user reads
(`geo.navigation.progress`), the off-route distance (`geo.navigation.off-route`), the status set
(`geo.navigation.status`), one route request in flight (`geo.navigation.route-request`), what an
engine reads at every position, when it arrives and who asks for a new route
(`geo.navigation.engine-walk`), the prompts a speaking engine announces each maneuver with
(`geo.navigation.prompts`) and an itinerary's segments joined into one route
(`geo.navigation.itinerary-route`) are each a capability `sdk-kotlin` and `sdk-dart` answer identically,
confirmed in `sdk/SPEC.md` §14,
so each is named here and none is restated: a rule restated in an SDK's spec is the rule the next
SDK reimplements from prose. Contract v0.9.0 carries them, and what follows is what they mean in
Swift.

**An instruction is a key and its arguments, never a sentence.** Geo resolves a maneuver to a copy
key and the way name or exit it takes; the words are the host's, or a view's own `strings`, so
the same step reads alike in every SDK and in every language a host ships.
`stepInstruction(_:)` answers a `NavigationInstruction`, whose `key` is one of the 34 cases of
`NavigationInstructionKey`, a closed set a host's `switch` covers, and whose `name` and `exit` are
stated exactly where the key's `arguments` hold them, since the rule alone builds one. A waypoint
an itinerary's route passes on the way is said with its own pair, `waypoint`, which takes the
waypoint's name, or `waypointPlain` where it has none, so a host's strings word it as an arrival
on the way and never as the end: "Pass Refuge de Bellachat".

| Piece | Lives in | Because |
| --- | --- | --- |
| `NavigationState`, the status set, `NavigationError`, instructions and progress as Mountaya values | `MountayaGeo` | a view renders them, and a view depends on no navigation engine |
| the pure rules, the guidance's plan and due prompt among them | `MountayaGeo` | fixtures reach them on every host |
| the `NavigationEngine` protocol | `MountayaGeo` | an app codes against it without linking an engine |
| a `NavigationEngine` whose route requests a test answers, `ScriptedNavigationEngine` | `MountayaGeo`, under `Testing` | an app's unit tests answer each route request themselves, on any host |
| the one machine under every engine, `RouteFollowingEngine`, published with one initializer over a route source and an inline observer | `MountayaGeo`, under `Engines` | the scripted engine's states are a navigation's, never states a test invents, and `MountayaNavigation` stands on Geo's public API alone (§2) |
| the engine an app navigates with, `DeviceNavigationEngine`, and the seams it takes | `MountayaNavigation` | its seams read the device, which Geo never does |

**The vocabulary, in Swift.**

- **A step is `NavigationStep`**, its maneuver the generated, open `RestSchema.ManeuverType`
  rather than a type of Geo's own, read from either surface by
  `readDirectionsSteps(_:coordinateCount:)` and `readItineraryDirectionsSteps(_:coordinateCount:)`,
  each taking the list the surface may not send. Every rule reads a maneuver as one of REST's
  fifteen members, matched by its scalars, so `merge`, the other surface's spelling and a step a
  host wrote by hand are said as `unknown`. The vocabulary holds one more, `.waypoint`, which Geo
  adds to the open type and no surface writes: a step a surface sends as `waypoint` reads as
  `unknown`, and only `readItineraryRoute(_:waypoints:)` says one.
- **An itinerary is followed whole as one route**, `readItineraryRoute(_:waypoints:)` joining its
  REST segments, in a stable chain order by `position`, into one `NavigationRoute`: their lines
  laid end to end, a vertex two lines share kept once, each segment followed by its own steps as
  `followedRouteOf(_:)` follows a route, every arrival but the last said as a `waypoint` named by
  the itinerary's named waypoint within `waypointProximityMeters`, 60, of where its segment ends,
  the nearer of two and the first in chain order of two as near, a departure naming no way right
  after one folded into it, and the duration the segments' summed, none where one holding a line
  states none. A route an app hands its engine from an itinerary is this one, so the guidance
  says each waypoint passed and arrives once, at the end.
- **A route a source answers is a `NavigationRoute`, and the route followed a `FollowedRoute`**,
  which `followedRouteOf(_:)` alone builds, so its steps tile its line. Its line is measured once,
  when it is followed, and published, `measured`, which the guidance plan reads its lengths from,
  a route with no steps of its own reading its departure's length off that one measure too, and
  never once per fix (`route-measure`, §7); a route and its copies share one storage, which its
  `==` compares first, so a state that holds the route it held compares no vertex on the position
  it reads. A vertex that names no place is bridged by every navigation rule, as a corridor reads a
  line. Its vertices that name a place are flattened once, when it is followed, into four arrays of
  numbers, each one's index, longitude, latitude and distance along the line, which a reading at a
  fix walks, every stretch still, rather than the line's array of arrays, whose every vertex is an
  array to retain and release: one fix on a route of 6,000 vertices was read in 47 µs and is read
  in 38 µs, its progress alone 33 and 25 µs, every figure the same to the last digit. A position a
  distance along it is read off its measure, `positionAtMeters(_:meters:)` over the route, by a
  search over the distances measured, as the line's own reading places it, and measures nothing, so
  a replay ticking along it pays a search a tick (`replay-measure`, §7): 226 µs a tick on 6,000
  vertices before, 0.1 µs now.
- **`NavigationStatus` is declared in the contract's order**, from `idle`, and
  `NavigationState.idle` is where every navigation starts. Every navigation value compares as
  every Geo value does, a text by its scalars.
- **A failure is a `NavigationError`**, a struct with an open `Kind`, `routeFailed(_:)` carrying
  in `cause` what the route source threw and `emptyRoute()` for a route whose line holds no vertex.
  A Swift error is a value with no identity, so a failure is given one where it is recorded: one
  failure and its copies are equal, and two failures recorded apart are two values, whatever their
  sources threw, two empty routes among them, so a state holding one never equals a state holding
  another (`sdk/SPEC.md` §14).

**The engine contract is `sdk-typescript`'s engine's surface in Swift's idiom.**
`NavigationEngine<Request>` is `state`, `subscribe()`, `start(_:)`, `reroute(_:)`,
`setPosition(_:)`, `stop()` and `close()`, and `Request`, what a host asks a route for, is
`Sendable`.

- **An engine is bound to the main actor and is `Observable`.** `state` is what a SwiftUI view
  reads, and `subscribe()` hands any other reader a stream of its own: the state as it is, then
  every state that differs from the one before it, in order and with nothing dropped, until
  `close()` ends it. A stream promises its own reader every state in order, and nothing about
  the order two readers read one state in, which is the order the main actor resumes their tasks
  in and which it does not promise. An engine built over the machine that keeps something of its
  own to each state is told each one by the machine's `onChange`, inline, in order and before any
  stream is handed it, so the guidance `DeviceNavigationEngine` keeps has followed a route before
  any reader sees it land; a command it makes there has its effect at once, and its state is
  handed on after the one it was told, to it and to every stream alike. A start or a reroute
  sends its request before it commits the state that asks for it, as `sdk-dart`'s machine does,
  so a stop or a close `onChange` makes on `routing` or `rerouting` abandons that request rather
  than leave it in flight behind the stop. Each command has its effect before it returns, and an
  engine holds no lock.
- **One state a command at most, and only a change**, but a route that lands while a position is
  held is two: the route, unread, then that position's reading on it. A position that reaches the
  end is reported `arrived` at once, and a reroute reports `rerouting` with the route and the
  reading held.
- **Positions arrive through `setPosition(_:)`**, as the host has them, and its altitude is never
  read. One that names no place throws a `PositionError` naming it, never a trap in a location
  callback and never silence; one stated before a route lands is kept and read on it, and a stop
  keeps it for the next route.
- **A position is read in one pass over the line.** Each stretch's foot is placed once and serves
  both readings: the nearest foot of every stretch is the distance the off-route rule reads,
  `metersToRoute(_:lines:)`'s, and the nearest of the stretches that end at or past the progress
  held is the progress, `navigationProgressAt(_:position:previous:)`'s, each kept by its own
  rule's comparison, so both answer what their rules answer, every conformance case included. No
  window is taken from the progress held: a route may come back past the traveller at any distance
  ahead, a loop or an out-and-back, and the nearest foot ahead wins wherever it stands, while the
  distance to the route reads every stretch, the passed ones included, so a stretch left unread
  would change an answer some route gives.
- **An engine reads every position against the route it holds, and asks for a new route only when
  told** (`geo.navigation.engine-walk`, `sdk/SPEC.md` §14): the arrival is raised where a position
  read on the route leaves no distance to its end, so a traveller who stops short never arrives
  and one at the end's foot but off the route has not; progress is read on every position while a
  route is held, off the route, while rerouting and after arriving included; and only
  `reroute(_:)` asks for a new route, only off the route and once per answer, a failed reroute
  never retried. The conformance runner plays the walk over `ScriptedNavigationEngine`, reading
  `state` once each step has settled, the state committed last, as the contract has a script's
  observer read it.
- **A failure stands through positions and a reroute**, and a start or a route that lands clears
  it. A stop abandons the request in flight and drops its late answer; after `close()`, every
  command does nothing and `state` stays as it was. A close `onChange` makes ends the command it
  was told from too, so what that command would still commit is told to nobody.
- **The scripted engine is the machine with a test for its route source.** Each request it sends
  is a `ScriptedRouteRequest` in `sent`, which the test answers once with `answer(_:)` or
  `fail(_:)`; a second answer throws a `ScriptedAnswerError`, so a test's mistake fails the test
  rather than the process, and a stop or a close marks the request in flight `isAbandoned`.

**The machine is published, and is an engine of its own.** `RouteFollowingEngine(route:)` asks a
`NavigationRouteSource`, the host's `@Sendable` async call, for each route, one request in flight,
each in a task of its own that a stop or a close cancels, so the host's call ends with it and its
answer is dropped, and a task cancelled before it asks never asks; the answer is acted on in the
main actor's next turn. It follows a route on
every platform the package builds on, with the positions a host hands it, which is how a server,
or an app that links Geo alone, follows one, and `DeviceNavigationEngine` is it with a location
source, a voice and the guidance that keeps them to it. It is `sdk-typescript`'s
`NavigationEngine({ route })`, the route source the same seam, and its `onChange` is that engine's
synchronous `subscribe(listener)`, told each change before any stream here is.

**The engine an app navigates with is `DeviceNavigationEngine`**, Geo's machine with its seams
beside it and the guidance that says each maneuver, all of it Swift in this repository and none of
it a navigation library's, as `sdk-dart`'s engine of the same name is Dart over its machine. It
names no platform framework, so it builds and runs its tests on every platform the package builds
on, and takes its seams at construction:

- **A route source**, `NavigationRouteSource<Request>`: an async function the host writes over
  `Mountaya.data.directions`, which is where the Data API's session token comes from, answering the
  `NavigationRoute` to follow, its steps read by `readDirectionsSteps(_:coordinateCount:)` or
  `readItineraryDirectionsSteps(_:coordinateCount:)`. The other routes of `DirectionsResult.routes`
  are the alternatives, which a host that offers one on a reroute keeps itself.
- **A location source**, `LocationSource`, started by the first `start(_:)` and stopped by
  `stop()` and `close()`, each position it states read as `setPosition(_:)` reads one, a refused one
  thrown back to the source: `DeviceLocationSource`, the platform's; `ReplayLocationSource`, which
  walks each route followed at a speed the host names, stating its start before it is done being
  told of the route, so the machine reads a route that lands at the walk's own start, never at
  the position a walk before it left, as `sdk-dart`'s replay states it, and reads its length and
  each tick's position off the route's measure, never measuring the line again;
  `StreamLocationSource`, over an
  `AsyncSequence` of the app's own positions, `sdk-dart`'s `LocationSource.fromStream`, which
  iterates it afresh at each start and cancels it at each stop, and tells its `onError` a position
  the engine refuses and an error that ends the sequence; `InertLocationSource`, the default,
  which states nothing; or the app's own. A source is told of each route followed, `follow(_:)`,
  which a replay walks and the others ignore. The engine closes no source it is handed.
- **A voice**, `NavigationVoice`, handed each maneuver to say: `SpeechNavigationVoice`, the
  platform's speech in the host's words and language, on iOS and in a Mac Catalyst app;
  `InertNavigationVoice`, the default, which says nothing; or the app's own, which is how an app on
  any other platform speaks. An instruction is a key and its arguments, so a voice is where the
  host's strings turn it into words. The engine closes no voice it is handed.
- **No clock of its own.** Nothing the engine decides reads the time: a position is judged by
  where it is. The one seam that waits, the replay, takes the clock, by default the system's
  suspending clock, which stands still while the device sleeps, as `sdk-dart`'s `Stopwatch` and
  `sdk-kotlin`'s `TimeSource.Monotonic` do, so a walk on a device asleep in a pocket goes on from
  where it stood rather than jump ahead by the time asleep, and a test's own where a test paces it.
  It places each position by the time elapsed on it since the walk began, as `sdk-dart`'s replay
  reads its clock, so a main actor too busy to wake the walk on time delays a position and never
  slows the walk.

**How the engine follows a route.** `DeviceNavigationEngine` holds the machine and is told each
state it commits through its `onChange`, inline and before any stream is handed it, so it stands
on the machine's public API alone and no reader sees a route land that the guidance does not
follow yet. At each state, the guidance keeps to the route the machine follows, laid out afresh for
each route that lands, and the location source is told of that route as the guidance takes it up,
so a position a source states the moment it is told is read on that route, as `sdk-dart`'s engine
tells it; then the prompt due at that state is chosen from its progress, `duePrompt(_:progress:)`,
so a fix the machine moves nothing for says no prompt, and a prompt is said once per route and only
while the status is `navigating`. A route that lands while a position is held is guided at that
position's reading, which comes next, so the route unread says no prompt. A new route, a stop and a
close hush the voice, and a close an observer of `state` makes as a start commits its state ends
that start, which then starts no source that nothing would stop. The plan is Geo's measure of the
route, `guidancePlanOf(_:)`: each step's length read off the route's own measure,
`FollowedRoute.measured`, and its prompts, each maneuver announced from the step that leads to it
`promptMeters`, 50 m, before its end, or as the step begins where it is shorter, the departure as
the first step begins, and nothing from the last step. A step of no length keeps no prompt, since
the traveller is never read with ground left on it, even where Geo's progress names it over
vertices that name no place. After a step of length, what it announces moves to the nearest such
step before it, after that step's own prompts and any moved there before, each due as that step
ends, at the vertex the maneuvers share: two maneuvers on one vertex are said in order, the first
50 m out and the second at the vertex, and of three or more the first and the last are said and
those between are not, since of a step's prompts due the last wins and each is said once. Where
steps of no length open the route, the departure, which covers no ground, is dropped, and what they
announce moves to the first step of length, before its own prompts, each due as it begins, so as
the walk begins the last maneuver of the opening vertex is said, or the one ending that step where
it is short enough to be due there too. A route with no step of length, one of a single vertex,
keeps every prompt where it is laid. The prompts are numbered from 0 in travel order once moved,
and `sdk-dart` and `sdk-kotlin` lay the plan out prompt for prompt, as `geo.navigation.prompts`
proves of the plan Geo publishes.

**How a prompt is chosen.** The step read is the one Geo's progress names, held within the plan,
and the first before any position is read; the distance read is what is left to that step's end,
`NavigationProgress.toManeuver`, measured from the traveller's foot on the route, which never
moves back and is found on every stretch ahead, and the whole step before any position. A prompt is
due where that distance less its trigger is 5 m or less, `promptSlackMeters`, and of the step's
prompts due the last wins, the one nearest the maneuver (`geo.navigation.prompts`, `sdk/SPEC.md`
§14). Which of the prompts due the engine says, each once per route and only while it is
`navigating`, is the engine's, and `sdk/SPEC.md` §14 states it as this engine says it. All of it is
host code, tested on every host the package builds on: a route followed fix by fix says each prompt
once, at the meter `sdk-dart`'s engine says it.

**The engine's rules:**

- **Each command has its effect before it returns**, and only the host asks for a route: the
  engine reads no clock, reroutes on no timer, and holds no lock.
- **Every number a user reads comes from Geo**, so the Swift app, the Kotlin app and the Flutter
  app show the same distance remaining for the same route.
- **The step is Mountaya's.** The step a prompt belongs to is the one Geo's progress reads the
  traveller in (`geo.navigation.progress`), so the maneuver a voice announces is the one the screen
  shows.
- **The off-route decision is Mountaya's.** The machine reads it from each position
  (`geo.navigation.off-route`), and the engine says no prompt while the status is other than
  `navigating`.
- **A prompt is Mountaya's too**, chosen from Geo's progress by the trigger rule (above), its
  instruction handed to the voice, and a fix is read as the contract's rules read one, a position
  with no accuracy, course or speed.
- **A failure is Mountaya's too.** `failed` carries a `NavigationError`, the machine's.
- **Permission prompts and background execution are the host's.** The engine never asks for
  location access, and reads with the screen off only where the host asks its location source to:
  both are app-level decisions, with Info.plist keys and review consequences only the host can
  own. A location source reads under a permission the host already holds, so
  `DeviceLocationSource` is Mountaya's, over a `CLLocationManager` of its own, started only while
  the app holds `whenInUse` or `always` at full accuracy, and at once when it is granted both, on
  every Apple platform but tvOS, whose location services update no position as it moves. Under
  reduced accuracy it reads nothing, so a traveller who turned precise location off is read
  nowhere rather than kilometres away, as
  `sdk-kotlin`'s reads nothing on approximate location alone, and it never asks for more: an app
  that navigates there asks for temporary full accuracy itself, on a location manager of its own
  with its purpose string. Its `standing`, a `LocationStanding` of a `LocationAuthorization` and a
  `LocationAccuracy`, is `sdk-dart`'s `standing`, read as the source is made, at each change the
  location services tell and on `recheckPermission()`, which an app calls from the answer to its
  own request, and an `@Observable` property where `sdk-dart`'s is a stream, since a SwiftUI view
  reads one. Its `onError` is told each failure as a `LocationError`, by the table below, and it
  reads on. `backgroundUpdates` turns the location manager's `allowsBackgroundLocationUpdates` on
  as it starts, and only where the app declares the `location` mode under `UIBackgroundModes`,
  which `sdk-dart`'s iOS side checks too: turning it on without that mode ends the app, so the
  request is refused there, `backgroundUndeclared` told, the positions read while the app is in
  use. A Mac app reads in the background as it is, and visionOS reads no location there, so it is
  refused on visionOS. On an iPhone or an iPad a voice is refused the audio session in the
  background unless the app declares the `audio` mode as well, so a source started with
  `backgroundUpdates` where the app declares none tells `audioUndeclared`, and reads on.
- **A failure of the device's location or speech is one value in every SDK.**
  `DeviceLocationSource(onError:)` is told a `LocationError` and `SpeechNavigationVoice(onError:)` a
  `SpeechError`, `sdk-dart`'s and `sdk-kotlin`'s `LocationException` and `SpeechException`, each
  with its `kind`, an open set every SDK names alike (§5), and what the platform reported as
  `cause`, the word `sdk-dart`'s and `sdk-kotlin`'s exceptions and `NavigationError` use:

  | Kind | When | Here |
  | --- | --- | --- |
  | `noProvider` | the device holds no location provider | never: Core Location always holds one |
  | `providerDisabled` | the device's location services are switched off | `CLLocationManager.locationServicesEnabled()` false as the source starts, or `CLError.denied` while they are off |
  | `permissionRevoked` | the app's access withdrawn while the source reads | `CLError.denied` while the services are on, a change of `standing` too |
  | `platformFailed` | any other failure of the location services | any other `CLError`, carried |
  | `backgroundUndeclared` | `backgroundUpdates` without the `location` background mode | no `location` under `UIBackgroundModes`, or visionOS |
  | `audioUndeclared` | `backgroundUpdates` without the `audio` background mode | no `audio` under `UIBackgroundModes`, on an iPhone or an iPad |
  | `engineUnavailable` | the speech engine did not start, told once a voice | never: the system's synthesizer always starts |
  | `audioRefused` | the audio a sentence is said in refused, told once a refusal, the sentence said all the same | the shared `AVAudioSession` refused the voice prompt's category or `setActive(true)`, its error carried |

  A position the location services cannot fix yet, `CLError.locationUnknown`, which they raise
  indoors while they keep trying and Apple asks be ignored, as `sdk-dart`'s iOS side ignores it,
  is no failure and is told to nobody. Whether the services are switched on is asked only where
  the app's access reads denied, which is how the platform reads it while they are off, and off the
  main actor, as Apple asks, since the answer may hold up the thread it is asked on: those two
  failures are told once it comes, the one found as the source starts only while it is still
  started. With no `onError`, every failure is dropped, with no throw and no trap, and a debug
  build prints it once, where a developer reads the console, as `sdk-dart` logs it under
  `kDebugMode` and `sdk-kotlin` where the app is debuggable. A failure is told before the source
  stops, where it stops; neither the source nor the voice stops on one.
- **The rate the device is read at is the host's choice.** `DeviceLocationSource(rate:)` takes a
  `LocationRate`. `navigation` (`Navigation` in Kotlin) is the default: every fix the platform reads
  for a navigation, on iOS at `kCLLocationAccuracyBestForNavigation` with no distance filter, and on
  Android from the GPS provider every 1,000 ms whatever the distance moved. `walking` (`Walking`)
  reads fewer fixes for a traveller on foot: on iOS at `kCLLocationAccuracyBest` with a 5 m distance
  filter, and on Android from the GPS provider every 2,000 ms once the device moved 5 m. Both rates
  read iOS's location as a fitness activity (`activityType` `.fitness`) and never let iOS pause the
  updates on its own. Why 5 m: a maneuver's prompt falls due 55 m before it, its 50 m trigger plus
  the 5 m of slack it is read with, so the fix that says it on time lands between 55 and 50 m
  before the maneuver. Android hands a fix on only once both its time and its distance have passed,
  so up to 2.5 m/s (9 km/h) the 5 m hold a fix back and two fixes stand 5 m apart; faster, the 2
  seconds do, and fixes stand farther apart than the prompt's slack, which is why the rate is a
  walker's.
- **Speech is the platform's, in the host's words.** `SpeechNavigationVoice`, on iOS and in a Mac
  Catalyst app, where the audio session it takes is the platform's, says each sentence through the
  system's speech synthesizer on the main actor, in the order the sentences were handed over. It
  takes the audio session's focus while it speaks, lowering other apps' audio and interrupting the
  spoken audio they play, and lets it go once it is quiet. The system refuses that focus to an app
  in the background that declares no `audio` mode under `UIBackgroundModes`, which is how a
  navigation goes silent with the screen off: each refusal is told to the voice's `onError` as a
  `SpeechError` of kind `audioRefused`, carrying the session's own error, on the main actor, the
  sentence handed to the synthesizer all the same, and none after `close()`. It looks the voice of
  the host's language up as each sentence is handed over, off the main actor, since the system's
  catalogue can take seconds to read the first time, and `prepare()` looks it up ahead of the
  first sentence. Where the device holds no voice for the host's language the sentence is said in
  `fallbackLanguage`, and where it holds none for that either in the system's own voice, as
  `sdk-dart`'s voice falls back. A hush stops the synthesizer before it returns and drops every
  sentence handed over before it, one whose voice is still being looked up included, and the
  system taking the audio for a call or an alarm hushes it too. `close()` hushes it, lets the
  synthesizer go and stops hearing the system take the audio, and nothing is said after it; the app
  that made the voice closes it, as it ends a source it made. A say and a hush take effect in the
  order they were made, never each in a task of its own, so a stop right after a prompt never loses
  its hush and a new route never cuts off its own departure.
- **The voice keeps a queue of its own, the one `DispatchQueue` the products write.** The Swift
  conventions refuse a queue beside structured concurrency, and the voice holds one for what the
  platform makes blocking: `AVSpeechSynthesisVoice(language:)` and the audio session's
  `setCategory` and `setActive` are synchronous calls that hold their thread for as long as the
  system takes, seconds for the first read of the catalogue of voices, and a call that blocks holds
  a thread of Swift's cooperative pool, which has one per core and which every task of the app
  shares. So each lookup, each take and each release of the session runs on the voice's serial
  queue, in the order the sentences and the hushes were made, and each sentence comes back to the
  main actor through the main queue, whose order is the order it was handed in, where two tasks
  made for the main actor are promised none. `prepare()` awaits its lookup through a continuation
  the queue resumes, and the system's interruption, heard off the main thread, reaches the voice
  in a task, since one hush needs no order.
- **No navigation screen ships here.** The screen is `MountayaElements` rendering
  `NavigationState`, or the host's own.

### Views

- **SwiftUI over MapLibre Native**, each view rendering an engine's state (above). `MapView` draws
  the state a `MapEngine` holds: its base map's style, its camera, its labels, and every source and
  layer above the base map, in the order the one layer registry ranks them; the renderer under it
  follows the engine's own stream of states, so it draws every state the engine reports, and it
  tells the engine where the reader moved the camera to, so the state is the map as it is shown.
  Each state sends MapLibre again only the sources it changed, a GeoJSON source given its new
  features in place, so a scrub frame sends the emphasis slot's source alone, where it lights
  another leg, the cursor marker being an annotation (`source-pushes`, §7). MapLibre on iOS, handed
  a feature whose geometry is a GeometryCollection, throws an exception nothing catches and ends the
  app, and a segment's geometry is one (`ItinerarySegment.geojson`), so the renderer hands each
  GeoJSON source, as it is added and as it changes, with such a feature laid out as one feature per
  geometry it holds, each with the feature's properties (`mapLibreFeatures`), which every platform
  draws as it draws the collection. `MapView` is a SwiftUI
  `View`: MapLibre's map is the `UIViewRepresentable` under it, `MapCanvas`, with `MapChrome` laid
  over it, the watermark, the label of the marker tapped last and the readout, so it takes `MapView.init(_:readout:onReady:onTap:onCameraChange:)`,
  the contract's own spelling of the readout's switch, `readout` true where the app states none.
- **A map reads its organization once it is first drawn** (`map.organization.read`,
  `sdk/SPEC.md` §15). `MapView` starts the read as it appears and as it is handed another engine,
  a task keyed on the engine's identity, `MapEngine.beginOrganizationRead()`,
  and `MapEngine.loadOrganization()` asks for it, answering nil for a client holding no
  publishable key, a closed map's included, and never throwing for one, as every SDK's map
  answers, and throwing a `MapError` of kind `closed` on a closed map whose client holds a key and
  which held no answer;
  `MapEngine.organization` holds the answer, observed by every view that reads it. The read is the
  core's `studio.organizations.postOrganizationLookup(body:)`, its key the client's, read through
  `Mountaya.publishableKey`, a `package` declaration, and it is shared through `OrganizationReads`,
  one per process, the main actor's, which holds each answer by its key and the Map Studio API
  origin its client sends to, `baseUrls.rest` as written, for as long as the process lives and
  keeps no failure, so a client pointed at a staging origin never shares an answer with one
  pointed at production; a load is a continuation of the engine's own over that read, so a closed
  map refuses the loads still waiting on it while the read goes on for every other map. Where the
  engine's read stands, `OrganizationRead`, is waiting from its making until a read first answers,
  and a read asked again after a failure, by a load of the host's or a view appearing again,
  leaves it failed until that read answers, so the watermark is never taken off while a retry
  waits. The first read holds the mark off for one attempt's time budget at most, the client's
  `postOrganizationLookup` budget, `Mountaya.organizationLookupBudget`, a `package` declaration,
  35 seconds unless the client names another, waited on the client's own clock through a second
  one, `Mountaya.wait(for:)`: once it has passed with no answer the read stands timed out,
  `OrganizationRead.timedOut`, which draws the mark while the read's further attempts go on, and
  only a later answer of white label takes it off. `MapEngine.organizationRead` publishes where the
  read stands in the five states the contract names and no other (`sdk/SPEC.md` §15), the public
  `OrganizationRead`: `waiting`; `answered(whiteLabel:)`, the organization itself being
  `MapEngine.organization`; `failed`; `timedOut`; and `noKey`, from the making of a map whose
  client holds no publishable key. A host reads it to keep its own interface clear of the mark
  until the read answers white label, as the map's own does. A headless engine, one no `MapView`
  draws, reads nothing until the app asks. The answer serves the watermark alone: no flag, unit,
  language, base map or accent is read from it.
- **A map draws the Mountaya watermark unless its organization holds white label**
  (`geo.organization.watermark`, `sdk/SPEC.md` §15). `WatermarkLink` lays the glyph table's
  `watermark` drawing over the canvas, under the readout and under the panels an app lays over the
  view, in the frame `watermarkOf(_:language:page:)` answers for the engine's read and the scope's
  language, measured from the top-left corner of the map's safe area, `watermarkFrame(_:safeArea:)`:
  180 points wide, its top-left corner 4 points outside that corner, and clipped to the map, so
  its empty margin and its shadow draw over nothing of the app's. The safe area is the part of the
  map the device leaves visible, which `MeasuredMapView`, the subclass of MapLibre's map the
  renderer draws on, measures as its layout, its window or its safe area changes and tells the
  engine, `MapEngine.safeArea`, and again as the map moves in its window with no layout of its
  own, a scroll view's scroll, a sheet's detent, an `.offset` or a transform, which no method of
  the map's own view hears and SwiftUI's `onGeometryChange` in global coordinates tells
  `MapChrome` of: the chrome tells the engine where the map stands, `MapEngine.shown(at:)`, and the
  engine hands each such move to its renderer, `MapSurface.mapMoved()`, whose map measures again
  once the drawing under way ends (`MeasuredMapView.measureLater()`): on each edge the depth the
  view reaches past what its window's own
  insets leave visible, the status bar, a notch or a display cutout and every window inset the
  system reports (`mapSafeArea`), and never the on-screen keyboard, which UIKit leaves out of a
  window's `safeAreaInsets`, as `sdk-dart`'s `view.padding` leaves it out and `sdk-kotlin` reads the
  system bars and the display cutout alone (`CONTRACT-GAPS.md`), so a keyboard coming up moves none
  of the SDK's own interface. It is the inset the operating system reports and never a value an
  app's layout can override, so it never reads the view's own `safeAreaInsets`, which a view
  controller's `additionalSafeAreaInsets` or a SwiftUI safe-area modifier rewrites, and a map in no
  window has none; a map drawn full bleed under SwiftUI's `ignoresSafeArea()` so shows the mark
  below the status bar and beside the Dynamic Island whatever safe area SwiftUI hands the views
  under it. The corner is the one the reader sees at the top left, in a layout that runs right to
  left too, as the contract's "top-left" says: the chrome places the mark, the label and the
  readout by the map's points, which run from its left edge, pinning its own layout direction to
  left to right and handing the reader's back to what it draws, and `MapCorner` names physical
  corners, `topRight` the top right a reader sees in either direction (`alignment(in:)`), so every
  frame a part keeps clear of is in those physical coordinates. Every part of the SDK's own
  interface keeps to that safe area and clear of the mark's frame, the frame held from the map's
  first drawing, while the read waits too, and released only once it answers white label, so
  nothing moves as the mark appears (`isWatermarkKeptClear(_:)`, Geo's, public, which every part
  reads, with the frame it holds from the safe area, `watermarkFrame(safeArea:)`), and so the
  claim that nothing of the
  SDK's own covers the mark holds. A stack, the readout and the marker's label move clear of the
  frame by the smallest move that keeps them inside the safe area, down to the frame's bottom or
  right to its right edge, and where no place inside clears it, open with their top at the frame's
  bottom, the map's edge cutting them (`clearOfWatermark`); a panel moves below the frame and never
  to its right, as every SDK's panel does (`panelPlacement`). The map's edge cuts each part the
  map cannot hold, as `sdk-dart`'s `ClipRect` cuts its readout and its stack's panel and
  `sdk-kotlin`'s `clipToBounds` its readout and its stack (`CONTRACT-GAPS.md`): the watermark, the label and the readout are clipped to the map's canvas, and a stack's panel to the
  map's own rect in the stack's space, `StackPlacement.mapRect(_:in:)`, read off where
  `MapChrome` told the engine the map stands, whatever larger space the stack is laid over, and
  to the stack's own space while no view draws the map. A `MapControls` stack, in whichever
  corner the app puts it, stands 10 points inside the part of its space the map's safe area covers,
  and as far from the frame (`StackPlacement.stackPadding`); a panel opens beside its toggle inside
  that part and clear of the frame (`panelPlacement`); a readout stands with its top-left corner at
  its point, flipped left or up where it would leave the safe area, then clear of the frame
  (`readoutPlacement`); and the label of the marker tapped last stands beside its pin, held inside
  the safe area, then clear of the frame (`markerLabelPlacement`). With a map a view draws, the
  stack reads the map's own safe area and frame through the engine, `MapEngine.safeAreaFrame` and
  `MapEngine.watermarkKeptClearFrame`, each in global coordinates, since `MapChrome` tells the
  engine where the map is laid out, so a stack laid over a space larger than the map, a map below
  a header among them, keeps clear of the frame where the map draws it and never of one measured
  from its own box (`StackPlacement.keptClear`). As SwiftUI lets a `MapView` go, its canvas tells
  the engine the map is drawn by no view, `MapEngine.unshown(by:)` from `dismantleUIView`, unless
  another view drew the engine since, its renderer no longer the surface the engine is drawn on, as
  `sdk-dart`'s `shown(null)` as its view lets the engine go and `sdk-kotlin`'s `unshown` as its view
  leaves the composition do; a view only hidden, under a pushed screen or in another tab, still
  draws its map and keeps its place, as theirs do. `MapView` makes its canvas and its chrome anew
  for another engine, so the engine it drew before is drawn by no view and the new one is told
  where the map stands. A stack over a map no view draws, before
  its view lays it out or once that view went, keeps to the safe area of its own space and holds
  the frame from that safe area's top-left corner as the map's read holds it
  (`StackPlacement.holdsFrame`), so nothing moves as the map appears, and releases it once the read
  answers white label, as `sdk-dart`'s and `sdk-kotlin`'s stacks do. A stack given no map and a
  `PanelControl` out of any stack hold the frame as a waiting read holds it, since neither knows a
  read that could release it, measured from the top-left corner of the safe area of the space they
  are laid in, the stack's space or the control's window, which `WindowProbe` reads off the window
  as `MeasuredMapView` reads a map's, the inset the operating system reports, again as the view
  moves in its window with no layout of its own. A host keeps its own interface clear of the mark
  while `isWatermarkKeptClear(_:)` holds the frame as `MapEngine.organizationRead` stands, by the
  extent Geo publishes, `watermarkWidth`, 180, `watermarkHeight`, 180 × 58 / 138, and
  `watermarkInset`, -4, from the safe area's top-left corner, or `watermarkClearance`, how far below
  the safe area's top the frame ends, as Trail's search box does. `WatermarkDrawing`
  draws it on a `Canvas` from its path data, read once for the process, its gradients a
  `GraphicsContext.Shading.linearGradient`, its opacity the context's, and its drop shadow one
  `GraphicsContext.Filter.shadow` over the whole drawing, of a radius twice the Gaussian's
  standard deviation, the reach a SwiftUI shadow's radius states, clipped to its box. A press opens
  its link in the device's browser through the system's own opener, `UIApplication.shared.open`,
  never the `openURL` action of the view's environment, which an app may replace, as
  BoundaryTests holds by a scan of `WatermarkLink.swift`, and assistive
  technologies read it as a link labelled `watermark.label`. The rule's `page` is a browser's, which
  no map this SDK draws is in, so `MapView` hands none, and its runner hands each case's page to the
  rule, so every case proves the rule itself; no argument of any view or engine hides, removes or
  replaces the mark.
- **A marker's label stands above the watermark, as a popup does, and never over it**
  (`sdk/SPEC.md` §15). The contract puts the mark beneath its popups and has every part of the
  SDK's own interface keep clear of it; the label is SDK-owned, so it is drawn above the mark and
  kept clear of its frame, as every SDK's is. MapLibre's callouts are drawn inside its own view,
  under every SwiftUI view laid over it, so the renderer shows none,
  `mapView(_:annotationCanShowCallout:)` answering false: a tap the engine tells writes the marker
  it fell on to `MarkerCallout`, where the marker holds a label, and clears it otherwise, and every
  move of the camera while one shows is counted there. `MarkerLabel`, laid between the watermark
  and the readout, draws the label 18 points past the marker's point toward the end its text runs
  to, centred on it, held inside the map's safe area and moved clear of the frame by the smallest
  move, the frame held clear while the read waits too, as the readout is
  (`markerLabelPlacement`), on the `tooltip-bg` ground in `tooltip-fg` at a radius of 4 points,
  clipped to the map, follows its marker as the moves are counted, and takes no touch. A marker
  whose point is off the map, or names no place, shows no label, `isMarkerLabelShown`, Geo's, so
  no label is held at the map's edge without its pin, in this SDK or any other
  (`CONTRACT-GAPS.md`). It lays the label out even where none
  shows, hidden, since an overlay reads no alignment guide off a view it holds conditionally, and
  reads its size in the alignment guides themselves, so it is placed in one layout.
- **Each control flag has a fixed default** (`sdk/SPEC.md` §7, §15). `MapControls`' flags are plain
  `Bool`s, `zoom`, `compass`, `layers` and `preferences` true and `geolocate`, `pois` and
  `offersTime` false where the app states none, and a flag it states stands. The preferences
  panel's own set starts at the SDK's default units, `UnitPreferences(language:)`, in the scope's
  language; the engine labels its map in the app's or the client's language, else the device's,
  and draws the base map the app names, else the catalogue's first terrain, in the variant the app
  names, `MapEngine(terrainVariant:)` light where it names none. The markers and the controls take
  the accent of the tokens around them, the host's.
- **A long press opens a readout of the point** (`map.readout.open`, `geo.readout.rows`). The
  engine opens it, `MapReadout`, with what it queries at the point, the topmost point of interest
  and zone and the first feature of the classic overlay drawn there stating a `minValue` or a
  `maxValue`, and at the detail zoom reads the terrain through `ElevationReads`: the catalogue's
  elevation source, its TileJSON read once for its address, and every tile the point needs at once,
  in the order `elevationTilesAt(_:source:)` answers them, by `x` then `y`, each through
  `Mountaya.mapFile(at:operationId:)`, a `package` declaration of the client that sends a Tile API
  address through the transport under the map's credential; a tile's image is read into its pixels
  by `PlatformElevationDecoder`, ImageIO and Core Graphics, a seam, on the shared pool, off the main
  actor, `@concurrent`, so a decode never holds a frame, no dependency is added and a platform with
  no codec, Linux, reads no terrain. The point of interest's category is the one its tile states,
  the OpenMapTiles `subclass`, else its `class`, and the band is read off the classic overlay's own
  layers alone, the first of its features stating either bound. A zone's are its feature's `name`,
  `description`, `level`, `start_at` and `end_at`, the two times JSON numbers of seconds truncated
  to the whole second, and a time written as a string read as none. A tap closes it, and so does a
  camera move as it starts: a move the reader makes
  as it begins, the renderer telling the engine `readerMoveBegan()` from MapLibre's
  `mapView(_:regionWillChangeWith:animated:)` for any reason that is no program's, and a move the
  app or a control asks for as it is asked, since the engine reports where it lands at once.
  Closing or replacing it cancels the reads of its terrain still out, each tile read a child task
  of the read, and an answer for a readout closed or replaced since lands nowhere. Its tiles
  leave in the order the rule answers them because each is sent once the one before it has left:
  `Mountaya.mapFile(at:operationId:departed:)` tells its caller as each attempt is handed to the
  client's exchange, so no executor's scheduling reorders them. A zone's level is the printed
  `RestSchema.ZoneLevel`, read off the tile as written, so a level the vocabulary does not name is
  kept and shown as spelled. `ReadoutCard` draws its rows on the panel's ground, 288 points wide,
  its top-left corner at the point, flipped to stay inside the map's safe area and kept clear of
  the watermark's frame (above), the moment
  on the clock of the view's environment, followed live while the card is open, the band as it
  was read at the press, and every moment in the time zone the device keeps, `deviceTimeZone()`, a
  seam over the system's own zone, never SwiftUI's `\.timeZone`, which an app may state for a
  view, nor a default an app states for its process; the system answers it at once, so no moment
  is ever written in another zone while the device's is read; where the locale services know no
  zone of its name, `formatDateTime` answering nil, the row or the line that would carry the
  moment is left out, the band's time, the moment's row and a zone's window, the window whole
  where a bound it states cannot be written (`ReadoutCard.windowMoments`), never written in UTC,
  as an ISO string or as an empty word, as every SDK's readout leaves it out
  (`CONTRACT-GAPS.md`); each figure in the SDK's default
  units and the scope's language, the classic overlay named in the scope's language, as every other
  word of the card, through the names `MapReadout` keeps of it, the aspect in whole degrees beside
  its direction's word, `123° · South-East` (`formatAspect`), and a copy button that writes the
  pair to `UIPasteboard` and reads `readout.copied` for a second.
- **The map's state is MapLibre's style, in the style document's terms.** A layer is `MapLayer`:
  its type, its source and source layer, its `paint` and `layout` properties under their style
  names as `JSONValue`, its filter and its zoom window, and its rank. The renderer makes MapLibre's
  style layer of the type and sets each property under the name MapLibre gives it, which is the
  style name in camel case but for the thirty-eight MapLibre renames, the same across the range
  §10 takes, each value handed to MapLibre's own expression parser as a style document's
  is, a color written as a string read by that parser rather than cast; MapLibre refuses a value its
  style does not take by raising, as it refuses one in a style document. A source is `MapSource`:
  the Tile API's vector tiles, a raster's or an elevation raster's, read from a tile specification
  as it is answered, or GeoJSON the app holds; a source of a type the contract does not declare is
  refused before anything of its specification is drawn, `typeRefused`, and a raster's tile size a
  specification leaves out is MapLibre's own, 512, as it is GL JS's (`map.specification.style`). A
  base map is the style document at a URL: a terrain of the Tile API's catalogue, `getTileLayers`,
  which `MapEngine.setTerrain(_:)` shows, the one of the slug named or the first, in the variant
  `setTerrainVariant(_:)` asked for last, light until dark is named, or a style of the app's own,
  `setStyle(_:)`, under which a variant switches nothing (`map.basemap.terrain`).
- **MapLibre Native is the sole renderer core.** A view that draws a map draws on MapLibre's own
  map, and no product links a platform map framework or a second map engine beside it, because a
  second renderer is a second copy of every style and layer rule the contract states once.
- **Each view takes its own `on*` handlers, and its words from the scope around it**, so a host
  wires one view without configuring every other, and localises one by stating a scope on it
  alone: `.mountayaScope(_:)` nests an `ElementsScopeStatement` in the scope around a view
  (`geo.i18n.nested-scope`), carried by SwiftUI's environment as `\.mountayaScope`, which SwiftUI
  itself nests. Each view that speaks words takes its own `strings` too, `[String: String]?`, as
  `sdk-kotlin`'s and `sdk-dart`'s widgets and `sdk-typescript`'s components do: a word at its path,
  `controls.zoomIn`, replaces the scope's for that view alone, a counted word's every form, and
  every other word is the scope's, an app's own words among them, so a view's words are layered
  over the app's rather than resolved afresh as a nested scope's are. The view lays them over the
  scope SwiftUI's environment carries once a drawing, through the internal `ViewScope`, holding
  the scope it lays by one reference, and hands them to its own parts, its rows and its panels,
  through one modifier every view shares, `ViewWords`, and never to an app's view: `MapControls`
  hands its words to its own controls and panels, and none to the controls an app places among them.
  The fourteen that take them are `ZoomControl`, `CompassControl`, `GeolocateControl`,
  `DirectionsControl`, `DownloadControl`, the three panels, `MapControls`, `SearchControl`, the
  three data elements and `WaypointCard`; `PanelControl` and `Glyph` are handed their words.
- **The colours are the contract's tokens, and the rest is the platform's.** Every view draws in
  the elements' tokens, `\.mountayaTokens` in the environment, `ElementTokens.standard` unless
  `.mountayaTokens(_:)` states others, each read under the colour scheme in force through
  `themeTokenValue(_:in:)` (`geo.style.theme-tokens`), SwiftUI's dark scheme reading the dark
  values. The environment holds the tokens by one reference, `SharedTokens`, which the views read
  them through, `\.sharedTokens`, a token read off it as off the tokens themselves: SwiftUI's
  `Environment` stores the value it reads inside the view, so a view reading the tokens whole
  carried every token, two colours each, and every copy, move and release of the view copied,
  moved and released them all, code repeated in each view's value witnesses, about 14 KiB a view
  and 440 KiB of every app over the 28 views that read them. A reference made anew for equal
  tokens compares equal, so a host stating its tokens again as it draws draws no view of the
  elements again. The scope is held the same way, `SharedScope`, which the views read it through,
  `\.sharedScope`, a setting and a word read off it as off the scope: a view reading the scope
  whole carried its language, its locale, its words and its two glyph sets, and the 17 views that
  read it so, with `ViewScope` and the statement every other view's scope comes through, carried
  20.7 KiB of every app (21,147 bytes of the app the size gate measured as the time slider landed).
  `\.mountayaScope` stays the scope an app states and reads. Sizes, radii, fonts, paddings and shadow geometry are the platform's (Q15): a
  control is 44 points across, the touch target Apple's guidelines name, where the web's is 36 pixels, and
  everything else a reader presses, a row, a chip, a search's clear button and its retry, a
  profile's pin, is pressed anywhere in a span of at least 44 points each way, `TouchTarget`, a
  32-point chip keeping its look in a transparent margin. The contract gives a design system to the
  studio binding, which this SDK does not have, and a host's modifiers stand over a view as over
  any other.
- **A control that holds the keyboard's focus draws a ring** (`sdk/SPEC.md` §7, which no fixture
  holds). Every button the elements draw, a map's control, a panel's row, a search's clear button,
  filter chip, retry and result row, a waypoint table's service chip, a profile's pin and a leg's
  chip where the app listens for its press, is drawn in `ElementButtonStyle`, which draws
  `FocusRing` while the button holds the focus the platform's focus system moves, a hardware
  keyboard's or Full Keyboard Access's, read off SwiftUI's `isFocused`: a ring 2 points wide in the
  `focus-ring` token under the scheme in force, inside the control's frame, or around the chip a
  label draws inside a wider touch target. A touch or a pointer presses a button without focusing
  it, so a press leaves no ring behind it. The platform's own focus effect is turned off on each,
  `focusEffectDisabled()`, so the ring is the one focus indicator shown, and the token is a colour
  of its own, which a consumer's accent does not move, standing at least 3 to 1 against the panel in
  both schemes as WCAG's success criterion 1.4.11 asks.
- **The platform's accessibility settings are honoured.** Where the reader asked the device for
  reduced motion, SwiftUI's `accessibilityReduceMotion`, every camera move a control starts lands at
  once rather than travelling: a zoom step, a compass reset, a located fix framed, the ease into an
  overlay's zooms and a search's pick, whose fit lands at once and whose flight is a jump. `MapView`
  and each control tell their map, which holds the setting for the moves its controls make, and a
  move the app makes itself travels as it asks. Text grows with Dynamic Type: a profile's distance
  axis and its chips, fixed rows on the web, are as high as their text at the reader's size, the
  axis measuring its places' names at the size it draws them, so a larger size is drawn whole
  rather than clipped.
- **The map's controls are a stack laid over it** (`sdk/SPEC.md` §7, which no fixture holds,
  Q22). `MapControls` sits in one corner, `MapCorner.topRight` unless the app names another, read
  as the reader sees it whichever way the text runs, and reads from the top: `ZoomControl`; the
  layers, points-of-interest and preferences toggles as one group; the app's own controls, its
  content; `GeolocateControl`; `CompassControl`. Each shows where its flag, at its fixed default
  where the app states none, turns it on (above). A control
  drives the map only where a map or a handler stands in for its default: each takes the map, nil
  included, and a handler of the app's in its place, `onZoomInTap` and `onZoomOutTap` half by half,
  `onTap` for the compass and the locate control, a handler alone driving where it stands in; one
  with neither is inert. An action control, `DownloadControl` and `DirectionsControl`, drives
  nothing but its required `onTap`. A disabled flag is SwiftUI's own, `.disabled(_:)`, which shuts
  every control under it, drawn in `control-fg-disabled` and never dimmed again by a button style.
  Zoom in is disabled at the window's ceiling and zoom out at its floor whoever answers the press
  (`zoomControlsDisabled(at:)`).
- **One panel is open at a time.** `PanelControl(_:label:glyph:help:content:)` opens a panel of
  its own beside it, the `MapPanel` it names showing its `content`, and a toggle in a stack opens
  its panel in place of any other, the stack's own and the app's alike, through the stack's open
  panel, `MapPanel?`, which the app may hold itself, `openPanel:`, a `Binding` being the pair. In a
  stack the panel is drawn by the stack, over the map it is laid over and inside it, as `sdk-dart`
  and `sdk-kotlin` draw theirs: the toggle tells the stack where it stands and what its panel shows,
  `OpenPanelPreference`, since a toggle's chip clips what it holds, and the panel opens beside it,
  toward the inside of the map's safe area, level with it, `panelGap`, 8 points, apart, and lays out
  by `geo.panels.layout` against the safe area's size with the toggle's top in it as its top inset,
  a narrow safe area's panel filling its width less 10 points each side and one beside a toggle in
  its lower half rising inside it, then moved clear of the watermark's frame by the smallest move
  and laid out from there, below the frame and never to its right (`panelPlacement`); a tap on the
  map closes it, as a tap outside a popover did. A panel control out of any stack holds its own
  word and draws its panel beside its chip the same way, inside the safe area of the window it
  stands in and clear of the frame a waiting read holds from that safe area's top-left corner,
  since it knows no map whose read could release it (`AlonePanel`), as `sdk-dart`'s
  and `sdk-kotlin`'s open theirs beside the toggle, each in a space and at a width of its own,
  which `CONTRACT-GAPS.md` sets side by side: the part of the window the device leaves visible
  here, 340 points wide where it is wider than 576 and its width less 10 each side otherwise;
  while it stands in no window, it draws the panel under its chip. The stack's layers toggle opens a `LayersPanel` over a `LayersSelectionEngine` the
  stack holds for its map, configured only while the toggle stands, so a stack with no layers
  toggle reads no catalogue, and hands it the stack's `offersTime:` and `thumbnail:`, so an app
  turns the time and the pictures on in one place; the points-of-interest toggle a `POIPanel` of the concepts the map
  draws; and the preferences toggle a `PreferencesPanel` over `unitPreferences:`, or a set the stack
  holds in the scope's language where the app hands none. A panel is as high as its sections up to
  420 points, as `sdk-dart`'s is; once they are laid out taller they scroll inside that height, or
  inside the height the panel is offered where that is less, so a panel of many rows never grows
  past the screen.
- **A locate control never asks for access.** `GeolocateControl` shows a `GeolocateControlEngine`
  over its map, configured as the view appears and as its map changes, drawn in the `accent` while
  busy, its description the blocked one, "allow it in your settings" (Q7), while the permission it
  read without prompting answers refused and only once it has read the map it shows. `onTap`
  stands in for the fix, for an app that runs its own flow, its prompt included, and `isLocating`
  then says when the app's own fix is out; `onError` is handed each failed fix of the control's.
- **The panels lay out as the embed's do** (`geo.panels.layout`). `MapControls` measures the map
  it is laid over and how far down its toggles' group ends, and states the
  `panelLayout(mapWidth:mapHeight:topInset:)` it answers to its panels through the environment:
  `PanelSurface` is then 340 points wide, or the map's width less the stack's padding on a map no
  wider than 576, under a title row naming the panel by its control's word that stays while its
  body scrolls past the layout's height. The layer cards stand three to a row, 77 points high,
  their pictures 52 points tall, 40 on that narrow map, and `PreferencesPanel` draws each option as
  a `PreferenceCard`, two to a row, 57 points high, the border `accent` while it is ticked. A panel
  outside a stack lays out as on a wide map, scrolling past 420 points.
- **The panels draw the pickers' models** (`geo.layers.picker-rows`, `geo.layers.poi-rows`,
  `geo.units.preference-choices`). `LayersPanel` lists its selection's catalogue in the scope's
  language, in the map studio's sections: the terrains as picture cards, three a line, each the
  picture `thumbnail:` hands for its choice and slug above its name, or its name alone; the
  enrichments as the platform's switches, a `Toggle` in the switch style tinted in the `accent`,
  each on or off by itself, a locked one showing its lock and `layers.locked` in place of its
  switch; the classic overlays as cards of one
  category at a time behind a segmented `Picker` of the categories, drawn where two or more hold
  an overlay, the category picked held as the panel's state for as long as it lives; and the time
  where `offersTime:` says the host offers it. It carries out a press through the selection, a
  locked entry's press handed to `onLockedTap` and selecting nothing. The time section,
  `LayersPanelTime`, lays its track out around the clock SwiftUI's environment carries,
  `\.mountayaClock`, a `WallClock`, the system's unless a host states its own, each time the panel
  draws, the clock `ReadoutCard` reads the moment it shows on too: its caption, `layers.timeHint`,
  `layers.timeKeyboard` where `HardwareKeyboard` finds a keyboard connected (`GCKeyboard`), and
  `layers.timeNote`; the thumb's readout, its moment written by the locale services in the scope's
  locale and the time zone the device keeps, `deviceTimeZone()`, never SwiftUI's `\.timeZone`,
  which an app may state for a view, as `ReadoutCard` writes its moments
  (`geo.layers.time-readout`), then ` · `, then its offset counted as
  `countedText(_:count:language:)` counts, the offset alone where the locale services know no
  zone of that name, never a moment written in UTC or as an ISO string; and the slider, drawn on a
  `Canvas`, its track filled in the `accent` from the stop of now to its thumb, ticked every day
  with the labelled days' words beneath, 48 points high, dragged to its nearest stop and pinning
  on release, stepped one stop by an arrow key while it holds the keyboard's focus, ringed by
  `FocusRing`, and by an assistive technology's adjustment, its value the readout. A clock that
  reads no instant holds it, under `layers.timeUnavailable`, and nothing is pinned. `POIPanel` reads the map's concepts at the points of
  interest's band and shows or hides a row's keys, unless `onToggle`, `onToggleGroup` or
  `onToggleAll` stands in, its note standing below `minZoom` and no panel at all where the map draws
  no point of interest; `PreferencesPanel` holds no set of its own, writing the app's
  `Binding<UnitPreferences>` back whole and relabelling the map for a language. Each row, card and
  switch is the platform's touch target high and read as selected while checked. A card and a
  switch of `LayersPanel` and a row of `POIPanel` is a part of its own that SwiftUI draws again
  only where what it shows or asks for changes, and presses through `PanelPress`, which the panel drawn last answers, so a row kept as
  it was drawn presses through the panel as it is now; a panel drawn again for a zoom note, a
  sibling's press or its host's own redraw redraws no row it did not change (`panel-rows`, §7).
  The points-of-interest note compares the live zoom with the floor in a view of its own, as a
  store's selector does, and what it says is drawn again only as the comparison flips, never once
  per zoom frame (`zoom-threshold`, §7).
- **The search box shows a `SearchEngine`** (`sdk/SPEC.md` §7), the app's where it hands
  `engine:`, as `sdk-kotlin`'s and `sdk-dart`'s boxes take one, and its own otherwise. Its own is
  made with no transport, so a control SwiftUI makes and drops asks nothing, and handed one as it
  appears: the app's `fetch`, else its map's client, `search(input:)`, as the map's content reads
  through it; with neither it is inert. The app's engine is the app's: the box shows it and drives
  it, never configures it nor closes it, its configuration standing in for the box's `targets`,
  `language`, `limit`, `wording` and `fetch`, and its failures reaching its own handler rather than
  the box's `onError`. It states its map's camera to the engine each time the map holds another,
  an engine the app hands keeping its own where the box has no map, and its own engine starts
  confined to the visible area of its map (Q21), with no map confining nothing and showing no
  toggle, where an engine starts unconfined unless its app states otherwise. Its text and its
  scope are the app's where it hands `query` and `isConfined`, each a `Binding`, kept in step with
  the engine both ways, and the engine's otherwise; each edit of the field and each press of the
  toggle is told to the engine through the binding the control hands them, since SwiftUI hands a
  view an app's binding as it stood when the view was drawn, and a text the app writes reaches the
  engine as the binding changes. The list shows while the focus stands anywhere in the control,
  its box, a filter chip, its scope's toggle, a retry or a row, each bound to a part of one
  `FocusState`, `SearchPart`, over a query that is not white space alone, and the reader has not
  dismissed it, as Geo's `isSearchListShown(hasFocus:query:isDismissed:)` answers and every SDK's
  control shows its list, so focus moving from the box to a chip keeps the list there; a pick
  dismisses it and takes the focus out of the control, and an edit or the focus coming back to the
  box lifts the dismissal; and the engine is told so, which alone lets a camera at rest ask
  again: the filter chips, the toggle, the note of a fall back, a line for each failed branch, the
  elements' own word `search.error` beside its retry, `search.retry`, and never the message the API
  wrote, which is English whatever the reader's language and stays on the branch's
  `SearchBranchError` for the app to log (`geo.search.list-state`), the rows, each its title, the runs the query matched set strong, and its second line,
  an itinerary's distance and ascent in the control's `units` behind an ascent's arrow and a
  collection's count behind an itinerary's glyph, a bar while a round is in flight, and the empty
  state; its status line is announced to assistive technologies. Every word is the scope's
  `search` and `profile` sections, and every colour a token under the colour scheme in force. A
  pick dismisses the list and leaves the control; it moves the map's camera as `pickTarget(_:)`
  answers, a fit through `fitBounds(_:with:)` and a flight to `pointZoom`, each landing at once
  where the reader asked for reduced motion, and hands its mark to
  `setSearchHighlight(_:accent:)` in the accent the tokens read, nil included, which takes the
  mark before down; `onSelect` stands in for the whole pick. The control takes its map's search
  highlight down as it leaves the screen or is handed another map, as `sdk-typescript`'s does as it
  unmounts. A round's language is the scope's, `dataLanguageFor(_:)`, unless the app states one.
- **The data elements read an itinerary by id through the app's cache, or through the app's
  engine** (`sdk/SPEC.md` §7). `ItineraryProfile`, `ItinerarySegmentTable` and
  `ItineraryWaypointTable` each make an `ItineraryResourceEngine` of their own as they first ask,
  so an element SwiftUI makes and drops asks nothing, and configure it as they appear, asking
  again where the id, the surface or the cache changes; or each shows the engine the app hands,
  `init(engine:…)`, an initializer of its own as `sdk-kotlin`'s overloads are, so the compiler
  holds an element to one reading, the app choosing the itinerary through the engine's
  `configure(cache:itineraryId:surface:)`, and the element never asking it nor closing it. Each
  failure to read is handed to `onError` once and draws the empty state: the internal
  `FailureRelay` follows the engine's `subscribe()` from before the element first asks it, the
  engine the app hands in place of another from then on, and
  hands each failed state the stream yields to the handler of the latest drawing, so a read asked
  again after an invalidation that fails in turn is heard too, though whether the element shows a
  failure has not changed, and no failure is heard twice. What each draws is read once
  from the answer: the geometry its curve walks, a chain the app states, `legs`, being the curve in
  place of the itinerary's own, the server's figures over the geometry's, the legs as rows and the
  places as profile places and rows. Every word is the scope's `profile`, `table`, `amenities` and
  `waypointCard` sections, every figure written in the element's `units`, the scope's language in
  metric where it names none, every colour a token, and a cut-off and a `date` field are written
  only by the app's `formatCutoffAt`, the time zone being the app's.
- **The profile is drawn where the rules place it.** `ItineraryProfile` draws the strip, then the
  chart: the elevation scale's lines, the leg `highlighted` names tinted under the curve, the area
  and the line in the accent or in the gradient its `coloring` paints (`ProfileColoring`: plain,
  stretches of the app's, the slope's buckets, Geo's `slopeBuckets` where the app names none, as
  `sdk-dart`'s and `sdk-kotlin`'s slope defaults to them, or the app's classes, which the card
  names), the drop
  line under each place that divides the itinerary, a dashed mark at each cut-off, a pin on the
  curve at each place with its services stacked above it, the cursor and its card. The `parts` the
  app asks (`ProfileParts`) add the elevation and distance scales, the places' names under the
  axis culled where crowded, the services, the card at the cursor (the strip then stating the
  itinerary alone), a chip per leg and a navigator over the window, whose handles and the window
  itself a drag moves through the scrub's columns. A leg's chip is a button where the app hands
  `onSegmentTap`, the segment table's own word for a press of a leg (`sdk/SPEC.md` §7): a press
  hands over the id `geo.profile.row-match` answers to, `group:` then the group's id for a
  collapsed group, and writes nothing to the map, and a disabled profile presses nothing; where the
  app hands none, a chip is no button, offered to neither the keyboard nor assistive technologies. The window is the app's where it hands a
  `Binding`, the profile's own otherwise, which a new itinerary resets. A drag or a pointer over the
  chart reads the column under it, an assistive technology steps the cursor a sample at a time, and
  an itinerary with no altitude states its empty line. A scrub draws the cursor alone, as
  `sdk-dart`'s chart does: the curve's area and line are built once for a series, a domain and a
  window and held across the profile's renders, `ProfileCurves`, and the layer they and their marks
  are drawn in is drawn once for what it takes into an image the chart shows until that changes,
  the cursor's rule and dot drawn in a layer of their own above it, so moving the cursor builds and
  draws nothing of the curve again (`profile-cursor`, §7). Where the cursor stands is held apart
  from the profile's root, `ProfileCursor`, and read by the parts it moves alone: the cursor's
  layer, the card at it, the strip where it states the cursor, and what assistive technologies
  read of the chart. The root, the chart, its pins and services, the axes, the navigator, the
  chips and the bands read none of it, so a scrub redraws none of them, and the root, which reads
  the whole itinerary again as it draws, never (`scrub-root`, §7).
- **The tables are a row per leg and a row per pass.** `ItinerarySegmentTable` states each leg in
  its `columns`, its sparkline, `ItinerarySparkline`, the whole curve in the `table-spark-base`
  token with the leg lit in its colour; `ItineraryWaypointTable` states each pass, with a chip per
  service over the rows that the app holds in `picked` or the table holds itself. A row is the
  touch target high, lit while pointed at, and a leg's row while the map's own cursor is over its
  leg, as its `map`'s `featureHover` names it (`hoveredLeg`), a collapsed group's row standing for
  each of its members, or, where the app names a row in `highlighted`, that one in its place
  (`isSegmentRowLit`, `map.profile.table-rows`); a tap hands its id to `onSegmentTap` or
  `onWaypointTap`. `WaypointCard` draws a place's card on the
  panel's ground: its mark in the place's colour or the card's own, its name and headline, and
  each section only where it states a line, a web address a `Link` and any other address text.
  A `Link` opens through the `openURL` action of the view's environment, the system's unless an
  app states its own around the card, `.environment(\.openURL, OpenURLAction { … })`, which takes
  every link the card draws over, as `sdk-kotlin`'s card opens through Compose's
  `LocalUriHandler` and `sdk-dart`'s hands each to `onLinkTap`.
  Each photo, at a web address alone, is drawn by the view the app's `photo` builds for it, its own
  image loader's or its cache's, as `sdk-dart`'s `photoBuilder` and `sdk-kotlin`'s `photo` draw
  one, and loaded by `AsyncImage` where the app hands none.
- **A data element writes its links to the map beside it** (`map.profile.cursor-marker`,
  `map.profile.emphasis`). While a reader points at a profile's sample, a segment row or a place's
  row, `MapLink` pins one marker on the element's `map` under the element's own `markerId`, the
  three defaults apart so a profile and two tables over one map never move or take down each
  other's marker, drawn with `cursorMarkerGlyph`, which the bundled marker set draws as the pin's
  dot (C40): at the sample, at the sample nearest the leg's end, or at the sample nearest the
  place's pass, the earlier of two samples as near (`segmentRowTarget`, `waypointRowTarget`, which
  `map.profile.table-rows` runs on every host). A profile and a segment table light the leg pointed
  at on the map's emphasis slot in `emphasisColor`, the later of two legs at the meter they share. Pointing where the element
  already points writes nothing; the element takes down only what it wrote, as the pointer leaves,
  as it is disabled and as it leaves the screen. An `onHover` handler takes the links over: it is
  told the sample or the row, the leave once, and the map nothing. A disabled element draws and
  drives nothing.
- **One layer registry.** Every layer a view adds to a map goes through one registry that reads
  `geo.layers.order`, so a layer's rank is the contract's and never the order in which code
  happened to add it. `MapEngine.addLayer(_:)` and every content the map draws add through it, a
  tile specification's layer at the rank `tileLayerRank(_:ranks:)` reads off its source layer in
  the map's own table, `MapEngine(paint:)`'s `layerRanks`: a layer of a greater rank draws above
  one of a lesser, two of one rank in the order they were added, the later above, and every one
  above the base map's own layers and MapLibre's, which take no rank. A layer placed again at the
  rank it holds keeps its place and takes its new definition, and one placed at another rank moves
  to the top of its new band; a content drawn again is taken off first, so its layers take the top
  of their bands (`map.layers.rank-insertion`). The renderer is the one place a layer reaches
  MapLibre's map (§7).
- **The escape hatch is MapLibre's own map.** `MapView`'s ready callback, `onReady`, hands back the
  `MLNMapView` once its first style is loaded, so an app reaches what this SDK does not wrap without
  waiting for it. MapLibre is a `public import` in `MountayaElements` for that reason and nowhere
  else (§7).
- **Tile credentials are attached per request, and only to the Tile API.** MapLibre also fetches
  styles, glyphs and sprites from hosts that are not Mountaya's, and a credential sent there is a
  credential leaked; the TypeScript SDK's `transformRequest` draws the same line. MapLibre iOS
  offers two places to touch its requests, and both are process-wide: its network configuration's
  `sessionConfiguration`, whose headers ride every request to every host and which takes effect
  only before the first map, and its delegate's per-request callback, `willSendRequest:`
  (`willSend(_:)` in Swift), which is handed each request before it leaves, on a thread of
  MapLibre's own, and answers the request to send. The hook is the second: it is the one that
  sees the URL a credential is claimed by, and it is MapLibre's own counterpart of the
  `transformRequest` every other binding uses. MapLibre holds the delegate weakly and documents it
  as unstable, so `MountayaElements` owns that slot, keeps its delegate alive itself
  (`MapRequestHook`), and takes an app's own hook to compose with rather than being replaced by it:
  `MapEngine(transformRequest:)`, handed each request as a `MapRequest`, its URL and its headers,
  a value of Mountaya's own that every platform has, is called first, the URL it answers is the one
  the credential is claimed by, and a header it sets stands over the client's. Every map shown
  holds the hook at once, from its renderer's making to its end, as `sdk-dart`'s and
  `sdk-kotlin`'s maps hold theirs: a request is handed the app's hook of the map shown last that
  names one, and the credential of the map shown last whose client claims the URL that hook
  answered, and a request made while no map is shown carries nothing of any client's. A
  request is the Tile API's where it lies under the client's Tile API base URL at a segment boundary
  of its path, its scheme and host read without regard to case and its port with the scheme's
  default (`isTileRequest`, the TypeScript SDK's claim by origin), and is given what
  `Mountaya.mapRequestHeaders(for:)` answers: the credential as every route a map fetches for
  itself declares it, the model's `templates`, which all act as nobody, take a share token on its
  own and require no session token, with the session snapshot read for that request (§4), so a
  refreshed token reaches the next tile, the client's language, and `X-Mountaya-Client`, which
  names this SDK and its version beside the credential as it does on every call (§4). It reads the
  session token as it stands and never waits, and MapLibre's own loader makes the request, which
  is how the contract has a map library's requests leave (`sdk/SPEC.md` §1): no first session
  token is waited for, so a tile asked for while one is on its way goes out under the key alone,
  and a refusal of it that arrives once the token has landed is told to nobody
  (`map.events.access-refused`); no `onResponse` hook is told of it, it carries no rate-limit
  state, and MapLibre repeats it on its own schedule. A tile the client's own methods read is held
  to all three.
- **A redirect carries a credential to the Tile API alone.** MapLibre's loader follows a `3xx`
  with the headers its request left with, to any host. MapLibre 7 asks its network configuration's
  delegate for the session each request leaves on, `sessionForNetworkConfiguration:`
  (`session(for:)` in Swift), and the hook answers one session of its own, made from the
  configuration MapLibre holds, the app's where it set one, and made again where that is replaced.
  Its delegate hears a redirect and nothing else, since MapLibre refuses a session whose delegate
  reads data: it takes off every header the hook and the app's hook set, gives a header they
  replaced back MapLibre's own, and applies the maps' rules again for the address the redirect
  leads to, so a redirect to another host carries no credential and one within the Tile API carries
  the credential read again. The API is one MapLibre calls experimental (§11).
- **A failed answer is told to the maps that claim it, at the address the map asked for.** The
  delegate hears each answer's status and the address its last hop went to, and names no request,
  so the hook keeps, beside what each request left with (below), the address MapLibre asked for,
  before the app's hook and any redirect, a redirect moving it with the rest to the address it
  leads to. An answer from 400 up is told at that address, not one a redirect led to, since it is
  that address which lies under a source's tile templates or names the style asked for
  (`sdk/SPEC.md` §15), to every map shown that claims it: one of its own sources' tile templates up
  to their first `{`, or its style's directory, the style's address before any query up to its
  last `/`, which holds what a Mountaya terrain names, its TileJSON, tiles, sprites and glyphs. A
  request that reached no answer, an offline tile or a host that does not answer, reaches the
  delegate with the error the loader failed with, which names the address its last hop failed at:
  it is told as a `failure` with no status at the address MapLibre asked for, as
  `map.events.access-refused` tells a failure carrying none, and as `sdk-dart`'s and `sdk-kotlin`'s
  maps tell theirs, but one MapLibre withdrew, `NSURLErrorCancelled`, a tile it no longer needs or
  a style another replaced, which is no failure, and one whose error names no address, which no
  map could claim. So is a request the client refused (below), which fails in the process at an
  address of its own the hook keeps the asked one by. An answer no map claims is told to the one
  map shown where only one is, and to none where several are (§11). What MapLibre's threads tell
  the maps, each failure and each tile a map parses, reaches the main actor in the order it was
  told, a burst of it in one hop: the first of a burst asks for the hop, which hands on everything
  told until it runs, so a storm of refused tiles is one hop rather than one a tile, as
  `sdk-kotlin`'s and `sdk-dart`'s maps batch theirs. A map reads its claims once for the sources
  and the style it draws, and again only once a state it draws changes either, never once a
  failure.
- **A style that failed is told once, as the hook told it.** MapLibre tells a style that did not
  arrive apart from its answer, through `mapViewDidFailLoadingMap`, with no status, and the
  renderer gives the map back the base map it showed (`map.basemap.replay`). The hook hears every
  answer before MapLibre does, and the renderer tells it, before it asks MapLibre for a style, the
  style's address, so the hook keeps how it told a failed answer at the address of a style a map
  shown asks for, a refusal of access, a 401, a 402 or a 403, told or told to nobody (below), or a
  `failure`, with its status or with none where it reached no answer, until the address is asked
  for again; a tile's answer it keeps for nobody, so no storm of refused tiles pushes a style's out,
  and it keeps at most 1,024, the oldest forgotten first. The renderer that finds its style's own
  address there, however the style was redirected, tells nothing beside what the hook told, as
  `map.events.access-refused` has a refusal never also a failure, and still gives the map back the
  base map it showed; one it finds nothing for arrived and MapLibre could not read it, a document
  that does not parse, which it tells as a `failure` with no status. The layers manifest is the
  engine's own read, whose one failure is told once, as a refusal or as a failure, never both.
- **A refusal of a credential the map no longer sends is told to nobody** (`sdk/SPEC.md` §15).
  MapLibre's delegate hears an answer with no request, so the hook keeps the client's headers each
  request's last hop was sent, what `mapRequestHeaders(for:)` answered as it was signed, by the
  address that hop went to, a redirect moving them to the address it leads to, read again there,
  until its answer, a request that reached none forgetting them where its failure names its
  address; it keeps them for at most 1,024 addresses awaiting an answer, past which it forgets the
  oldest first, as `sdk-typescript`'s map forgets the credentials its requests left with, since
  MapLibre may never answer a request it withdrew and what such a request left with goes before
  what a request still on its way did, and an answer at an address forgotten is told as it is
  (§11). As an answer arrives, the headers are read again for the address its last
  hop went to, under the same choice of the map shown last whose client claims that address:
  where they differ from those kept, a session token since replaced or minted after the
  request left under the key alone, or a visitor's cookie since changed, or where the read throws,
  the request left under a credential the client no longer sends, and each map claiming the
  address is told so with the failure. Its engine tells a 401 or a 403 of such a request to
  nobody, neither as `accessRefused` nor as a `failure`, and starts and keeps no refusal standing
  (`refusesSupersededCredential(_:superseded:)`), and a 402, which refuses the organization rather
  than its credential, and every other failure, as they are (`map.events.access-refused`,
  `map.events.access-standing`). A map's style refused that way is asked for again, once an ask,
  where it would otherwise give the map back the one it showed, the renderer finding the refusal
  the hook kept at its address (above); a style refused so again gives the map back the one it
  showed, told to nobody. `ScriptedMapSurface.failRequest(url:status:source:superseded:)` plays
  such a failure for an app's tests and the conformance runners.
- **MapLibre's own compass gives way to the elements'.** MapLibre shows a compass of its own on a
  rotated map, which would stand beside `MapControls(compass:)`'s: `MapView` shows none, as
  `sdk-dart`'s map shows none, and keeps MapLibre's credit button at the bottom right.
- **A credential the map attaches is held to the client's checks before the map makes any
  request.** An empty key, a wrong prefix and a character no header carries are refused where the
  client is built, so no map can be given one, and a secret key is unavailable on every app
  platform; on macOS and Linux, where the map's engine builds, `mapRequestHeaders(for:)` refuses a
  secret key, which authenticates no route a map fetches. A session token a function or a source
  answers per request is checked at that request (`sdk/SPEC.md` §1), and a request whose token is
  refused never leaves: the hook hands it back for an address of its own under a scheme no loader
  serves, so it fails in the process, MapLibre reports its resource failed, and the hook tells it
  as a `failure` with no status at the address MapLibre asked for (above), carrying what the read
  of the credential threw as its `cause`, as `sdk-dart`'s and `sdk-kotlin`'s failures carry one:
  the engine tells a failure carrying a cause whatever status the request would have met, and
  `ScriptedMapSurface.failRequest(url:status:source:superseded:cause:)` plays one. A failure's
  cause is for diagnostics, and two events are never compared by it. The client's language rides every tile request
  as it rides a call, `Accept-Language: *` where the client names none, so a platform loader writes
  none of the device's.
- **The labels speak the client's language.** A map given no label language takes the one its
  `Mountaya` sends as `Accept-Language`, then the device's, read through `Seams/`, so the labels on
  a map and the words the API answers in are one language (`geo.style.label-language`). The engine
  relabels every symbol layer of the base map from the label its style wrote, through the surface
  that draws it, by `relabelTextField(_:language:)`, leaving a label as written where it cannot be
  relabelled without changing what it says (`geo.style.label-relabel`), and putting back as written
  one it rewrote before where a new language leaves it so; it never relabels a layer the map placed,
  which draws from a source the base map knows nothing about, and relabels again every base map a
  switch brings in, as the style loads (`map.style.label-scope`).
- **The map and editing engines are the binding's.** How a patch merges onto what a map holds
  (`map.engine.patch`) and where an edit's magnet lands (`map.edit.snap`) are the `map` layer's
  rules, held in this product (§2, §6) and applied by its engines to MapLibre's map. A patch's
  member written as absent leaves the held one as it is, which in Swift is a member written `nil` in
  a patch of optional members, `[String: JSONValue?]`, distinct from one set to a value, JSON's
  `null` (`.null`) among them: `MapEngine.editLayer(_:paint:layout:)` merges one onto a layer's
  paint and layout, where `null` sets a property back to the style's default, and refuses a layer
  it does not draw with `MapError`. The magnet, `snapToActiveSegments`, measures in the screen's
  density-independent pixels, iOS's points, as `sdk-kotlin` measures in Android's `dp` and
  `sdk-typescript` in CSS pixels, through the renderer's own projection as the map is drawn, MapLibre's `convert(_:toPointTo:)`
  and back, within `snapThresholdPx`, 40, on the main actor, where that projection reads its map.
- **A waypoint is placed by an edit, a tap at a time.** `MapEngine.beginWaypointEdit(_:at:)`
  begins placing a waypoint of the app's, and `endWaypointEdit()` ends it, a save and a cancel
  alike, answering the edit as it stands, a `WaypointEdit`: where it was placed and whether the
  magnet placed it. While it lasts, each tap on `MapView` places it,
  `placeWaypoint(at:through:)`, the tap's longitude read within [-180, 180] and the magnet asked
  through MapLibre's projection, on the active segments the app sets apart,
  `setActiveSegments(_:)`, none turning the magnet off; a tap the edit takes is told to no handler.
  The projection is a `ScreenProjection`, two `@MainActor` functions, so a consumer drawing a map
  of their own places a waypoint through their renderer's. It is `sdk-typescript`'s point waypoint
  engine, a tap where the browser clicks (`sdk/SPEC.md` §15).
- **A map draws its content in slots, each drawing its latest request**
  (`map.slots.latest-request`). `setItinerary(_:fit:)` and `setCollection(_:fit:)` draw an itinerary
  and a collection by id, their specification read through the client,
  `getItinerarySpecification` and `getCollectionSpecification`, and answer whether they drew;
  `setItineraries(_:)` and `setZones(_:)` switch the credential's itineraries and zones on or off,
  a toggle switched on while drawn reading nothing; and `setSpecification(_:named:)` draws a
  specification the app holds under a name of its own, `removeSpecification(named:)` and
  `clearSpecifications()` taking it off. A slot asked for again draws in the place it was first
  asked for, and a clear forgets it. A read that answers after a later call for its slot, or after
  the slot's clear, draws nothing, its call answering false. A fit is read before anything is read
  or drawn, and frames once the call drew: an itinerary's on the box its segments span, read beside
  its specification through `getItinerary`, and a collection's on the box its specification
  states (`geo.camera.content-bounds`).
- **A call is withdrawn by cancelling its task**, Swift's own withdrawal, where `sdk-typescript`
  takes an abort signal: withdrawn before it drew, a call throws `CancellationError` and gives its
  slot back to the request it superseded; withdrawn after, nothing changes. Since every Swift call
  can be withdrawn, a request a later call superseded waits for that call to draw, end or be
  withdrawn, and answers false only once it settles, as `sdk/SPEC.md` §15 has a language whose
  every call can be withdrawn answer (`map.slots.latest-request`). A toggle and a specification in hand take their slot for good. Every read
  runs in the task of the call that asked for it, the engine starting no task of its own, so a
  call's priority and its cancellation reach its read.
- **A base map switches whole, and the map's content is drawn again on it**
  (`map.basemap.terrain`, `map.basemap.replay`). The latest base map asked for wins, and
  `state.terrain` and `state.terrainVariant` name it, the variant the drawn document's where a
  terrain's two variants are two documents and the one asked for last otherwise; a slug the
  catalogue refused is never asked for again by a variant switch. Every layer the map draws is
  drawn again on the base map a switch brings in, at its rank and hidden where the app hid it, a
  layer the app added by hand with `addLayer(_:)` included: the contract leaves that one to each
  SDK (`sdk/SPEC.md` §15), and MapLibre Native makes carrying it over the simplest, since the
  renderer reconciles the state, every layer it holds, onto each style it loads. A document that
  does not arrive, MapLibre iOS's `mapViewDidFailLoadingMap`, gives the map back the base map
  shown, its style, terrain and variant, and the renderer loads that style again and draws the
  content on it; that load answers nothing, so a refusal of the switch's style stands through it
  until a style the map asks for loads (`map.events.access-standing`). The base map shown is the one whose style MapLibre loaded: the renderer draws the
  states the engine reports a turn later, and MapLibre drops a style's load as another is asked of
  it, so a style told loaded, from MapLibre's cache or not, is the one the renderer drew last,
  credited as itself even where a later base map was asked for before it was told, and a failure
  is held to that style too, the failure of one a later base map replaced giving nothing back.
- **The layers catalogue is read once per studio scope** (`map.layers.manifest`). `loadLayers()`
  answers `getTileLayers`, held as `layersManifest` and shared by every load until
  `setLayersOrganization(_:)` moves the scope; each read that lands is told as `layersChange` with
  the catalogue held, nil where a move dropped it, so a reader of `events()` needs no read-back. A
  read that fails is kept by nobody, and one landing after the scope moved answers its loads the
  current scope's catalogue. `setTerrain(_:)`, `setOverlay(_:)` and `addEnrichment(_:)` resolve
  their slugs through it, and a closed map answers the catalogue it held, else throws `closed`.
- **A map draws one classic overlay and stacks enrichments** (`map.overlays.composition`).
  `setOverlay(_:)` draws an overlay in place of the one drawn before and `addEnrichment(_:)` adds
  one on top, in the order first added, each easing the camera into the zooms it paints across; a
  slug the catalogue holds as the other kind is refused as `kindMismatch`, and one it holds under
  neither as `overlayNotFound`. `clearOverlay()`, `removeEnrichment(_:)` and `clearEnrichments()`
  take them off, and `enrichments` lists the slugs drawn.
- **A map draws the classic overlay the server stamps for the instant pinned**
  (`map.overlays.instant`). `setInstant(_:)` pins it, and `instant` reads it; the engine keeps the
  classic overlay it draws with the catalogue it was found in, and draws each address of its
  sources as `timestampedSources(_:overlay:at:)` stamps it, or as the manifest wrote it with none
  pinned. A pin that moves rewrites the tiles of the overlay's sources in the state alone, its
  layers left where they stood; MapLibre Native builds a tile source with its addresses and takes
  no others after, so the renderer replaces a source whose addresses moved, under the same id, and
  makes the layers drawing from it again at their places, where MapLibre GL JS's `setTiles` swaps
  them in place. An overlay drawn later is drawn for the pin, the pin outlives a cleared overlay,
  and a base-map switch draws the state's sources again, so it keeps the addresses asked for. An
  enrichment and a classic overlay the server does not stamp are drawn as the manifest wrote
  them, and a stamped tile refused is told at the address it was asked at, as any of the map's own
  requests (`map.events.access-refused`).
- **A layer's visibility is the app's word, kept by its id** (`map.layers.visibility`).
  `setLayerVisibility(_:visible:)` holds it before the layer is drawn, so it is born hidden,
  across a base-map switch and through a redraw of its content, until that content is cleared or
  the layer removed, and `isLayerVisible(_:)` reads it; a hidden layer keeps its place and its
  tiles, its layout carrying `visibility: none`. A concept is the catalogue's key a layer carries,
  `MapLayer.key` (`map.layers.keys`): `drawnLayerKeys(rank:)` lists the concepts drawn in the order
  their content was first asked for, `layerIds(forKey:)` names a concept's layers, and
  `setKeyVisibility(_:visible:)` and `isKeyVisible(_:)` show, hide and read them all. The wire's
  empty key names no concept (`map.layers.keys`).
- **A plain map draws an itinerary's restricted stretches** (`map.road-access.layers`). Beside the
  first itinerary line of every specification the map draws, whatever its slot,
  `roadAccessLayersOf(_:isShown:)` adds the stripes over each stretch at
  `LayerRank.itineraryRestriction` and its kind's warning icon at the waypoints' band, both reading
  the tiles' `itinerary_restrictions`, shown until `setAccessRestrictionsVisibility(false)`, which
  `isAccessRestrictionsVisible` reads. Their layers stay drawn while hidden, so showing them again
  fetches nothing, and one the app hid by its id stays hidden either way. The renderer answers the
  stripe image a kind names, `road-access-stripe-` then the kind, with that kind's stripe tile, and
  a warning icon is a marker sprite, as a waypoint's is.
- **A Data API result is drawn under an id of its own** (`map.analysis.slots`,
  `map.analysis.layers`). Each kind has an add that asks the client and one that draws a result the
  app holds, asking nothing, both answering an `AnalysisHandle`, its id and its result:
  `addDirections`, `addSuggestions`, the candidate at `chosen` solid and the rest dashed,
  `addIsochrones`, `addPlaces` and `addMatrix`, whose result is handed over with its input, since
  its connectors run between the input's locations. Results accumulate, each drawn from a source of
  its own under `analysis:<kind>:<n>`, one count across every kind, at its kind's band, and taken
  off by `removeAnalysis(_:)` or by its kind's clear. Points of interest are one result at a time,
  `setPointsOfInterest(_:fit:)`, under `MapEngine.poisAnalysisId`, `analysis:pois`. An edit asks
  again with a patch, `((inout Input) -> Void)?`, applied to the input held, and with no patch
  redraws the result held under the draw options it states, asking nothing (`map.analysis.edit`);
  it refuses an id nothing is drawn under, `analysisNotFound`, a result of another kind,
  `kindMismatch`, and a patch for a result handed over, `noInput`. A query runs in the caller's
  task, raced against an abort: a later edit of its result, its removal or its kind's clear cancels
  it, and the call throws `CancellationError` (`map.analysis.requests`).
- **Three geometry slots draw over the content** (`map.geometry.slots`, `map.geometry.layers`).
  `setGeometry(_:in:color:)` draws a geometry in the `preview`, the `highlight` or the `emphasis`,
  in the slot's own colour where it names none, `editGeometry(in:geometry:color:)` changes what it
  names, `clearGeometry(in:)` takes the slot down and `geometry(in:)` answers what it holds;
  writing one slot never clears another, and a slot holding nil draws nothing. Each draws from a
  source of its own as the itinerary's cased line in the map's paint, the highlight adding a
  circle for a point, at its band: the highlight at the chrome band, 100, above every content, and
  the preview and the emphasis at `LayerRank.itineraryFocus`, 52, just above the itinerary lines,
  so the order the calls arrive in never stacks one under the route it lights.
- **A picked result is drawn above everything else** (`map.search.result-highlight`, Q5).
  `setSearchHighlight(_:accent:)` draws a `SearchHighlight` from a source of its own,
  `mountaya-search-highlight`, at the chrome band, apart from the geometry slots, in the accent it
  is handed, the standard light one where a caller hands none, whatever tokens the app restyled and
  whatever scheme is in force, so a list of an app's own hands it the accent its tokens read under
  the scheme in force, as `SearchControl` does: a place as the point-of-interest
  pin carrying `point`, or `map-pin` where the map's glyph set holds no point, a marker sprite the
  renderer answers as it answers a style's; a point of interest as its category's own pin in its
  category's colour, its feature carrying its category, and one of no category the table styles as
  a place; a way as its line under a halo and a white casing with a dot at each end, the dots a
  circle filtered to the collection's points, else its extent washed and outlined dashed, its east
  edge a turn further east where it crosses the antimeridian, else a pin at its anchor. The latest
  call wins, nil takes it down at once, a closed map draws none, and it is drawn again on every base
  map a switch brings in, since the renderer reconciles the state onto each style it loads.
- **Markers stand above everything the map draws.** A `MapMarker` is the map's own, its id, its
  position, its color, its glyph and the label a tap on it shows, which `MarkerLabel` draws over
  the watermark (above), drawn by MapLibre as an annotation, never a layer of the style: it takes no rank, survives a change of base map and is
  never relabelled. It is shown as a pin (`map.marker.pin`): a disc 28 points across in its color,
  the elements' `accent` token, the host's as the next sentence reads it, where it names none, ringed in
  white 3 points wide inside that diameter, with its glyph of the engine's set in white in the
  16-point square at its centre, or a white dot 8 across where it names no glyph or the set cannot
  draw the one it names, over a soft shadow, as the web map's pin is. The accent is the host's:
  `MapView` hands its renderer the `accent` token of the tokens around it, read under the colour
  scheme in force, as SwiftUI draws the view again, and a new accent draws the look of the pins
  naming no colour again, the ring of the waypoint being placed included. A pin is drawn once for
  each look, its fill, its glyph and, where it names no colour, the accent, and every marker of
  that look is shown through the one image, as `sdk-dart`'s map registers one image per look,
  however often a marker moves (`pin-images`, §7); a
  change of the markers is one change to the annotations shown, a marker kept moved and relabelled
  in place and given the pin of a look it changed to, and only a marker added or dropped added or
  removed, every one shown again only where the markers kept change their order, so the last stays
  on top. `addMarker(_:)`,
  `editMarker(_:position:color:glyph:label:)`, `removeMarker(_:)` and `clearMarkers()` answer as
  `sdk-typescript`'s do (`map.marker.lifecycle`): one under an id in use replaces it, on top; an
  edit keeps the marker's place among the others and every member it is not given, and refuses an
  id not shown; a position is two numbers or three, the third an altitude a marker drawn flat
  ignores, while the camera still refuses a third number, and one that names no place a map draws
  is refused. A tap on one is `MapView`'s `onTap`, told its id, since a value that holds a closure
  does not compare.
- **The camera is held to a pan lock and a zoom range.** `setMaxBounds(_:)` reads a lock as a box
  is read, each axis ordered and the latitudes held within the map's, a lock a turn or more wide
  written as the whole world (`maxBoundsLongitudes(west:east:)`), and refuses one that encloses no
  area (`refusesMaxBounds(_:)`) with `MapError`, the engine being where that refusal is raised; nil
  lifts the lock. `setZoomBounds(min:max:)` moves each limit a call states and keeps the other, a
  `ZoomLimit` that is `.kept`, `.released` or a zoom, a released limit going back to the renderer's
  own, MapLibre Native's floor of 0 and ceiling of 25.5, the window the contract names for every SDK
  that draws on MapLibre Native, a floor under 0 refused (`sdk/SPEC.md` §15), and refuses a limit
  that is not finite and
  a window a camera cannot take (`map.camera.zoom-window`), the renderer's limits read off the
  surface that draws the map. The engine holds the camera's zoom within the range itself, so its
  state is the camera shown. MapLibre holds what the
  view shows within the lock, `maximumScreenBounds`, so the view zooms out no farther than the
  zoom at which it fits within the lock, as the web's `maxBounds` holds it and as `sdk-kotlin`'s
  renderer holds it over MapLibre Android, which bounds the camera's center alone. MapLibre iOS
  moves the camera into a lock before it holds the screen within one, so the first lock a map is
  given would hold the camera's center alone until the camera next moved, the view showing up to
  half its size past the lock: the renderer hands each lock over twice, which holds the screen at
  once. After a change of limits the renderer tells the engine where MapLibre holds the camera, and
  tells it nothing where the engine holds another camera by then, one the app set since, which the
  renderer shows next; a camera the app sets is drawn as set and held by MapLibre, the state
  keeping the app's. MapLibre iOS may move the camera after a limit change asynchronously, so where
  it has not moved it as the limits were handed over, the renderer reports the held camera at its
  next programmatic rest, where MapLibre Android applies a bound at once. MapLibre iOS publishes no way back from holding the screen, so a lifted lock
  leaves the view held within the world's edges, the antimeridian a wall, where a map never locked
  crosses it; `sdk-kotlin`'s lift hands MapLibre Android no bound at all, so its view crosses it
  after a lift too.
- **A map draws the marker and stripe images its style names.** MapLibre asks its delegate for an
  image a style names and does not hold, `mapView(_:didFailToLoadImage:)`, on the main thread as it
  lays a symbol or a patterned line out, and the renderer answers where the id names a marker
  sprite (`readMarkerImageId(_:in:)`, `map.icons.missing-image`): the sprite of that glyph of the
  engine's set, `MapEngine.glyphs`, the bundled marker set unless the app hands in its own, on a
  disc of that colour, which MapLibre adds to the style under the id; and where it names a
  restricted stretch's stripes, `road-access-stripe-` then a kind of the vocabulary read scalar by
  scalar (`readRoadAccessStripeImageId(_:)`), the stripe tile of that kind. Any other id stays
  missing, as MapLibre leaves it, a stripe id whose tail is no kind among them, as
  `sdk-typescript` leaves one. A plain `MapView` answers them, so an itinerary's waypoint pins, its
  restricted stretches and a map's points of interest draw with no editor, as `sdk-typescript`'s
  plain map answers them. The answer is synchronous, the image drawn by CoreGraphics in
  microseconds, so no image waits on a later layout as an asynchronous answer would.
- **A sprite is drawn at the size its rule states, in points.** A marker sprite is a 48-point
  `UIImage` drawn at the screen's density (`markerSpriteImage(_:figures:)`,
  `map.icons.marker-sprite`): the disc filled with the feature's colour, its border stroked
  centred on its edge, and the glyph's shapes, read through `parseGlyph(_:)` and never drawn as
  handed over, fitted to the 24-point square at its centre and painted in white as
  `glyphPaint(_:in:)` answers, each shape's transform applied as it is drawn so a stroke scales
  with it as SVG scales it. It renders in its own colours, never as a template MapLibre would
  recolour. A restricted stretch's stripe tile (`stripePatternImage(_:)`,
  `map.icons.stripe-pattern`) is drawn the same way, at 16 points, for the stripes of
  `map.road-access.layers`, and so is a marker's pin (`markerPinImage(_:accent:in:)`,
  `map.marker.pin`), 28 points across, its ring drawn inside its diameter and its glyph fitted to
  the 16-point square at its centre; a pin's fill that is no CSS hexadecimal colour fills no disc,
  as a sprite's does.
- **A glyph's geometry is SVG's, read by this SDK.** No Apple framework reads SVG path data, so
  the renderer reads each shape into a SwiftUI `Path` itself (`shapePath(_:)`, `svgTransform(_:)`):
  SVG 1.1's path grammar, every command, implicit repetition, smooth curves and elliptical arcs
  drawn as cubic curves of a quarter turn at most, up to the command holding the first error as
  SVG draws a path in error; a circle, an ellipse, a rectangle with its corners as SVG 2 lays them
  out, a line, a polyline and a polygon; and a transform list, refused whole where any part is not
  SVG's. CoreGraphics draws no `arcs` or `miter-clip` join, so both are drawn as a miter, as SVG
  asks of a renderer that draws neither, and the miter limit is set on every stroke, since
  CoreGraphics' default is 10 where SVG's is 4. The grammar is not contract (`sdk-kotlin` reads it
  with a port of this reader, since Compose's own parser departs from SVG on several edges), and
  it is proven on the simulator against every bundled glyph. A glyph's markup is read once: its
  figures are kept by the process's `GlyphFigureCache`, under the markup and the paint and width of
  its set, for every later drawing of it, a control drawn again, a pin and a sprite, as `sdk-dart`
  keeps a glyph's parsed figures per set.
- **`Glyph` draws one glyph in SwiftUI.** `Glyph(_:in:size:color:label:)` draws a glyph of the set
  it is handed, the control set of the scope SwiftUI's environment carries where it is handed none
  (`\.mountayaScope`, the bundled control set where no scope states another), in a square of its
  size, 16 points unless it names another, on a `Canvas`, each shape painted as
  `glyphPaint(_:in:)` answers in the colour it is handed, or, where it is handed none, in the
  `control-fg` token of the tokens SwiftUI's environment carries under the colour scheme in force
  (`\.mountayaTokens`), as `sdk-kotlin`'s and `sdk-dart`'s glyphs are drawn. The views of the
  elements draw their faces' glyphs in the foreground style they set around them, internally, so a
  control's glyph takes its state's colour, disabled or busy. A glyph the set does not hold is drawn as nothing
  and takes no room, as a control draws a glyph its set cannot (`geo.icons.glyph-fallback`). It is
  hidden from assistive technologies unless it is given a label. It is the `Glyph` component of
  `sdk-typescript`'s React binding, and the nil it takes for its set is the scope's control set, as
  `sdk-dart`'s is.
- **The engine asks what draws it, and what draws it tells the engine.** What only a renderer
  knows, its canvas, its projection, the features it drew at a point, the layers and sources its
  live style holds and its base map's labels and credits, the engine asks of the surface it is
  drawn on, `MapSurface`, an internal protocol `MapView`'s renderer conforms to and the engine holds
  weakly, and it hands that surface each move of the view drawing the map, `mapMoved()`, so a
  renderer measures again what it reads off the window; what happens on the map, a tap, a long press, a hovering pointer, a frame drawn, a request
  failed, a tile and a style loaded and the camera at rest after the reader moved it, the surface
  tells the engine, which applies the contract's rules and tells the host. A map no view draws has
  no canvas and no projection: it frames nothing, answers no feature and projects to `[NaN, NaN]`.
  `ScriptedMapSurface`, published under `Map/Testing/`, plays such a surface for an app's tests and
  for the conformance runners, which drive the real engine through it as `sdk-typescript`'s drive
  its map over a stand-in of MapLibre.
- **The camera moves by what a move states.** `jump(to:)`, `ease(to:)` and `fly(to:)` take a
  `CameraTarget`, each member it states handed to the renderer and every other kept where the camera
  has it, a centre past the antimeridian handed on as written, and refuse before anything moves a
  centre that names no place, `positionRefused`, and a zoom, a bearing or a pitch that is no finite
  number, `numberRefused` (`map.camera.pose`); the state holds where the move lands and the renderer
  animates there, MapLibre's camera built from the zoom through `MLNAltitudeForZoomLevel`.
  `fitBounds(_:with:)` and a drawing call's `fit:` read a `CameraFit` before anything is read or
  drawn, a padding or a duration not finite from 0 up or a ceiling not finite refused as
  `numberRefused` (`map.camera.fit-options`), and the renderer frames the box with
  `cameraForBounds` on its own canvas, facing north and keeping the pitch. `zoomIn()`, `zoomOut()`
  and `resetNorth()` ease to `controlMoveTarget`'s camera, a step one level from the zoom held and
  within the window, a reset turning the bearing and the pitch to 0, which MapLibre iOS's own reset
  of north does not (`map.camera.control-moves`). `locate()` asks the map's `Geolocation` for one
  fix and frames the box its accuracy spans at zoom 16 at most; a fix refused moves nothing and
  throws `fixRefused` with its reason, `denied`, `noApi` or `unavailable`, and a closed map throws
  `closed` without asking (`map.camera.locate`). `DeviceGeolocation`, the default, never asks the
  reader for access: a fix asked for before the app holds a permission answers `denied` and its
  permission reads `prompt`, and one under reduced accuracy answers `denied` too, as the navigation's
  device source reads only full-accuracy positions. It answers a fix the device made within
  `locateMaxFixAge`, a minute, at once, and waits `locateFixWait`, ten seconds, for one before it
  answers `unavailable`, the two published beside the seam so the fixture's constants hold them on
  every host.
- **A point query answers what the map placed, as GeoJSON features.** `features(at:)`, `pois(at:)`,
  `zones(at:)` and `itineraries(at:)` ask the renderer only about the layers the map placed in the
  bands each reads that the live style still holds, in the order the map placed them, and nothing
  where none is left (`map.query.layers`), and answer each feature as a `QueriedFeature`, its id, its
  string, number, boolean and null properties, its geometry, and the layer and source layer that
  drew it, once per layer (`map.query.feature-shape`). MapLibre iOS answers a feature with no layer,
  so the renderer asks each layer alone, topmost first. `project(_:)` and `unproject(_:)` read the
  renderer's projection. `elevation(at:)` asks the Data API for the terrain sample there, its
  elevation alone, and is no read of the drawn terrain (`map.query.elevation-at`).
- **A map tells what happens on it through `events()`**, a stream per reader, as `subscribe()` hands
  states: a tap and a long press, each a `MapTap`, its longitude brought within [-180, 180] only
  where MapLibre read it past that range, the topmost marker within 22 points named; a tap that
  lands on features the map drew, told again as `featureTap` with every such feature topmost first;
  each told to nobody while a waypoint is being placed, whose edit takes both (`map.events.pointer`).
  A hovering pointer, a trackpad's, a mouse's or a pencil's over an iPad (`UIHoverGestureRecognizer`),
  never a finger, is told once a display frame where it ended, with the features of the itinerary
  line and point bands under it, and with none as it leaves (`map.events.feature-hover`). A request
  of the map's own that MapLibre's network delegate hears answered 401, 402 or 403 is told as
  `accessRefused` with its status and address, and never as a `failure`, which any other status is,
  the layers manifest's refusal included at `layersManifestAddress`, but a 401 or a 403 of a
  request that left under a credential the client no longer sends is told to nobody (above,
  `map.events.access-refused`); a refusal stands in `state.isAccessRequired` until a tile of its
  source loads, MapLibre's `tileDidTriggerAction` telling a tile parsed, handed on in order with
  the hook's failures, or, naming no source,
  until the next style loads, one told to nobody starting none, and the end of the last is told
  once, `accessRestored` (`map.events.access-standing`). A tile parsed while no refusal stands
  answers nothing and reads no state, so a map loading tile after tile compares no state for
  each. `MapView`'s
  `onTap` is handed each tap the engine tells, and `onCameraChange` the camera each time it comes to
  rest, after the reader moved it or the app did, as `sdk-typescript`'s `moveend`; no handler is
  handed every frame of a move, which would draw a SwiftUI view again at the frame rate. SwiftUI
  hands the view new handlers as it draws it again, and the renderer takes them.
- **A map credits what it draws.** `credits` is Mountaya's credit first, then each source a layer
  draws at the camera's zoom by the credit it states, the base map's as MapLibre reads them, a
  source named by its TileJSON's address crediting its TileJSON's where the style states none, and
  then the map's own, each once by its exact text and a blank one left out
  (`map.style.attribution`); the order is the renderer's and no answer, so the fixture's credits
  are compared as a set, and `ScriptedMapSurface.baseSources` reports a base map's sources as the
  renderer does. The
  renderer's credit button opens a sheet of them, `creditSheet(_:open:)`, in place of MapLibre's own,
  which credits no Mountaya on a map that draws only its base map.
- **A closed map is inert** (`map.engine.closed`): a command does nothing, a drawing call by id
  reads and draws nothing and answers false, a point query answers no feature, a projection no
  number, `locate()` is refused, `loadLayers()` answers the catalogue it held and throws `closed`
  where it held none, every stream ends so nothing is told, `state` and `credits` read as the map
  ended, and `elevation(at:)` and a Data API result's add and edit, which read through the client,
  still answer, drawing nothing.

## 9. Conformance

`Tests/ConformanceTests/` loads `sdk/registry.yaml` from the sibling `schemas` checkout and runs
each entry's fixture against this SDK. **The registry is the port manifest, and there is no
other**: a list of what this SDK has ported, kept beside the registry, is a second registry that
disagrees with the first.

- **One test per case, named `"<id> · <case>"`**, so a failure names the capability and the case
  without opening the fixture.
- **Scoping is by layer.** Every `studio.*` entry is reported `scoped`, because §11 puts the
  studio out of scope, and it is reported rather than skipped: a skip is indistinguishable from a
  runner nobody wrote. One entry is scoped by id, `transport.browser.secret-key`, because this
  SDK publishes no browser target (§11). Nothing else is: `transport.browser.cookie-mode` is run
  (§4), and so is every `map.*` entry, since this SDK drives a renderer. Any other entry with no
  runner fails the gate, and the list of those entries is the work left.
- **A runner for an id the registry dropped fails too**, since it proves a rule the contract does
  not declare.
- **Every published name is declared, or its capability scoped.** A coverage test of its own,
  `everyPublishedNameIsDeclared`, reads the registry's `swift` column for every capability the
  scope table does not scope and fails where no declaration of the five API baselines
  (`Tests/BoundaryTests/Baseline/`), the admin unit's read beside the core's as `sdk/SPEC.md` §9
  asks, stands at exactly that path (§5), so `constructWebhookEvent`'s name is held to
  `MountayaAdmin`'s listing and `WebhookSignatureError`'s to `MountayaClient`'s, listing each as
  `<id>: <name>`; another, `swiftColumnFollowsTheScopes`, fails where the column says `scoped` and
  the scope table runs the capability, or lists names where the table scopes it. A fixture proves
  what a rule answers and never what it is called, so the names are held to the API a consumer
  builds against, which BoundaryTests holds the baselines to, `MountayaNavigation`'s and
  `MountayaElements`' iOS-only declarations included (§7). `mise run ci:coverage` runs both beside
  the runners' coverage test.
- **An `api: true` entry runs through a plain `import`** of its product, which proves a consumer
  can reach the capability. An `api: false` entry may reach internals through `@testable import`.
  The suite depends on `MountayaAdmin` as a server does: `transport.webhooks.verify-signature` runs
  through its `constructWebhookEvent`, and the envelope's fixture, whose REST cases call operations
  of the `admin` group, through `mountaya.admin`, each in a file that imports the unit.
- **Floating point compares within the fixture's `tolerance`**, as `sdk/SPEC.md` §10 defines
  its three kinds, `absolute`, `relative` and `angular`, and exactly where none is stated. A kind
  the harness does not know fails the fixture, and the harness reads every fixture the registry
  names, a scoped one included, so a new kind is caught the day it lands.
- **A number JSON cannot carry is decoded before a case runs.** `{ "$number": "NaN" }` and the two
  infinities become Swift's `Double` values, and a number that is not finite agrees with itself
  alone under any tolerance.
- **A set is compared as a set where the contract says so.** A runner answering values whose order
  is no part of the answer, a map's credits (`map.style.attribution`), answers them as members,
  each expected value matched by one answered, none left over, whatever the order.
- **A refusal names the class, never the message**, spelled as `sdk/SPEC.md` §3 spells it. One
  fixture, the scoped `browser-secret-key.json`, still writes a refusal as `error` with `throws`,
  and the runner reads that spelling beside `refused`.
- **Two strings compare by their scalars.** `OrderedJSON`'s equality reads a string's Unicode
  scalars, never Swift's `String` equality, which is canonical equivalence, so a fixture that
  writes two spellings of one text, `geo/i18n-bundle.json` restating a word, catches an SDK that
  reads them as one (`sdk/SPEC.md` §7).
- **Time is simulated where a fixture measures it.** A runner that measures a wait, an attempt's
  budget, a first token's wait or a stream's silence runs its case in `Tools/Simulation`: every
  task of the case runs on one serial task executor, and a virtual clock moves on only when that
  executor has nothing left to run, to the earliest instant a task sleeps until. The client is
  given that clock through its `clock` seam, and the runner's scripted `HTTPExchange` answers on
  it, so a case of 240 seconds runs in microseconds and the same way on every host. Code a
  simulation runs keeps to structured concurrency, since a `Task {}` leaves the executor. Its
  wall clock is the simulation's too, `Scripted.Wall`, from the fixtures' day forward, and its
  draws and its keys `Scripted.Random`'s, each fresh key numbered from a count the process keeps,
  so every draw differs and every run draws the same. A runner off a simulation hands its client
  `HeldSeams`: a clock whose time never moves, so no attempt's budget runs out on the machine's
  time, a wall clock reading the fixtures' day, and draws of the harness's own; the session
  engine's scripts settle in `Quiescence`'s rounds (below), and a wait of theirs for good
  suspends until its task is cancelled. No runner reads the machine's clock, calendar or random
  source.
- **A script over an engine bound to the main actor settles once what it observes stands still.**
  An engine's tasks are its own, unstructured, so no executor of the harness's holds them, and no
  count of the main actor's turns waits for them: the scripts' seams are closures and doubles of
  the main actor's, which an engine holds as functions and requirements of no actor's, so each
  call and each return is a hop off the main actor and back, which a loaded machine can hold back
  while the main actor turns on. Such a call takes from 22 to 65 turns under busy loops, and now
  and then eight at rest, so a count of turns is outrun under load, an answered request reading as
  still loading. So a step settles in `Quiescence`'s rounds (`Tests/ConformanceTests/Harness/`), each awaiting a job of low
  priority queued on the pool, which runs only once what was queued there before it has been
  taken, then sixteen turns of the main actor, until what the script reports stands still for
  three rounds in a row: what the engine shows, the requests, reads and commands its doubles hold,
  sent and withdrawn, the waits its `ManualTime` holds and the outcomes of its calls, with a bound
  of a thousand rounds past which the state is read as it stands and the comparison says what
  moved, and every case passes twelve serial runs under busy loops.
- **A stream fixture is read through a real reopen.** Where a case asks where a reader resumes
  from, the runner lets the reader open the stream again and reads the `Last-Event-ID` that open
  sent, answering it with a 404 that ends the stream; an open the reconnect fixture keeps open
  writes the comment every open stream carries every 15 seconds, as the API does.
- **The interruptible-backoff fixture's `abort` is a task's cancellation.** The wait is the
  client's own sleeper on a simulation's clock: `before` is a child task cancelled before its
  wait, `during` a cancellation 50 simulated milliseconds into it, `never` a child task nothing
  cancels and `none` a wait in the runner's own task, which nothing holds to cancel, and whether it
  settled before its time passed is read off the simulation's clock; the caller's own
  cancellation is `CancellationError`, which carries no reason of its own.
- **A value a predicate reads is of the runner's own type.** `transport.errors.structural` builds
  each value as a type of the runner's own, a `NamedError` declaring the case's name as data or an
  error declaring none, which no constructor of the SDK's made, as a second copy of the SDK or code
  that never linked it hands one over, and the published predicates read it (§4).
- **A constant a fixture declares is held to the rule's own.** A runner reads each of the
  fixture's `constants` back through the surface the entry proves, a defining factor as the
  conversion of one unit and a radius as the constant Geo publishes, and compares the two within
  the fixture's tolerance. A constant the runner does not know fails the entry, so one the
  contract adds is read the day it lands rather than read past. A constant a rule keeps
  `internal` is read back through what the rule answers: the zoom floor as the minimum of a range
  that reaches zoom 0, the nominal canvas as the ratio of two altitudes, the zoom-altitude
  ceiling and floor as the zooms the nearest and the farthest altitudes are held to and its
  field-of-view factor as an altitude over the ground one pixel spans, and the unit patterns, their
  widths, the minimum grouping digits and the rounding as the published formatters write a
  measurement every language writes alike, as `sdk-dart`'s runner reads them.
- **A constant that is no single number is held as a value.** A ramp, a rank table, a vocabulary
  and the climb categories' scores are compared with the rule's own as a case's answer is, and a
  constant the cases read as their input, the locale fixture's `referenceDate` and `timeZone`, is
  named and held to nothing, as an unstated one is.
- **A constant no case reads and no rule here states is named, and held to nothing.**
  `geo/zoom-bounds.json` declares a pan lock's padding and the tile API's zoom span, and
  `geo/zoom-altitude.json` the cinematic preset's eye height, none of which a rule of this SDK
  states. The runner names each, so a constant the contract adds still fails the entry and one it
  drops is noticed, and holds it to nothing, since a value held to itself proves nothing.
- **A geo value is built from the fixture by hand, as written.** A position keeps the length the
  fixture writes it with and a `$number` where it stands, which `JSONDecoder` would refuse, so a
  rule meets a position that names no place exactly as the case states it; a GeoJSON geometry is
  the client's own type, and a segment or a boundary the generated REST type, every member a case
  leaves out a placeholder no rule reads.
- **Four geo fixtures are read at their edge.** `geo/longitude.json` names each case's operation
  in the opening of its name, as its description says; `geo/meters-to-route.json` writes no
  distance as null, "where an SDK answers its infinity"; `geo/route-geometry.json` names a line's
  length and its cumulative distances, which take the same input, only in the case's name; and
  `geo/route-ground-meters.json` writes a jump that is no whole number, which a route's `Int`
  index cannot hold. The runners read the operation, `length` and `cumulative` off the name,
  answer `Double.infinity` as null, and build the route without such a jump, which is no jump by
  construction, as the rule answers for it.
- **Four profile fixtures are read at their edge too.** `geo/pace-clock.json` names the
  operation in the opening of a case's name; `geo/waypoint-summary.json` spells a timing
  `cutoffAt` and `stopDuration` and a contact `openingHours`, where the wire spells `cutoff_at`,
  `stop_duration` and `opening_hours`; `geo/info-bands.json` hands each segment an analysis of no
  one wire name, its values words or numbers, read as `String` or `Double` as the wire's analyses
  hold them, which the runner finds by the segment's place in the case, an id no rule reads, since
  a Swift segment is a value with no identity; and `geo/segment-groups.json` writes segments that
  are not quite the wire's, so the runner builds wire values with placeholders and writes the projected
  chain back through the generated type's own encoder, a creator as its id (`CONTRACT-GAPS.md`).
- **Seven family 4 fixtures are read at their edge too.** `geo/data-geojson.json` and
  `geo/search-rows.json` write Data API values, which the runners read through the generated
  types' own decoders, as a consumer receives them, a cell that is no finite number handed to the
  decoder as the string Foundation's non-conforming float strategy reads; `geo/layer-order.json` declares `poiSourceLayers` as `{}`, a JavaScript set serialized,
  named and held to nothing; `geo/overlay-lookup.json` writes overlays that are not the wire's,
  built with placeholders and an id of each one's own, so the one found is answered as the entry
  the fixture wrote; `geo/search-query.json` writes a cap of 2.5, refused because a round's `Int`
  cannot hold it, the refusal by its types `sdk/SPEC.md` §10 leaves a typed SDK; `geo/search-filters.json` names sections by the search input's members,
  `places`, read as the `SearchTarget` they upper-case to; and `geo/i18n-bundle.json` writes an
  override that names a language and a section together, answered as its `refused`.
- **The ten navigation fixtures are read at their edge too.** `geo/navigation-steps.json`
  writes each surface's steps as that surface's JSON, which the runner reads through the
  generated `DataSchema.DirectionsStep` and `RestSchema.ItineraryDirectionsStep` decoders, so
  `merge` and the other surface's spelling reach the adapters as written;
  `geo/navigation-instruction-keys.json` writes a step's maneuver, name and exit alone, built into
  a step of vertex 0 alone, which no instruction reads, and declares `keys`, held as a value to
  `NavigationInstructionKey`'s cases; `geo/navigation-itinerary-route.json` writes each segment and
  waypoint as REST's, the members the rule reads and the `id` and `mode` a typed builder needs,
  every other member the wire requires a placeholder; `geo/navigation-stepless-route.json` and
  `geo/navigation-progress.json` write steps in the vocabulary, the second's tiling their line, so
  the route is built through `followedRouteOf(_:)`, which keeps them as they are;
  `geo/navigation-status.json` declares both closed sets, the initial status and the whole
  table, each held as a value, the table cell by cell to the internal rule;
  `geo/navigation-route-request.json` names an answer by the request it answers, read as the
  ticket that request last left under, and an answer to a request never sent fails the case; and
  `geo/navigation-off-route.json` holds its threshold through `meters` and its corridor through
  `line` and `position`, its `offRouteMeters` held to the internal constant;
  `geo/navigation-prompts.json` builds its route as the progress fixture does and lays it out
  through Geo's published `guidancePlanOf(_:)`, its `due` cases reading `duePrompt(_:progress:)`
  at the progress the case writes, null as no position, its two constants held to `promptMeters`
  and `promptSlackMeters`; and `geo/navigation-engine-walk.json` plays its script over
  `ScriptedNavigationEngine`, each request answered by the name it was asked under and `state`
  read once each step has settled, a position the engine refuses read as the `PositionError` it
  throws and `stop` as `stop()`, and, where a case states `failures`, each state's `failure` read
  off the kind of the error the engine holds. The last five are `api: false` and run from
  `Runners/Internal/`.
- **The two map fixtures are read at their edge too.** `map/engine-patch.json` writes what a map
  holds and the patch as JSON objects and names the members a patch carries as undefined in
  `unstated`, which JSON cannot write: the runner draws a layer whose paint is `held`, edits it with
  the patch through `MapEngine.editLayer(_:paint:layout:)`, each `unstated` member written `nil`,
  a case whose `drawn` is false editing a layer the map does not draw, and answers the paint the
  layer holds, or the kind of the refusal with the paint held as it was, through a plain import,
  since the entry is `api: true`; its `spelled` members, each the JSON text of a value, are read
  by `JSONDecoder` into `JSONValue`, the map's own reader, so `4.0` is the number 4, and such a case
  answers `holds` and `changed`, whether `state` differs from the one before the edit;
  `map/edit-snap.json` states the projection as the identity, a longitude an x and a latitude a y,
  which the runner hands the internal rule as a pair of functions, its `snapThresholdPx` held to the
  rule's own.
- **The icon fixtures are read at their edge too.** `geo/glyph-set.json` and
  `geo/glyph-set-chain.json` write a set's paint as a string, which the runners read into the
  closed `GlyphSet.Paint`, so `filled` is refused by the type before any set is built, and they
  hand the initializer only the box and the width a case states, so a set that states neither is
  built at the initializer's own defaults, which the fixture's constants are held to;
  `geo/glyph-set-chain.json` lists a chain's names sorted by code unit, which the runner reads off
  the chain's markup, a dictionary, sorted by UTF-16 code unit; `geo/glyph-paint.json` and
  `map/icons-marker-sprite.json` state a set by its paint, width and box alone, and the second by
  the glyphs it holds, so the runners build a set named for the case, each glyph it holds a
  placeholder no rule reads, and hold the paint's constants to what a shape stating nothing is
  painted with; `geo/glyph-parse.json` declares its lists, held to Geo's sorted as the fixture
  lists them, each shape read as a shape where it is written alone; `geo/glyph-fallback.json`'s
  `control` surface names no rule of Geo's, so the runner answers it from the set's holding, as
  `Glyph` reads it, and its place and badge surfaces through the internal rules;
  `map/icons-missing-image.json` declares the glyphs its map's set holds as a constant every case
  reads, named as an input; and `map/icons-marker-sprite.json`'s `glyphBoxPx` is read back as the
  sprite's scale times its set's box. The three `map.icons.*` capabilities are `api: false` and run
  from `Runners/Internal/`, as does `geo.icons.glyph-fallback`.
- **The family 8c fixtures are read at their edge too.** The fifteen `map.*` capabilities of the
  camera, the queries and the events are `api: true`, and their runners drive the real engine
  through a plain import on the published `ScriptedMapSurface`, which plays the renderer: what it
  records is what the engine handed a renderer, as `sdk-typescript`'s runners read its MapLibre
  stand-in. A value a Swift type cannot hold is refused by the type before any call, as the kind the
  fixture names for it: `map/camera-pose.json`'s centre written as an object (`position-refused`)
  and pitch written as text (`number-refused`), `map/camera-fit-options.json`'s `fit` of text, null,
  a list or a number (`kind-mismatch`) and duration of no finite length, which a `Duration` cannot
  hold (`number-refused`), and `map/camera-zoom-window.json`'s limit written as text
  (`number-refused`); a member written `unstated` is left nil. `map/camera-fit-options.json`'s
  drawing call is `setCollection(_:fit:)`, its specification stating a box, a refused fit reading
  nothing, and `map/engine-closed.json`'s `setItinerary` and its other calls are the engine's own
  names for them, and what it `told` is what a stream taken after the close is told. `map/camera-zoom-window.json`'s cases name the renderer they play on, the
  scripted surface's limits; MapLibre Native's are held to the window a map opens on and a release
  goes back to, and MapLibre GL JS's are named as an input. A gesture an edit took
  (`map/events-pointer.json`) is played while a waypoint is being placed, the edit that takes a
  gesture here, and the access steps (`map/events-access-standing.json`) are each closed by a tap
  that marks where one step's events end, a `refused` step refused the `status` it states, and a
  402 where it states none. A renderer's failure and a `refused` step are played under the
  credential their `sentUnder` names, `superseded` handed to
  `failRequest(url:status:source:superseded:)` as a request that left under a credential the
  client no longer sends, which `MapView`'s renderer reads off the headers each request left with
  (§8). `map/query-elevation-at.json`'s selection is read back
  off the document the query sent, its persisted digest first refused, as the protocol asks; a
  status written as text (`map/events-access-refused.json`) is one that is no number, which a
  renderer reports as none; and the constants a rule keeps `internal`, the refusing statuses, the
  manifest's path and Mountaya's credit, are read back through what the engine tells and credits.
  The three `geo.*` capabilities marked `api: false` run from `Runners/Internal/`; a fit's answer
  faces north by its type, a `MapViewport` holding no bearing, which is the expectation's 0.
- **The embed's parity is read at its edge, and its scripts through the engine.** The terrain's
  three `api: true` capabilities run through a plain import, a tile's pixels handed as their bytes,
  and the neighbours' spacing held to the published `terrainNeighbourDegrees`.
  `map.organization.read` plays its maps over one exchange holding every read, each map's client a
  client of its own that repeats no attempt, a `timeout` failing the held read as an attempt the
  platform gave up on at its budget does; the reads are shared for as long as the process lives,
  by key and Map Studio API origin (`sdk/SPEC.md` §15), so each case's clients send to an origin of
  the case's own, numbered in the order the cases run, and every read's whole body is compared as
  it was sent, a read carrying any credential header failing the case. The four `api: false` ones
  run from `Runners/Internal/`: `geo.organization.watermark` hands the rule the case's browser
  page, which a native map never hands it, and its read, `timed-out` as `OrganizationRead.timedOut`,
  so every case the contract states proves the rule itself and none is answered from the runner's
  own expectation; and `map.readout.open` plays a long press on the engine at the case's zoom over
  an exchange that answers the catalogue and the source's TileJSON at once and holds every tile
  read, a tile's image read by a decoder of the script's own, since the fixture's pixels are no
  image a codec reads, a `move` the reader's, begun and then at rest, and the reads numbered in
  the order the exchange received them, so the order the engine sends them in is the one the case
  holds; a step settling a read the map withdrew, its readout since closed or replaced, lands
  nowhere.
- **The family 8b fixtures are read at their edge too.** The `map.*` scripts of the map's content
  drive the real engine through a plain import on `ScriptedMapSurface`, as 8c's do; the six marked
  `api: false`, `map.basemap.replay`, `map.road-access.layers`, `map.analysis.layers`,
  `map.analysis.requests`, `map.geometry.layers` and `map.marker.pin`, run from
  `Runners/Internal/`, the rules among them held through the map's paint with the case's patch
  folded on as a consumer restyles a copy. A script whose reads are held until a step answers them,
  `map.layers.manifest`, `map.slots.latest-request` and `map.analysis.requests`, runs every call in
  a task preferring `MainQueue`, a task executor of the harness's own that runs its jobs on the main
  queue, and settles each step once its calls' outcomes, the reads its exchange holds and what the
  map draws stand still (above), since the engine is main-actor bound and its client is not, so no
  step waits on real time; its exchange fails a held read with
  `CancellationError` as the read's task is cancelled, and a read is named by its path.
  `map.specification.style` draws through `setSpecification(_:named:)` and leaves the restricted
  stretches out, which are `map.road-access.layers`'s; `map.layers.rank-insertion` writes the base
  map's own layers first, beneath every layer the engine holds, as the renderer draws them; a
  `switch` (`map.layers.visibility`, `map.basemap.replay`) sets each base map in order, then plays
  its style loading or failing, `loadStyle()` or `failStyle()`. `map.analysis.edit`'s patch writes
  the members a case states onto the input held through the input's own encoding, a member named
  `unstated` left as held and `{}` no patch at all, and its queries are read off the full document
  each sends once its persisted digest is refused. `map.marker.lifecycle`'s edit leaves nil each
  member its patch names `unstated`, as a Swift caller leaves a member it keeps. The eleven `geo.*`
  capabilities run through a plain import: `geo.style.map-paint` and `geo.style.itinerary-stroke`
  set a patch member by member on a copy of `MapPaint.standard`, a member written null left unset
  and one the paint does not hold failing the case, and the stroke's layer is assembled with
  `type: "line"`; a point of interest's colour is written `#rrggbb` only where it is opaque;
  `geo.data.road-access-stretches` reads its ranges with REST's decoder; and
  `geo.data.itinerary-waypoints` builds each wire waypoint as its type holds it, a member in another
  shape left out, which a typed decoder would refuse whole, the refusal by its types `sdk/SPEC.md`
  §10 leaves a typed SDK. The two engine
  fixtures of the itinerary resource settle each step once what each element shows and the reads
  sent and settled stand still (above), where its engine and its cache run on the main actor.
- **The family 8d fixtures are read at their edge too.** `geo.style.theme-tokens` states each
  override as a consumer does, the token set whole on a copy of `ElementTokens.standard`, a token
  of its value alone, reached by its member through the runner's table of the contract's names,
  which the elements' data suite holds to the printed one; a colour is written back `{hex}`, with
  `opacity` only where it is translucent. `geo.i18n.nested-scope` names the glyph sets by name, the
  bundled ones `bundled-controls` and `bundled-markers` and any other a set the runner builds under
  that name, and reads the scope's words through `word(_:)`. `geo.i18n.counted-words` reads its
  word off the elements' own words resolved for the case's language, a counted word through
  `countedText` and a template through `filledText`. The two selection scripts play a selection
  over doubles of `LayersSelectionTarget` holding every read and command until a step settles it,
  numbered across maps, a catalogue named by slug built as one classic category, `conditions`, and
  the category whose overlays stack; the locate control's script plays it over doubles of
  `GeolocateControlTarget`, whose read answers `denied` as refused, `granted`, `prompt` and
  `unknown` as not, and `fails` by throwing. Every script settles each step once what it reports
  and what its doubles hold stand still (above), where the engines, their tasks and the doubles all
  run. The pickers' runners name a word
  by its key in the `layers` or the `preferences` section, as the fixtures do, and
  `geo.layers.poi-rows` labels a group by its id and reads its note as the view does, the zoom not
  at least `poiPanelNoteZoom(_:)`. The four `api: false` capabilities,
  `geo.controls.geolocate-state`, `geo.layers.picker-rows`, `geo.layers.poi-rows` and
  `geo.units.preference-choices`, run from `Runners/Internal/`, through rules a view of
  `MountayaElements` reads and so publishes.
- **The family 8e fixtures are read at their edge too.** The five engine scripts play a real
  `SearchEngine` on time the script moves, `ManualTime`, the harness's own, whose main-actor wait
  the engine is handed, over a transport bound to the main actor that records each request as the
  engine sends it, holds it open until a step answers, fails or reports it, and records the
  requests the engine abandoned while open; every step settles once what the list shows, the
  requests, the waits and the failures handed over stand still (above), and a `wait` moves the
  time, waking each wait due at its deadline and settling what each wakes. A branch is read as the
  target its name upper-cases to, a request written through the Data API's own encoder with its
  targets' enabled flag alone, and an answer built as the Data API's result of one entity per name,
  each titled by it; `configure`'s `units` are a reader's preferences, English and metric where they
  leave one out. `geo.search.focus` plays a round of one branch, and holds its focus to the
  internal rule besides; `geo.search.list-state` builds a snapshot of rows titled as named, a failed
  section holding the API's report; `geo.search.describe` reads its entity through the Data API's
  decoder and its words through a resolver, and holds its elevation floor and separator through
  the line itself; `geo.search.pick` reads a payload by its kind. `map.search.result-highlight`
  draws through the real engine's `setSearchHighlight(_:accent:)`, over a glyph set holding a point
  or none, and reads every constant back through what the engine draws for a way's line, a way's
  extent and a place. C34's matrix inputs state their activity, which the data-geojson runner now
  reads as written. `geo.search.focus`, `geo.search.list-state` and `geo.search.pick` are
  `api: false` and run from `Runners/Internal/`.
- **The family 8f fixtures are read at their edge too.** A stretch a fixture names is a
  `ProfileClass` whose word is its name; `geo.profile.curve-placement`'s places stand at their
  distance with no geometry, `pin` read as `isPinned` and a `cutoffAt` as the details' timing,
  written back as RFC 3339; `geo.profile.scrub-grid`'s runs are folded from the grid's columns by
  the runner. `geo.profile.segment-rows` hands a segment's `metrics` as `stated` under its id; the
  card is read through a scope whose `amenities` and `waypointCard` words are their own paths, a
  text matching a path written `{word}`; a table's `held` glyph set is built under the case's names
  with placeholder markup; the filter's rows carry their place's index as their own; a caller's
  formatter is stated by what it answers. `map.profile.cursor-marker` and `map.profile.emphasis`
  drive a real `MapEngine` through a double that hands each write on and records the ones the engine
  took, so a refused edit writes nothing: an element's `style` takes effect at once where its cursor
  stands, `leave` and `unmount` both hide, `remove` and `pin` write to the engine directly, `pin`
  with the glyph `map-pin`, and the emphasis slot's colour is read null where it is the slot's own.
  `geo.profile.totals` holds `minRangeSpanMeters`, which `clampRange` states. The nine `api: false`
  capabilities, `window-spans`, `stat-strip`, `cursor-readout`, `section-chips`, `amenity-stacks`,
  `segment-table-cells`, `waypoint-table-cells`, `amenity-filter` and `row-match`, run from
  `Runners/Internal/`, through rules a view of `MountayaElements` reads and so publishes.
- **A `dateTime` case of the locale fixture names its lengths.** Its `dateLength` is read as the
  `DateLength` of that raw value and its `timeLength` as the `TimeLength`, and a name neither type
  holds fails the case, as a case naming neither length or naming options does, rather than being
  read past. The instant is the fixture's `referenceDate`, placed in the zone the case names or in
  the fixture's own.
- **The locale is pinned per case.** The locale and unit-formatting runners build an explicit
  `Locale(identifier:)` from each case and never read `Locale.current`, since Foundation's locale
  data differs by OS version and by host. The cases of `geo.format.locale-services` expect strings
  every platform's locale data writes alike, Nepali's digits and date order among them (`ne-NP`
  writes 1531 as `१,५३१`, 14 March 2026 as `२०२६ मार्च १४` and 05:45 as `०५:४५`), so each host
  answers every case with its own data, macOS 27 (ICU 78.1, CLDR 48) and Linux at the pinned Swift
  and at the floor alike, and no digit is ever assembled to match.
- **The report** is `schemas/sdk/reports/swift.json`, carrying `sdk`, `registryVersion`,
  `modelDigest`, the digest `sdk/SPEC.md` §11 defines of the files in the checkout the run read,
  and a `pass`, `fail` or `scoped` per capability, the shape `PARITY.md` is generated from, and
  `published`: for every capability whose `swift` column is a list, the names of it the committed
  API baselines declare, in the column's order, none where they declare none, which the contract's
  gate holds equal to the column. The names are read off the committed baselines rather than a
  build, so the Linux run, which builds no iOS product, reports the same ones. A report keyed on
  another registry version counts as no report at all, and the contract's gate refuses one whose
  digest is not the digest of its files. A run refuses to report while the printed `modelDigest`
  differs from the digest of the files it read, since its ticks would be earned by a surface
  printed from other files: `swift run GenerateClient` prints it again first. It is written on
  request, by
  `mise run conformance:report`, and by nothing else: a plain test run writes nothing into
  another repository.
- **Where it runs.** The client, geo and `map` runners run on macOS and on Linux, since both are
  supported hosts and Linux's Foundation is a second implementation of the locale services the
  fixtures probe; the `map` rules name no renderer type, so they build there (§2). The report is
  written by the macOS run, and the Linux run has to agree with it: `mise run ci:linux`, which CI
  runs on every push and the gate runs last, holds both Linux legs to it with
  `MOUNTAYA_CONFORMANCE_REPORT=check`. The scripted navigation engine
  and the machine under every engine run there too, with the rest of Geo, and so does everything
  of `MountayaNavigation` but its voice: the seams, the plan and `DeviceNavigationEngine`, a route
  followed fix by fix and held, state for state, to the machine's and the scripted engine's for the
  same inputs, each prompt said once at the meter `sdk-dart`'s engine says it; and everything of
  `MountayaElements` that is not MapLibre's: the map's state, its engine, the one layer registry
  and both `map` rules. The voice and the map's renderer run on the iOS simulator, since the audio
  session and MapLibre load nowhere else, and `mise run test:device` runs both suites, the voice's
  then the renderer's, then Trail's journey, `mise run test:trail`, the sample app walked through
  `sdk/trail.yaml`'s `journey` by its UI test (§7): `mise run test:ios` builds `MountayaNavigation` for the
  iOS device and the simulator, warnings as errors, and runs the `Speech/` package's tests on the
  simulator with `xcodebuild test`; `mise run test:ios:elements` builds `MountayaElements` for the
  device and the simulator with its trait, warnings as errors, then runs the tests of the
  `Renderer/` package, which turns `Elements` on as a map-only app does, on the simulator: the view mounts and draws a style from
  the state, the layers draw in the registry's order, a patch reaches the property MapLibre draws,
  the labels speak the state's language, the magnet measures through MapLibre's projection, the
  markers are MapLibre's annotations, a tap reaches `onTap` or places the waypoint being edited,
  the pan lock and the zoom range are MapLibre's camera limits, the camera at rest reaches
  `onCameraChange`, a jump, an ease, a flight, a zoom step and a reset of north land MapLibre's
  camera where the engine holds it, a fit lands where `cameraForBounds` frames the box on the view's
  own canvas, a point query answers MapLibre's rendered features layer by layer, topmost first, a
  tap, a long press and a hover are told with the features under them, a tile the stub refuses a
  402 is told as a refusal of access that stands, a tile and a style that reach no answer are told
  as failures, a style that fails is told once, and the map is asked for its style only once the
  request hook shows it, the base map's labels are relabelled and the map's
  own left as they are, the map credits Mountaya first and its credit button opens a sheet of them,
  the map's own requests carry the credential, the map answers the marker
  images its style names with sprites of its engine's glyph set and a stretch's stripe images with
  its kind's tile, which MapLibre adds as it lays them out, and leaves any other missing, a marker
  is shown as its pin, the accent and a dot where it names neither colour nor glyph, a
  specification draws its restricted stretches beside its line, shown until the toggle hides them,
  and its content and a layer added by hand are drawn again on a base map switched to and on the
  one shown when a switch does not arrive, the geometry slots and a Data API result draw at their
  bands and are taken off, a sprite's, a pin's and a stripe tile's pixels are where their rules put
  them, every bundled glyph's
  geometry is read whole, and `Glyph` draws a glyph in the colour it is handed, else `control-fg`
  under the scheme in force, and nothing for one its
  set does not hold, each against a stub of the Tile API and of another host served to MapLibre's
  own loader, so no test reaches the network. The controls and panels are drawn by SwiftUI's own
  `ImageRenderer` and read pixel by pixel: the tokens under each scheme, a consumer's standing in
  both; the stack's order and its corner; a half or a control with neither a map nor a handler
  inert, one at its window's end disabled, and a disabled flag shutting every control; the locate
  control in the accent while busy; the compass's needle turned against the bearing; and each
  panel on the panel's ground. Each control's press drives the engine, or the handler standing in
  for it, each panel carries out its rows' presses, one panel is open at a time, the locate
  control's description says location is blocked on the permission's word, and the map's pins
  take the host's accent, through `MapView` read under the scheme in force. The search box asks
  its engine as it appears and as an app writes its text, waiting out the pause before a round
  leaves, opens its list only while the focus stands in the control, draws its list on the panel's ground under
  each scheme and its rows the touch target high, reads its status line, filters and titles in the
  scope's words, moves the camera onto a pick and marks it in the accent, a collection taking the
  mark down, and takes its map's highlight down as it leaves the screen or is handed another map;
  a picked result is drawn above the map's content on MapLibre's map, its pin answered as a sprite,
  and drawn again on a base map switched to. The data elements read an itinerary through a cache
  over a source answering at once: the profile's chart draws its curve, its area, a leg tinted
  under it, its pins and its cursor's rule and card where the rules place them, and a pointer
  reads the column under it; the navigator's handles and window move through the scrub's columns,
  held to the itinerary and the narrowest window, the rest veiled; the distance axis culls a
  crowded name; the sparkline lights its stretch in its colour; the tables lay out a row per leg
  and per place once the answer lands, their cells write their figures in the reader's units, and a
  chip pressed writes the choice the app holds; the card draws its mark in the place's colour on
  the panel's ground; a profile with no altitude draws its empty line, and each failure reaches
  `onError` once, one that replaces a failure after an invalidation included, each element's and
  the relay's alike. What an element points at writes the marker under its own id and the
  stretch it lights to a real engine, only once for a pointer resting, never from a disabled
  element, and never to the map where `onHover` takes it over, and takes down only what it
  wrote; on MapLibre's map the cursor marker is the pin's dot and the leg is drawn on the
  emphasis slot's line.
- **A fixture is never edited to make a test pass.** A disagreement is a defect here or a defect
  in the contract, and the second is fixed in `schemas` under a new tag.

The sibling checkout is tolerated as absent by a plain `swift test` and refused by
`mise run ci`, so a contributor builds without it and a green gate always means the fixtures
ran. This repository has no CI runner: no hosted runner offers the macOS and Xcode its gate
needs, so the gate runs where a contributor works, as `mise run ci` before a push, and no hook
runs it for them.

Since the gate runs on a contributor's own disk, it cleans up before it builds. `mise run ci`
starts with `mise run clean` (`scripts/clean.sh`), which deletes what the builds left behind in the
repository and no longer use, and nothing outside it: a scratch directory for a toolchain neither
pin names (`.build/linux-<version>`, `.build/consumer-<host>-<major.minor>` and the size gate's
`.build/trail-ios-release-<major.minor>`, §7), the release build the size gate measured before it
measured Trail, `.build/consumer-ios-release-<major.minor>`, a platform build no task makes, and the
resolve-only `.build` of the packages under `Tests/` and `Examples/`, so a pin that moves frees its
old builds at the next gate. Trail's own builds, the journey's `.build/trail-derived` and the
session server's `.build/trail-session`, are kept, as the simulator suites' are. The `swift:<version>-noble` images the Linux runs pulled live in Docker's disk, which
every project on the machine shares, so no gate deletes one: `mise run clean:toolchains`
(`scripts/clean-toolchains.sh`) lists those of a Swift no Mountaya checkout's `mise.toml` pins any
more, and deletes them only with `-- --yes`, the person's to run and denied to an agent. Then
`mise run disk:check` (`scripts/check-disk.sh`) stops the gate before it starts where the disk has
less than 35 GB free for a first gate or 15 GB for a later one, `MOUNTAYA_MIN_FREE_GB` asking for
another figure, and names both: a build that runs the disk out of space fails part-way and stops
every other program on the machine that writes. `.build` holds about 25 GB, so nobody copies the
repository to build it elsewhere.

## 10. Release

- **One version across the repository**: one tag, every product together. The source writes it
  once, `ClientIdentification.version`, which every request names in `X-Mountaya-Client` (§4);
  the release refuses a version other than the one it states, so it is moved in a commit of its own
  before the release, and BoundaryTests reads it as the release does and holds it no older than the
  newest release `CHANGELOG.md` records.
- **`schemaVersion` and `modelDigest` are generated**, and a test compares the first with the
  sibling checkout's `VERSION` and the second with the digest of the checkout's five files.
- **MapLibre is a range**, `"7.0.0"..<"8.0.0"`, its `MapLibre` product alone, because a consumer's
  MapLibre is theirs and an app that reaches through `onReady` declares it too. Its floor is
  7.0.0, its newest stable release, which the package pins and the gate builds (§2).
- **Navigation links no third-party package**, so no navigation library's release is ever a
  change a consumer sees: the engine is Geo's machine with its guidance, and the navigation
  fixtures, the engine's suites on every host and the API baseline are what prove it.
- **A consumer turns the map's trait on**, `.package(url:..., traits: ["Elements"])` in a tools
  6.1 manifest or newer, or the trait in the Xcode project's package settings, which the project
  file records as `traits = ( Elements, );` on the package's reference. The README's manifest
  lines show it.
- **The admin unit is a product a target names, and no trait.** Its one dependency beyond the core
  is swift-crypto, which the core resolves already, so it adds nothing to a consumer's resolution,
  and a target that does not name it links none of it (§7). A server, or an app that runs its
  organization, writes `.product(name: "MountayaAdmin", package: "sdk-swift")` beside the core's,
  and the README's install section lists it as optional. It ships at the package's one version, as
  every product does.
- **A break in the API baseline needs a major.** Below 1.0 the contract's own rule applies: a
  minor carries what a major carries later, and nothing is deprecated before it is removed. From
  1.0 a contract operation is retired through a deprecation the generator prints (§3), never
  renamed in place.
- **README snippets compile** against the real products, in the outside-in package, because a
  snippet is the first code a consumer copies. Every fence tagged `swift` is printed into the
  consumer's `ReadmeSnippets` target, each in a function of its own with its imports gathered,
  and BoundaryTests fails where the printed file differs from what the README prints; a name a
  snippet uses without declaring, an app's own backend, is declared beside it in a prelude. A
  fence that cannot compile, such as a manifest fragment, opts out with
  `<!-- swift:skip <reason> -->` above it, and the printed file lists every reason. The
  TypeScript SDK gates its README the same way. The floors table under Install is held by the
  same suite to `Package.swift` and Trail's project, as §2 has it.
- **The skill's snippets compile too.** `mountaya-sdk-swift`, the skill an agent reads to use this
  SDK, lives in `mountaya/ai`, a sibling the manifest names beside `schemas`, and BoundaryTests
  reads it from the `../ai` checkout at every run, keeping no copy. Every Swift fence of `SKILL.md`
  and its references is printed as the README's are, under the same skip marker, and type-checked
  beside the README's prelude, under the consumer's settings, against the consumer built for the
  iOS simulator with the `Elements` trait, where every product and view is whole; a fence that
  guards itself for a server, `#if os(macOS)`, compiles to nothing there, so the macOS run
  type-checks each such fence again against the consumer built for macOS, where the secret key,
  the admin unit's mint and the receiving of a webhook exist. The Linux run reads the fences and
  refuses a malformed one. The floors the skill
  states, the tools version and each platform's minimum, are held to the ones `Package.swift`
  declares. A missing checkout skips both tests with a note on a contributor's machine and fails
  them in CI. A snippet that fails is fixed in the skill, in `ai`.
- **The licence is the Mountaya SDK License 1.0**, the text the TypeScript packages ship, in
  English and French at the repository root, `LICENSE.txt` and `LICENCE.fr.txt`. A SwiftPM
  manifest has no field that names a licence, so the manifest names both beside its products
  and the README names them for every product. It is carried verbatim and never edited for house
  style, and BoundaryTests holds both texts to the TypeScript checkout's bytes where it stands
  beside this one.
- **What is not Mountaya's carries its own licence.** `MountayaGeo`'s glyph sets hold the markup
  of icons from Lucide, under the ISC licence, with the MIT licence for the icons Lucide derives
  from Feather. `THIRD-PARTY-NOTICES.txt` at the root carries both, printed from the contract's
  `sdk/elements/NOTICE` (§3), each printed glyph file carries them in its comments, and the
  README's licence section names the file.
- **A consumer resolves the package from a public, read-only GitHub mirror of this repository,**
  `https://github.com/mountaya/sdk-swift`. This repository's pages on Entire are public, but cloning
  it takes an Entire account, and SPM resolves a package from a URL it can clone and a version from
  that URL's tags, so each release is a tag of this repository that reaches the mirror as well, and the
  README's install line names the mirror. Nothing pushes to the mirror by hand:
  `.depot/workflows/mirror.yml`, which `ai` renders into every SDK that has a mirror, pushes every
  push of `main` and every `v*` tag from Entire, never by force, with the deploy key a Depot secret
  holds and the address a Depot variable names, so this public repository names nothing it ships
  to. Maven Central is `sdk-kotlin`'s; nothing of this repository is published there. Until the
  first release a consumer depends on a checkout.
- **CI runs the gate's Linux part on every push.** `.depot/workflows/ci.yml`, rendered from
  `.agents/manifest.json`'s one job, `linux`, runs `mise run ci:linux` on a Depot Ubuntu runner,
  with the contract and the `ai` checkout at the commits `siblings.lock` pins, both mounted into
  the container read-only: the lints and the printed files' check, then every suite at the pinned
  toolchain and at the floor, each in the official Swift container and each held to the conformance
  report, the hot-path gate among them, which holds every budget test to the contract's list,
  the simulator's included (§7). No CI runner carries the pinned Xcode, so what needs it, the
  Apple platform builds, the iOS simulator suites and the six hot-path budgets they run, the naming
  law over the iOS build, the API baselines, the skill's snippets type-checked for iOS and the
  app-size gate, which builds for an iOS device (§7), runs in `mise run ci` alone, on macOS, which
  runs `ci:linux` last.
- **A release is `mise run release <version>`, run where the gate can run.** No CI runner carries
  the pinned Xcode, so the release's own preflight runs the gate, last, once nothing else has
  refused: `mise run disk:check` on its own, since it passes under CI without looking, then
  `CI=true mise run ci`. Each refusal says what to do, all of them told together: a tree that is
  no git repository; a version that is not MAJOR.MINOR.PATCH, tagged already here or on Entire, or
  not newer than the newest `v*` tag; a mirror that holds the version's tag or a newer one, asked
  over https; a version other than the one every request names, `ClientIdentification.version`; a
  tree with changes; a commit that is not `main` at the commit Entire's `main` is at, or no
  `origin` remote; nothing under `CHANGELOG.md`'s `[Unreleased]` and no section of the version's;
  a sibling that is not clean at the commit `siblings.lock` pins, which `sh .agents/siblings
  at-pins` names; a licence text that differs from sdk-typescript's bytes; and a gate that fails,
  which holds the API baselines, the README's snippets, the licence, the hot-path budgets and the
  app's size as well. It then says what it will do and asks, moves the notes to the version and
  its date in a commit holding nothing else, unless the section is there already, tags that commit
  `v<version>`, annotated, with the section as its message, and pushes `main` at that commit to
  Entire, then the tag, since Entire takes no atomic push; no other branch is pushed. Last, it
  waits, ten minutes at most, until the mirror lists the tag, and where it never does it says the
  release is done and names `mirror.yml`'s runs to read. `--dry-run` runs every check but git's, and the gate, and
  pushes nothing; `--skip-gate` leaves the gate out of a dry run, and is refused without one.
- **`CHANGELOG.md` records the package's version**, in Keep a Changelog's shape: `[Unreleased]`
  first, then each release as its version and its date, newest first, the five products being one
  release. BoundaryTests holds it to that shape, and every name it writes in backticks to a product,
  a trait or a symbol a product's API baseline publishes, since it is the one document no generator
  stands behind.

## 11. Deliberate divergences

Departures from `sdk/SPEC.md`, and nothing else. `PARITY.md` reads a ➖ in this SDK's column as a
sentence here. What every SDK does alike is the contract's to state, and once it does it is no
departure: MapLibre's own loader carrying the credential, the language and `X-Mountaya-Client`
and nothing else of the transport (`sdk/SPEC.md` §1, here §8), an app build being a phone's, a
tablet's, a watch's, a headset's, a TV's or a browser's page and never a desktop or server process
(§1 there, here §4), the receiver's clock a caller states as `now` (§3 there, here §4), and a
renderer's own zoom window, MapLibre Native's 0 to 25.5 (§15 there, here §8).

- **No studio layer.** The studio is TypeScript-only (§1), so every `studio.*` capability is
  `scoped`.
- **No browser refusal for the secret key.** This SDK publishes no WebAssembly target, so it has
  no browser build and `transport.browser.secret-key` is `scoped`. The app-platform refusal
  stands in its place (§4): the secret-key case is unavailable on iOS, tvOS, watchOS, visionOS
  and Mac Catalyst, a compile-time barrier. The prefix check and the server-only guidance remain.
- **`select` narrows the document and not the result type.** Swift has no mapped types. The
  generated result type is returned whole, its fields optional, and a field the caller did not
  request is `nil`.
- **`MountayaGeo` links `MountayaClient`.** Swift has no type-only dependency, so the "never calls
  the network" promise is held by §7 rather than by the graph.
- **Two maps on one Tile API send one credential, and an answer no map claims is told to one map
  alone.** MapLibre's request hook is process-wide, so every map shown holds it at once, each
  map's credential sent where its client's Tile API claims a request: two maps whose clients reach
  one Tile API under different credentials send the credential of the map shown last, where the
  TypeScript SDK lets each map override its own, and a map showing a shared resource under another
  credential puts `share_token` in its tile URLs, which the Tile API accepts, as a query credential
  the contract otherwise sends as a header. The hook hears an answer's address and names no map, so
  a failed answer is told to every map that claims its address, by its sources' tile templates or
  its style's directory, and one no map claims, which a map shown alone is told, is told to none
  while several are shown, as `sdk-dart` and `sdk-kotlin` route theirs.
- **A redirect is held to the Tile API through an experimental MapLibre API.** MapLibre iOS sets a
  request's headers once, before it leaves, and its loader follows a `3xx` with them, to any host;
  the one place a redirect is heard is the session a request leaves on, which MapLibre 7 asks its
  network configuration's delegate for, `sessionForNetworkConfiguration:`, an API it documents as
  experimental and likely to change or go (§8). `Package.swift` takes MapLibre within
  `7.0.0..<8.0.0`, and the hook's tests drive a redirect through MapLibre's own loader, so a
  release within that range that stops asking fails the gate rather than a consumer's privacy. No
  Mountaya API declares a redirect today.
- **A marker is a pin, and brings no view of its own.** The contract lets a marker bring a view
  and a handler of its own where an SDK's types let it hold them (`sdk/SPEC.md` §15). A Swift
  value cannot hold a view or a closure and still compare, and every map value compares, so a
  `MapMarker` is the pin `map.marker.pin` describes, drawn as MapLibre's annotation, and its press
  is `MapView`'s `onTap`, told its id, as `sdk-kotlin` draws its markers.
- **A lifted pan lock leaves the view within the world's edges.** MapLibre iOS's
  `maximumScreenBounds` keeps what the view shows within a lock, as the contract asks, and it
  publishes no way back from holding the screen: once a lock is lifted the view stays held within
  the world's edges, the antimeridian a wall, where `sdk-typescript`'s `setMaxBounds(null)` leaves
  it open (`sdk/SPEC.md` §15). The first lock a map is given is held to the camera's center alone
  until the camera next moves, so the renderer hands each lock over twice, which holds the screen
  at once.
- **A refusal of access to the base map's tiles, or a failure with no answer whose error names no
  address, is read as MapLibre iOS reports it.** Its network delegate hears an answer's status and
  address and names no source, so a refused tile names the map's own source whose tile templates
  the address MapLibre asked for lies under, and one of the base map's sources names none and
  stands until the next style loads, where the contract ends it with the next tile of that source
  (`map.events.access-standing`). A request that failed with no answer reaches the delegate with
  the loader's error, which names the address its last hop failed at, and is told as a failure at
  the address MapLibre asked for, as the contract tells it (`map.events.access-refused`, §8); only
  one whose error names no address at all, which no map could claim, is told nowhere. The delegate
  hears no request either, and only the address an answer's last hop went to, so what a request
  left with, the address MapLibre asked for among it, is kept by that address, for at most 1,024
  addresses awaiting an answer, the oldest forgotten first (§8): an answer at an address forgotten
  past them is told at the address its last hop went to, where the contract names the one the map
  asked for, and a 401 or a 403 there as a refusal, where the contract tells one of a credential the
  client no longer sends to nobody.
  MapLibre's style keeps no order of its sources, so the base map's credits follow the order the
  layers drawing them are drawn (`map.style.attribution`).
