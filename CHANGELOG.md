# Changelog

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and this package
follows [semantic versioning](https://semver.org/spec/v2.0.0.html).

The package version and the contract version are two different numbers. This file records the
first; `schemaVersion` records the contract tag a release was printed from, and a contract change
reaches this file only when it changes something a caller can see.

The five products are one release: a tag of this repository versions `MountayaClient`,
`MountayaAdmin`, `MountayaGeo`, `MountayaNavigation` and `MountayaElements` together, and SwiftPM
resolves it from the public mirror. `mise run release <version>` moves the notes under `[Unreleased]` to the
version and its date, and tags it.

## [Unreleased]

## [0.1.0] - 2026-11-26

The first release, written against contract v0.9.0 of `mountaya/schemas` (registry version 20), its
model and elements' data digesting to
f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.

- `MountayaClient`, on iOS, iPadOS, macOS, Mac Catalyst, tvOS, watchOS, visionOS and Linux: the
  client for the Map Studio API, the Tile API and the GraphQL Data API, every operation printed
  from the contract's model, with every transport rule the contract states: credentials and the
  session lifecycle, retries and idempotency keys, conditional writes, the error ladder and the
  next step each error names, dates, pagination, field selection, and event streams that reopen,
  wait and resume on the contract's schedule, each opened by a method that throws and awaits
  nothing, the stream opening as its first frame is asked for:
  `for try await frame in try client.agent.runs.getAgentRunEvents(run_id:)`. `modelDigest`, printed
  beside `schemaVersion`, names the exact model and elements' data a build was printed from, which
  a build printed between two tags of the contract differs by while its tag does not. Every request
  it sends names the SDK that made it, `X-Mountaya-Client: mountaya-swift/0.1.0`, and so does every
  request a map sends to the Tile API. Each member of an enum is named by its words in lowerCamelCase, by the rule the contract
  states for every SDK, `RestSchema.TileLayerType.line` and `DataSchema.ActivitySlug.hikingAndTrail`,
  and every enum is an open set that reads a value this build has never seen as itself.
  `reading(asUser:)` names the user an editor stream is read as where the session token names
  none. Every listing that pages has its walk printed beside its method, `walkGetItineraries` and
  the rest, at the page size the operation states; a `Response` carries every header of the
  answer, `headers`; the routes a map fetches on its own are printed as `TileTemplates`, each a
  `URLTemplate`; and an operation newer than this build is called by its declaration whatever its
  body, `send` taking JSON or a form of `MultipartPart`s, and `query` a Data API operation. The
  wall clock is a seam beside the clock, `wallClock:` on the client and on `SessionTokenEngine`,
  so a test pins a `Retry-After` date and the refresh schedule; a `Retry-After` date is waited out
  to the whole second after it, the seconds the error carries, so no repeat asks before the
  instant the server named. `parseTimestamp(_:)` reads a
  timestamp you hold as text by the anchor every date the client decodes is held to, and answers
  nil for a text that names no real instant, the thirtieth of February or a second of 60 among
  them. A header
  you name in another case replaces the client's, a body's own type standing over yours, a header
  name that is no RFC 9110 token, one holding a space, a colon or a bracket, is refused before any
  request, and a header value outside printable ASCII, a letter of Latin-1 included, is refused
  before any request on every platform rather than sent changed, as a key, a token, a language, an
  idempotency key, a tag and a visitor's cookie are; an event stream whose last record's id no
  header can carry ends with a `ConfigurationError` rather than open again from it. A web address the contract types
  `format: uri` is a `URI`, kept as the text an answer sent, one with no scheme or one Foundation
  would rewrite included, and one with no scheme is refused in a body you build; `url` reads it as
  Foundation does. A secret the model marks, a session token, a webhook endpoint's signing
  secret, a setup intent's client secret and a share link's token, is printed `<redacted>` by the
  type that holds it, and stays readable, and a credential and a `SessionToken` print each key's
  and token's prefix and `…`. A client given no language asks for none in particular,
  `Accept-Language: *`, which `Credential.headers(for:language:method:)` answers too, and it
  answers a share token that asks for the visitor's cookies by the call's method, GET where none
  is named, and the operation's declaration: a read, an operation declared one
  (`CredentialDeclaration.isRead`, which every Data API query declares) or a request sent with
  GET, HEAD or OPTIONS in any letter case, goes out on the visitor's own session, one that requires
  a session token included, for the server to judge, and a write is refused. A value of any type declaring an
  error's name, `NamedError`, is recognised by `isMountayaError(_:)` and `isAPIError(_:)`. A
  session mint that fails or times out is minted again on the engine's schedule, waiting the
  floor, five seconds, and twice as long after each failure or spent token in a row, up to a
  minute, and one your app cancels ends that run of minting. A base URL with no scheme, a path or
  a host alone, is refused as the client is built, since an app has no page to read it against. `true` on an object of a Data API selection selects it whole. A file you send in a form
  with no media type goes out as `application/octet-stream`, and a printed form's file part as the
media type the contract's model names for it. A member a later contract adds to a
  stream's events is handed to you as an ordinary event, and no build waits on it. **Breaking:** a
  listing's sort is named by its words, `GetZonesSort.updatedAtDescending` for `-updated_at` and
  `.createdAt` for `created_at`, in place of its wire spelling.
- `MountayaAdmin`, on the same platforms, the client's admin unit as the contract declares it, for
  a server and an admin tool: the operations of the contract's `admin` group, an organization's
  members, keys, invitations, billing, users and webhook endpoints and the mint of a session token,
  `postSession`, called as `admin` on the core's `Mountaya` once the product is imported, an
  organization's lookup by its publishable key being the core's, which a map reads; the
  types only those operations and the webhook events send or receive, in `AdminSchema`, a type of
  the core they carry staying in `RestSchema`; and the receiving of a webhook delivery,
  `constructWebhookEvent`, which verifies its signature within a tolerance given as a span of
  time and reads it as a `WebhookEvent`, on a server and never in an app. Its refusal of a
  delivery is the core's `MountayaError.webhookSignature`, a `WebhookSignatureError`, so the one
  catch an app writes for every failure of the SDK catches it too. A server mints a session token
  under the core's secret key, and the session it answers is the core's `RestSchema.Session`. An app
  that shows a map, reads data or navigates does not link it.
- `MountayaGeo`, on the same platforms: what Mountaya decides about that data, the contract's
  rules as functions that call nothing: distances and units, formatted values in the language you
  name, the elevation profile, a segment's groups and its road access, the camera, the map's
  layers and icons, the map's paint and a point of interest's style, the glyph sets a host builds
  and chains and how each glyph is painted, search rows with their titles cut at what a query
  matched (`SearchRow.parts`), an itinerary read by id through
  `ItineraryResourceEngine` over a cache your elements share, with its legs and its places, the
  rules the controls and panels draw by (`themeTokenValue`, `scopeOf`, `countedText`,
  `filledText`, `layersPanelSections`, `poiPanelRows`, `preferenceChoices`) and their engines,
  `LayersSelectionEngine` and `GeolocateControlEngine`, over a map of yours or `MapEngine`, the
  search, `SearchEngine`, with the rules a result list and a pick draw by (`searchListState`,
  `pickTarget`, `describePlace`, `describePoi`, `describeWay`), the rules an itinerary's data
  elements draw by: the profile's scale, curve, places, scrub and window (`profileDomain`,
  `placeOnCurve`, `scrubGrid`, `clampRange`), its strip, its card at the cursor and its chips
  (`statStripCells`, `profileReadout`, `sectionChipCells`), the two tables' rows and cells
  (`itinerarySegmentRows`, `itineraryWaypointRows`, `segmentRowCell`, `waypointRowCell`), the
  services' filter (`amenityFilter`), a place's card (`waypointCard`) and an altitude band
  written as the language's own range (`formatAltitudeRange`), and navigation's rules, with the
  `NavigationEngine` protocol, `RouteFollowingEngine` and `ScriptedNavigationEngine` for an app's
  tests, and the plan a speaking engine announces a route's maneuvers from and the prompt due at a
  reading (`guidancePlanOf`, `duePrompt`, `GuidancePlan`, `promptMeters`), so an engine of your own
  says each maneuver at the meter `DeviceNavigationEngine` says it. `readItineraryRoute(_:waypoints:)`
  joins an itinerary's segments into the one route a traveller follows over all of them, every
  arrival but the last said as a `.waypoint` named by the itinerary's waypoint standing there, with
  its own instruction keys, `waypoint` and `waypointPlain`, for your strings to word.
  `hoveredItineraryOf(_:)` reads the leg and the place a pointer over a drawn itinerary is over. A
  rank band a `MapPaint` patch names after one of JavaScript's own object members, proto,
  constructor or prototype, is left out, as every SDK leaves it. A date is written in the
  Gregorian calendar whatever the locale keeps, the viewport a time zone opens on is the
  contract's whole table, and a search's typing pause is a `SearchPause`, which no pause below zero
  is.
