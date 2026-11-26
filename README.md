# Mountaya Swift SDK

The documentation is at [docs.mountaya.com/en/sdks/swift](https://docs.mountaya.com/en/sdks/swift/):
installing the package, a first map, the client, the map's elements and navigation, a page each.

Mountaya's Swift SDK, written against contract v0.9.0 of
[`mountaya/schemas`](https://entire.com/et/mountaya/schemas). It declares five products, the units every Mountaya SDK shares, each listed
with its TypeScript twin in [the API by capability](https://docs.mountaya.com/en/sdks/swift/reference/api/).
The first three run on iOS, iPadOS, macOS, Mac Catalyst, tvOS, watchOS, visionOS and Linux:

- `MountayaClient`, the client for the Map Studio API, the Tile API and the GraphQL Data API,
  holding every transport rule the contract states: credentials and the session lifecycle,
  retries, idempotency keys, conditional writes, the error ladder, dates, pagination, event
  streams and field selection.
- `MountayaAdmin`, the client's admin unit, for a server and an admin tool: the operations that
  run an organization, its members, keys, invitations, billing, users and webhook endpoints, and
  the one that mints a session token, as `client.admin` once it is imported, and the verification
  of the webhook deliveries Mountaya sends. An app that shows a map, reads data or navigates needs
  none of it, and does not link it.
- `MountayaGeo`, what Mountaya decides about that data: distances and units, formatted values, the
  elevation profile, a segment's road access, the camera, the map's layers and icons, search rows,
  and navigation's rules, with the `NavigationEngine` protocol and a scripted engine for an app's
  tests. It calls nothing.

The other two are for an app that follows a route and an app that shows a map:

- `MountayaNavigation`, the engine an app navigates with: the contract's navigation over Geo's
  machine, which says each maneuver aloud in your words. It calls nothing either: the route comes
  from your own client. It follows a route on every platform, reads the device's position where
  the platform has one, and speaks each maneuver through the system's voice on an iPhone or iPad.
- `MountayaElements`, the map, for an iPhone and iPad app, which turns it on with the package's
  `Elements` trait: a SwiftUI view over [MapLibre Native](https://maplibre.org), drawing the state
  a map engine holds, every layer ranked as the contract ranks it and every tile fetched with your
  client's credential, with its controls, its panels, its search, and the data elements over an
  itinerary: its elevation profile, its two tables and a place's card. The engine and its state
  build on every platform, for an app that draws its own map.

[SPEC.md](SPEC.md) is what the SDK is and will be, and [AGENTS.md](AGENTS.md) the rules a change
to it is held to.

## Install

Each release is a tag on this repository's public, read-only GitHub mirror,
`https://github.com/mountaya/sdk-swift`, which SwiftPM resolves. A package depends on it from
the release it was written against, and names the products it links. `MountayaAdmin` is optional:
a server that mints session tokens, runs its organization or receives webhooks, and an admin tool,
name it beside `MountayaClient`, and an app names it never.

<!-- swift:skip a manifest, which Tests/Consumer/Package.swift declares the same way -->
```swift
dependencies: [
  .package(url: "https://github.com/mountaya/sdk-swift", from: "0.1.0")
],
targets: [
  .target(
    name: "App",
    dependencies: [
      .product(name: "MountayaClient", package: "sdk-swift"),
      .product(name: "MountayaGeo", package: "sdk-swift"),
    ]
  ),
  .target(
    name: "Server",
    dependencies: [
      .product(name: "MountayaClient", package: "sdk-swift"),
      .product(name: "MountayaAdmin", package: "sdk-swift"),
    ]
  ),
]
```

These are the oldest Swift and the oldest release of each platform the package builds for, as its
`Package.swift` declares them, and SwiftPM, or Xcode for a project, names the one yours falls short
of:

| Floor | Version |
| --- | --- |
| Swift | 6.2.3 or newer |
| iOS and iPadOS | 17 or newer |
| Mac Catalyst | 17 or newer |
| macOS | 14 or newer |
| tvOS | 17 or newer |
| visionOS | 1 or newer |
| watchOS | 10 or newer |

Each platform's floor is the release Observation arrived in, which every engine a view draws is
observed through, and Trail, the sample app, targets the iOS one. Linux takes no floor of its own:
the client, the admin unit, the geo layer and the navigation engine build wherever that Swift runs.

## A first call

```swift
import MountayaClient

let client = try Mountaya(
  credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"),
  language: "fr"
)
let itinerary = try await client.studio.itineraries.getItinerary(itinerary_id: "itn_4e5f")
print(itinerary.data.name, itinerary.status, itinerary.requestId ?? "")
```

`Mountaya` is the one type that reaches the network. An operation hangs where the contract files
it: `client.studio.itineraries`, `client.agent.runs`, `client.tiles`, `client.data`, and
`client.admin.organizations` once `import MountayaAdmin` declares the admin unit's `admin` on the
client. Each method is named by the contract's `operationId`, verbatim,
and takes its path parameters by name, its query as one `query:` value and its body as one
`body:` value. Every method that calls the API is `async throws`, and every one ends with
`options:`; a walk of a listing, `walk` before its operation's name or `walk(_:path:…)` by its
declaration, is synchronous, refusing a page size out of range where it is called, and asks for
each page as its rows are read, and so is an event stream's method, which awaits nothing, since the
stream opens as its first frame is asked for: `for try await frame in try …`. A member of an
enum is named by its words in lowerCamelCase, `RestSchema.TileLayerType.line` and
`DataSchema.ActivitySlug.hikingAndTrail`, and every enum is an open set: a value this build has
never seen decodes as itself. A web address is a `URI`, the text the answer sent, never rewritten,
which `url` reads as Foundation does; one you build with no scheme is refused before any request.
A credential, a `SessionToken` and a session snapshot print the prefix of each key or token and
`…` in place of the rest, `pk_live_…`, `sess_…` or `share_…`, and a token a function or a source
answers per request by where it is read from; a secret field of the model's, the `token` of the
`Session` a mint answers or a webhook's signing secret, prints `<redacted>`.

A client is configured once: `language` rides every request as `Accept-Language`, and a client
given none sends `Accept-Language: *`, which asks for no language in particular, never for the
device's. Pass
`Locale.preferredLanguages.first` to answer in the user's own. Every request also names the SDK
that made it, `X-Mountaya-Client: mountaya-swift/<version>`, which no call sets.

```swift
import Foundation
import MountayaClient

// The contract tag this build speaks, and the digest of the files it was printed from.
print(schemaVersion, modelDigest)

// A client pointed at another environment, its Map Studio API at a staging origin.
if let origin = URL(string: "https://api.staging.example.com") {
  let staging = try Mountaya(
    credential: .publishable(key: "pk_test_0a1b"), baseUrls: BaseURLs(rest: origin))
  print(staging.baseUrls)
}
```

`schemaVersion` is the contract tag a build speaks, `v0.9.0` for this one: every type and method
was printed from it, and it moves only when the client is printed again from a later tag, apart
from the package's own version, which `X-Mountaya-Client` names. `modelDigest` names the exact
files it was printed from, the contract's model and its elements' data, which a build printed
between two tags differs by while its tag does not.

`baseUrls` points a client at another environment, a staging deployment or a proxy. Each surface's
origin is set on its own, `rest`, `tiles` and `data`, one left out stays Mountaya's,
`BaseURLs.standard`, and an origin may carry a path of its own, a proxy's prefix, which every
request's path follows.

## Examples you can run

Trail, under [`Examples/Trail`](Examples/Trail), is the one sample app every native SDK ships, the
same app in Swift, Dart and Kotlin, as the contract's `sdk/trail.yaml` describes it: one portrait
screen of a map under its zoom, compass, locate, layers, points-of-interest and preferences
controls, its layers panel offering the time slider, a search box over it, an itinerary drawn and
framed, and a sheet with the itinerary's elevation profile, its legs and its places once you open
it, and Start, which follows the whole itinerary end to end, says each maneuver and each waypoint
passed aloud in Trail's own words, and shows what is left of the route until you arrive, on your
iPhone's positions or on a replay that walks the route. You run it from `Trail.xcodeproj`, an
iPhone app that takes this package as a local package with the `Elements` trait on, as yours does,
and reaches the products through their public API alone. Its session server,
[`Examples/Trail/Session`](Examples/Trail/Session), mints the session tokens search needs. Both are
MIT-licensed ([Examples/LICENSE](Examples/LICENSE)), unlike the SDK, so you copy them into your own
code freely.

### First, a publishable key

Trail reads its settings once, as it starts, from `Examples/Trail/Config/Local.xcconfig`, which git
ignores and which you copy from `Local.xcconfig.example` beside it; an environment variable of the
same name, set in the scheme, stands over it. **`pk_…` in this README is a placeholder, not a
working key.** Yours comes from your organization's API keys page in the Mountaya dashboard; the
reference for what each kind of key reaches is at [docs.mountaya.com](https://docs.mountaya.com). A
key is its prefix followed by 32 lowercase hex characters, with nothing in between that names an
environment. A publishable key (`pk_…`) is the one an app carries. A **secret** key (`sk_…`) mints
session tokens and belongs on a server: no app reads it, and an iOS build refuses to construct one
([Credentials](#credentials)).

| Setting | Read by | The key's scopes it needs | What it does |
| --- | --- | --- | --- |
| `MOUNTAYA_PUBLISHABLE_KEY` | the app and the session server | `tiles`, `publishing`, `data` | Every request carries it: `tiles` draws the map, `publishing` reads an itinerary and `data` searches. It carries no `management`, since a session minted for it reaches the device. |
| `MOUNTAYA_ITINERARY_ID` | the app | `publishing` | A published itinerary your key reads, shown and followed in place of the demo. |
| `MOUNTAYA_SESSION_URL` | the app | `data` | Where the app asks for a session token, which search needs: the session server's, `http://localhost:8787/session` from the iOS simulator and `http://10.0.2.2:8787/session` from the Android emulator, or your own backend's. |
| `MOUNTAYA_SECRET_KEY` | the session server | none | Authenticates `postSession`, the one operation the server makes. It never reaches the app. |

With no publishable key, Trail shows a notice in place of the map and the search, and runs
everything that needs no network on its demo itinerary, Chamonix to La Floria: the profile, the
tables, and navigation on the replay. A map the API refuses the key for shows a notice of its own,
naming the `tiles` scope. With no session URL, search stays disabled and says why: the Data API
answers a publishable key only beside a session token.

The session server, `mise run trail:session`, is a Swift program on your Mac over `MountayaAdmin`.
It reads `MOUNTAYA_PUBLISHABLE_KEY` and `MOUNTAYA_SECRET_KEY` from your shell, refuses to start with
a sentence naming the one missing, and answers the app's `POST /session` on `127.0.0.1:8787` with
the session `postSession` mints for your key without `user_id`, so the secret key stays on your Mac.
The iOS simulator reaches it at `localhost`, over plain HTTP to a local address, which Trail's
Info.plist allows and nothing else; the Android emulator of the other SDKs' Trail reaches the same
server at `10.0.2.2`, the host's loopback as the emulator sees it. On an iPhone, point the session
URL at your own backend, over HTTPS.

```sh
cp Examples/Trail/Config/Local.xcconfig.example Examples/Trail/Config/Local.xcconfig   # then fill in what you have
MOUNTAYA_PUBLISHABLE_KEY=pk_… MOUNTAYA_SECRET_KEY=sk_… mise run trail:session   # for search, in a shell of its own
open Examples/Trail/Trail.xcodeproj   # then run the Trail scheme on an iPhone simulator
```

Trail navigates in the foreground alone: it asks for when-in-use location access only when you
press Start with Replay off, reads your position at full accuracy while it is on screen, and
declares no background mode. An app of yours that navigates with the screen off declares `location`
under `UIBackgroundModes` in its Info.plist, with `audio` beside it for the voice, and makes its
source with `DeviceLocationSource(rate: .walking, backgroundUpdates: true)`. [Navigation](#navigation)
says what each declaration does, and each is one App Review reads.

## Credentials

```swift
import MountayaClient

// In an app: a publishable key, and a session token your own backend mints with its secret key.
let engine = SessionTokenEngine {
  try await fetchSessionFromYourBackend()
}
let app = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: .source(engine)))

// For a visitor holding a share link: the share token replaces the key.
let visitor = try Mountaya(credential: .share(token: "share_6a7b"))

// From parts held apart, a key from your configuration and a token from a link.
let linked = try Mountaya(
  credential: Credential(publishableKey: "pk_live_0a1b", shareToken: "share_6a7b"))

print(app, visitor, linked)
```

A session token accompanies a publishable key, and `SessionTokenEngine` keeps one fresh: it mints
through the function you give it, refreshes before expiry, and runs only while something holds it,
which a `Mountaya` built over it does for as long as it lives. It mints the next token 60 seconds
before the last expires, or halfway through a shorter life, from the `expires_at` each mint
answers, never after a `401`. A mint that fails keeps the token it held and is tried again 5
seconds later, each failure in a row after it waiting twice as long as the one before, up to those
60 seconds, a timeout your own call set among the failures; one your app cancels mints nothing
more until `refresh()`, `enable()` or a new subscription asks. A token can also be a plain value,
a minted `RestSchema.Session`, a function read on every request, or any `SessionTokenSource`.

`Credential(publishableKey:sessionToken:shareToken:)` builds the credential from parts you hold
apart, a key from your configuration and a share token from a link, and applies "a share token
replaces the key" itself, so `linked` above sends the share token alone. Parts that make no
credential, a session token with no key among them, are a `ConfigurationError`. A share link that
rides the visitor's own session takes its `Cookie` header from the `cookies:` source you give
`.share`, per request: a read, every Data API query and any `GET`, `HEAD` or `OPTIONS`, goes out
on that session alone, one that requires a session token included, for the server to judge, and
a write under it is refused. `headers(for:language:method:)` answers the headers a credential sends
to an operation, by what it declares and the call's method, `GET` where you name none.

`.secret(key:)` exists on macOS and Linux only, for servers: on iOS, iPadOS, tvOS, watchOS,
visionOS and Mac Catalyst it cannot be named, so a secret key cannot ship in an app. Your backend
mints the token an app's engine fetches through the admin unit, `MountayaAdmin`, under its secret
key, and hands the app the session it answers:

```swift
import MountayaAdmin
import MountayaClient

// On a server: a session token for the user your backend has signed in, for the app to use.
#if os(macOS) || os(Linux)
  func mintSession(forUser user: String) async throws -> RestSchema.Session {
    let server = try Mountaya(credential: .secret(key: "sk_live_0a1b"))
    let minted = try await server.admin.sessions.postSession(
      body: .init(publishable_key: "pk_live_0a1b") { $0.user_id = user })
    return minted.data
  }
#endif
```

The session it answers is the core's `RestSchema.Session`, which an app's `SessionTokenEngine` and
`.minted` read as it arrives.

A credential or a language no request could carry is refused where the client is built, and so is
a base URL with no scheme, `/tiles` or `tiles.example.com`, which only a browser's page could read;
a credential an operation does not take is refused before its request leaves, each as a
`ConfigurationError`.

## Writes

```swift
import MountayaClient

let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))
let zone = try await client.studio.zones.getZone(zone_id: "zon_8c9d")

let renamed = try await client.studio.zones.patchZone(
  zone_id: "zon_8c9d",
  body: .init { $0.name = "Vallée Blanche" },
  idempotencyKey: "rename-zon_8c9d-1",
  ifMatch: zone.data.etag,
  options: RequestOptions(timeout: .seconds(10))
)
print(renamed.status, renamed.data.name, renamed.etag ?? "")
```

A write acts as a member, so it goes out under a session token minted for the `studio-embedded`
surface and naming that member, beside a publishable key that carries the `studio-embedded` scope.
Your backend mints it as [Credentials](#credentials) shows, with the surface and the member set in
the body's closure, `{ $0.surface = .studioEmbedded; $0.user_id = user }`. A token minted for any
other surface, `api` among them, is refused with a `401`, an `.api` error whose `kind` is
`.authentication`, and so is one minted without `user_id`. The mint itself is refused with a
`402`, `.billing`, while the organization does not hold Embedded Studio, and with a `403`,
`.forbidden`, for a key without the scope.

A body takes its required fields as arguments and its optional ones in the trailing closure. A
property that is optional and nullable in the contract is a `T??`: left `nil` it is not sent,
and `.some(nil)` sends `null`, which clears it.

A write that takes an `Idempotency-Key` sends the one you pass, or draws one, and sends it on
every attempt, so a repeated write lands once. `ifMatch:` sends the tag you read the resource
under; a stale one fails with `.api` whose `kind` is `.preconditionFailed`, the contract's
`PreconditionFailedError` by `name`, carrying the resource's current `etag`, and is never repeated. A `Response` carries `data`,
`metadata`, the `status`, and the answer's `requestId`, `location` and `etag`, and `headers`,
every header the answer sent, read in any letter case through `header(_:)`.

## Errors

```swift
import MountayaClient

let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b"))
do {
  _ = try await client.studio.itineraries.getItinerary(itinerary_id: "itn_4e5f")
} catch let error as MountayaError {
  switch error {
  case .api(let apiError) where apiError.kind == .notFound:
    print("gone", apiError.requestId ?? "")
  case .api(let apiError):
    print(apiError.kind.name, apiError.code?.rawValue ?? "", apiError.retryAfter ?? .zero)
  case .connection(let connection):
    print(connection.message, "after every retry it was owed")
  case .configuration(let configuration):
    print(configuration.message)
  case .selection(let selection):
    print(selection.path)
  case .webhookSignature(let refusal):
    print(refusal.reason)
  @unknown default:
    print(error)
  }
}
```

Every error is a `MountayaError`, and a cancelled task throws `CancellationError` as it is. The
ladder grows with the contract, so a `switch` over it ends in `@unknown default`. An error's
`message`, which its description prints, ends on what to do about it, where its status names a
step: the credential to check on a `401`, where a `402`'s remedies are taken, the scope on a `403`,
a stale tag on a `412`, and on a `429` the wait, a ceiling's remedies, or the instant a spent
monthly allowance renews. The error that caused one, a `URLError` or a `DecodingError`, rides
along as its `cause`, never as the type you catch.

```swift
import MountayaClient

// The contract's schedule with a longer budget of waits for this client, and no retry for one call.
let client = try Mountaya(
  credential: .publishable(key: "pk_live_0a1b"),
  retry: try RetryPolicy(waitBudget: .seconds(120))
)
do {
  _ = try await client.studio.activities.getActivities(
    options: RequestOptions(retry: try RetryPolicy(maxRetries: 0), timeout: .seconds(10)))
} catch {
  // Whether an error is one of the family, and whether the API answered it.
  print(isMountayaError(error), isAPIError(error))
}

// A call you withdraw throws `CancellationError`, never an error of the ladder.
let call = Task { try await client.studio.activities.getActivities() }
call.cancel()
do {
  _ = try await call.value
} catch is CancellationError {
  print("withdrawn")
}
```

A `429`, and a `502`, `503` or `504` or a dropped connection where the operation is idempotent or
carries a key, are repeated on the contract's schedule before an error is raised: two attempts
after the first, waits drawn up to a ceiling that doubles from 500 ms to 30 s, or what a
`Retry-After` names, all out of one 60-second budget, and each attempt within the larger of 30
seconds and five seconds past the operation's own time, 35 seconds for a Data API call.
`RetryPolicy`, its `waitBudget` among it, and the `timeout` are the client's to change and a call's
to override through `RequestOptions`.

A ceiling is the one `429` never repeated: the seats, the published itineraries or zones an
agreement allows, the webhook endpoints an organization may hold, the invitations waiting at once
or a personal space's itineraries. It is a `.rateLimit` whose `code` reads `LIMIT_REACHED` and
whose `metadata` names the ceiling with what it allows and what is held, and it names no wait,
since only something freed or a changed agreement lifts it.

An error's `code`, and each entry's, is an `APIErrorCode`, the one vocabulary of every surface's
codes, `.limitReached`, `.idempotencyKeyInUse`, `.validationFailed` and the rest, so you branch on a
member rather than a string. It is open: a code a later release of the API sends is kept exactly as
sent, as `APIErrorCode(rawValue:)`, and never refused. `code` is the first entry's, the one the
ladder classifies by, and `hasCode(_:)` asks every entry, since one refusal may name several codes:

```swift
import MountayaClient

func describe(_ error: APIError) -> String {
  if error.code == .limitReached { return "a ceiling, which no wait lifts" }
  // Any entry, the first or another: one refusal may name several codes.
  if error.hasCode(.validationFailed) {
    return error.errors.filter { $0.code == .validationFailed }.map(\.message)
      .joined(separator: "\n")
  }
  return error.code?.rawValue ?? "\(error.status)"
}
```

`isMountayaError(_:)` and `isAPIError(_:)` answer whether any error is one of the family and
whether the API answered it, by the contract's name each declares, `NamedError.name`, so code
that holds an `any Error`, a logger or a crash reporter's filter, tells them apart without a
`switch`, an error a type of your own rebuilt across a boundary included where it declares the
name it was raised under.

A call is withdrawn by cancelling its task. A task cancelled before the call starts sends nothing,
a cancellation during a request or a wait between two attempts settles it at once, and the call
throws `CancellationError` as it is, since your cancellation is no failure of the API and is never
repeated. A stream or a walk ends the same way when the task reading it is cancelled.

## Lists, streams and the Data API

```swift
import MountayaClient

let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))

// A listing is read a page at a time, each page requested as the rows before it are read.
let itineraries = try client.studio.itineraries.walkGetItineraries(
  query: .init { $0.status = .published }, maxPages: 10)
for try await itinerary in itineraries {
  print(itinerary.name)
}

// An event stream reopens, waits and resumes on the contract's schedule, and ends on `done`. It
// opens as its first frame is asked for, so its method awaits nothing.
for try await frame in try client.agent.runs.getAgentRunEvents(run_id: "run_0f1e") {
  if case .AgentMessageEvent(let message) = frame.event {
    print(message.content)
  }
}

// An editor stream is read as its member's user, which a session token given as a value does not
// name, so that member's own arrival is not read as the stream moving on.
let editors = try client.studio.collab.getItineraryEvents(itinerary_id: "itn_8f14")
for try await frame in editors.reading(asUser: "usr_7a4e") {
  if case .CollabPresenceJoinEvent(let join) = frame.event {
    print(join.user_id)
  }
}

// A Data API call narrows its document to the fields it selects.
let places = try await client.data.geocode(
  input: .init(query: "Chamonix"),
  select: ["places": ["name": true, "point": true]]
)
print(places.places?.first?.name ?? "")
```

Every listing that pages has its walk beside its method, `walk` before the operation's name, which
takes the method's own path and query, a `pageSize`, the operation's own default of 50 unless you
name another, and `maxPages`, the most pages it requests before it stops without an error, and
reads each row as the listing types it; `PageWalk` walks any paged call you hand it. A
`Response`'s `headers` hold every header of the answer.

An operation newer than this build is called by its declaration, written from the contract:

```swift
import Foundation
import MountayaClient

let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))

// A read this build prints no method for, by what the contract declares of it.
let getThing = OperationDeclaration(
  operationId: "getThing", method: "GET", idempotent: true,
  credentials: CredentialDeclaration(requiresSession: true))
let thing: Response<JSONValue, [String: JSONValue]?> = try await client.send(
  getThing, path: "/v1/things/thg_1a2b")
print(thing.data)

// A listing, walked a page at a time: the walk writes the cursor and the page size into your query.
let getThings = OperationDeclaration(operationId: "getThings", method: "GET", idempotent: true)
let things: AsyncThrowingStream<JSONValue, any Error> = try client.walk(
  getThings, path: "/v1/things", query: [URLQueryItem(name: "sort", value: "name")], maxPages: 5)
for try await row in things {
  print(row)
}

// A Data API operation, by its name, its input's type and its field tree.
let input: JSONValue = ["near": [6.86, 45.83]]
let nearby: JSONValue = try await client.query(
  DataOperation(name: "things", inputType: "ThingsInput!", selection: ["things": ["name": true]]),
  input: input)
print(nearby)

// A stream, read as a feed of records.
let getThingEvents = OperationDeclaration(operationId: "getThingEvents", method: "GET")
for try await frame in try client.events(getThingEvents, path: "/v1/things/thg_1a2b/events") {
  print(frame.event.event ?? "", frame.event.data)
}
```

`send(_:path:query:headers:body:idempotencyKey:ifMatch:options:)` takes an `OperationDeclaration`,
its surface, method, idempotence, budget and credential facts, whether it `declaresIdempotencyKey`
and whether it `isConditional`, each fact you leave out the one no operation states, and returns the
envelope with `data` and `metadata` read as the types you name. It takes a body as JSON or as a
form, `.multipart([MultipartPart(name: "file", content: .file(bytes, filename: "tour.gpx"))])`. A
listing this build prints no method for is walked by its declaration,
`walk(_:path:query:headers:pageSize:maxPages:options:)`, which sends your query, cursor and limit
replaced on each page, and answers an `AsyncThrowingStream` of the rows you name, as a printed walk
does; `query(_:input:select:options:)` calls a Data API operation by
its `DataOperation`; and `events(_:path:query:options:)` opens a stream by its declaration, each
frame carrying an `EventRecord`. A call made this way is held to every rule a printed method is,
and infers nothing its declaration does not state. The routes a map fetches on its own are
`TileTemplates`, each a `URLTemplate` you fill with `filled(with:)`.

## Receiving webhooks

Mountaya delivers each change an organization's webhook endpoints subscribe to as a signed `POST`
to the endpoint's URL. `constructWebhookEvent`, the admin unit's, verifies the delivery's
`Mountaya-Signature` with the endpoint's signing secret and returns the event, a case of
`WebhookEvent` for each type, so a `switch` reads what each type carries:

```swift
import Foundation
import MountayaAdmin
import MountayaClient

// On a server: the body exactly as it arrived, and its `Mountaya-Signature` header, in; the
// status to answer the delivery with, out.
#if os(macOS) || os(Linux)
  func receive(body: Data, signature: String?) -> Int {
    let event: WebhookEvent
    do {
      event = try constructWebhookEvent(
        rawBody: body, signatureHeader: signature, secret: webhookSecret)
    } catch MountayaError.webhookSignature(let refusal) {
      print(refusal.reason)
      return 400
    } catch {
      return 500
    }

    // Each event arrives at least once: act on its `id` once.
    print(event.id, event.type.rawValue, event.created_at)
    switch event {
    case .organizationMemberUpdated(let event):
      // The membership as it is now, and the role it held before the change.
      print(event.data.object.role.rawValue, event.data.previous_attributes?.role?.rawValue ?? "")
    case .collectionDeleted(let event):
      print("collection \(event.data.object.id) deleted")
    default:
      break
    }
    return 204
  }
#endif
```

`constructWebhookEvent` exists on macOS and Linux only, for servers, as `.secret(key:)` does: the
endpoint's secret never ships in an app. Pass the body exactly as it arrived, before any JSON
parser reads it: the signature covers those bytes, and a body decoded and encoded again is other
bytes, which do not verify. A body read as a `String` is verified by its UTF-8 bytes, which are the
bytes Mountaya signed. The secret is the endpoint's, `whsk_` included, answered once by
`admin.webhooks.postOrganizationWebhookEndpoint`: keep it on the server.

A delivery is refused with `MountayaError.webhookSignature`, the core's, so the one
`catch let error as MountayaError` that catches every failure of the SDK catches it too; its
`reason` says why:
`.missingHeader`, `.malformedHeader`, `.signature` where no `v1` of the header matches, and
`.timestamp` where the signature verifies and was made further from your clock than the
tolerance, 300 seconds either way unless you pass another as a `Duration`, `tolerance:
.seconds(600)`. Answer it with a `400`. A secret that does not start with `whsk_`, which the error
never quotes, and a tolerance below 0 are your server's set-up rather than the delivery's, and
each throws `MountayaError.configuration`, a `ConfigurationError`, before any byte is verified;
both are cases of the one `MountayaError`, so a `catch` of it catches them as it catches the
refusal.
While a rotated secret overlaps its successor the header carries a `v1` for each, and either secret
verifies. `now:` states the clock a delivery is judged by, which a test pins; left out, it is the
platform's.

Every member of the envelope, `id`, `created_at`, `task`, `actor` and the rest, is read off the
event whatever its case. The event's instants are `Date`s, as a method answers them, and its
previous attributes are the fields its change moved, each `nil` where it did not move, and `Never`
for a type whose change moves none. Mountaya delivers an event at least once and in no set order,
so keep what you act on keyed by its `id`, and answer with a `2xx` within 10 seconds, before any
slow work. An event this build cannot type, of a type a newer contract added or whose payload its
types do not read, arrives as `.unknown`, holding the contract's envelope, `AdminSchema.WebhookEvent`,
as `admin.webhooks.getOrganizationWebhookEvents` lists it.

## Testing your own code

Every attempt leaves through an `HTTPExchange`, so a test answers it with no network. The
platform's is `SystemExchange`, over `URLSession`; it keeps no cookie and follows no redirect, so no
credential reaches a host the contract never named.

```swift
import Foundation
import MountayaClient

struct Answered: HTTPExchange {
  func send(_ request: ExchangeRequest) async throws -> ExchangeResponse {
    ExchangeResponse(status: 200, body: ExchangeBody(Data(#"{"data": []}"#.utf8)))
  }
}

let client = try Mountaya(credential: .publishable(key: "pk_test_0a1b"), exchange: Answered())
let activities = try await client.studio.activities.getActivities()
print(activities.data.count)
```

`clock:`, `random:` and `wallClock:` are seams too: every wait and budget is measured on the
`Clock` you give, every jitter and drawn key comes from the `RandomSource` you give, and the
instant a `Retry-After` date is read against comes from the `WallClock` you give.
`SessionTokenEngine(mint:clock:wallClock:)` takes the same two clocks, so a test pins the instant
a token arrives at and holds its refresh to it. The client records nothing, so an app watches its
traffic through `onResponse`, told of every attempt an answer came back to:

```swift
import MountayaClient

let client = try Mountaya(
  credential: .publishable(key: "pk_live_0a1b"),
  onResponse: { report in
    print(
      report.operationId, report.status, "attempt", report.attempt, report.requestId ?? "",
      report.rateLimit?.policies.map(\.remaining) ?? [])
  }
)
_ = try await client.studio.activities.getActivities()
```

The hook is told the operation, the surface, the status, the attempt, whether the answer was
replayed for a key, the request id and the rate-limit state. It is a function that throws nothing,
so nothing it does changes what a call answers. A test of your own error handling builds the
failure it means to handle through its public initializer,
`MountayaError.api(APIError(status: 404))`, and the map and navigation have scripted doubles of
their own, below.

## The geo layer

```swift
import Foundation
import MountayaGeo

// A rule is a function over the wire's own values: a position is `[longitude, latitude]`.
let line: [[Double]] = [[6.8652, 45.9237], [6.8752, 45.9287], [6.9271, 45.9682]]
let meters = routeLengthMeters(line)

// A value is written for its reader, in their language and their units, never the device's.
let units = UnitPreferences(language: "fr-FR", length: .metric)
print(formatDistance(meters, units: units), formatLngLat(line[0]) ?? "")

// A time of day is the locale's own, on its own clock, in the zone you name: 오후 1:00 in Korean.
let arrival = Date(timeIntervalSince1970: 1_773_446_400)
print(
  formatDateTime(arrival, locale: "ko-KR", timeZone: "Pacific/Auckland", timeLength: .short) ?? "")
```

Every rule is a function at the module's top level, named as the contract's other SDKs name it,
and answers the same numbers and words they answer for the same input: the contract's fixtures
prove each one. A rule handed a position that names no place answers rather than throws: a
distance is `NaN`, a printed position `nil`. A number, a date and a time of day go through
Foundation's locale services with the locale you name, and the language is always yours to pass.
`formatDateTime(_:locale:timeZone:dateLength:timeLength:)` writes an instant's date at a
`DateLength`, its time of day at a `TimeLength`, short or medium, or both, in the time zone you
name, each in the locale's own style and on its own 12- or 24-hour clock whatever the device is set
to, and the long date where you name no length.

The terrain under a point is read off the Tile API's elevation tiles: the tiles a point needs at
the source's deepest zoom, `elevationTilesAt(_:source:)`, and the height, the slope and the aspect
the pixels you read out of them answer, `terrainFromElevationTiles(_:source:tiles:)`, each pixel
decoded by the encoding the source's TileJSON names, `decodeElevation(_:encoding:)`. Reading an
image into its pixels is your platform's own codec; the rules start from the bytes. An aspect is
named by its eighth of the compass, `aspectCardinal(_:)`, and a humidity and a depth of snow are
written for their reader as every other measurement is:

```swift
import MountayaGeo

// The tiles the terrain at a point is read off, by their address.
let source = ElevationSource(encoding: .mapbox, tileSize: 512, zoom: 15)
let needed = elevationTilesAt([6.8652, 45.9237], source: source)

// A pixel's height, and the direction a bearing faces.
let sea = decodeElevation([1, 134, 160], encoding: .mapbox)
let facing = aspectCardinal(236.3)

// A depth of snow in inches for an imperial reader, a humidity in a French one's pattern.
let imperial = UnitPreferences(language: "en", length: .imperial)
print(
  needed.count, sea ?? 0, facing?.rawValue ?? "", formatSnowfall(35, units: imperial),
  formatHumidity(54.6, units: UnitPreferences(language: "fr")))
```

The words, colours and glyphs the elements are drawn with are the contract's own tables, printed
into Geo as data you read and restyle: the words resolve for a language with your own folded over
them, a token is restyled on a copy of the standard set, and a glyph is markup `parseGlyph(_:)`
reads into shapes, each painted as `glyphPaint(_:in:)` answers. A glyph set of your own, a
licensed one, is drawn alone or chained over a bundled set of the same paint, box and width, and a
set that cannot be drawn is refused where you build it.

```swift
import MountayaClient
import MountayaGeo

// The elements' words in French, with one of your own folded over them.
let words = resolveBundle(
  .elements, language: .fr,
  overrides: .bySection(["controls": ["close": "Fermer la carte"]]))

// The standard colours, the accent restyled and every other token as the contract states it.
var tokens = ElementTokens.standard
tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))

// A glyph's markup, read into the shapes a view draws, each painted as its set paints it.
let pin = parseGlyph(GlyphSet.marker.markup["map-pin"] ?? "")
let paints = pin.map { glyphPaint($0, in: .marker) }

// A licensed set of your own, its missing glyphs drawn from the bundled marker set.
let licensed = GlyphSet(
  name: "licensed", paint: .stroke, markup: ["refuge": #"<path d="M3 21h18"/>"#])
let markers = licensed.flatMap { GlyphSet(chaining: [$0, .marker]) } ?? .marker
print(words.keys.sorted(), tokens.accent.light.hex, paints.count, markers.markup.count)
```

The paint a map draws its content in is a value too, restyled on a copy, and a point of
interest's glyph and colour are read off its category:

```swift
import MountayaClient
import MountayaGeo

// Every member you leave is the contract's; a band of your own sits between two of the map's.
var paint = MapPaint.standard
paint.itinerary.casingColor = "#1b1b1b"
paint.layerRanks["acme_avalanche"] = LayerRank.poi.rank + 2

let hut = poiStyleOf(.hut)
print(paint.itinerary.lineWidthStops, hut?.glyph ?? "", hut?.color.hex ?? "")
```

An element handed an itinerary's id reads it through `ItineraryResourceEngine`, which shows its
geometry, its figures, its legs and its places at once. Answers are kept by a cache you make once
per client and hand to every engine, so two elements over one itinerary read it once:

```swift
import MountayaClient
import MountayaGeo

let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b"))

// One cache per client: every element reading through it shares its reads.
let itineraries = await ItineraryResourceCache { id, surface in
  try await client.studio.itineraries.getItinerary(
    itinerary_id: id, query: .init { $0.surface = surface }
  ).data
}

// An element handed an id shows every projection at once, once its answer lands.
let profile = await ItineraryResourceEngine(cache: itineraries, itineraryId: "itn_4e5f")
for await resource in await profile.subscribe() {
  guard case .resolved(let itinerary) = resource else { continue }
  print(itinerary.legs.map(\.name), itinerary.waypoints.compactMap(\.name))
  break
}

// Once your app has saved the itinerary, every element over it reads it again.
await itineraries.invalidate(itineraryId: "itn_4e5f")
```

Navigation's rules are here too: a route's steps read from either API, the copy key each
instruction is said with, the progress a traveller is told, when they have left the route, and when
an engine that speaks announces each maneuver, the plan of a route, `guidancePlanOf(_:)`, and the
prompt due at a reading, `duePrompt(_:progress:)`, so an engine of your own says each maneuver at
the meter `DeviceNavigationEngine` says it.
`NavigationEngine` follows a route over them, and an app codes against it. In an app's own tests,
`ScriptedNavigationEngine` is the engine, and the test answers each route request itself:

```swift
import MountayaGeo

// Every engine is bound to the main actor, and so is a test of one.
try await MainActor.run {
  let navigation = ScriptedNavigationEngine<String>()
  navigation.start("Refuge du Couvercle")
  try navigation.sent[0].answer(
    NavigationRoute(line: [[6.8652, 45.9237], [6.9271, 45.9682]], duration: 5_400))

  try navigation.setPosition([6.9271, 45.9682])
  print(navigation.state.status)  // arrived
}
```

`state` is observable, so a SwiftUI view that reads it is drawn again when it changes, and
`subscribe()` hands any other reader every state in order. A state reports the status, the route
followed, the progress and why the last route request failed; the instruction for a step is
`stepInstruction(_:)`, a key and its arguments, and the words are your strings'.

## Navigation

`MountayaNavigation` follows a route. It links nothing beyond the platform's own frameworks, so it
needs no trait: name it where you depend on the package, beside your client.

<!-- swift:skip a manifest fragment, which Tests/Consumer/Package.swift declares the same way -->
```swift
dependencies: [
  .package(url: "https://github.com/mountaya/sdk-swift", from: "0.1.0")
],
targets: [
  .target(
    name: "App",
    dependencies: [
      .product(name: "MountayaClient", package: "sdk-swift"),
      .product(name: "MountayaNavigation", package: "sdk-swift"),
    ]
  )
]
```

`DeviceNavigationEngine` builds on every platform the package does. On an iPhone or iPad it reads
the device's position and speaks each maneuver in your words:

<!-- swift:skip it needs an iOS build, whose voice speaks, which Tests/Consumer/Sources/Consumer/Navigation.swift compiles it in -->
```swift
import MountayaClient
import MountayaGeo
import MountayaNavigation

let mountaya = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))

let navigation = DeviceNavigationEngine<[[Double]]>(
  // Your route source: one Data API request, its steps read into one vocabulary.
  route: { waypoints in
    let found = try await mountaya.data.directions(
      input: .init(activity: .hikingAndTrail, waypoints: waypoints))
    guard let route = found.routes?.first, case .lineString(let line)? = route.geometry else {
      throw NoRoute()
    }
    let steps = readDirectionsSteps(route.steps, coordinateCount: line.coordinates.count)
    return NavigationRoute(line: line.coordinates, steps: steps.steps, duration: route.duration)
  },
  location: DeviceLocationSource(),
  // Your words for each instruction, which is a copy key and its arguments.
  voice: SpeechNavigationVoice(language: "fr-FR") { instruction in
    sentence(for: instruction)
  }
)
navigation.start([[6.8652, 45.9237], [6.9271, 45.9682]])
```

A saved itinerary is followed whole as one route: `readItineraryRoute(_:waypoints:)` joins its
segments in their chain order, each followed by its own steps, and says every arrival but the last
as a `.waypoint`, named by the itinerary's waypoint standing where its segment ends. Your strings
word the two keys it is said with, `waypoint`, which takes that name, and `waypointPlain`, so the
traveller hears a place passed on the way and arrives once, at the end:

```swift
import MountayaClient
import MountayaGeo

let client = try Mountaya(credential: .publishable(key: "pk_live_0a1b", sessionToken: "sess_2c3d"))
let itinerary = try await client.studio.itineraries.getItinerary(itinerary_id: "itn_4e5f")
let route = readItineraryRoute(itinerary.data.segments, waypoints: itinerary.data.waypoints)

// Your words: a waypoint is a place passed on the way, never the arrival.
func sentence(for instruction: NavigationInstruction) -> String {
  switch instruction.key {
  case .waypoint: "Pass \(instruction.name ?? "the waypoint")"
  case .waypointPlain: "Pass the waypoint"
  case .goal, .goalPlain: "You have arrived"
  default: instruction.name.map { "Continue onto \($0)" } ?? "Continue"
  }
}
print(route?.steps.map { sentence(for: stepInstruction($0)) } ?? [])
```

`DeviceNavigationEngine` is a `NavigationEngine`, so it reports exactly what
`ScriptedNavigationEngine` reports in your tests: the same status, progress and arrival, a
traveller off the route past 50 m, and a new route asked for by `reroute(_:)` alone. It is Geo's
machine, `RouteFollowingEngine`, with a location source and a voice beside it, so every decision
is the contract's: each maneuver is said once, while the traveller is on the route, through the
voice you give it, at the meter Geo's progress names, as the Dart SDK says it.

Its seams are yours. `DeviceLocationSource` reads the device's position while your app holds the
permission, and never asks for it: your app asks, with Core Location's
`requestWhenInUseAuthorization()`, and states why in its Info.plist, words App Review reads and the
reader sees in the system's prompt, which the map's locate control and `locate()` read through too:

```xml
<key>NSLocationWhenInUseUsageDescription</key>
<string>Your position on the map, and along the route you follow.</string>
```

Then its `standing` tells you where your app stands on location access, observable from SwiftUI,
`recheckPermission()` reads it again from the answer to your own request, and `onError` hears each
failure as a `LocationError` (below). It reads every fix a navigation reads unless you make it
`DeviceLocationSource(rate: .walking)`, a fix once the device has moved 5 m, which still says each
prompt between 55 and 50 m before its maneuver.
`ReplayLocationSource` walks each route followed at a speed you name, for a demo or a recording,
on a clock that stands still while the device sleeps, each tick read off the measure the route
was followed with, `positionAtMeters(_:meters:)` over the `FollowedRoute`, which a source of your
own can read too; `StreamLocationSource` states the
positions an `AsyncSequence` of your own yields, for an app that reads the device through its own
stack; `InertLocationSource`, the default, states nothing, and you hand each position to
`setPosition(_:)`. `SpeechNavigationVoice`, on an iPhone, an iPad or a Mac Catalyst app, speaks
your sentence for each instruction in the language you name, or in a `fallbackLanguage` where the
device has no voice for it, lowering other apps' audio while it does; `prepare()` looks the voice
up ahead of the first sentence, `close()` ends it, and its `onError` hears each time the system
refuses it the audio session, a `SpeechError` whose `kind` is `.audioRefused`, the sentence said
all the same. `InertNavigationVoice`, the default, says nothing. The engine closes neither seam:
the app that made one ends it.

A failure of the device's location is a `LocationError`, whose `kind` is one of an open set every
Mountaya SDK names alike, so a `switch` over it ends in `default`: `.providerDisabled`, the
device's location services switched off, as the source starts or while it reads;
`.permissionRevoked`, your app's access withdrawn while it reads, which `standing` shows too;
`.platformFailed`, any other failure the location services report, carried as `cause`;
`.backgroundUndeclared` and `.audioUndeclared` (below); and `.noProvider`, which an Android device
with no location provider raises and an Apple one never does. A position the services cannot fix
yet, indoors, is no failure. A speech failure is a `SpeechError`, `.audioRefused` or
`.engineUnavailable`, which the system's synthesizer never raises. A source or a voice given no
`onError` drops every failure, and a debug build prints it to the console.

Background navigation is your app's to turn on. Declare `location` under `UIBackgroundModes`, with
the capability its review needs, and `audio` beside it for the voice to speak with the screen off,
and make the source with `DeviceLocationSource(backgroundUpdates: true)`:

```xml
<key>UIBackgroundModes</key>
<array>
  <string>location</string>
  <string>audio</string>
</array>
```

Without `location`, the source refuses, tells its `onError` a `LocationError` of kind
`.backgroundUndeclared`, and reads while the app is in use; without `audio`, it tells
`.audioUndeclared` and reads on, and the voice is silent whenever the screen is off.

On every other platform the engine is the same, with the positions a source states or you hand
it, and a voice of your own. `RouteFollowingEngine` in `MountayaGeo` is the same navigation with
no source and no voice, for an app that links Geo alone.

## The map

`MountayaElements` shows a map on an iPhone or iPad. Its view sits behind the package's `Elements`
trait, off by default, so an app that shows no map resolves no MapLibre. Turn the trait on where
you depend on the package, which takes a tools 6.1 manifest or newer:

<!-- swift:skip a manifest fragment, which Tests/MountayaElementsTests/Renderer/Package.swift declares the same way -->
```swift
dependencies: [
  .package(url: "https://github.com/mountaya/sdk-swift", from: "0.1.0", traits: ["Elements"])
],
targets: [
  .target(
    name: "App",
    dependencies: [
      .product(name: "MountayaClient", package: "sdk-swift"),
      .product(name: "MountayaElements", package: "sdk-swift"),
    ]
  )
]
```

In an Xcode project, turn the trait on in the project's package dependencies, where Xcode lists
each package's traits; the project file records it on the package's reference as
`traits = ( Elements, );`. Without it, or on a platform other than iOS, `MapView` is a type the
compiler refuses with a message that says what to do.

A map is a `MapEngine` over your client, and a `MapView` that draws it:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in -->
```swift
import MountayaClient
import MountayaElements
import SwiftUI

struct TrailMap: View {
  @State private var map = MapEngine(client: mountaya)

  var body: some View {
    MapView(map)
      .ignoresSafeArea()
      .task { try? await map.setTerrain() }
  }
}
```

The engine holds what the map shows, and builds everywhere, so a Mac or a server holds a map's
state as an iPhone does:

```swift
import MountayaClient
import MountayaElements
import MountayaGeo

@MainActor
func showTrip(on map: MapEngine, itinerary itineraryId: String) async throws {
  // An itinerary by id, the camera framing it once it is drawn; a later call takes its place.
  try await map.setItinerary(itineraryId, fit: CameraFit(padding: PixelPadding(48)))
  // The zones of your credential's scope, each layer at the rank its source layer declares.
  try await map.setZones(true)

  map.addSource(MapSource(id: "trail", kind: .geoJson(GeoJSONFeatureCollection(features: []))))
  map.addLayer(
    MapLayer(
      id: "trail", type: .line, source: "trail",
      rank: LayerRank.poi.rank + 2, paint: ["line-color": "#e64980", "line-width": 4]))
  // A member set to a value replaces the one held, JSON's null included; one left nil is kept.
  try map.editLayer("trail", paint: ["line-color": "#228be6", "line-width": nil])
}
```

Each call draws in a slot of its own, an itinerary, a collection, the itineraries and the zones
of your scope, or a specification you hold under a name of yours, `setSpecification(_:named:)`,
and the latest call for a slot draws: one that answers after a later call answers false. A call
is withdrawn by cancelling its task, as SwiftUI's `.task` does when its view goes away, and gives
its slot back to the call it superseded.

`setTerrain()` shows the first terrain of the Tile API's catalogue, or the one you name, in the
variant `setTerrainVariant(_:)` asks for, light until you ask for dark, and `setStyle(_:)` shows a
style of your own. Everything the map draws is drawn again on the base map a switch brings in, a
layer you added by hand included, and a base map that does not arrive leaves the one shown. The
labels speak the language you give the engine, else your client's, the one it sends as
`Accept-Language`, else the device's. Every request the map makes for itself, for its style, its
tiles, its sprites and its glyphs, is given your client's credential and language, and the
`X-Mountaya-Client` every request names the SDK by, where it goes to the Tile API, and nothing
where it goes to any other host a style names. `MapEngine(transformRequest:)` is your own hook over
those requests, handed each as a `MapRequest` and called first: the address it answers is the one
your client's credential is claimed by, and a header it sets stands over the client's. Those
requests are MapLibre's own: a tile asked for before a first session token lands goes out under
the key alone, and MapLibre repeats a failed tile on its own schedule. Every map you show sends its
own client's credential to that client's Tile API, and two maps whose clients reach one Tile API
under different credentials send the credential of the map shown last; a request MapLibre is
redirected to another host for reaches it with no credential, and a refusal is told to the maps
whose sources or base map asked for what was refused.

A map reads the organization your publishable key was minted for once `MapView` first draws it,
`loadOrganization()`, through `postOrganizationLookup`, the key in the body and no credential sent.
The read is made once per key and Map Studio API origin and shared by every map of your process,
so a client pointed at staging never shares an answer with one pointed at production; one that
fails is kept by nobody, so the next load reads again, and a client holding a share token reads
nothing, `loadOrganization()` answering nil and never throwing for it. Its answer decides one
thing: the map draws the Mountaya watermark in the top-left corner of its safe area, the part of
the map the device leaves visible, in a layout that runs right to left too, clipped to the map,
over its canvas and its markers and under its popups and panels, which keep clear of it, unless
your organization holds white label. The safe area is the inset the system reports, never one your layout sets, so a map drawn
full bleed, under `.ignoresSafeArea()`, shows it below the status bar and beside the Dynamic
Island. Its frame is published, so you lay nothing of your own over it: `watermarkWidth`, 180
points, `watermarkHeight`, 180 × 58 / 138, about 76, and `watermarkInset`, -4, from the safe area's
top-left corner, or `watermarkClearance`, how far below the safe area's top the frame ends, as
Trail lays its search box below it, and whether the frame is held as the read stands,
`isWatermarkKeptClear(_:)`, true from the map's first drawing until the read answers white label,
the rule the SDK's own interface keeps clear of it by:

```swift
import MountayaGeo

// The mark's frame on a map whose safe area starts `top` and `left` inside its edges.
func markFrame(top: Double, left: Double) -> (x: Double, y: Double, width: Double, height: Double) {
  (left + watermarkInset, top + watermarkInset, watermarkWidth, watermarkHeight)
}

// Where a bar of yours across the top of the safe area starts: 8 points below the mark's frame
// while the map's read holds it, and at the safe area's top once the read answers white label.
func barTop(safeAreaTop top: Double, read: OrganizationRead) -> Double {
  isWatermarkKeptClear(read) ? top + watermarkClearance + 8 : top
}
```

It draws nothing while the first read waits, for one attempt's time budget at most, 35 seconds
unless your client names another, and the mark once that budget has passed, even while the read is
retried, until an answer says white label; the mark once the read answers none or fails, and at
once for a client holding no publishable key; and a read asked again after a failure keeps the
mark while it waits. `map.organizationRead` says where the read stands, in the five states the
contract names: `.waiting`, `.answered(whiteLabel:)`, `.failed`, `.timedOut` and `.noKey`. The
SDK's own controls, panels, readout and marker label keep to the safe area and clear of the mark's
frame from the map's first drawing, while the read waits too, until it answers white label, so
nothing moves as the mark lands: a `MapControls` stack in any corner, the readout and a marker's
label move clear of the frame by the smallest move, so a stack in the top-left corner starts below
it, a panel opens beside its toggle and moves below the frame, never to its right, and where
nothing inside the map clears it, a card or a panel opens with its top at the frame's bottom, cut
by the map's edge. A stack reads the map's own frame wherever you lay it, over the map or over a
larger space around it, and the map's safe area follows the map as it moves with no layout of its
own, in a scroll view, a sheet or under an offset. A stack over a map no view draws yet, or no
more, keeps to the safe area of the space it is laid in and holds the frame there as the map's
read holds it, so nothing moves as the map appears; a stack you hand no map, or a `PanelControl`
you place out of any stack, holds the frame where it would stand, in the safe area of the space it
is laid in, as a waiting read holds it. A press opens Mountaya's site, in your scope's language, in the device's browser through
the system's own opener, never your view's `openURL`, and nothing you state hides it. Nothing else is read from your organization: the
controls, the units, the language, the base map and the accent are yours, else the SDK's own:

```swift
import MountayaClient
import MountayaElements

@MainActor
func brand(_ map: MapEngine) async throws -> String {
  // One read per publishable key and origin, shared by every map; nil for a client holding none.
  let organization = try await map.loadOrganization()
  return [organization?.name ?? "", map.organization?.white_label == true ? "white label" : ""]
    .joined(separator: " ")
}
```

A right-click or a long press opens a readout of the point, 288 points wide, its top-left corner
there, flipped left or up to stay inside the safe area and moved clear of the mark's frame: the
point of interest and the zone drawn there, the classic overlay's band in its measure, the terrain's
altitude, slope and aspect read off the elevation tiles through your client's tile transport and
decoded off the main thread, the moment the map shows, live while the card is open and in the
time zone the device keeps, whatever time zone your views state, a moment it cannot write there
left out rather than written another way, and the coordinates with a button that copies them,
latitude first, to five places, each figure in the SDK's default units in your scope's language,
the aspect in whole degrees beside its direction, `123° · South-East`. A tap closes
it, and so does a camera move as it starts, which cancels the tile reads still out.
`MapView(map, readout: false)` turns it off, and a long press is still told to `events()`.

The layers catalogue lists every terrain, overlay and enrichment your credential draws, read once
and shared. A map draws one classic overlay at a time and stacks enrichments over it; your word
on a layer, or on every layer of one concept, is kept by its id before the layer is drawn and
across a base-map switch; and an itinerary's restricted stretches, striped in their kind's colour
beside its line, are shown until you hide them:

```swift
import MountayaClient
import MountayaElements

@MainActor
func showSnow(on map: MapEngine) async throws {
  let catalogue = try await map.loadLayers()
  print(catalogue.terrains.map(\.slug))
  try await map.setOverlay("snow-depth")
  try await map.addEnrichment("avalanche-risk")
  map.setLayerVisibility("avalanche-risk-fills", visible: false)
  for key in map.drawnLayerKeys() where key == "labels" {
    map.setKeyVisibility(key, visible: false)
  }
  map.setAccessRestrictionsVisibility(false)
}
```

A classic overlay the server stamps, a snow forecast or a wind field, is drawn for the instant you
pin: each of its tile addresses asks for it, and a pin that moves asks again without drawing the
overlay anew, its layers where they stood. An overlay drawn later is drawn for the pin, a base-map
switch keeps it, and with none pinned the map draws the manifest's own addresses, which the Tile
API answers for the moment each tile arrives, so a device whose clock runs fast still draws the
present. A publishable key or a share token is refused a stamped tile asked more than 15 minutes
from that moment, unless your organization's overlay time control allows it:

```swift
import Foundation
import MountayaElements

@MainActor
func forecast(on map: MapEngine) async throws {
  try await map.setOverlay("snow-forecast")
  map.setInstant(Date(timeIntervalSinceNow: 6 * 3600))
  print(map.instant?.description ?? "none pinned")
  map.setInstant(nil)
}
```

A Data API result is drawn under an id of its own, asked through your client or handed over as
you already hold it; results of one kind accumulate until you remove or clear them, and an edit
asks again with your patch, a later edit or a removal cancelling a query still out. Three
geometry slots draw over everything else: the preview of an itinerary being planned and the
emphasis of the leg a reader points at, just above the itinerary's line, and the highlight of what
the reader picked, above everything:

```swift
import MountayaClient
import MountayaElements

@MainActor
func showReach(on map: MapEngine) async throws {
  let reach = try await map.addIsochrones(
    DataSchema.IsochronesInput(
      activity: .hikingAndTrail, locations: [[6.8652, 45.9237]], range: [1_800, 3_600],
      rangeType: .time))
  try await map.editIsochrones(reach.id, patch: { $0.range = [900, 1_800] })
  map.removeAnalysis(reach.id)

  map.setGeometry(.point(GeoJSONPoint(coordinates: [6.8652, 45.9237])), in: .highlight)
  map.clearGeometry(in: .highlight)
}
```

Markers stand above everything the map draws, and the camera can be held to a pan lock and a
zoom range; a command handed something a map cannot take throws a `MapError` that says what to
pass instead, and leaves the map as it was:

```swift
import MountayaElements
import MountayaGeo

@MainActor
func showHut(on map: MapEngine) throws {
  try map.addMarker(MapMarker(id: "hut", position: [6.8652, 45.9237], glyph: "hut", label: "Refuge"))
  // A member left nil keeps the one the marker holds, and the marker keeps its place.
  try map.editMarker("hut", color: "#e64980")
  // [west, south, east, north]: the camera stays within it, and nil lifts it.
  try map.setMaxBounds([6.7, 45.8, 7.0, 46.0])
  // A limit left out is kept, and one released goes back to MapLibre's own, 0 and 25.5.
  try map.setZoomBounds(min: 8, max: 17)
  try map.setZoomBounds(max: .released)
}
```

The camera moves to the members you state and keeps the rest, at once, along an ease or a flight;
it frames a box, which this SDK computes on the canvas the map is drawn on rather than asking
MapLibre, facing north under the ceiling you give; it steps a zoom in or out, and turns back to
north and level; and it locates the device, framing the box its accuracy spans at zoom 16 at most.
The engine never asks for location access: a fix your app holds no permission for, or one the
reader allows only approximately, is refused as `denied`, and asking is your app's own flow, with
the purpose string [Navigation](#navigation) shows.

```swift
import MountayaElements
import MountayaGeo

@MainActor
func frameValley(on map: MapEngine) async throws {
  try map.ease(to: CameraTarget(center: [6.8652, 45.9237], zoom: 13))
  try map.fitBounds([6.8, 45.8, 6.95, 45.9], with: CameraFit(padding: PixelPadding(48), maxZoom: 15))
  map.zoomIn()
  map.resetNorth()
  // A refusal names its reason, `denied`, `noApi` or `unavailable`, and moves nothing.
  _ = try await map.locate()
}
```

A point query, `features(at:)`, `pois(at:)`, `zones(at:)` or `itineraries(at:)`, answers what the
map drew under a point, never its base map: every feature, or those of the points of interest, the
zones or an itinerary, each a GeoJSON feature with the layer that drew it, topmost first, and
`elevation(at:)` asks the Data API for the ground's elevation there rather than reading the drawn
terrain.
What happens on the map is told by `events()`, a `MapEvent` of each kind: a tap, `.tap`, and a long
press, `.longTap`, the features a tap lands on, `.featureTap`, the itinerary's features a hovering
pointer is over on an iPad, a trackpad's, a mouse's or a pencil's, `.featureHover`, a refusal of
access, a 401, a 402 or a 403, and its end, `.accessRefused` and `.accessRestored`, a failure of one
of the map's own requests, `.failure`, carrying as its `cause` what a read of your client's
credential threw where the request never left for want of one, and a change of the layers
catalogue, `.layersChange`, carrying the catalogue the map holds after it, nil where a move of the
studio scope dropped it. A refusal stands in `state.isAccessRequired` until the source it came from
loads again, and `credits` lists what the map credits, Mountaya first, which its credit button
shows.

```swift
import MountayaClient
import MountayaElements

@MainActor
func listen(to map: MapEngine) async {
  for await event in map.events() {
    switch event {
    case .featureTap(_, let features):
      print(features.map(\.layer))
    case .accessRefused(let status, _):
      print("access refused: \(status)")
    case .failure(let url, _, let cause?):
      print("never left: \(url), \(cause)")
    case .layersChange(let catalogue):
      print(catalogue?.terrains.map(\.slug) ?? [])
    default:
      break
    }
  }
}
```

`ScriptedMapSurface` draws the engine's state nowhere and plays what a renderer tells it, a tap,
a frame, a failed request, so your own tests read what your map does with no MapLibre at all.

A waypoint is placed by an edit: each tap on the map places it, and a tap within 40 points of an
active segment, such as the itinerary's line, places it on the line:

```swift
import MountayaElements

@MainActor
func placeWaypoint(on map: MapEngine, along line: [[Double]]) throws -> WaypointEdit? {
  map.setActiveSegments([line])
  try map.beginWaypointEdit("w1")
  // MapView places it at each tap; a map drawn some other way hands its own projection.
  try map.placeWaypoint(
    at: [6.86, 45.83], through: ScreenProjection(point: { $0 }, position: { $0 }))
  return map.endWaypointEdit()
}
```

`MapView`'s `onTap` hands you each tap, the place and the marker it fell on, where it fell on one,
and `onCameraChange` the camera each time it comes to rest, after the reader moved it or you did:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in -->
```swift
MapView(map, onTap: { tap in picked = tap.marker }, onCameraChange: { camera = $0 })
```

`MapView`'s `onReady` hands you MapLibre's own `MLNMapView` once its first style is loaded, for
anything the view does not wrap; an app that reaches it names MapLibre too, within the package's
range. A snapshot you take through it records MapLibre's canvas alone, without the watermark the
view draws over it.

A map draws the pins its style names, an itinerary's waypoints and a map's points of interest,
and its markers' pins from the engine's glyph set: the bundled marker set, or the one you hand it,
`MapEngine(client: mountaya, glyphs: markers)`. A waypoint's pin is a disc of its colour with its
glyph in white, and a glyph the set cannot draw leaves its pin missing rather than blank. A
marker's pin is a disc 28 points across in the marker's colour, the accent where it names none,
ringed in white, with its glyph in white, or a white dot where the set cannot draw it. A tap on a
marker shows its label beside its pin, above the watermark and clear of it, inside the map's safe
area, until a tap falls anywhere else; while the camera holds its marker off the map, it shows
none, never one held at the map's edge without its pin.
`Glyph` draws one glyph in SwiftUI, from the control set of the scope around it unless you name
another set, in the `control-fg` token of the tokens around it under the colour scheme in force
unless you hand it a colour:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in -->
```swift
Label {
  Text("Zoom in")
} icon: {
  Glyph("zoom-in")
}
Glyph("hut", in: .marker, size: 24, color: .orange, label: "Refuge")
```

### Controls and panels

`MapControls` floats the map's controls in one of its corners, top right unless you name
another. From the top it reads the zoom pair, the layers, points-of-interest and preferences
toggles as one group, your own controls, geolocate and the compass. Each flag has a fixed default,
`zoom: Bool = true`: with nothing stated the zoom, the compass, the layers and the preferences
toggles show, and the points of interest, geolocate and the layers panel's time are offered only
where you turn them on. Nothing is read from your organization. Each drives the map unless you hand a handler in its place, and
`.disabled(true)` shuts them all. A toggle opens its panel in place of any other, so one is open at a time, yours included,
beside its toggle and inside the map's safe area. The stack, in any corner, and its panels keep
clear of the watermark's frame, a panel moving below it, so you may put the stack in the top-left
corner too, and the corners are the ones the reader sees, in a layout that runs right to left too.
`offersTime` and `thumbnail` reach the stack's own layers panel, so the time and the pictures are
turned on in one place:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in -->
```swift
MapView(map)
  .overlay {
    MapControls(
      map, zoom: true, compass: true, geolocate: true, layers: true, pois: true,
      preferences: true, openPanel: $open, unitPreferences: $units, offersTime: true,
      thumbnail: { _, slug in Image("layers/\(slug)") }
    ) {
      DownloadControl { exporting = true }
      PanelControl("filters", label: "Filters", glyph: "controls", help: "Huts only") {
        Text("Huts only")
      }
    }
  }
```

Zoom in is disabled at the camera's zoom ceiling and zoom out at its floor. Geolocate never asks
the reader for access: it reads the standing permission without prompting, says location is
blocked while it answers refused, and is drawn in the accent until every fix it asked for
settles. Download and directions drive nothing of the map's, so their handler is required. The
panels draw the same models the stack's do, so you can place one where you like:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in -->
```swift
LayersPanel(
  selection: selection, isLocked: { $0 == "avalanche-risk" }, offersTime: true,
  thumbnail: { _, slug in Image("layers/\(slug)") }, onLockedTap: { _ in })
PreferencesPanel(preferences: $units, map: map)
POIPanel(map: map, groups: [POIPanelGroup(id: "water", label: "Water", keys: ["spring", "fountain"])])
```

A `PanelControl` names the panel it opens, a `MapPanel`, and shows its `content` there. A layers
panel lists the catalogue as `LayersSelectionEngine` holds it, which drives the map, in the map
studio's sections: the base maps as picture cards, each the picture your `thumbnail` hands or its
name alone; the enrichments as switches, the points of interest left to their own panel; the
classic overlays as cards of one category at a time, behind a segmented control of the categories
where two or more hold one, opening on the category you picked last, else the one holding the
overlay selected; and, where you offer it, the time. Its slider spans the forecast window, 71 hours
back to 144 ahead, an hour a stop, ticked every day with two days back, now, and two and five days
ahead labelled. Its track is filled from now to the thumb. The thumb reads its moment in the time
zone the device keeps, whatever time zone your views state, and how far it is from now, a moment it
cannot write there left out rather than written another way. A release pins that instant on the
selection, and so on the map, or pins none on now, so the map follows the clock again. An arrow
key steps it an hour while it holds the keyboard's focus, and so does VoiceOver's adjustment,
which reads the readout as its value. The time is yours to offer, since a publishable key or a
share token is refused a stamped tile far from the present unless your organization's overlay time
control allows it. The panel lays its track out around the clock your view's environment carries,
the system's unless you state your own, so a replay moves the window with it:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Elements.swift compiles it in -->
```swift
LayersPanel(selection: selection, offersTime: true)
  .environment(\.mountayaClock, replayClock)
```

A preferences panel writes your set back with
one preference changed, and relabels the map for a language; a points-of-interest panel offers
the concepts the map draws. In a stack, a panel lays out as the embed's does: under a title row,
340 points wide, or the width its corner leaves on a map no wider than 576, its body scrolling
under the title once it is taller than the map less the panel's inset allows; the layers panel's
cards stand three to a row, their pictures 52 points tall, 40 on that narrow map, and the
preferences panel's options two to a row. Outside a stack, a panel taller than 420 points scrolls
inside that height. The words
and the glyph sets come from the scope around a view, and each view that speaks takes words of its
own too, `strings`, each at its path, which replace the scope's for that view alone and leave
every other word the scope's, yours included: `ZoomControl(map: map, strings: ["controls.zoomIn":
"Closer"])`. `MapControls` hands its `strings` to its own controls and panels, and none to yours.
The colours come from the tokens, read under
the colour scheme in force, so a dark scheme draws the tokens' dark values and a value you state
stands in both. The map's markers take the accent from the same tokens. Every control, row, chip,
clear and retry is pressed anywhere in a span of 44 points each way, the platform's touch target,
and draws a ring 2 points wide in the `focus-ring` token while it holds the keyboard's focus, a
hardware keyboard's or Full Keyboard Access's, and none after a touch.
Where the reader asked the device for reduced motion, every move a control starts, a zoom step, a
compass reset, a located fix and a search's pick, lands at once rather than easing there; a move
your own code makes travels as you ask. A profile's distance axis and its chips grow with Dynamic
Type. Every rule under the views is Geo's, so a screen of your own reads the same words, tokens
and models:

```swift
import MountayaClient
import MountayaGeo

func controlWords() -> [String] {
  // A scope nested in another takes every setting it does not state from it.
  let french = scopeOf(.standard, stating: ElementsScopeStatement(language: .fr, locale: "fr-CH"))
  var tokens = ElementTokens.standard
  tokens.accent = ThemeToken(light: HexColor(hex: "#e9501e"))
  let results: JSONValue = ["one": "{count} résultat", "other": "{count} résultats"]
  return [
    french.word("controls.zoomIn"),
    themeTokenValue(tokens.controlBg, in: .dark).hex,
    countedText(results, count: 1_234, language: .fr) ?? "",
  ]
}
```

The time slider's rules are Geo's too, each handed your clock's reading, so a slider of your own
draws the same track and pins the same instants:

```swift
import Foundation
import MountayaGeo

@MainActor
func slide(_ layers: LayersSelectionEngine, now: Date, to value: Int) -> String {
  let track = timeSliderWindow(now: now)
  let ticks = timeSliderTicks(track).compactMap(\.word)
  if let released = timeSliderRelease(track, at: value) {
    layers.setInstant(released.pin)
  }
  let readout = timeSliderReadout(track, at: track.value(at: layers.state.instant))
  return "\(ticks) \(readout.word) \(readout.count ?? 0)"
}
```

### Search

`SearchControl` is a search box over Mountaya's unified search, with its results under it while
the focus stands anywhere in the control, its box, its filter chips or its list, over a query of
more than white space you have not dismissed, as `isSearchListShown(hasFocus:query:isDismissed:)`
answers. It reads the Data API through your map's client, starts confined to the visible area of
the map, and moves the camera onto a row you pick, drawing it on the map in the accent of your
tokens:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Search.swift compiles it in -->
```swift
MapView(map)
  .overlay(alignment: .topLeading) {
    SearchControl(map: map, query: $query, isConfined: $confined)
      .padding()
  }
```

A round is asked once the typing pauses, 150 ms, one request per branch: itineraries, places,
ways, points of interest, zones and collections, their sections in that order whatever order they
answer in, or the branches you list in yours. A new query abandons the round in flight, whose
answers land nowhere, and a failed branch shows a line of its own, `search.error` beside its
retry, while the others answer: the control's own words, never the API's message, which stays on
the branch's `SearchBranchError` for you to log. A round confined to the visible area that finds
nothing asks once more everywhere, and says so; while the list is open, the camera coming to rest asks the round again. A pick frames a
result's extent, else flies to its point, and the map's search highlight marks it: a place as a
pin, a point of interest as its category's own, a way as its line, its extent or a pin. The control
takes the highlight down as it leaves. `onSelect` takes a pick over; `fetch` sends the requests
through a transport of yours, in place of your map's client; `wording`, a `SearchWording`, words a
row's title and second line, your word for each wire value and your units; and `onError` is handed
each branch's failure, which the list shows a line for, with its retry, either way. A row's title
comes cut at what the query matched, its `parts`, ready to draw. The control's words are the
scope's `search` section, each replaced by its `strings` where you name the word's path.

Hand the control your own `SearchEngine` where you hold the search yourself, a typing pause of
your own among it, `SearchControl(map: map, engine: search)`: it then shows and drives your engine,
its typing, its scope and its map's camera, never configures it nor closes it, and your engine's
configuration stands in for `targets`, `language`, `limit`, `wording` and `fetch`. An engine starts
unconfined unless you state otherwise, where the control's own starts confined to the visible area,
so state `isConfined: true` on yours, or hand `isConfined`, to search the visible area. The engine
and every rule under the control are Geo's, so a list of your own reads the same search:

```swift
import MountayaClient
import MountayaGeo

@MainActor
func searchHuts(through mountaya: Mountaya) async -> [String] {
  // The engine waits for the typing to pause, asks one request per branch and keeps the latest.
  let search = SearchEngine(
    configuration: SearchConfiguration(
      fetch: { try await mountaya.data.search(input: $0) }, language: dataLanguageFor("fr-CH"),
      targets: [.pois, .places]))
  search.setQuery("refuge")
  for await state in search.subscribe() where state.isSettled {
    search.close()
    // What a list shows under a filter, and what picking a row does to a map.
    return searchListState(state, filter: .places).rows.map { row in
      "\(row.title): \(pickTarget(row.payload).mark == nil ? "unmarked" : "marked")"
    }
  }
  return []
}
```

A list of your own marks a pick on its map as the box does, handing the accent your tokens read
under the colour scheme in force: left out, the accent is the standard light one, whatever tokens
you restyled and whatever scheme is in force.

```swift
import MountayaElements
import MountayaGeo

@MainActor
func mark(_ row: SearchRow, on map: MapEngine, tokens: ElementTokens, scheme: ThemeScheme) {
  map.setSearchHighlight(
    pickTarget(row.payload).mark, accent: themeTokenValue(tokens.accent, in: scheme))
}
```

### Elevation profile and tables

`ItineraryProfile` is an itinerary's elevation profile: the stat strip over it, the curve with its
places pinned on it and their services above them, and, as you ask, the elevation and distance
scales, a band strip, a chip per leg, the card at the cursor and a navigator over the window shown.
It reads the itinerary by its id through an `ItineraryResourceCache` you make once per client, one
read for every element over the itinerary, and a scrub over it pins a marker on your map at the
sample and lights the leg under it, the later leg at the meter two share:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in -->
```swift
struct ItineraryScreen: View {
  let itineraries: ItineraryResourceCache
  @State var map: MapEngine

  var body: some View {
    VStack(spacing: 0) {
      MapView(map)
      ItineraryProfile(
        itineraryId: "itin_abc", cache: itineraries, map: map,
        parts: [.amenities, .tooltip, .distanceAxis, .navigator]
      )
      .frame(height: 220)
    }
  }
}
```

Your cache reads through your client, `getItinerary` in one line, so the elements never call the
network themselves:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in -->
```swift
let itineraries = ItineraryResourceCache { id, surface in
  try await mountaya.studio.itineraries.getItinerary(
    itinerary_id: id, query: .init { $0.surface = surface }
  ).data
}
```

A profile's leg chips are buttons where you hand `onSegmentTap`, each press handing over the leg's
id, or a collapsed group's `group:` id, as a segment table's row does, and drawing nothing on the
map of its own.

`ItinerarySegmentTable` states the legs as a roadbook, a row per leg with the itinerary's
sparkline, its length, its climb and loss over the running totals, and, as you ask, its altitude
band, its duration and its difficulty. `ItineraryWaypointTable` states the places, a row per pass,
with a chip per service over the rows that keeps the places offering every service picked. A row
pointed at pins the marker at the leg's end, or at the place, and a segment row lights its leg; a
leg your map's cursor is over lights its row, a collapsed group's row for each of its members,
unless `highlighted` names the row to light:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in -->
```swift
ScrollView {
  ItinerarySegmentTable(itineraryId: "itin_abc", cache: itineraries, map: map)
  ItineraryWaypointTable(
    itineraryId: "itin_abc", cache: itineraries, map: map,
    formatCutoffAt: { $0.formatted(date: .omitted, time: .shortened) })
}
```

A profile and the two tables over one map never move or take down each other's marker, each
pinning under an id of its own, and each takes down what it wrote as it leaves. `onHover` takes
the map over, handed the sample or the row, and `.disabled(true)` draws an element and drives
nothing. A cut-off, and a `date` field, are written only by your `formatCutoffAt`, the time zone
being your app's. Trail writes each as its date and its time of day in the device's zone,
`TimeZone.current.identifier`, through `formatDateTime(cutoff, locale: language, timeZone: zone,
dateLength: .medium, timeLength: .short)`. That answers nil for a zone the locale services do not
know, whatever the instant: hand no `formatCutoffAt` there, as Trail does, so no cut-off is
written rather than one in UTC, as an ISO string or in another zone. Each element's words are the
scope's, replaced by its `strings` where you name the word's path.

Where you hold the itinerary's engine yourself, hand it in place of the id and the cache: the
element shows what your engine reads and never closes it, and you choose the itinerary through the
engine's `configure`:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in -->
```swift
let reading = ItineraryResourceEngine(cache: itineraries, itineraryId: "itin_abc")
ItineraryProfile(engine: reading, map: map)
ItinerarySegmentTable(engine: reading, map: map)
```

`WaypointCard` is a card about one place: its mark and its name, the line under it, then its
services, when it can be used, how to reach it, its own fields, its links and its photos, each
section drawn only where the place states a line. A website or a booking page is a link only at a
web address, so no script is ever tapped:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in -->
```swift
WaypointCard(place: place, formatCutoffAt: { $0.formatted(date: .abbreviated, time: .shortened) })
```

A photo, at a web address alone, is loaded by `AsyncImage`, or drawn by your own view where you hand
one, your image loader's or your cache's:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in -->
```swift
WaypointCard(place: place) { photo in
  AsyncImage(url: URL(string: photo.url)) { image in
    image.resizable().scaledToFill()
  } placeholder: {
    ProgressView()
  }
  .frame(height: 140)
  .clipped()
}
```

A link the card draws, a website, a booking page or a photo's address where you hand no `photo`,
opens through the `openURL` action of SwiftUI's environment, the browser or the app the system
opens it in. State your own around the card to take every link over, to open a page in your app,
ask first, or note the tap:

<!-- swift:skip it needs an iOS build with the Elements trait, which Tests/Consumer/Sources/Consumer/Profile.swift compiles it in -->
```swift
WaypointCard(place: place)
  .environment(
    \.openURL,
    OpenURLAction { url in
      opened = url
      return .handled
    })
```

Every figure the elements draw is a rule of Geo's, so a screen of your own states the same rows,
the same chips and the same bands, in the reader's language and units:

```swift
import MountayaClient
import MountayaGeo

func roadbook(_ itinerary: RestSchema.ItineraryWithDetails) -> [String] {
  // The projections every data element reads, and the rows a segment table states.
  let resolved = ResolvedItinerary(itinerary)
  let series = buildElevationSeries(resolved.geometry)
  let units = UnitPreferences(language: "fr")
  return itinerarySegmentRows(series, legs: resolved.legs).map { row in
    let band = formatAltitudeRange(min: row.metrics.altitudeMin, max: row.metrics.altitudeMax, units: units)
    return "\(row.name): \(formatDistance(row.metrics.sectionDistance, units: units)), \(band)"
  }
}
```

## Licence

`MountayaClient`, `MountayaAdmin`, `MountayaGeo`, `MountayaNavigation`, `MountayaElements` and
every product this package declares later are published under the **Mountaya SDK License**, version 1.0, in
[LICENSE.txt](LICENSE.txt), with a French translation in [LICENCE.fr.txt](LICENCE.fr.txt). Where
the two differ, the English text prevails. The licence is source-available, not open source: you
may read the code and ship it inside your own application, in conjunction with the Mountaya
services and for as long as an agreement with Mountaya is in force. The texts are the ones the
TypeScript packages ship, carried verbatim. MapLibre Native, which `MountayaElements` links with
its trait on, is under its own BSD licence. The glyph sets `MountayaGeo` publishes hold the markup of
icons from Lucide, under the ISC licence, and the MIT licence for the icons Lucide derives from
Feather: [THIRD-PARTY-NOTICES.txt](THIRD-PARTY-NOTICES.txt) carries both. The examples under
`Examples/`, Trail and its session server, are published under the MIT licence, in
[Examples/LICENSE](Examples/LICENSE), the text the TypeScript SDK's examples carry, so you copy them
into your own code freely.

## Requirements

What working on this repository needs. Using the SDK needs none of it: see [Install](#install).

| Tool | How it is installed | What needs it |
| --- | --- | --- |
| Swift | Xcode on macOS, installed by hand; pinned in `mise.toml` on Linux | Everything |
| xcodebuild, xcrun | come with Xcode, at the version `mise.toml` names | `scripts/check-toolchain.sh`, `scripts/build-platforms.sh` and the size gate, `Tools/SizeGate` |
| Docker | Docker Desktop, installed by hand | `scripts/test-linux.sh` and `scripts/lint-linux.sh`, the suites and the lints on Linux, in the gate and in CI |
| git, mise | git comes with Xcode's command line tools; `sh .agents/setup` installs mise | `scripts/release.sh`, a release: the tag, its push, and the questions it asks Entire and the GitHub mirror |

## Setup

```sh
sh .agents/setup           # Entire, mise and the pinned tools, the git hooks, the dependencies
sh .agents/setup --check   # what is missing, changing nothing
```

## Commands

| Command | What it does |
| --- | --- |
| `mise run lint` | The format check, and the file structure and naming lints |
| `mise run test` | The suites on this machine |
| `mise run build` | Every target, the tests included |
| `mise run format` | `swift format` over the tree |
| `mise run ci:quick` | What pre-commit runs: `lint` |
| `mise run ci` | The gate: the toolchain, the lints, the builds and every suite, the coverage tests of the capabilities and of the names the registry publishes for Swift, the hot-path budgets the contract lists for Swift, this README's snippets and floors table and the `mountaya-sdk-swift` skill's, the device suites on the iOS simulator, the size of an iOS app and the Linux containers included. It first deletes what the builds left in the repository and no longer use, and stops where the disk lacks room |
| `mise run clean` | Delete what the builds left in the repository and no longer use: the build directories of a Swift no pin names, and nothing outside the repository. `mise run clean -- --all` deletes every build directory, `-- --dry-run` only lists |
| `mise run clean:toolchains` | Yours to run, never the gate's, and denied to an agent: list the Linux images, `swift:<version>-noble`, of a Swift no Mountaya checkout pins any more, which live in Docker's disk outside the repository. `mise run clean:toolchains -- --yes` deletes them |
| `mise run ci:linux` | What CI runs on every push, and the gate last: the lints, the printed files and every suite in the Linux containers, each run held to the conformance report. It leaves the Apple platform builds, the iOS simulator suites, the API baselines and the size gate to `mise run ci` |
| `mise run test:device` | The device suites on the iOS simulator: `test:ios`, `test:ios:elements`, then `test:trail` |
| `mise run test:ios` | `MountayaNavigation` built for iOS, and its voice's tests on the iOS simulator |
| `mise run test:ios:elements` | `MountayaElements` built for iOS with its trait, and its Renderer tests on the iOS simulator |
| `mise run test:trail` | Trail's journey, `sdk/trail.yaml`'s, walked by its UI test from `Trail.xcodeproj` on the iOS simulator |
| `mise run test:trail:session` | The tests of Trail's session server, a package of its own, on macOS |
| `mise run trail:session` | Run Trail's session server on `127.0.0.1:8787`, with `MOUNTAYA_PUBLISHABLE_KEY` and `MOUNTAYA_SECRET_KEY` set in your shell ([Examples you can run](#examples-you-can-run)) |
| `mise run size:check` | What each product adds to an iOS app: Trail, the sample app, built in release for a device, its executable read module by module, against `Tests/BoundaryTests/Size/ios.json`, on macOS. `MOUNTAYA_SIZE_BASELINE=write` records the figures |
| `mise run test:linux` | The suites in the Linux container at the pinned Swift; `test:linux:floor` at the oldest Swift the package supports |
| `mise run api:update` | Print each product's public API baseline, `Tests/BoundaryTests/Baseline/<Product>.txt`, again after a deliberate change to the API, on macOS; the diff is the review |
| `mise run snippets -- <file.md> [...]` | Type-check the Swift fences of Markdown files this repository does not hold, the public docs' pages among them, against the products, on macOS: each fence printed under `.build/snippets` as a file of its own, `<!-- swift:skip <reason> -->` above it opting it out, checked for the iOS simulator with the `Elements` trait where it imports `MountayaElements`, `MountayaNavigation`, `SwiftUI` or `UIKit`, and for macOS otherwise. It names each fence that fails by its file and line, ends on how many it compiled and skipped, and reads only the paths it is handed |
| `mise run release <version>` | A release: the preflight, every sibling clean at its pin among it, and the gate, then `CHANGELOG.md`, the tag `v<version>`, a push of `main` to Entire and then of the tag, since Entire takes no atomic push, and a wait until the GitHub mirror lists the tag, which the Depot workflow `mirror.yml` pushes there from Entire |
| `mise run release <version> --dry-run` | Every check of the release but git's, and the gate (`--skip-gate` leaves it out); no commit, no tag and no push |

Pre-commit runs `mise run ci:quick`, and CI runs `mise run ci:linux` on every push to Entire. The
rest of the gate needs Xcode, which no CI runner here offers, so run `mise run ci` yourself before
you push: no hook runs it for you. It reads the contract from the `../schemas` checkout beside this
one, or from wherever `MOUNTAYA_SCHEMAS_DIR` points, and the `mountaya-sdk-swift` skill from the
`../ai` checkout beside it, each as it stands; CI reads both at the commits `siblings.lock` pins.

Every Swift snippet in this file is compiled by the consumer package in `Tests/Consumer`, printed
into `Tests/Consumer/Sources/ReadmeSnippets/ReadmeSnippets.swift`. After changing one, run
`MOUNTAYA_README=write swift test --disable-xctest --filter ConsumerPackageTests`, and the diff is
the review. The same suite holds the floors table under [Install](#install) to `Package.swift` and
to Trail's project, so a floor raised there fails it until the table says so, and refuses a floor's
number on any other line of this file. The skill an agent reads to use this package, `mountaya-sdk-swift` in
`mountaya/ai`, is held the same way and never copied here: `SkillSnippetTests` type-checks its
Swift snippets, read from `../ai` at every run, against the consumer built for the iOS simulator
with the `Elements` trait, and holds the floors it states to `Package.swift`'s. Without `../ai`
both tests are skipped with a note, and in CI they fail.
`mise run snippets -- <file.md> [...]` holds any other Markdown document to the products against
the same two builds, the public docs' pages among them, each fence a file of its own: one with
top-level code a `main.swift`, one declaring `@main` or importing a test framework a library. No
gate runs it, and it names no other repository: the paths it reads are the ones it is handed.

Every hot path the contract's `sdk/hot-paths.yaml` lists for Swift, work that runs per pointer,
camera or scrub frame, keeps a budget test beside its subject: titled `hot-path budget <id>:`, it
drives the path through a realistic burst and asserts the count of work against a constant its
file declares at its top level, `<id>Budget` in lowerCamelCase, the number to argue with in review.
`HotPathBudgetTests` fails on a listed path with no such test, a test naming a path the list does
not hold for Swift, one asserting nothing against its constant, a file declaring none, and a test
switched off. The renderer's budgets run on the iOS simulator, in `mise run test:ios:elements`, which `mise run test:device` runs;
the gate that holds them runs on every host, Linux included. Without `../schemas` it is skipped
with a note, and in CI it fails.

Trail, the sample app under `Examples/Trail`, is held to the contract's `sdk/trail.yaml`: each step
it lists is marked by the code that does it, `// trail: <id>`, and `TrailScenarioTests` fails on a
step no marker names, on a marker that names no step, on a value shaped as a key or a session token
in a file under `Examples/` that git commits, on a copy of the demo itinerary that differs by a
byte, and on a missing licence. Your own `Config/Local.xcconfig` and the build's output are never
read, so a key you set fails nothing. `mise run test:trail` walks the scenario's journey through
the app on the iOS simulator, and `mise run test:device` runs it after the other device suites.

What the SDK adds to an app has a baseline too. `mise run size:check` builds Trail in release for
a device, reads the linker's map of its executable module by module, and holds each product's
bytes, and each module the SDK brings, such as swift-crypto's `Crypto` with the version Trail's
`Package.resolved` pins, to `Tests/BoundaryTests/Size/ios.json`, measured to the version of
`sdk/trail.yaml` it records. Each share is told on a line of its own, `name: bytes, ±change (±%),
within tolerance` or `past tolerance`, then the products together and the whole executable, which
are not compared. A share that grows past 2% of its baseline or 16 KiB, whichever is larger, fails,
and so does a module the baseline does not record; a shrink is told, and a baseline measured to
another scenario, or with another Xcode or Swift, is reported and not compared, as is a module
brought at another version. MapLibre, a dynamic framework, is no share. After a deliberate change,
or a new Xcode, `MOUNTAYA_SIZE_BASELINE=write mise run size:check` records the figures, and the diff
is the review.
