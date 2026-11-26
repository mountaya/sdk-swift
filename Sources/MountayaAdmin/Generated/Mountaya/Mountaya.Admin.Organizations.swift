// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Organizations is every operation of `admin.organizations`, one method to an operation.
  public struct Organizations: Sendable {
    let sender: any OperationSending

    /// Delete an organization's AI provider configuration.
    ///
    /// Removes the organization's AI provider configuration, the stored
    /// credential with it. Without one the co-pilot cannot run for this
    /// organization's resources: `postAgentRun` answers 409
    /// `AI_PROVIDER_NOT_CONFIGURED` until `postOrganizationAiProviderConfig`
    /// creates a new one, and a run already in flight ends with an error at its
    /// next model call.
    /// - Owner or admin only (403 otherwise).
    /// - Deleting is an act on the organization's state, so with none configured
    ///   it answers 200 and changes nothing, whatever `If-Match` names: there is
    ///   no configuration left for the condition to protect.
    /// - `If-Match` makes it conditional on the configuration's `etag`, so a
    ///   configuration somebody changed since it was read is not deleted
    ///   unseen.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with the owner or admin role, whom the request acts
    /// as. A session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func deleteOrganizationAiProviderConfig(
      organization_id: String,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteOrganizationAiProviderConfig,
        pathParameters: ["organization_id": organization_id],
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the AI provider catalog.
    ///
    /// Returns the catalog of AI providers an organization may configure for the
    /// studio co-pilot: each provider's id, label, selectable model ids, and the
    /// credential fields it requires. The catalog is the same for every caller (no
    /// per-organization data) and is safe to cache. It asks no member role, so a
    /// session token is answered alike whoever it names, or, minted for `api`, with
    /// no user at all; one minted for `studio-embedded` without `user_id` is a
    /// `401`.
    ///
    /// It is the vocabulary `postOrganizationAiProviderConfig` and
    /// `patchOrganizationAiProviderConfig` check a configuration against: the
    /// model is one of the provider's models, and the credential carries exactly
    /// the fields the provider names.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization; past either, the answer is a `429` carrying
    /// `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getAiProviders(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.AiProviderCatalog], [String: JSONValue]?> {
      let request = OperationRequest(facts: .getAiProviders)
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve an organization.
    ///
    /// Returns the organization: its name, whether it awaits its agreement,
    /// whether it may leave the Mountaya mark off its maps (`white_label`), and
    /// the Map Publishing settings that shape what an embed of it looks like.
    ///
    /// Every credential is served the same object. Nothing is trimmed for a
    /// publishable key or a share token: the settings an embed needs to paint
    /// itself, `safety_rules.domains` among them, are what this bootstrap read
    /// exists to serve. What the organization's agreement entitles it to is read
    /// elsewhere: the products it holds as `organization_capabilities` on
    /// `getMyOrganizations`, and its subscription with
    /// `getOrganizationBillingSubscription`.
    ///
    /// The path names the key's own organization: a key reaches its own
    /// organization and no other, and naming another is a `403` whether or not it
    /// exists. A share token reaches the organization that owns what its link
    /// names, because a share view is an embed: it paints the same layers, reads
    /// the same branding and needs the same settings to do it. Naming any other
    /// organization under a share token is the same `403`.
    ///
    /// An embed that does not know which organization it belongs to resolves one
    /// from its own key with `postOrganizationLookup`, which takes the key itself
    /// rather than an id.
    ///
    /// Reads are limited per minute. A publishable key sent without a session
    /// token, or with one minted without `user_id`, is held to 600 per client IP
    /// address and then 6000 per organization; a key with a session token naming a
    /// user to 1200 per user the token names and then 6000 per organization,
    /// counted apart from the reads made under the key alone; and a share token to
    /// 600 per client IP address and then 6000 per organization that owns the link.
    /// Past any of them the read is a `429` carrying `Retry-After`. A share token
    /// not resolved moments earlier is refused the same way when its client IP
    /// address has had 60 unknown share tokens refused within the minute.
    ///
    /// A publishable key needs the `publishing` scope, or the `studio-embedded`
    /// scope that includes it. A share token carries its own authority and needs
    /// none.
    public func getOrganization(
      organization_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Organization, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganization,
        pathParameters: ["organization_id": organization_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve an organization's AI provider configuration.
    ///
    /// Returns the organization's AI provider configuration for the studio
    /// co-pilot, masked: the provider, the model, the base URL override if one is
    /// set, and a non-sensitive hint of the credential. The credential itself is
    /// never returned.
    ///
    /// An organization with no configuration is not a missing resource: it
    /// answers 200 with `data: null`, which is the state a client renders a setup
    /// prompt from, and which `postOrganizationAiProviderConfig` leaves.
    /// - A session token minted for `api` without `user_id` is asked for no member
    ///   role on this read; one minted for `studio-embedded` without `user_id` is
    ///   the `401` a key alone gets. One that names a user is answered only while
    ///   that user is a member of the organization, in any role, and is a 403
    ///   otherwise.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization; past either, the answer is a `429` carrying
    /// `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationAiProviderConfig(
      organization_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.AiProviderConfig?, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationAiProviderConfig,
        pathParameters: ["organization_id": organization_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve an organization's Map Publishing settings.
    ///
    /// Returns the settings that shape an organization's embeds: the
    /// default props a viewer starts from, the map theme, and the safety rules a
    /// visitor can never exceed. Read it against the same object the PATCH beside
    /// it replaces: this is the whole of what that operation writes, and nothing
    /// else.
    /// - A session token minted for `api` without `user_id` is asked for no member
    ///   role on this read; one minted for `studio-embedded` without `user_id` is
    ///   the `401` a key alone gets. One that names a user is answered only while
    ///   that user is a member of the organization, in any role, and is a 403
    ///   otherwise. Changing the settings takes the owner or admin role, which is
    ///   why the PATCH needs a session token naming a user and this read does not.
    /// - The settings carry an `etag` of their own, versioned apart from the
    ///   organization's: a settings change moves it and leaves the
    ///   organization's alone, and a rename moves the organization's and leaves
    ///   this one alone, so neither ever refuses the other.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization; past either, the answer is a `429` carrying
    /// `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationSettings(
      organization_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.OrganizationSettings, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationSettings,
        pathParameters: ["organization_id": organization_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve an organization's data usage.
    ///
    /// Returns data usage a day at a time, one figure per operation per surface
    /// per metric per status class. A combination with usage anywhere in the
    /// range carries a figure for every day of it, `0` on the days it had none.
    /// `requests` is recorded for every call that gets past the credential
    /// check; the other metrics count the work one kind of call did, so each
    /// appears only beside the operation that can emit it. A refused request
    /// records `requests` alone, because the work the other metrics count never
    /// happened, and one refused before any operation ran is counted under each
    /// operation its document names. `UsageDataResourceType` says which refusals
    /// are counted nowhere. A request whose caller went away before the server
    /// began to answer it, by closing its connection or cancelling the request,
    /// is counted nowhere, however long it had waited, since its answer reached
    /// nobody. A caller that leaves once its answer has begun does not change how
    /// it is counted. A request too slow is the server's to fail: one answered
    /// `504` because its time budget ran out is counted as a `5xx`. So is one the
    /// server could not finish checking once it knew the organization, answered
    /// `500`, on the surface its session token was minted for, and a root field
    /// that fails once its operation has run, its answer included, is counted as
    /// the failure it was answered with, never as the success its work reached
    /// first. A call through Mountaya's MCP server is counted as the same call
    /// made to this API directly, its refusals included. One the MCP server could
    /// not deliver to this API once it held a session for it, this API
    /// unreachable or what stands in front of it answering in its place, is
    /// counted as a `5xx` on the `mcp` surface; one it could get no session for
    /// names no organization, and is counted nowhere.
    /// - A session token minted for `api` without `user_id` is what authorizes this
    ///   read, and no member role is checked on top of it; one minted for
    ///   `studio-embedded` without `user_id` is the `401` a key alone gets. One
    ///   that names a user is answered only while that user holds the owner or
    ///   admin role in the organization, and is a 403 otherwise. The path names the
    ///   key's own organization: another is a 403, whether or not it exists.
    /// - Omit `start_at` and `end_at` and the range is the current month plus the
    ///   three complete months before it. A lone `start_at` runs to the end of the
    ///   current month, or to a year after it when that comes first, and a lone
    ///   `end_at` starts a year before it.
    /// - A `start_at` after `end_at` is a `400`, and so is a window of more than
    ///   366 calendar days, both ends included, an `end_at` more than 365 days
    ///   after `start_at`, refused at both parameters: ask for a long history a
    ///   year at a time.
    /// - `resource_type` and `metric` may be combined, but only into a pair that
    ///   exists: `polygons` belongs to `isochrones` and nothing else, so asking for
    ///   it beside `directions` is a 400 rather than an empty list. A value
    ///   outside `UsageDataResourceType`, `UsageMetric` or `UsageDataSurface` is
    ///   a `400` naming its parameter.
    /// - Usage is recorded under one of four surfaces: `api`, a request to the
    ///   Data API from one of the organization's own clients; `mcp`, a request
    ///   made through Mountaya's MCP server; `studio-embedded`, the work an
    ///   Embedded Studio did for the organization under one of its keys, which is
    ///   the routing a Map Studio write did (a routed segment, an import preview
    ///   and confirm, or a zone computed from a source) and every Data API
    ///   request made with a session token minted for `studio-embedded` while
    ///   the organization holds Embedded Studio, such a request being `api` while
    ///   it does not; and `studio-online`, the same work done by Map
    ///   Studio in Mountaya's web
    ///   application for a member of the organization. Only `api` and `mcp`
    ///   count toward the Data API's per-minute limit, its monthly allowance and
    ///   the invoice. The two studio surfaces are reported so the organization
    ///   can see them, and are never counted. `surface` keeps one of them;
    ///   omitted, all four are reported.
    /// - The figures are a series over the window, not a listing of resources, so
    ///   they are not paged: every figure of the window comes back at once.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization; past either, the answer is a `429` carrying
    /// `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationUsageData(
      organization_id: String,
      query: AdminSchema.GetOrganizationUsageDataQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.UsageDataPoint], [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationUsageData,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve an organization's Tile API usage.
    ///
    /// Returns Tile API usage a day at a time, one figure per kind of resource per
    /// surface per status class. The split is deliberate: a day on which a resource
    /// was served from both the embed and the API, or both succeeded and failed,
    /// yields one figure per combination rather than one total, so a reader can add
    /// them for a headline number, take the `2xx` ones of the `api` and
    /// `embedding` surfaces, `terrain` aside, for what the monthly allowance
    /// counts, or
    /// compare `2xx` against `5xx` for availability. A request whose caller went
    /// away before the server began to answer it, as a map does with the tiles it
    /// stops waiting for when it moves, is counted nowhere, however long it had
    /// waited. A caller that leaves once its tile has begun does not change how
    /// it is counted. A request the server could not finish checking once it
    /// knew the organization, its own or the one a share link belongs to, is
    /// answered `500` and counted as a `5xx`. A combination with usage anywhere
    /// in the range carries a figure for every day of it, `0` on the days it had
    /// none.
    /// - A session token minted for `api` without `user_id` is what authorizes this
    ///   read, and no member role is checked on top of it; one minted for
    ///   `studio-embedded` without `user_id` is the `401` a key alone gets. One
    ///   that names a user is answered only while that user holds the owner or
    ///   admin role in the organization, and is a 403 otherwise. The path names the
    ///   key's own organization: another is a 403, whether or not it exists.
    /// - Omit `start_at` and `end_at` and the range is the current month plus the
    ///   three complete months before it. A lone `start_at` runs to the end of the
    ///   current month, or to a year after it when that comes first, and a lone
    ///   `end_at` starts a year before it.
    /// - A `start_at` after `end_at` is a `400`, and so is a window of more than
    ///   366 calendar days, both ends included, an `end_at` more than 365 days
    ///   after `start_at`, refused at both parameters: ask for a long history a
    ///   year at a time.
    /// - A `resource_type` outside `UsageTileResourceType` is a `400` naming it.
    /// - The `api` surface, the organization's own clients, and the `embedding`
    ///   surface, a tile drawn inside the Mountaya-hosted embed, count toward
    ///   the Tile API's per-minute limit and its monthly allowance, and the
    ///   allowance counts their figures of class `2xx` alone: a tile refused or
    ///   failed is recorded here and never counted toward it. The other surfaces
    ///   are recorded so the organization can see them and are never counted: a
    ///   `studio-embedded` figure is a tile an Embedded Studio drew, a
    ///   `studio-online` figure one Map Studio in Mountaya's web application drew
    ///   for a member of the organization, and a `share` figure one drawn through
    ///   one of the organization's share links. A `terrain` figure, the base map
    ///   served through the Tile API, is recorded on whichever surface asked for
    ///   it and never counted, on any surface.
    /// - The figures are a series over the window, not a listing of resources, so
    ///   they are not paged: every figure of the window comes back at once.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization; past either, the answer is a `429` carrying
    /// `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationUsageTiles(
      organization_id: String,
      query: AdminSchema.GetOrganizationUsageTilesQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.UsageTilePoint], [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationUsageTiles,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update an organization.
    ///
    /// Changes the organization's own fields, merged into what is stored: a field
    /// left out keeps its value, and an empty object changes nothing and answers
    /// the organization as it stands. The display name is the whole of what is
    /// settable here: the Map Publishing settings are `patchOrganizationSettings`,
    /// the products the account holds follow from its agreement or its Data API
    /// subscription, and its limits from its agreement or the defaults. A change
    /// made here therefore cannot carry one of those along by accident.
    /// - Owner or admin only (403 otherwise).
    /// - A name of more than 30 characters as sent, or of fewer than 2 once leading
    ///   and trailing whitespace is trimmed, is a 400.
    /// - It does not change the name invoices are addressed to once one has been
    ///   set through `patchOrganizationBillingInfo`.
    /// - `If-Match` makes it conditional on the organization's `etag`. The
    ///   settings carry an `etag` of their own, so a settings change made in the
    ///   meantime never refuses this one.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with the owner or admin role, whom the request acts
    /// as. A session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchOrganization(
      organization_id: String,
      body: AdminSchema.OrganizationUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Organization, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchOrganization,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update an organization's AI provider configuration.
    ///
    /// Changes the organization's AI provider configuration, merged into what is
    /// stored: a field left out keeps its value, and an empty object changes
    /// nothing and answers the configuration as it stands.
    /// - Owner or admin only (403 otherwise).
    /// - `model` must be one of the configured provider's models in
    ///   `getAiProviders`. `base_url` set to null clears the override, so
    ///   completions go to the provider's default endpoint again.
    /// - `credential` replaces the stored credential whole, carrying every field
    ///   the configured provider names, each non-empty; omitted, the stored
    ///   credential is kept, so the model can be changed without sending the key
    ///   again. It is write-only and never returned.
    /// - A `base_url` other than the one stored must come with `credential`: the
    ///   stored credential is never sent to a host it was not stored for, so a
    ///   new URL without it is a 400 with one entry at `["credential"]`, and
    ///   nothing changes. A null `base_url`, which returns completions to the
    ///   provider's own endpoint, keeps the stored credential.
    /// - The provider is not a field here: switching providers is
    ///   `deleteOrganizationAiProviderConfig` and then
    ///   `postOrganizationAiProviderConfig`.
    /// - With none configured there is nothing to change: the answer is a 409
    ///   coded `AI_PROVIDER_NOT_CONFIGURED`, whatever the body or `If-Match`
    ///   says. It comes before any 400 this operation judges of the body (a
    ///   model the provider lacks, a `base_url` refused or sent without
    ///   `credential`, a credential of the wrong shape), since each is judged
    ///   against the configured provider. Create one with
    ///   `postOrganizationAiProviderConfig`.
    /// - `If-Match` makes it conditional on the configuration's `etag`.
    /// - A change takes effect at the next model call of every run, a run already
    ///   in flight included.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with the owner or admin role, whom the request acts
    /// as. A session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchOrganizationAiProviderConfig(
      organization_id: String,
      body: AdminSchema.AiProviderConfigUpdateParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.AiProviderConfig, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchOrganizationAiProviderConfig,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update an organization's Map Publishing settings.
    ///
    /// Applies a partial update to the settings that shape an organization's
    /// embeds: the default props, the map theme, and the safety rules.
    /// Only the groups present in the request body are replaced; the omitted groups
    /// are preserved. A group that is present carries every one of its fields, so
    /// a partial group is a 400 rather than a partial change.
    /// - Owner or admin only (403 otherwise). That is the role difference from the
    ///   GET beside it, and the reason this one needs a session token naming a
    ///   user.
    /// - `If-Match` makes it conditional on the settings' own `etag`, which only
    ///   a settings change moves: a rename made in the meantime never refuses it.
    /// - Three safety rules are set by Mountaya, and a request sends them as they
    ///   stand: `safety_rules.with_overlays` and
    ///   `safety_rules.with_overlays_control` on every organization, and
    ///   the sites of `safety_rules.domains` on an organization covered by an
    ///   agreement. A `safety_rules` group that changes any of them is a `403`
    ///   whose entry names that field, and nothing is changed. `with_overlays` is
    ///   compared as a set, so the order of its slugs changes nothing, and the
    ///   sites of `domains` are compared as a set once each entry is normalized
    ///   the way it is stored, its loopback entries (`localhost`, a name under
    ///   `.localhost`, `127.0.0.0/8`, `[::1]`) left out: an administrator adds and
    ///   removes those on any organization. A self-serve organization's
    ///   administrators set its `domains` whole.
    /// - `safety_rules.domains` holds as many counted entries as the
    ///   organization's agreement allows, 1 unless it says otherwise, a loopback
    ///   entry never counting: a request that would leave more, and more than the
    ///   list counts now, is refused at `allowed-domains`, a `429` coded
    ///   `LIMIT_REACHED` with no `Retry-After`, and nothing is changed. Remove one
    ///   first, or agree a higher limit. A list counting more than a lowered limit
    ///   is kept: its entries may be edited or removed, and no counted entry
    ///   added until it counts fewer than the limit.
    /// - The organization's limits, the per-minute rate limits and monthly
    ///   allowances among them, are not settings and are not here: they are the
    ///   organization's agreement's, and a caller that exhausts one is refused by
    ///   the surface that limit governs.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with the owner or admin role, whom the request acts
    /// as. A session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    ///
    /// `ifMatch` is the `etag` the caller read the resource under, or `"*"`, sent as `If-Match`
    /// exactly as given, and nothing is sent where it is `nil`.
    public func patchOrganizationSettings(
      organization_id: String,
      body: AdminSchema.OrganizationSettingsPatchParams,
      idempotencyKey: String? = nil,
      ifMatch: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.OrganizationSettings, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchOrganizationSettings,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey,
        ifMatch: ifMatch
      )
      return try await sender.envelope(request, options: options)
    }

    /// Create an organization.
    ///
    /// Creates an organization and makes the user the session token names its
    /// owner.
    /// - The new organization is not reachable with the key that created it. A
    ///   publishable key acts on its own organization only, so every operation
    ///   naming the new one is a `403` under that key, and no operation in this
    ///   contract issues a key into another organization. Its subscription, keys
    ///   and settings are managed with a key issued in it.
    /// - It starts with no subscription and holds no product, so every
    ///   operation that needs one answers `402` until it does. There are two
    ///   ways in. Self-serve, its first card opens the metered Data API
    ///   subscription, through `postOrganizationBillingProvision`,
    ///   `postOrganizationBillingPaymentMethodSetup` and
    ///   `postOrganizationBillingPaymentMethod` in that order, and from then it
    ///   holds `data` for as long as that subscription is in force. Under an
    ///   agreement with Mountaya, which `agreement_requested` asks for, it holds
    ///   exactly the products the agreement names once it is set: Map Studio,
    ///   Map Publishing, the Tile API, Embedded Studio and White label are only
    ///   ever granted this way. Until then `awaiting_agreement` reads true and
    ///   the organization is not asked for a card.
    /// - Creating it also opens its billing account, whichever of the two ways
    ///   it takes, normally within seconds of the answer and otherwise by the
    ///   next weekly check at the latest: nothing is charged and no subscription
    ///   is opened. Until the account is open, the billing
    ///   operations that need one answer as they do for an organization without
    ///   one, and `postOrganizationBillingProvision` opens it at once.
    /// - The optional `website` seeds the embed domain allowlist from its host, so
    ///   a new organization's keys work from its own site from the start. Omit it
    ///   and the allowlist starts empty: no page but Mountaya's own can call the
    ///   API with the organization's keys from a browser, and no site but
    ///   Mountaya's own can frame its hosted embed, until it is set: by
    ///   `patchOrganizationSettings` on a self-serve organization, and by
    ///   Mountaya, as the agreement states, once an agreement covers it. Calls
    ///   from the organization's own servers, which name no page, work either
    ///   way.
    /// - A name of more than 30 characters as sent, or of fewer than 2 once leading
    ///   and trailing whitespace is trimmed, is a 400.
    /// - Send an `Idempotency-Key`: a create sent again without one makes a second
    ///   organization. A create sent again with it, after the first failed with a
    ///   `5xx` once the organization was made, is the `409` coded
    ///   `IDEMPOTENCY_ANSWER_UNAVAILABLE`, whose `extensions.metadata.location`
    ///   names the organization made, `/v1/organizations/{organization_id}`, so
    ///   carry on with that one rather than creating it again.
    /// - Each user creates at most 10 organizations a minute and 50 a day. Past
    ///   either, the request is a `429` carrying `Retry-After`, and nothing is
    ///   created.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with a write role, whom the request acts as. A
    /// session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postOrganization(
      body: AdminSchema.OrganizationCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Organization, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganization,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Configure an organization's AI provider.
    ///
    /// Creates the organization's AI provider configuration for the studio
    /// co-pilot: the provider, the model, the credential, and optionally a base
    /// URL override. From then on the organization can start agent runs, which
    /// `postAgentRun` refuses while none is configured.
    /// - Owner or admin only (403 otherwise).
    /// - An organization has one configuration at most: creating one while one
    ///   exists is a 409. Change it with `patchOrganizationAiProviderConfig`;
    ///   the provider is fixed once configured, so switching providers is
    ///   `deleteOrganizationAiProviderConfig` and then this.
    /// - The model must be one of the provider's models, and the credential must
    ///   carry every field the provider names and no other, each non-empty, as
    ///   `getAiProviders` lists them; anything else is a 400 naming the field.
    /// - The credential is write-only: it is encrypted at rest and never
    ///   returned. The answer is the masked configuration, with a hint of the
    ///   credential in its place.
    ///
    /// Requires a publishable key with the `management` scope AND a session token
    /// naming a user, a member with the owner or admin role, whom the request acts
    /// as. A session token minted without `user_id` is refused with **401**, and a
    /// publishable key without a session token is not accepted here: a key written
    /// to be shipped in a browser cannot be sufficient on its own to read or change
    /// an organization's account.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postOrganizationAiProviderConfig(
      organization_id: String,
      body: AdminSchema.AiProviderConfigCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.AiProviderConfig, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationAiProviderConfig,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