- `MountayaNavigation`, on the same platforms, with no trait to turn on and no third-party
  package: `DeviceNavigationEngine`, the contract's navigation over Geo's machine, which says each
  maneuver aloud in your words, at the meter Geo's progress names, one after a step of no length
  included; and its seams: `DeviceLocationSource`, wherever the platform reads a position but on
  tvOS, at the rate you choose, every fix a navigation reads or a walker's every 5 m
  (`LocationRate`), with where your app stands on location access (`standing`,
  `recheckPermission()`), and `backgroundUpdates` where your app declares the mode, each failure
  told to `onError` as a `LocationError` whose `kind` every native SDK names alike, an open set:
  `providerDisabled` for location services switched off, `permissionRevoked`, `platformFailed`
  carrying the platform's error, `backgroundUndeclared` and `audioUndeclared` where the app
  declares no background location or no background audio, and `noProvider`, a fix not found yet
  aside; `ReplayLocationSource`, which walks a route by the time elapsed on a clock that stands still
  while the device sleeps, from its start stated at once; `StreamLocationSource`, over an async
  sequence of your own positions; and, on an iPhone, an iPad and a Mac Catalyst app,
  `SpeechNavigationVoice`, with a fallback language, `prepare()`, `close()` and an `onError` told
  each refusal of the audio session as a `SpeechError` of kind `audioRefused`, the kinds every SDK
  names being `SpeechError.Kind.audioRefused` and `SpeechError.Kind.engineUnavailable`, a speech
  engine that never starts, which the system's synthesizer never is, so this voice never tells it.
  A source or a voice given no `onError` drops each failure, and a debug build prints it.
