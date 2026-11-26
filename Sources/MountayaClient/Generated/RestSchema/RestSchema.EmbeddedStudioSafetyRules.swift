// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// The organization's security contract for Map Publishing: the ceilings a
  /// visitor of an embed can never exceed, whatever the embed's URL parameters or
  /// `default_props` ask for. Every rule here but `with_profile_elevation`, which
  /// the embed surface applies, is enforced server-side on every publishable-key
  /// request; a request made with a share token is held to `with_overlays` and
  /// `with_overlays_control` alone. Read it against `EmbeddedStudioDefaultProps`,
  /// which is the opposite kind of object: those are *starting values* a visitor
  /// may override, these are *limits* a visitor cannot.
  ///
  /// Where both objects carry the same key (`with_overlays`,
  /// `with_overlays_control`, `with_collection_itineraries`,
  /// `with_collection_zones`, `with_profile_analysis`, `with_profile_elevation`),
  /// the rule wins: the default proposes, the rule caps. A rule set to `false`
  /// forces the corresponding default off for embeds even when the default says
  /// `true`.
  ///
  /// These are the organization's own settings, with three exceptions that are
  /// Mountaya's: `with_overlays` and `with_overlays_control`, on every
  /// organization, and the sites of `domains`, on an organization covered by an
  /// agreement, whose owners and admins still add and remove its loopback
  /// entries. An owner or an admin writes the rest through
  /// `PATCH /v1/organizations/{organization_id}/settings`, under `safety_rules`,
  /// and sends those three as they stand. What a
  /// *visitor* of an embed cannot do is raise them, which is the guarantee this
  /// object exists to make: a URL parameter or a `default_props` value asking for
  /// more than a rule allows is capped every time, server-side for every rule but
  /// `with_profile_elevation`. Widening a rule is a deliberate act by someone who
  /// can already administer the organization, and it takes effect on the next
  /// request.
  public struct EmbeddedStudioSafetyRules: Sendable, Hashable, Codable {
    /// Named geographic regions outside which tiles are refused. A tile request
    /// made with a publishable key whose coordinates fall in none of them is
    /// rejected with a validation error, which caps how far an embed can pan. **An EMPTY array
    /// means no
    /// geographic restriction**, so every tile is in range. That makes this list
    /// opt-in, unlike `with_overlays`. The zoom range applies either way. Tiles
    /// scoped to a single already-authorized resource skip the boundary check
    /// (refusing them would hide nothing the caller cannot already read) but
    /// still honour the zoom range.
    public var boundaries: [RestSchema.Boundaries]
    /// The pages allowed to call the API from a browser with the organization's
    /// publishable keys, and the sites allowed to frame Mountaya's hosted embed.
    /// A request is compared by its `Origin`, falling back to `Referer`, after
    /// normalization, which ignores letter case and a leading `www.`. Mountaya's
    /// own pages are always allowed, whatever the list holds: its web
    /// application, and for the API alone its documentation, whose explorer
    /// runs the queries a reader sends with their own key. The list is checked
    /// against the page a browser names, and only then: a request naming no page,
    /// as a server sends, or as a page sends under a `no-referrer` policy that
    /// strips `Referer` from a request that carries no `Origin`, such as an
    /// image or a map tile, is not checked against it at all. It is therefore
    /// not an access control on the key: it decides which pages may use the
    /// key from a browser that names them, while the publishable key and, when
    /// required, the session token are what gate a request.
    ///
    /// **An EMPTY array allows no page but Mountaya's own**, on the API and for
    /// the hosted embed alike: a browser on any other page is refused with a
    /// `403`, and no other site can frame the embed. An organization lists
    /// every site that uses its keys or shows its embed, and `localhost` with
    /// the port of its development server while it builds; a request naming no
    /// page, from its own servers, a command line or a native app, keeps
    /// working with an empty list. A page that names the `null` origin, a
    /// sandboxed frame, a `data:` URL or a `file:` page, is refused, whatever
    /// the list holds.
    ///
    /// An entry is `host[:port]`: a host name, `localhost`, an IPv4 address or
    /// an IPv6 address in brackets, optionally followed by a port, such as
    /// `guides.example.com` or `localhost:3000`. A host name is made of letters,
    /// digits, hyphens and underscores in dot-separated labels. Anything else is
    /// a `400` naming the entry, a scheme, a path, a query, a wildcard and
    /// `null` among them: entries are compared whole, so a wildcard such as
    /// `*.example.com` would match nothing, and `null` is the origin every
    /// sandboxed frame sends. A host with an underscore and an IPv6 address are
    /// allowed on the API but cannot frame the hosted embed, because no browser
    /// accepts either in the `frame-ancestors` policy that names the sites
    /// allowed to frame a page.
    ///
    /// It holds as many entries as the organization's agreement allows, 1 by
    /// default: the `allowed-domains` limit, which an agreement may raise, lower
    /// or make unlimited. An entry naming the loopback, `localhost`, a name
    /// under `.localhost`, an address in `127.0.0.0/8` or `[::1]`, with or
    /// without a port, is not counted toward it: a page on a developer's own
    /// machine is no site of the organization's. A write that would leave more
    /// counted entries than that limit, and more than the list counts now, is a
    /// `429` coded `LIMIT_REACHED` at `allowed-domains`, and nothing is changed.
    /// A list counting more than a lowered limit is kept as it is: its entries
    /// may be edited or removed, and no counted entry added until it counts
    /// fewer than the limit.
    ///
    /// Apart from that limit, the list holds 100 entries at most, loopback ones
    /// included, whatever the agreement allows, since it is walked on every
    /// publishable-key request and
    /// sent whole in the policy that names the sites allowed to frame the hosted
    /// embed. More is a `400` naming the list.
    ///
    /// Who sets it depends on how the organization is covered. On a self-serve
    /// organization, whose keys serve the Data API, it is its administrators',
    /// written with `patchOrganizationSettings`. On an organization covered by
    /// an agreement its sites are set by Mountaya, as the agreement states, and
    /// a `patchOrganizationSettings` that adds, removes or changes a counted
    /// entry is a `403`; its administrators still add and remove its loopback
    /// entries themselves, so a developer lists `localhost:5173` without asking
    /// Mountaya.
    public var domains: [String]
    /// Whether a publishable-key request that a key alone would otherwise be
    /// served must carry a session token, minted by the publisher's backend, in
    /// the `X-Session-Token` header, or in the `session_token` query parameter
    /// where that form is read: every Tile API and Data API request. When true,
    /// a request carrying only the key is
    /// refused with a `401`; when false, a valid publishable key plus an allowed
    /// page, or no page named at all, is enough. A new organization starts with
    /// it off, so an organization with no backend can embed once it lists its
    /// sites, which makes the domain allowlist the only visitor gate in that
    /// configuration.
    ///
    /// It decides whether a request may be made, not what it reads. A token
    /// minted without `user_id`, which is what a backend mints for a visitor
    /// nobody signed in, satisfies it and is served exactly what the key alone
    /// would be: the published snapshot, public-only listings and tiles cut
    /// from published content. Only a token naming a member reads the
    /// organization's drafts.
    ///
    /// Required on every write, with no default: a settings write that left it
    /// out would otherwise be read as turning enforcement off.
    ///
    /// What it governs is what a key reaches alone. Every `management` and
    /// every `studio-embedded` operation requires a session token whatever this
    /// says, and the Data API requires one on every request, so on the Map
    /// Studio API it governs the `publishing` reads, and on the Tile API every
    /// request a key makes. It is NOT limited to the embed or to the Tile API:
    /// with it on, the `publishing` reads are refused without a token too, so
    /// turning it on for an embed also changes what a server-to-server
    /// integration reading with the same key must send.
    public var require_session_token: Bool
    /// Whether an embed may render the itineraries of a collection. A collection
    /// tile request picks the itinerary layer with its `with_itineraries` query
    /// parameter, and falls back to `default_props.with_collection_itineraries`
    /// without one. When this rule is false, a request made with a publishable
    /// key has the layer withheld whatever either of those says, and whatever
    /// its `itinerary_id` names: the rule can switch the layer off, never on.
    public var with_collection_itineraries: Bool
    /// Whether an embed may render the zones of a collection. A collection tile
    /// request picks the zone layer with its `with_zones` query parameter, and
    /// falls back to `default_props.with_collection_zones` without one. When this
    /// rule is false, a request made with a publishable key has the layer
    /// withheld whatever either of those says, as with the itinerary layer.
    public var with_collection_zones: Bool
    /// Slugs of the terrain overlays an embed may request. **An EMPTY array
    /// denies every overlay**, which is the deliberate secure default, as
    /// `domains` reads an empty list and the opposite of how `boundaries` reads
    /// one. An entry
    /// `"*"`, anywhere in the list, allows all of them. Any other list is an
    /// exact-slug allowlist, and an overlay tile for an unlisted slug is refused
    /// to a publishable key and to a share link of the organization alike. Note
    /// that `EmbeddedStudioDefaultProps.with_overlays` is a *display* list read
    /// by the client with the opposite empty-case meaning (empty there means
    /// "offer the whole catalog"); this one is the enforced cap.
    ///
    /// An entry is an overlay slug from `GET /v1/layers`, exactly as it is
    /// spelled there, or the wildcard `"*"`. Mountaya sets no other entry, so
    /// every slug listed draws that overlay; an overlay later withdrawn from
    /// the catalog is denied by its entry rather than erroring.
    ///
    /// It is always set by Mountaya, as the organization's agreement states, on
    /// every organization: a `patchOrganizationSettings` that changes it is a
    /// `403`, and one that sends it as it stands, in any order, changes
    /// nothing. It governs what a publishable key and a share link draw. The
    /// organization's own members, in Mountaya's studio, are drawn every
    /// overlay while the organization holds Map Studio.
    public var with_overlays: [String]
    /// Whether an embed visitor may move an overlay's time cursor. When false, a
    /// tile of an overlay whose `capabilities.server.timestamp` is true (the
    /// weather and snow overlays) asked for an instant more than 15 minutes from
    /// the current one is a `403`, a share-token request included, so the
    /// visitor sees the present state only and cannot browse history or
    /// forecast. An overlay whose tiles do not change with the instant is drawn
    /// whatever instant is sent.
    ///
    /// It takes away the time cursor alone: which overlays a visitor may switch
    /// on is `with_overlays`, and a false here neither hides the layers control
    /// nor refuses an overlay drawn at the present instant. Granting it grants
    /// forecast and history beyond 15 minutes, nothing else.
    ///
    /// It is always set by Mountaya, as the organization's agreement states, on
    /// every organization: a `patchOrganizationSettings` that changes it is a
    /// `403`, and one that sends it as it stands changes nothing.
    public var with_overlays_control: Bool
    /// Whether an embed may receive the computed terrain analysis of an
    /// itinerary's segments: `surface_info`, `way_type_info` and
    /// `trail_difficulty_info`. When false those three are null in the itinerary
    /// payload served to embeds: they are removed from the response, not merely
    /// hidden by the client. `road_access_info`, `slope_info`, `speed_info` and
    /// the durations are always served. Whether a share-token view receives the
    /// three does not depend on this rule.
    public var with_profile_analysis: Bool
    /// Whether an embed may show the elevation profile chart. Consumed by the
    /// embed surface, which forces the corresponding control off and disables it
    /// when this is false, so a publisher cannot re-enable it per embed.
    public var with_profile_elevation: Bool
    /// Highest zoom level for which tiles are served. A request above it is
    /// refused, which is the anti-scrape ceiling: it bounds how much detail an
    /// embed can pull. Enforced on every tile request made with a publishable
    /// key, including for tiles scoped to a single authorized resource; a
    /// share-token request is not held to it. The client pulls its camera
    /// maximum slightly inside this value to leave headroom for pitch and terrain
    /// drift. A new organization starts at 18.
    ///
    /// The bounds are the tile surface's own: `z` is `0..22` on every tile
    /// operation, so a ceiling outside that range can never refuse anything a
    /// structurally valid request could ask for.
    public var zoom_max: Int
    /// Lowest zoom level for which tiles are served. A request below it is
    /// refused, which bounds how far out an embed can zoom. Enforced wherever
    /// `zoom_max` is. Set it equal to or near `zoom_max` only deliberately: the
    /// client has to widen a degenerate range to keep a valid camera, so a very
    /// narrow window is honoured at the tile layer but approximated at the
    /// camera. A value above `zoom_max` is a 400 naming `zoom_min`: an inverted
    /// range would refuse every tile, which reads to a visitor as a map that
    /// never loads. A new organization starts at 8.
    public var zoom_min: Int

    /// Creates a `EmbeddedStudioSafetyRules` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      boundaries: [RestSchema.Boundaries],
      domains: [String],
      require_session_token: Bool,
      with_collection_itineraries: Bool,
      with_collection_zones: Bool,
      with_overlays: [String],
      with_overlays_control: Bool,
      with_profile_analysis: Bool,
      with_profile_elevation: Bool,
      zoom_max: Int,
      zoom_min: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.boundaries = boundaries
      self.domains = domains
      self.require_session_token = require_session_token
      self.with_collection_itineraries = with_collection_itineraries
      self.with_collection_zones = with_collection_zones
      self.with_overlays = with_overlays
      self.with_overlays_control = with_overlays_control
      self.with_profile_analysis = with_profile_analysis
      self.with_profile_elevation = with_profile_elevation
      self.zoom_max = zoom_max
      self.zoom_min = zoom_min
      configure(&self)
    }

    /// Reads a `EmbeddedStudioSafetyRules` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.boundaries = try container.decode([RestSchema.Boundaries].self, forKey: "boundaries")
      self.domains = try container.decode([String].self, forKey: "domains")
      self.require_session_token = try container.decode(Bool.self, forKey: "require_session_token")
      self.with_collection_itineraries = try container.decode(
        Bool.self, forKey: "with_collection_itineraries")
      self.with_collection_zones = try container.decode(Bool.self, forKey: "with_collection_zones")
      self.with_overlays = try container.decode([String].self, forKey: "with_overlays")
      self.with_overlays_control = try container.decode(Bool.self, forKey: "with_overlays_control")
      self.with_profile_analysis = try container.decode(Bool.self, forKey: "with_profile_analysis")
      self.with_profile_elevation = try container.decode(
        Bool.self, forKey: "with_profile_elevation")
      self.zoom_max = try container.decode(Int.self, forKey: "zoom_max")
      self.zoom_min = try container.decode(Int.self, forKey: "zoom_min")
    }

    /// Writes a `EmbeddedStudioSafetyRules` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encode(self.boundaries, forKey: "boundaries")
      try container.encode(self.domains, forKey: "domains")
      try container.encode(self.require_session_token, forKey: "require_session_token")
      try container.encode(self.with_collection_itineraries, forKey: "with_collection_itineraries")
      try container.encode(self.with_collection_zones, forKey: "with_collection_zones")
      try container.encode(self.with_overlays, forKey: "with_overlays")
      try container.encode(self.with_overlays_control, forKey: "with_overlays_control")
      try container.encode(self.with_profile_analysis, forKey: "with_profile_analysis")
      try container.encode(self.with_profile_elevation, forKey: "with_profile_elevation")
      try container.encode(self.zoom_max, forKey: "zoom_max")
      try container.encode(self.zoom_min, forKey: "zoom_min")
    }
  }
}
