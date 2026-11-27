# AGENTS.md

`sdk-swift` is Mountaya's Swift SDK, under construction. What is here is the package manifest,
the gates, the conformance harness, the printer of the generated surface, and five products, all
written against `schemas` at contract v0.9.0, registry version 20, with its 262 capabilities, 226 run and 36 scoped, its model
and elements' data digesting to the `modelDigest` the client prints beside `schemaVersion`.
`MountayaClient`, the client's core: every `transport.*` capability passes its fixture but the
browser's secret key, which is scoped, and every request leaves through `SystemExchange`, over
`URLSession`, unless a caller gives the client an `HTTPExchange` of its own, and a collaboration
editor stream is read as its member's user, the one the session token names or, where it names
none, the one `reading(asUser:)` names.
`MountayaAdmin`, the client's admin unit, which the contract declares and the printer splits off by
the model's `unit`: the `admin` group's operations, declared on the core's client as
`mountaya.admin` once the product is imported, the types only they and the webhook events reach,
`AdminSchema`, and the receiving of a delivery, verified and read by `constructWebhookEvent` into
the printed `WebhookEvent`, on a server and never in an app. It sends through the core's transport
by `package` declarations, and its refusal of a delivery, `MountayaError.webhookSignature`, stays
the core's. An app that shows a map or navigates links none of it. `MountayaGeo`, the geo layer: every
`geo.*` capability has its runner, the foundations (units, geodesy, terrain, longitude,
`format.lnglat`, corridor, `boundaries.select`, `timezone.viewport`, and the terrain read off the
elevation tiles, a pixel's height, a point's tiles and its aspect's direction), the camera rules, the
profile rules, the unit formatters, the segment groups with their road access, a stretch's road
access kind and its restricted stretches as features, the locale services, the rules the elements
draw by (style, the map's paint and an itinerary's stroke, layers, a point of interest's style,
icons, i18n and search), an itinerary read by id through `ItineraryResourceEngine` over a cache
the app shares per client, with its legs and its places, the glyph sets a host builds and chains
and how each shape of a glyph is painted, the controls' and panels' rules (a token under a
scheme, a nested scope's words, a counted word, the layers, points-of-interest and preferences
pickers' models, the layers picker in the map studio's four sections, a panel's layout, the
one rule a map follows of its organization, its watermark, with the frame's extent a host keeps
clear of, `watermarkWidth`, `watermarkHeight`, `watermarkInset` and `watermarkClearance`, the
read's five states, `OrganizationRead`, and whether the frame is held as the read stands,
`isWatermarkKeptClear(_:)`, which every part of the SDK's own interface reads too, and a readout's
rows, the time's rules,
the moment
shown, the stamped tile addresses and a time slider's track, ticks, release and readout, each
handed the clock's reading, and the two engines over a map, `LayersSelectionEngine`, which holds
the instant pinned, and `GeolocateControlEngine`, each over a target protocol `MapEngine` conforms
to), the search,
`SearchEngine`, its typing pause, a request per branch, the latest round writing, the fall back
from the visible area and the refresh as the camera rests, over the Data API handed in and on a
wait it is handed, with the rules a result list and a pick draw by and when a control shows its
list, `isSearchListShown(hasFocus:query:isDismissed:)`, the rules an itinerary's
data elements draw by (the profile's scale, curve, places, scrub and window, its strip, its card at
the cursor and its chips, the two tables' rows and cells, the services' filter, a place's card and
an altitude band as the language's own range), and
navigation's rules, with the `NavigationEngine` protocol, the scripted engine and the
machine under every engine, `RouteFollowingEngine`, published with an initializer over a route
source and an inline observer of its states, `onChange`, which an engine built over it is told
each state by before any stream is, and the guidance's, the plan an engine that speaks announces a
route's maneuvers from, `guidancePlanOf(_:)`, and the prompt due at a reading,
`duePrompt(_:progress:)`. Every case passes.
`MountayaNavigation`: the engine an app navigates with, `DeviceNavigationEngine`, Geo's machine
saying Geo's guidance, each maneuver at the meter Geo's progress names, over no navigation
library and on every platform, and the seams it takes, the location sources and the voices, the
system's speech among them in an iOS build.
`MountayaElements`, the map: its state and engine, `MapEngine`, with the one layer registry and the
`map` layer's rules (the patch, the magnet, the marker sprite, the images a map answers and a
restricted stretch's stripes, and the camera's moves, fits, steps and zoom window, the point
queries, the events a map tells, a refusal of access standing, its credits and the scope of its
label language), its organization read once per publishable key and Map Studio API origin and
shared by every map of the process, `loadOrganization()`, which decides its watermark and nothing
else, where that read stands published as `organizationRead`, and the readout a long press opens, which reads the elevation tiles through the client's
tile transport, in the order `elevationTilesAt` names them, and decodes them off the main thread, the content it draws by id or by name in slots, each drawing its latest request
and withdrawn by cancelling its task, a base map switched whole with that content drawn again on
it, the layers catalogue, overlays and enrichments, the classic overlay the server stamps drawn
for the instant pinned, its tiles swapped as the pin moves, a layer's and a concept's visibility, an
itinerary's restricted stretches on a plain map, Data API results each under an id of its own,
three geometry slots, a picked search result drawn above everything in the accent it is handed,
markers drawn as pins with a glyph, a data element's cursor marker and the leg it points at lit on
the emphasis slot, the camera's pan lock, the device
located through a `Geolocation` seam that never asks for access, the editing engine that places a
waypoint a tap at a time through the magnet, and `ScriptedMapSurface`, the published double an
app's tests and the conformance runners
drive the engine through with no renderer, which build and run their fixtures and tests
everywhere, and, behind the package's `Elements` trait, off by default,
the SwiftUI `MapView` over MapLibre Native, its renderer the surface the engine asks and tells,
the Mountaya watermark over its canvas, in the top-left corner of the map's safe area, the inset
the system reports through its window, measured again as the map moves in it with no layout of
its own, in a layout that runs right to left too, and clipped to the map, unless the organization
holds white label, whose press opens Mountaya's site through the system's opener and whose frame
every part of the SDK's own interface keeps clear of, inside that safe area, a panel moving below
it, the label of the marker tapped last drawn above it and clear of it, a control stack over a map
no view draws keeping to its own space and holding the frame as the map's read holds it, and the
readout a long press opens unless its `readout` is false, its moments in the time zone the device
keeps,
with its `onReady`, `onTap` and `onCameraChange` handlers, whose own requests carry the client's
credential through MapLibre's process-wide request hook, which hears their refusals and their failures too, a request that reached no answer among them, whose
style's waypoint and point-of-interest pins, restricted stretches' stripes and markers' pins it
draws from the engine's glyph set and whose markers take the accent of the host's tokens, whose
credit button lists the engine's credits, `Glyph`, a glyph drawn in SwiftUI, and the map's
controls and panels, `MapControls` with its zoom, compass, locate, panel and action controls,
each flag a plain `Bool` at the contract's fixed default, and
the layers panel, its cards, switches, categories and time slider, laid out around the clock
SwiftUI's environment carries, `\.mountayaClock`, the points-of-interest and preferences panels,
the search box, `SearchControl`, whose
pick moves the camera and draws the map's search highlight, and the data elements over an
itinerary read by id through the app's cache, `ItineraryProfile`, `ItinerarySegmentTable`,
`ItineraryWaypointTable`, `ItinerarySparkline` and `WaypointCard`, which pin a cursor marker on
their map and light the leg a reader points at, drawn in the tokens and the words of
the scope SwiftUI's environment carries; without the trait, or off
iOS, a `MapView` the compiler refuses with a message saying what to do. The consumer package in `Tests/Consumer` builds against the five products, with the `Elements`
trait on but on Linux, and for the iOS simulator too, the README's snippets with it, while the
README's floors table is held to `Package.swift` and Trail's project, and each product's
public API is held to a committed baseline, `MountayaNavigation`'s and `MountayaElements`'s
printed from that iOS build. Trail, the sample app the contract's `sdk/trail.yaml` describes, sits
under `Examples/Trail`, MIT-licensed: an iPhone app over the four products an app links and never
the admin unit, run from its Xcode project, with its session server beside it, held to the
scenario by BoundaryTests and walked through its journey on the simulator. It is the app the size
gate builds in release for a device, and what each product adds to its executable is held to a
recorded figure, `Tests/BoundaryTests/Size/ios.json`, the admin unit's held at 0. Every capability of the registry has its runner or its scope
sentence, every name the registry's `swift` column publishes for a capability not scoped is a
declaration of those baselines at exactly that path, and the column says `scoped` where the scope
table does, so the coverage tests pass, inside the gate (below). The skill an agent reads to use
this SDK, `mountaya-sdk-swift` in the sibling `ai` checkout, is held to the products too: its Swift
snippets type-check for the iOS simulator, those it guards for a server for macOS too, and the
floors it states are `Package.swift`'s.

**`SPEC.md` beside this file is what to build.** It is the specification for this SDK:
scope, the product graph, the generated surface, transport behaviour, the naming
law, the layout law, the boundary rules, the elements family and navigation,
conformance, release, and the divergences this SDK takes deliberately. Read it before
anything else here.

## The contract, and where it is not

**The contract is `mountaya/schemas`, and it is the contract for every SDK at once.** It is
read from the sibling checkout, `../schemas`, or from wherever `MOUNTAYA_SCHEMAS_DIR` points.

- `openapi/api.yaml`, `openapi/tiles.yaml` and `graphql/data/*.graphqls` describe the
  SHAPES. `sdk/model.json` restates them as one language-neutral document, built there, and it
  is what this repository's generator reads. A generated file is never hand-edited: a wrong
  shape is a defect in the description.
- `sdk/SPEC.md`, `sdk/registry.yaml` and `sdk/fixtures/**.json` describe the
  BEHAVIOUR: when a request is repeated, how a session token is kept fresh, which
  failure maps to which class, how an elevation series is derived, which words a
  capability gate knows. Those are contract too, and no bundle can express them.

**`mountaya/sdk-typescript` is not the reference.** It is the first implementation of
the same contract. Writing this SDK against that one would make it a translation of a
TypeScript module list rather than an implementation of an agreement, which is the soft form of
the dependency the "100% native, no bridges" rule exists to forbid. Where a question is
not answered by `SPEC.md` here or by `sdk/SPEC.md` there, the answer is to settle it in
`schemas` and write it down, not to read it off another language.

**Parity is proven against JSON.** `Tests/ConformanceTests/` loads `sdk/registry.yaml` and runs
each fixture's cases; a Swift test reads a JSON file and knows nothing about any other SDK.

**`CONTRACT-GAPS.md` is the list of what the contract leaves open**, for this SDK, `sdk-kotlin`
and `sdk-dart`, which read it here and keep no copy. A question the fixtures do not answer becomes
a row there, with what each SDK does until the contract answers it. It never becomes a guess
presented as the contract, and a row the contract closes is removed.

## Commands

`mise.toml` is the one place a tool version is written: the Swift every gate runs on, Xcode, and
the floor `Package.swift` declares, which the suites run at too. On macOS the compiler is Xcode's,
so the version is asserted rather than installed; the Linux runs use the official container at
the same version.

```bash
mise run ci                   # the gate: ci:local, then ci:linux
mise run ci:local             # the part CI never runs: clean, the disk check, toolchain, lints, builds, every suite with the coverage test, the README's snippets and floors, the hot-path budgets and the Trail scenario, Trail's session server, the device suites with Trail's journey, the size gate
mise run ci:quick             # what pre-commit runs: the format check and the layout and naming laws
mise run lint                 # lint:format, lint:structure and lint:naming
mise run build                # every target, the tests included
mise run format               # rewrite the sources in place; not part of the gate
mise run ci:linux             # what CI runs on every push: the release's test, then the lints and both Linux legs in the container, against the conformance report
mise run test:release         # the release's fixture test: scripts/version.sh and scripts/release.sh against fakes, no network
mise run clean                # delete what the builds left in the repository and no longer use; `-- --all` every build directory, `-- --dry-run` only lists
mise run clean:toolchains     # the person's, denied to an agent: list the Linux images of a Swift no checkout pins; `-- --yes` deletes them
mise run disk:check           # refuse to start the gate where the disk lacks room for it
mise run ci:coverage          # the coverage tests alone: the capabilities with no runner, the published names no baseline declares and a `swift` column the scope table disagrees with, none now
mise run generate             # print Sources/MountayaClient/Generated/, Sources/MountayaAdmin/Generated/ and Sources/MountayaGeo/Generated/
mise run generate:check       # fail where the printed files differ from what the contract prints
mise run test                 # every suite on the host
mise run test:linux           # every suite in the Linux container, at the pinned Swift
mise run test:linux:floor     # the same, at the tools version Package.swift declares
mise run build:platforms      # every target under Sources/ for iOS, tvOS, watchOS, visionOS, Catalyst
mise run test:device          # the device suites on the iOS simulator: test:ios, test:ios:elements, then test:trail
mise run test:ios             # MountayaNavigation for iOS, and its Speech tests on the simulator
mise run test:ios:elements    # MountayaElements for iOS with its trait, and its Renderer tests on the simulator
mise run test:trail           # Trail's journey (sdk/trail.yaml), its UI test from Trail.xcodeproj on the simulator
mise run test:trail:session   # the tests of Trail's session server, a package of its own, on macOS
mise run trail:session        # run Trail's session server on 127.0.0.1:8787, its two keys read from your shell
mise run size:check           # what each product adds to Trail, the sample app, in release for iOS, against Tests/BoundaryTests/Size/ios.json
mise run lint:structure       # the layout law (SPEC.md section 6)
mise run lint:naming          # the naming law (SPEC.md section 5), on macOS over the iOS build too
mise run lint:format          # formatting and the never-force rules; it repairs nothing
mise run api:update           # print the five products' API baselines again after a deliberate API change, on macOS
mise run snippets -- <file.md> # type-check the Swift fences of Markdown files outside this repository, the docs' pages among them, on macOS; no gate runs it
mise run conformance          # only the contract's fixtures
mise run conformance:report   # writes sdk/reports/swift.json in the contract checkout
mise run version <version>    # write the release into the files: ClientIdentification.version, the README's install lines, CHANGELOG.md; an agent may run it
mise run release <version>    # the person's: the checks, ci:local once per commit, the tag, its push alone to Entire, and the wait for the mirror
mise run release <version> --check  # every check, and what a release would do; it runs, tags and pushes nothing
```

- `MOUNTAYA_CONFORMANCE_ONLY=transport.retry` narrows `conformance` to ids with that prefix.
- The printer's golden files are what a miniature model prints, and what miniature elements'
  tables print (`Golden/elements/`). After a deliberate change to the printer,
  `MOUNTAYA_GOLDEN=write swift test --disable-xctest --filter "ClientPrinterTests|ElementsPrinterTests"`
  rewrites them, and the diff is the review.
- The public API's baseline is `Tests/BoundaryTests/Baseline/<Product>.txt`, one per product.
  After a deliberate change to the API, `mise run api:update`, on macOS, prints all five again,
  `MountayaNavigation.txt` and `MountayaElements.txt` from the consumer built for the iOS simulator
  with the `Elements` trait, and a line removed or changed is a break. It runs
  `swift test --disable-xctest --filter PublicAPITests` with `MOUNTAYA_API_BASELINE=write`, the
  switch the suite reads.
- `MountayaNavigation` links no third-party package and needs no trait: the engine and every seam
  but the voice build and run their tests on every host. The voice over the system's speech,
  `Speech/`, exists only in an iOS build, and its tests speak through the audio session, which runs
  on iOS alone. `mise run test:ios` builds `MountayaNavigation` for the device and the simulator,
  warnings as errors, then runs `Tests/MountayaNavigationTests/Speech/` with `xcodebuild test` on
  the simulator `mise.toml` names. Those tests are a package of their own because `xcodebuild`
  would build every test target of the root package for the simulator, the gate's tools among
  them, which cannot build for iOS. `mise run test:device` runs it, then `test:ios:elements`
  (below), and `ci` runs `test:device` after the host suites.
- The `Elements` trait's code exists only in an iOS build with it on, which `xcodebuild` cannot ask
  of a root package. `mise run test:ios:elements` builds `MountayaElements` that way for the device
  and the simulator, warnings as errors, then `Tests/MountayaElementsTests/Renderer/`, a package of
  its own that turns `Elements` on, as a map-only app does, runs its tests on the simulator against
  a stub of the Tile API served to MapLibre's own loader, so no test reaches the network. Both
  resolve one MapLibre, 7.0.0, at the floor of its range. Linux runs never turn the trait on, so
  they download no MapLibre binary.
- `Package.resolved` is written with the trait on, by `swift package --traits Elements resolve`,
  never `update`. SwiftPM 6.4 drops the trait-gated pins from any file it writes anew, `resolve`
  included where the manifest's dependencies changed: a change to them keeps the three pins by
  hand under the manifest's new `originHash`. `Tests/Consumer`, the Renderer package, Trail's
  package and Trail's Xcode project take the root's pins, and the Speech package and Trail's session
  server the root's but MapLibre's, since they turn no trait on. A file's `originHash` is the
  SHA-256 of its own package's `Package.swift`, byte for byte: after any edit of one of the six
  manifests, a comment's included, write `shasum -a 256 <dir>/Package.swift` into that file's
  `originHash`, its pins kept, or a Linux run, with its trait off, writes the file again without
  them. BoundaryTests fails on a stale hash and prints the one to write. The Xcode project's file,
  `Examples/Trail/Trail.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`, carries
  the hash Xcode wrote, which no manifest gives: Xcode resolves the newest releases where nothing
  pins them, so it keeps the root's pins under that hash, and `test:trail` builds with
  `-onlyUsePackageVersionsFromResolvedFile`.
- The README's Swift snippets are printed into `Tests/Consumer/Sources/ReadmeSnippets/`. After
  changing one, `MOUNTAYA_README=write swift test --disable-xctest --filter ConsumerPackageTests`
  prints them again. A fence that cannot compile opts out with `<!-- swift:skip <reason> -->`, and
  a fence that needs an iOS build with the trait is compiled by `Tests/Consumer/Sources/Consumer/`,
  which its reason names. The same suite holds the README's floors table, `| Floor | Version |`
  under `## Install`, to `Package.swift`'s tools version and platforms and iOS's row to Trail's
  project (`ReadmeFloors` in `Tools/GateSupport`), and refuses a floor's number on any other line
  of the README: a floor raised in the manifest fails the gate until the table follows (SPEC.md
  section 2).
- The skill `mountaya-sdk-swift` lives in `mountaya/ai`, the manifest's other sibling, checked
  out beside this one. `SkillSnippetTests` reads it at every run and keeps no copy: its Swift
  snippets are printed as the README's are, under the same skip marker, and type-checked beside the
  README's prelude against the consumer built for the iOS simulator with the `Elements` trait, each
  it guards for a server, `#if os(macOS)`, which compiles to nothing there, again against the
  consumer built for macOS, and the floors it states are held to `Package.swift`. A missing `../ai`
  skips those tests with a note here and fails them in CI, whose Linux run reads the fences and the
  floors but compiles nothing.
  A snippet that fails is fixed in the skill, in `ai`, never here.
- Every hot path the contract's `sdk/hot-paths.yaml` lists for Swift keeps a budget test beside its
  subject, titled `hot-path budget <id>:`, asserting its count of work against a top-level
  `let <id>Budget` in lowerCamelCase, and that the work still happened (SPEC.md section 7).
  `HotPathBudgetTests` scans every test file, the Renderer's and the Speech packages' included, on
  every host, and fails on a listed path with no live test, an unlisted id, a test asserting
  nothing against its constant, a file declaring none, and a test switched off. A count no API
  shows is read through an internal probe nothing installs in an app: Geo's `MeasureProbe`, a
  task-local, and the renderer's `RenderProbe`, an environment value. A budget that fails is work
  that grew: fix the work, never raise the number without saying why in review.
- A conformance script over an engine bound to the main actor settles each step in `Quiescence`'s
  rounds (`Tests/ConformanceTests/Harness/Quiescence.swift`), until what it reports, what the
  engine shows and what its doubles hold, has stood still for three rounds, each awaiting a job of
  low priority on the shared pool and then sixteen turns of the main actor. Never settle one by a
  count of turns: an engine holds a script's closures and doubles as functions of no actor's, so
  each call and return is a hop off the main actor and back, which a loaded machine can hold back
  for more than sixteen turns (SPEC.md section 9). Every case passes serial runs under busy loops,
  the stress that holds it.
- Trail, the sample app every native SDK ships, is `Examples/Trail`, as the contract's
  `sdk/trail.yaml` describes it (SPEC.md section 7), MIT-licensed by `Examples/LICENSE`, sdk-typescript's
  `examples/LICENSE` byte for byte. Its sources, `Sources/Trail/`, are read by `Trail.xcodeproj`,
  which a developer runs, and built by its `Package.swift` for the size gate; its settings come from
  the gitignored `Config/Local.xcconfig` (`Local.xcconfig.example` is committed) or the
  environment; its session server is `Examples/Trail/Session`, a package of its own over
  `MountayaAdmin`, which Trail never links. Each step's code is marked `// trail: <id>`, and
  `TrailScenarioTests` (BoundaryTests, over `Tools/GateSupport/TrailScenario.swift`) fails on a step
  with no marker, a marker naming no step, a value under `Examples/` that git commits in either
  shape `sdk/SPEC.md` gives a credential, `(pk|sk|sess)_` and 32 lowercase hex characters, or a
  session token's `sess_`, unpadded base64url JSON, a `.` and a signature, an itinerary copy that
  differs by a byte and a missing licence; `Config/Local.xcconfig` and build
  output are never read. `mise run test:trail` walks the journey with `TrailUITests`, and
  `test:device` runs it last. A change to the API Trail calls changes Trail in the same change.
- What the SDK adds to an app has a baseline, `Tests/BoundaryTests/Size/ios.json` (SPEC.md section
  7). `mise run size:check`, on macOS, builds Trail's package in release for an iOS device in
  `.build/trail-ios-release-<major.minor>`, linking it again each run, and `Tools/SizeGate` reads the
  linker's map module by module: each library product is a share, and so is each module of another
  package the build links, `Crypto` today, recorded with its package and the version Trail's
  `Package.resolved` pins; MapLibre, a dynamic framework, is none. A share grown past 2% of its
  baseline or 16 KiB, whichever is larger, fails, and so do a module the baseline does not record and
  a missing baseline; a baseline measured to another version of `sdk/trail.yaml` (read from
  `../schemas`), or with another Xcode or Swift, is reported and not compared, and so is a module
  brought at another version. Each share is one line, `name: bytes, ±change (±%), within tolerance`
  or `past tolerance`. `MOUNTAYA_SIZE_BASELINE=write mise run size:check` records the figures after
  a deliberate change or a new Xcode, and the diff is the review. A share that grew is code or data
  every app now carries: find it before recording it. `swift run SizeGate --map <file>` reads a map
  a build already wrote. `ci` runs it after `test:device`.
- A conformance report carries `modelDigest`, the digest of the model and the elements' data in the
  checkout its run read (`sdk/SPEC.md` section 11), and a run refuses to report while the client's
  printed `modelDigest` names other files: `mise run generate` first.
- A plain test run never writes into `schemas`. Only `conformance:report` does, from macOS, and
  a Linux run given `MOUNTAYA_CONFORMANCE_REPORT=check`, as `ci:linux` gives both legs, holds
  itself to that report instead.
- CI runs `mise run ci:linux` on every push to Entire, on a Depot Ubuntu runner
  (`.depot/workflows/ci.yml`, rendered from the manifest's one job, `linux`), with `schemas` and
  `ai` checked out beside this one at the commits `siblings.lock` pins: the format, layout and
  naming lints and the printed files' check, then every suite at the pinned toolchain and at the
  floor, each in the Swift container (`scripts/lint-linux.sh`, `scripts/test-linux.sh`, which
  mounts both checkouts read-only). It leaves to macOS what needs Xcode: the toolchain check, the
  Apple platform builds, the iOS simulator suites, the naming law over the iOS build, the API
  baselines, the skill's snippets type-checked for iOS and the size gate. A push CI passes is not done until
  `mise run ci` passes on macOS; `ci` runs `ci:linux` last.
- `ci` runs its tasks in order and stops at the first that fails. The coverage tests run inside
  `test` and both Linux legs, so a capability the registry adds without its runner stops the gate,
  and so does a name its `swift` column publishes that no product's API baseline declares at that
  path, or a `swift: scoped` the scope table does not hold (SPEC.md section 5).
- `ci` starts with `clean`, which deletes what the builds left behind in the repository and no
  longer use, and nothing outside it: a `.build/linux-<version>`,
  `.build/consumer-<host>-<major.minor>` or the size gate's `.build/trail-ios-release-<major.minor>`
  neither pin names, the release build the size gate measured before Trail,
  `.build/consumer-ios-release-<major.minor>`, a `.build/platforms/<name>` no task builds any more,
  and the resolve-only `.build` of the packages under `Tests/` and `Examples/`. So a pin that moves
  frees its old builds at the next gate. The `swift:<version>-noble` images the Linux runs pulled live in
  Docker's disk, which every project on the machine shares, so the gate never deletes one:
  `mise run clean:toolchains` lists those of a Swift no Mountaya checkout pins any more, and
  deletes them with `-- --yes`. It is the person's to run, and an agent is denied it. `disk:check`
  then stops the gate before it starts where the disk has less than 35 GB free for a first gate or
  15 GB for a later one (`MOUNTAYA_MIN_FREE_GB` asks for another figure), naming both: a full disk
  stops a build part-way and every other program on the machine that writes. `.build` holds about
  25 GB, so never copy the repository to build it elsewhere: the copy builds its own.
- A release is a tag, in three steps. `mise run version <version>` (`scripts/version.sh`) writes it
  into the files, `ClientIdentification.version`, the one every request names in
  `X-Mountaya-Client`, the README's install lines and `CHANGELOG.md`'s `[Unreleased]` notes, dated
  under the version; it edits files alone, so an agent may run it, and run again it changes
  nothing. The person commits that as `version: Release v<version>` and pushes `main`, and CI runs
  on it. Then `mise run release <version>`, the person's alone (`bash scripts/release.sh --help`),
  refuses, every refusal told together and each with what to do: a tree that is no clean `main` at
  the commit Entire's `main` is at, a version that is not MAJOR.MINOR.PATCH or not newer than every
  `v*` tag here, on Entire and on the mirror, a tag of it anywhere but on this commit, CI not
  finished green on the commit (Depot), a version other than `ClientIdentification.version` or the
  README's install lines, no dated `CHANGELOG.md` section of it, a sibling that is not clean at its
  pin (`sh .agents/siblings at-pins`), a licence text that differs from sdk-typescript's, and, while
  `ci:local` has not passed on the commit, no booted simulator of the one `mise.toml` names.
  `--check` stops there and changes nothing. It then says what it will do and asks, runs
  `mise run disk:check` and `CI=true mise run ci:local` unless they passed here on the commit
  already (a marker under `.git/mountaya/release/`), tags `v<version>`, annotated, with the
  version's section as its message, pushes the tag alone to Entire, and waits, ten minutes at most,
  until the GitHub mirror lists it: the tag is the publish. It makes no commit and pushes no
  branch, and every step reads where it stands from the clone and the remotes, so run again after a
  stop it resumes. Nothing pushes to the mirror by hand: `.depot/workflows/mirror.yml`, rendered by
  `ai`, pushes every push of `main` and every `v*` tag from Entire, and makes the tag's GitHub
  Release. `mise run test:release` (`scripts/test-release.sh`), which `ci:linux` runs, holds both
  scripts to all of it against fakes.

**No failure is expected.** Every case of every runner passes on macOS, on the iOS simulator and
in both Linux containers, and so does `every capability has a runner or a scope sentence`: every
capability the registry declares has its runner or its scope sentence, 226 of the 262 run, the 45
`map.*` ones by the map engine, its rules and the editing engine's magnet, and the other 36, every
`studio.*` entry and `transport.browser.secret-key`, reported `scoped`, as `sdk-kotlin` and
`sdk-dart` report them, and so does
`every published name is declared, or its capability scoped`, each name of the registry's `swift`
column the exact path of a declaration of the baselines, and so does the column's agreement with
the scope table. A capability the registry adds fails the coverage test, and a name its `swift`
column publishes that no baseline declares fails the second, and the list each prints is the work
left. Do not silence either and do not add a runner that proves nothing: a declaration renamed, or
a label changed, moves its name in the `swift` column, in `schemas`.

## Where things are

```
Package.swift                       five products, MountayaClient, MountayaAdmin, MountayaGeo, MountayaNavigation and MountayaElements, whose view is behind the Elements trait
LICENSE.txt, LICENCE.fr.txt         the Mountaya SDK License 1.0, verbatim, the TypeScript packages' own
CHANGELOG.md                        the package's versions, [Unreleased] first; held to the products' names by BoundaryTests
scripts/version.sh                  `mise run version`: the version written into ClientIdentification.version, the README and CHANGELOG.md
scripts/release.sh                  `mise run release`: the checks, ci:local once per commit, the tag, its push and the wait for the mirror
scripts/test-release.sh             `mise run test:release`: both scripts against fakes, in a scratch workspace, which `ci:linux` runs
scripts/clean.sh                    `mise run clean`: what the builds left in the repository and no longer use, the gate's first step
scripts/clean-toolchains.sh         `mise run clean:toolchains`, the person's: the Linux images of a Swift no checkout pins
scripts/test-linux.sh, lint-linux.sh  the suites and the lints in the Linux container, which `ci:linux` runs
.depot/workflows/ci.yml             rendered from .agents/manifest.json: `mise run ci:linux` on every push to Entire
.depot/workflows/mirror.yml         rendered by `ai`: every push of `main` and every `v*` tag, from Entire to the GitHub mirror
Sources/MountayaClient/<Topic>/<Kind>/   Contracts, Engines, Rules; Seams is a topic
Sources/MountayaAdmin/              the client's admin unit: Webhooks/Rules/ (constructWebhookEvent, the signature header, the HMAC); the rest is printed
Sources/MountayaGeo/<Topic>/<Kind>/ the geo layer and navigation's rules, engine protocol, machine, scripted engine and guidance (Navigation/: the plan and the prompt due), the itinerary resource engine over its source seam, the controls' and panels' rules and engines (Controls/ the locate control's and a panel's layout), the organization's rules (Organization/: the watermark, its frame from the map's safe area and what keeps clear of it), a readout's rows and where it stands (Readout/), the terrain read off the elevation tiles (Terrain/), each engine over a target protocol, the search engine over its fetch seam (Search/), and the data elements' rules (Profile/, a place's card under Waypoints/); links the client, calls nothing itself
Sources/MountayaNavigation/         Seams/ (location sources, voices), Guidance/ (the engine over Geo's machine and its guidance), Speech/ (the voice over the system's speech, which an iOS build alone compiles)
Sources/MountayaElements/           Map/ (the state, the engine, the organization's reads every map shares and the elevation tiles a readout reads, the one layer registry, the slots' requests, the patch rule, the sprite, missing-image, stripe and pin rules, the camera, query, event and credit rules, the base map, road access, analysis, geometry slot and search highlight rules, the cursor marker and leg emphasis rules over their target protocols, and under Testing/ the scripted surface), Edit/ (the magnet), Seams/ (the device's language and position, and an elevation tile's image read by the platform's codec), Renderer/ (the one directory that knows MapLibre, SwiftUI and UIKit: the views, the watermark and the readout, the controls and the panels, the search box, the data elements and the link each writes to its map, the renderer, the request hook, a glyph's geometry, the map's images, its credit sheet, the environment's scope and tokens and a token as a colour)
Tools/GateSupport/                  the lexer, the order-preserving JSON reader, the registry reader, the baselines' declared paths, the snippets' printer, the consumer's builds and their type-checker, a document's fences as files of their own, the README's floors table rule, the hot-path budgets' list reader and scanner, Trail's scenario reader and scanner, the linker map's reader and the size rule, the rules
Tools/ClientPrinter, GenerateClient the printer of the generated surface, as a library and an executable
Sources/MountayaClient/Generated/   printed from sdk/model.json, the core's unit; never edited, outside the layout and naming laws
Sources/MountayaAdmin/Generated/    printed from sdk/model.json, the admin unit's: the admin accessors, AdminSchema, their facts, WebhookEvent; the same
Sources/MountayaGeo/Generated/      the elements' words, tokens and glyphs, printed from sdk/elements/; the same
THIRD-PARTY-NOTICES.txt             Lucide's ISC and Feather's MIT licences, printed from sdk/elements/NOTICE
Tools/LintNaming, LintFileStructure the two lints, as executables
Tools/SizeGate                      the app-size gate over Trail, as an executable, which `mise run size:check` runs on macOS
Tools/CompileSnippets               `mise run snippets`: the Swift fences of the Markdown files it is handed, each a file of its own under .build/snippets, type-checked against the consumer's builds, on macOS
Tools/Simulation                    simulated time: a serial executor whose idleness moves a virtual clock
Tests/<Target>Tests/                mirrors Sources/ path for path
Tests/MountayaNavigationTests/Speech/   the Speech topic's tests, a package of its own, run on the iOS simulator
Tests/MountayaElementsTests/Renderer/   the Renderer topic's tests, a package of its own with Elements on, run on the iOS simulator
Tests/BoundaryTests/                import scans, the built-artifact walk, the suppression ledger, determinism,
                                    the consumer build, the API baseline (Baseline/), the licence, the
                                    skill's snippets and floors, read from ../ai, the hot-path budgets,
                                    held to ../schemas' sdk/hot-paths.yaml, Trail's scenario, held to
                                    its sdk/trail.yaml, and the size gate's baseline (Size/)
Tests/Consumer/                     the outside-in consumer package: plain imports, the README's snippets
Examples/LICENSE                    the examples' MIT licence, sdk-typescript's examples/LICENSE byte for byte
Examples/Trail/                     Trail, the sample app (sdk/trail.yaml): Sources/Trail/ (the app, and its copy of the demo itinerary), Trail.xcodeproj (run it from there), Package.swift (the size gate's build), Config/ (Info.plist, Trail.xcconfig, Local.xcconfig.example; Local.xcconfig is gitignored), TrailUITests/ (the journey)
Examples/Trail/Session/             Trail's session server, `mise run trail:session`, a package of its own over MountayaAdmin, with its tests
Tests/ConformanceTests/Harness/     fixtures, comparison, coverage, the scope table, the report, and the scripts' waits: Quiescence, ManualTime, MainQueue
Tests/ConformanceTests/Runners/     Public/ for `api: true` (plain import), Internal/ for the rest
Tests/ClientPrinterTests/Golden/    the miniature model and the files it prints, byte for byte
```

Adding a capability is: the rule under `Sources/`, under the names its registry entry publishes,
its mirrored unit test, and a runner in the table its registry entry's `api` flag names. The
coverage tests then stop listing it, once the API baselines are printed again.

## What is settled

- **The units are products `MountayaClient`, `MountayaAdmin`, `MountayaGeo`, `MountayaNavigation`
  and `MountayaElements`.** One repository holds them all, because an SPM product is the boundary
  unit: a consumer links the products they name and nothing else. Resolution is wider than
  linking, so the one heavy dependency, MapLibre, sits behind a package trait, `Elements`, off by
  default, which keeps it out of resolution; the navigation engine links no third-party package
  and needs none (`SPEC.md` section 2).
- **The client is two units, the core and the admin unit, as the contract declares** (`sdk/SPEC.md`,
  "The three layers, in every language"). The printer splits the generated surface by the model's
  `unit` and by no list of its own; `MountayaAdmin` declares `admin` on the core's `Mountaya` in an
  extension, holds the admin unit's components in `AdminSchema` (the word `sdk-kotlin` and
  `sdk-dart` print too), and reaches the core's transport through `package` declarations, the
  second reach `SPEC.md` section 2 names. No product of the core imports it, which the boundary scan
  holds, and the size gate holds Trail's share of it at 0. `WebhookSignatureError` stays the
  core's, carried by `MountayaError.webhookSignature`, so the one `catch` an app writes catches a
  delivery's refusal too.
- **The order is the rest of transport, then the renderer-free geo layer, then the navigation
  engine and the elements.** The elements own the `map` layer's engines, so `map.*` is run here
  rather than scoped.
- **Navigation is contract.** Its rules are the `geo.navigation.*` capabilities and §14 of
  `sdk/SPEC.md`, which v0.9.0 carries; `MountayaGeo` holds them, the navigation vocabulary, the
  `NavigationEngine` protocol, the machine and the scripted engine, and `MountayaNavigation`'s
  engine stands on them through Geo's public API alone, over no navigation library.
- **The studio is TypeScript-only.** No studio product is written here.
- **An `operationId` is the method name, verbatim, in every language at once.** There is no rename
  table; the contract freezes an operation from 1.0, and below it a minor of the contract may
  rename one, which a regeneration then carries.
- **Every capability in `sdk/registry.yaml` needs a conformance runner here, or is scoped
  with its sentence in `SPEC.md` section 11.** The scope table is held to those sentences by a
  test that reads `SPEC.md`, so section 11 keeps its number and each scope bullet its bold
  opening.

## Key rules

- **Git is strictly read-only.** `git diff`, `git log`, `git blame`, `git show`,
  `git status` only. Every mutating command is the user's.
- **Never hand-edit a generated file.** The next regeneration overwrites it, and the
  defect it was papering over is in `mountaya/schemas`.
- **Never edit a fixture to make a test pass.** A disagreement is a defect here or a
  defect in the contract, and the second one is fixed in `schemas` under a new tag.
- **Ask before deciding.** Where `SPEC.md` is silent, ask, then write the answer into `SPEC.md`.
  This repository ships to consumers who cannot be refactored.
- **No suppression without its sentence.** `@unchecked Sendable`, `nonisolated(unsafe)` and
  `@preconcurrency` are counted by a test; the count is zero.
- **A floor's number lives in `Package.swift` and in the README's floors table, and nowhere else.**
  Anywhere else, prose names the reason for a floor, never its number; raise a floor in the
  manifest and the table in the same change, which the README's suite holds.

<!-- mountaya-ai:tooling:begin -->
<!-- Generated by mountaya/ai (scripts/apply.mjs). Edit .agents/manifest.json instead. -->

## Agent tooling

`entire` and `mise` are required. Every other tool here is optional, and nothing in the repository fails without it.

| Tool | What it does here | Install | Without it |
| --- | --- | --- | --- |
| `entire` (required) | Hosts every Mountaya repository and records agent sessions as checkpoints linked to commits; its git hooks record every session. Its Graph plugin answers structural questions (where a symbol is defined, what calls it, what a change breaks); its Brain plugin holds the memory of past work. | CLI 0.12.2 or newer: `brew install --cask entireio/tap/entire` (Linux: `curl -fsSL https://entire.com/install.sh \| bash`), then `entire login`. Plugins: `entire plugin install brain` (0.4.0 or newer) and `entire plugin install graph` (0.6.0 or newer), then `entire brain setup --no-backfill --no-daemon`. For recall across repositories: `entire brain workspace create mountaya`, then `entire brain workspace add mountaya <path>` for each checkout | Nothing can be cloned or pushed, sessions are not recorded and the git hooks skip Entire's steps. Without the plugins, fall back to search and reading files. |
| `mise` (required) | Installs every tool the repository's commands run, at the version its `mise.toml` pins (Node, Go, the linters, the CLIs), and the git hooks run every step on them. Docker Desktop is the one tool installed by hand. | `sh .agents/setup` installs it (`brew install mise`), then add `eval "$(mise activate zsh)"` (or bash, fish) to your shell profile so a shell in the repository uses the pinned tools | The git hooks refuse every step, and a command runs on whatever version the shell happens to have. |
| `rtk` | Rewrites shell commands so their output costs fewer tokens. A user-level hook, never a repository setting. | brew install rtk, then add the `rtk hook claude` PreToolUse hook to ~/.claude/settings.json | Nothing breaks. Command output is unfiltered. |
| `context-mode` | Runs large-output work (logs, JSON, web pages) in a sandbox so only the answer enters the conversation. | claude plugin marketplace add github:mksglu/context-mode | The `ctx_*` tools do not exist. Read files with offset and limit instead. |

`sh .agents/setup` installs or updates everything this table names, and checks the rest. It is the person's to run; an agent runs it with `--check` only, to report what is missing.

### Code structure

Ask Entire Graph before searching by hand: `entire graph query --profile full "<the task in one sentence>"` finds the code for a task, and `entire graph impact --symbol <name>` shows what a change to a symbol reaches. `entire graph agent-guide` is the reference for the installed version; the `graph-first` skill says when to use which.

<!-- entire-agent:begin -->
### Memory of past work

- Start a substantial task with `entire brain brief "<task>" --json`. Look for earlier work with `entire search "<topic>" --compact`, and across every Mountaya repository with `entire brain workspace query mountaya "<query>"`.
- Record a decision, gotcha or invariant the code cannot show with `entire brain remember "<fact>" --kind decision|gotcha|invariant`, and read them back with `entire brain recall "<query>"`. `--path` takes a taxonomy path (`architecture.billing.decision`), never a file; `recall --locus <file or symbol>` narrows to code. A fact about the repository goes to Brain, which every agent shares; an agent's own memory is for the person's preferences.
- Brain records into the repository the command runs in, and Entire records a session in the repository its working directory is in. So a session that changes a sibling works inside it: `cd ../<repo>` stays there for a session that lists it among its working directories, as platform's lists every sibling, Entire then records the session there too, and the commit the person makes there links its checkpoint. Read the sibling's AGENTS.md before changing it, since its rules do not load from here. A fact about a sibling is recorded from inside it (`cd ../<repo> && entire brain remember ...`), and one that holds in every repository with `--global`.
- Before changing a line you do not understand, ask `entire why <file>:<line>`: it names the commit, the checkpoint and the prompt behind it.
- Brain and checkpoints say what was decided and what went wrong before. Current source and a passing test outrank both.
- `entire brain setup` without `--no-backfill --no-daemon` installs a background service and spends model tokens distilling past sessions. Choose that deliberately: `entire brain workspace watch mountaya` keeps every brain of the workspace fresh and spends none.
<!-- entire-agent:end -->

### Review and CI

- Before you report a change done, run `sh .agents/siblings gate`. It runs the quick gate (`mise run ci:quick`) of every repository checked out beside this one that the change reaches, one at a time, with the render check of each one ai renders where ai changed and `mise run generate:check` where a sibling it reads changed; `sh .agents/siblings impact` lists them first, and why. A change to ai or schemas is done once every repository it reaches passes.
- CI runs on Depot for every push to Entire (`.depot/workflows/ci.yml`): `mise run ci:linux`, part of the gate, as one job, a check on the commit. The whole gate, `mise run ci` (tests and the build), runs only where you work. Pre-commit runs formatting and linting (`mise run ci:quick`). Run the gate yourself before you report a change done. `depot ci run list` and `depot ci logs <run>` read CI's runs, and `depot ci run --workflow .depot/workflows/ci.yml` runs CI's part on your uncommitted changes.
- CI builds against the sibling commits `siblings.lock` pins, fetched as the bundles each sibling's own CI publishes on every push. Pre-commit stops while any sibling checked out beside this one has uncommitted or untracked files or a HEAD no remote branch holds, naming each one and what to do. It then pins each sibling whose HEAD moved forward and stages the lock, so a commit pins the sibling commits it was tested against: it stops on a HEAD behind or diverged from its pin, it keeps the pins of a commit that changes the lock itself or concludes a merge, and `SIBLINGS_ALLOW_DRIFT=<name>` leaves a pin where it is, never past uncommitted or unpushed work. Pre-push stops a push whose commit carries no lock, which CI's checkout stops on, or whose pin no remote branch holds or its sibling's CI never ran on, so no bundle of it exists. `sh .agents/siblings status` shows each pin beside its sibling's HEAD and CI run, `sh .agents/siblings pin` moves pins by hand, and `sh .agents/siblings at-pins`, which a release runs before it tags, stops unless every sibling is checked out, clean and at its pin.
- A release of this repository runs with the rest of the workspace's, from ../platform (`mise run release`), and is a person's. `mise run version <X.Y.Z>` writes it into the files, and an agent may run it; `mise run ci:local` is the part of the gate CI cannot run, which the release runs on the commit it tags; `mise run release <X.Y.Z>` tags the pushed commit CI passed, publishes what a registry lacks and waits for the mirror, and run again it resumes where it stopped.
- Every push of `main` and of a release tag (`v*`) also reaches the read-only public mirror, https://github.com/mountaya/sdk-swift, which Depot CI pushes (`.depot/workflows/mirror.yml`) and nothing else does. Published metadata and links for readers name the mirror; contributors clone, push and review here.
- Review happens on Entire trails. Read one with `entire trail show <number>` and answer its findings with `entire trail finding` (the `address-findings` skill). Creating, approving and merging a trail is the person's.
- Entire's repository, trail, login and setup commands are the person's too: suggest them, never run them.

### Shared conventions

Claude Code: model `claude-opus-5-5`, effort `xhigh`, plugins `mountaya-core@mountaya`, `entire@entire-skills`, `mountaya-swift@mountaya`, all set in `.claude/settings.json`.

Any other agent: the same conventions are plain skills in the `mountaya/ai` repository (https://github.com/mountaya/ai), installed for your user (`-g`) rather than into this repository. `sh .agents/setup` does it for Codex and Cursor; by hand, from a checkout beside this one:

```bash
npx skills add ../ai -g --skill graph-first --skill retrieve-via-ctx --skill swift-conventions
```

Entire's own skills (search, explain, recall, review, address-findings and the rest) come with `entire@entire-skills` in Claude Code. Any other agent installs them with `npx skills add https://github.com/entireio/skills -g --all`.

<!-- mountaya-ai:tooling:end -->