- `MountayaElements`, for an iPhone and iPad app that turns on the `Elements` trait: `MapView`, a
  SwiftUI view over MapLibre Native drawing the state `MapEngine` holds, every layer ranked as the
  contract ranks it, every tile fetched with its own client's credential, two maps shown at once
  included, and none carried across a redirect to another host, no compass of MapLibre's beside
  yours, the waypoint and
  point-of-interest pins a style names and the stripes of an itinerary's restricted stretches,
  and your markers as pins carrying a glyph, drawn from the engine's glyph set, yours or the
  bundled one, in your tokens' accent, each look drawn once; `Glyph`, a glyph drawn in SwiftUI from
  the control set of the scope around it, in the `control-fg` token under the colour scheme in
  force unless you hand it a colour, each glyph read once; and the map's controls
  and panels, `MapControls` with `ZoomControl`, `CompassControl`, `GeolocateControl`,
  `PanelControl`, `DownloadControl` and `DirectionsControl`, and `LayersPanel`, `POIPanel` and
  `PreferencesPanel`, drawn in the tokens `mountayaTokens(_:)` states under the colour scheme in
  force and in the words of the scope `mountayaScope(_:)` nests, each view's own strings laid over
  them for it alone; `SearchControl`, a search box over the Data API whose pick moves the camera
  and draws the map's search highlight in your tokens' accent, over a `SearchEngine` of its own or
  yours; and the data elements over an itinerary read by id through your cache, or by your own
  `ItineraryResourceEngine`,
  `ItineraryProfile`, `ItinerarySegmentTable`, `ItineraryWaypointTable`, `ItinerarySparkline` and
  `WaypointCard`, whose photos your own view may draw, which pin a cursor marker on your map and
  light the leg a reader points at
  (`showCursorMarker`, `writeLegEmphasis`), the profile's scrub drawing its cursor alone and its
  slope coloring Geo's own buckets unless you name yours, and its leg chips pressed through
  `onSegmentTap:` where you listen. Every
  control, row, chip, clear and retry is pressed in a 44-point touch target and draws a ring in the
  `focus-ring` token while it holds the keyboard's focus, a move a control
  starts lands at once where the reader asked for reduced motion, a profile's distance axis and
  chips grow with Dynamic Type, and a panel scrolls inside 420 points. The engine and its state
  build on every platform: itineraries, collections, zones and specifications drawn by id or by
  name, each call withdrawn by cancelling its task, a terrain's base map switched with your content
  drawn again on it, overlays and enrichments from the layers catalogue, layers and concepts shown
  and hidden,
  Data API results, three geometry slots and a picked search result
  (`setSearchHighlight(_:accent:)`) drawn over the map, the camera moved, fitted and
  stepped as the contract lands it, an ease over the renderer's own duration unless you name one, the
  device located without ever asking for access, point
  queries answering `QueriedFeature`, the taps, long presses, hovers and refusals of access a map
  tells through `events()`, the credits it shows, a TileJSON's included, and `ScriptedMapSurface`
  for an app's tests, which reports a base map's sources, `baseSources`. A refusal of a base-map
  switch stands as the base map given back loads again, until a style the map asks for loads.
  `ItinerarySegmentTable` lights the row of the leg your map's cursor is over, a group's row for
  each of its members, unless you name another row to highlight. The device's own geolocation answers a
  fix of the last minute at once and waits ten seconds for one, `locateMaxFixAge` and
  `locateFixWait`. A
  refusal of a credential your client no longer sends, such as a tile asked for under the key
  alone while the first session token was on its way and refused once it landed, is told to
  nobody and leaves `isAccessRequired` as it was, a style refused so is asked for again, and
  `ScriptedMapSurface.failRequest(url:status:source:superseded:cause:)` plays one, and a request
  that never left for want of a credential the client could read fails carrying what the read
  threw, `MapEvent.failure`'s `cause`. A base map's style
  that failed is told once, a refusal of access as that refusal alone, never also as a `failure`,
  and a failure with its status, a failure names the address the map asked for, not one a
  redirect led to, so a redirected tile's refusal names its source and is told to the map that
  asked for it, and a request that reached no answer, an offline tile, is told as a `failure` with
  no status. A map asks for its style only once its request hook shows it, so the first map of an
  app sends its style the credential too.
- Time, in the geo layer and the map, as the map studio draws it: a layers selection holds the
  instant a reader pins, `LayersSelection.instant`, a command like any other,
  `LayersSelectionEngine.setInstant(_:)`, which drives the map's own
  `LayersSelectionTarget.setInstant(_:)`, a requirement a map of yours answers too; and
  `MapEngine.setInstant(_:)` and `MapEngine.instant` draw the classic overlay the server stamps for
  that instant, each tile address asking for it, swapped as the pin moves with its layers where
  they stood, kept over a base-map switch, the manifest's own addresses with none pinned. The rules
  under it are Geo's, each handed the clock's reading: `overlayInstant(pinned:now:)`, the moment a
  map shows, `timestampedSources(_:overlay:at:)` and `TimestampedSource`, the stamped addresses,
  edited as text so a signature over them still verifies, and a time slider's
  `timeSliderWindow(now:)` and `TimeSliderWindow`, 71 hours back to 144 ahead, an hour a stop,
  `timeSliderTicks(_:)` and `TimeSliderTick`, `timeSliderRelease(_:at:)` and `TimeSliderRelease`,
  and `timeSliderReadout(_:at:)` and `TimeSliderReadout`. A date of no number, or one past the
  8.64e15 milliseconds every SDK holds a time to, names no instant and pins none.
- `LayersPanel` lists the map studio's four sections, in its order: the base maps as picture cards
  showing the picture your `thumbnail:` hands, the enrichments as switches with the points of
  interest left to their own panel, the classic overlays as cards of one category at a time behind
  a segmented control of the categories, opening on the one you picked last, else the overlay's,
  and the time where you offer it, `offersTime:`, a slider over the forecast window that pins the
  instant on release, reads its moment in the time zone the device keeps, whatever time zone your
  views state, beside its distance from now, steps an hour under an arrow key and VoiceOver's
  adjustment, and lays its track out around the clock the environment carries, `\.mountayaClock`,
  the system's unless you state your own.
  `MapControls` takes `offersTime:` and `thumbnail:` too, and hands them to its own layers panel.
  `layersPanelSections(_:language:isLocked:picked:offersTime:)` answers those sections, each
  headed by the path of its word, `LayersPanelHeading(word:)`, a classic category's name now
  naming its switch's segment, `LayersPanelCategory`, and `poisOverlaySlug` names the overlay it
  leaves out. The layers words gain the time's, in English and in French.
- One word for one concept across the three native SDKs, before the first release: the default
  origins BaseURLs.default → `BaseURLs.standard`, the `Mountaya` initializer's default included;
  SCHEMA_VERSION → `schemaVersion`; underlyingError → `cause`, on `APIError`, `ConfigurationError`
  and `ConnectionError`, their initializers' labels included; ZoomWindowEnd.neither →
  `ZoomWindowEnd.none`; `PanelControl`'s kind and panel labels → panel and content; the two
  `Credential.headers` overloads → one, `headers(for:language:method:)`, its method GET unless
  named; the static NavigationError.emptyRoute → `NavigationError.emptyRoute()`, each empty route a
  failure of its own; the Boundaries alias → `RestSchema.Boundaries`, which `selectBoundary(_:center:)`
  takes; and formatDate(_:locale:timeZone:length:), which wrote a date alone, →
  `formatDateTime(_:locale:timeZone:dateLength:timeLength:)`, which writes a date, a time of day or
  both, the word of the contract's dateTime and of TypeScript's dateTimeFormat. `APIError` and
  `ConnectionError` carry a `message` as `ConfigurationError` does; a type spells an acronym in
  capitals, as Foundation does, so ApiError → `APIError`, BaseUrls → `BaseURLs`, isApiError(_:) →
  `isAPIError(_:)`, which names the type it tests, and QueriedFeature.Id → `QueriedFeature.ID`, a
  member keeping it as a word, `baseUrls` and `requestId`; a call by declaration walks a listing too, `Mountaya.walk`, and the comparison helpers sameText,
  sameNumber, sameNumbers, sameJson and sameGeometry are no longer published: every value that
  holds what they compare is Hashable by them.
- What each of `MountayaClient`, `MountayaGeo`, `MountayaNavigation` and `MountayaElements` adds
  to an iPhone app's executable in release, and what the package brings with them, is held to a
  recorded figure (`mise run size:check`), MapLibre's framework aside, so a release that makes
  every app carry more says why, and `MountayaAdmin`'s is held at none, an app linking no admin
  unit.
- Trail, the one sample app every native SDK ships, as the contract's `sdk/trail.yaml` describes
  it, under `Examples/` and MIT-licensed, so you copy it freely: an iPhone app you run from
  `Examples/Trail/Trail.xcodeproj`, with a map and its controls, a search box, an itinerary's
  elevation profile and tables, and a navigation along the whole itinerary, said aloud, on the
  device's positions or a replay, which runs on its demo itinerary with no key; and its session
  server, `mise run trail:session`, a Swift program over `MountayaAdmin` that mints the app's
  session tokens on your Mac with your secret key. It is the app whose size the release holds each
  product to. README.md, Examples you can run, says how to run both.
- An instant is written as a date, a time of day or both (registry version 15):
  `formatDateTime(_:locale:timeZone:dateLength:timeLength:)` takes a `DateLength`, a `TimeLength`,
  short, the hour and the minute, or medium, the second too, or both, each in the locale's own
  style and on the locale's own 12- or 24-hour clock whatever clock the device is set to, a date and
  a time joined as the locale joins a date of that length, and writes the long date where neither
  is named, as the date alone was written before. A time names no zone, so it has no long or full
  length. Trail writes the arrival as its time of day and each cut-off as its date and its time of
  day. On Linux a zone writes only where the system's zone files hold it, so a legacy name such as
  `Asia/Calcutta` or `US/Eastern` on a system without `tzdata-legacy` answers nil, where it stopped
  the process, and a process whose own zone is such a name writes every zone it is asked; on Apple
  platforms a legacy name writes as its zone.
- A map matches the hosted embed (registry version 18). It reads its organization once
  `MapView` first draws it, `MapEngine.loadOrganization()`, which answers nil and never throws for
  a client holding no publishable key, and `MapEngine.organization`, through
  `postOrganizationLookup`, which moved from the admin unit to the core as
  `studio.organizations.postOrganizationLookup(body:)` with `RestSchema.Organization` and its
  settings, the key in the body and no credential sent, one read per publishable key and Map
  Studio API origin shared by every map of the process, so a staging client never shares an
  answer with production, a failed one kept by nobody. It draws the Mountaya watermark in the
  top-left corner of its safe area, the part of the map the device leaves visible, so a map drawn
  full bleed, past the safe area SwiftUI keeps, shows it below the status bar and beside the
  Dynamic Island, clipped to the map, over its markers and under a marker's label and the readout, unless
  the organization holds white label; the first read holds the mark off for one attempt's time
  budget at most, 35 seconds unless the client names another, and the mark is drawn once it has
  passed, even while the read is retried, until an answer says white label; a press opens
  Mountaya's site in the device's browser through the system's own opener, which no open-URL
  action of the app's replaces, a read asked again after a failure keeps the mark while it waits,
  and nothing an app states hides it. The mark stands top left in a layout that runs right to left
  too. Nothing of the SDK's own covers the mark: a `MapControls` stack in the top-left corner
  starts below its frame, a readout or a marker's label that would reach it moves clear of it, and
  a panel that would reach it moves below it, never to its right; a stack reads the map's own frame
  wherever it is laid, and a stack given no map, or a `PanelControl` out of any stack, holds the
  frame a waiting read holds in the safe area of the space it is laid in. A `MapView` handed another engine draws it on a canvas of its own and reads
  its organization. The answer serves the watermark alone: `MapControls`' flags have fixed defaults, the zoom,
  the compass, the layers and the preferences toggles shown and the locate control, the points of
  interest and the time offered only where the app turns them on, where every control was off
  before; the preferences panel's own set starts at the SDK's default units in the scope's
  language, and the base map, its variant, the label language and the accent are the app's, else
  the SDK's own. A marker's label is drawn by the view beside its pin, above the watermark and
  clear of it, inside the map's safe area, where it was MapLibre's callout, and none while its
  marker's point is off the map, where it was held at the map's edge without its pin. A right-click or a long press opens a readout of the point,
  `MapView(_:readout:onReady:onTap:onCameraChange:)` on unless the app turns it off: the point of
  interest, under its tile's subclass, else its class, the classic overlay's band, the terrain
  read off the elevation tiles through the client's tile transport in the order
  `elevationTilesAt(_:source:)` names them, decoded by the platform's own image codec off the main
  thread, the moment, followed live while the card is open and written in the time zone the device
  keeps, a row whose moment cannot be written there left out where it read `As of` with nothing
  after it, the coordinates with a copy button, and the zone, each figure in the SDK's
  default units, the classic overlay named in the scope's language and the aspect in whole degrees
  beside its direction, `123° · South-East`; a tap closes it, and so does a camera move as it
  starts, the reader's as it begins and the app's as it is asked, cancelling its tile reads still
  out, which leave in the order the rule names them because each is sent once the one before it
  has left. A zone's level is the printed `RestSchema.ZoneLevel`. A panel opens beside its
  toggle, inside the map and level with the toggle, where it was a system popover, and lays out as
  the embed's does from where it stands, 340 points wide or the width a narrow map leaves, under a
  title row, the layer cards three to a row and the preference options two; a tap on the map
  closes it. `MapView` is now a SwiftUI view over MapLibre's
  map rather than a UIKit representable. Together they add 204 KiB of `MountayaElements` and
  104 KiB of `MountayaGeo` to an iPhone app's executable, Trail's release build measuring 1.78 MiB
  and 1.32 MiB of them, 38 KiB and 7 KiB of it the safe area, the frame kept clear, the panels
  drawn in the map and the readout's placement and ordered reads.
- Every error's code is typed, and the map keeps clear of its mark in full (registry version 19).
  An error's `code` and each `ErrorEntry`'s are an `APIErrorCode`, printed from the contract's
  model: the union of the codes each surface declares, the Map Studio API's, the Tile API's and the
  Data API's, an open set with a static member per code, `.limitReached`,
  `.idempotencyKeyInUse` and the rest, which keeps a code a later release of the API sends exactly
  as sent, where each was a string; `APIError.hasCode(_:)` answers whether any entry carries a
  code, the first or another. `formatAltitudeRange(min:max:units:)` and `scopeOf(_:stating:)` label
  their arguments, as the registry's Swift column names them, where they took two unlabelled ones.
  `MapEngine.organizationRead` publishes where the read of the map's organization stands, the
  public `OrganizationRead` in the contract's five states, waiting, answered with white label or
  not, failed, timed out and no key, and `MountayaGeo` publishes the watermark's frame,
  `watermarkWidth`, `watermarkHeight`, `watermarkInset` and `watermarkClearance`, and whether the
  frame is held as the read stands, `isWatermarkKeptClear(_:)`, as every native SDK publishes it,
  so a host keeps its own interface clear of the mark, as Trail's search box does. The map's safe
  area is the inset the system reports through the map's window, never the view's own safe area,
  which an app's layout rewrites, and it is measured again as the map moves in its window with no
  layout of its own, in a scroll view, a sheet or under an offset, where the mark slid under the
  status bar. Every part of the SDK's own interface keeps to it and clear of the mark's frame,
  held from the map's first drawing, while the read waits too, until it answers white label: a
  `MapControls` stack in any corner and the readout each move clear of the frame by the smallest
  move, its panels move below it, and where nothing inside the map clears it, each opens with its
  top at the frame's bottom and the map's edge cutting it, the readout clipped to the map and a
  stack's panels to the map's own rect, where neither was cut. A stack over a map no view draws, before
  its view lays it out or once that view went, keeps to its own space's safe area and holds the
  frame there as the map's read holds it, so nothing moves as the map appears, where it held the
  frame a waiting read holds whatever the read answered; a map whose view goes is drawn by no view,
  where a stack over it kept reading the place that view last laid it out at. A readout stands with its top-left corner at its point,
  flipped left or up to stay inside the safe area, where it stood centred under the point, and it
  reads a zone's times to the whole second and a time written as a string as none. A failed search
  branch's line reads `search.error` beside its retry, never the API's message, which stays on the
  branch's `SearchBranchError` for the app to log. `SearchControl` shows its list while the focus
  stands anywhere in it, its box, its filter chips or its list, by `MountayaGeo`'s
  `isSearchListShown(hasFocus:query:isDismissed:)`, which a host's own list reads too, so focus
  moving to a filter chip keeps the list there. The aspect's English words are the contract's,
  `South-East`.
- The terrain under a point is read off the elevation tiles in the geo layer:
  `elevationTilesAt(_:source:)` names the tiles a point needs, `terrainFromElevationTiles(_:source:tiles:)`
  reads its height, slope and aspect off their pixels, `decodeElevation(_:encoding:)` reads a
  pixel's height by `ElevationEncoding`, `mapbox` or `terrarium`, and `aspectCardinal(_:)` names
  the eighth of the compass an aspect faces, an `AspectCardinal`. `formatHumidity(_:units:)` and
  `formatSnowfall(_:units:)` write a humidity and a depth of snow, and `filledText(_:values:)` fills
  each placeholder of a template by its name. `GlyphDrawing` carries a drawing's `opacity`, its
  `shadow` and gradient fills, `GlyphDrawing.Paint.linear`, which the watermark is drawn with.

### Performance

- `MountayaClient` adds 2.46 MiB to an iPhone app's executable where it added 4.28 MiB: the
  `admin` group's operations, the types only they and the webhook events carry, and the receiving
  of a webhook delivery are `MountayaAdmin`'s, which an app that shows a map, reads data or
  navigates does not link, and which measures 1.35 MiB where a server or an admin tool links it.
- `MountayaElements` adds 1.55 MiB to an iPhone app's executable where it added 2.00 MiB: the
  views read the design tokens of the environment through one reference rather than the tokens
  whole, which SwiftUI stores inside each view, so a view's copies and releases no longer copy and
  release every token, about 14 KiB of every app for each of the 28 views that read them; the
  views share one modifier for their own words; and the three data elements hold one body for
  both initializers. `mountayaTokens` reads and writes the tokens as before, and a host stating
  equal tokens again draws no view of the elements again.
- A Data API answer is decoded once: its entries and its metadata off its errors and its
  extensions members, and the operation's field as its type, never the whole body as JSON values
  first, and an answer carrying errors is read for them from that one decode. A 6,000-position
  directions answer decodes in 7.8 ms where it took 66 ms, or 129 ms carrying errors, each answer
  read as before.
- An answer's headers are folded once as it arrives, and every header the client reads of it,
  `Response.headers` included, is one lookup of that fold, each value as it was: the header work
  of an answer of twenty headers takes 7 µs where it took 72 µs.
- A replay walks a route without measuring it again: `ReplayLocationSource` reads each tick's
  position off the measure the `FollowedRoute` holds, through `positionAtMeters(_:meters:)` over
  the route, published for a source of your own, which places the position the line's own
  reading places to the last digit, by a search: a tick on a route of 6,000 vertices takes 0.1 µs
  where it took 226 µs, and sixty ticks measure the line once, as it is followed, where they
  measured it 63 times. The contract's `replay-measure` budget holds it.
- A fix is read along the vertices of the route flattened once as it is followed, rather than
  the line's array of arrays, each figure as before: one fix on a route of 6,000 vertices is read
  in 38 µs where it took 47 µs.
- On iOS, what MapLibre's threads tell a map, each failed request and each tile parsed, reaches
  the main actor a burst at a time, one hop for everything heard before it runs, each told once
  and in the order heard, as `MapEvent.failure` or `MapEvent.accessRefused` as before, and a map
  reads its claims once for what it draws rather than once a failure; a tile parsed while no
  refusal stands reads no state.
