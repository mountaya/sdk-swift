// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Organizations is every operation of `studio.organizations`, one method to an operation.
  public struct Organizations: Sendable {
    let sender: any OperationSending

    /// Resolve the organization a publishable key belongs to.
    ///
    /// Takes a publishable key and returns the organization it was minted for. It
    /// is the bootstrap read an embed host makes before it knows anything: given
    /// only the key it was configured with, it needs the branding, the theme and
    /// the `safety_rules` its host page will be checked against, and it has no
    /// organization id to ask `getOrganization` with.
    ///
    /// It is the one operation here that takes NO credential. The key travels in
    /// the body as the subject of the question rather than in `X-API-Key` as the
    /// answer to one, which is why sending it as a header does nothing. The answer
    /// is the organization exactly as `getOrganization` serves it: its identity,
    /// its settings and `white_label`, which is everything an embed paints by and
    /// nothing about the account behind it. Neither blanket refusal in this
    /// document's introduction applies here.
    ///
    /// UNKNOWN, REVOKED and UNDER-SCOPED keys, and every key of a canceled
    /// organization, all answer `404` with the same body. What an embed needs is
    /// the `publishing` scope, or the `studio-embedded` scope that includes it, and
    /// no other scope is asked for. A key that exists but carries neither is
    /// refused exactly as one that never existed, so this cannot be used to sort
    /// real keys from invented ones, and there is deliberately no `403` for the
    /// same reason: a refusal that said "this key is real but not for you" would
    /// be the oracle the single answer exists to close.
    ///
    /// Whether the organization holds Map Publishing is not asked here: an
    /// organization whose agreement does not include it is answered `200` all the
    /// same, and the reads its embed then makes, `getOrganization` among them,
    /// answer the plain `402` `PAYMENT_REQUIRED` while it does not. So a `200`
    /// says the key can open an embed, not that the embed will draw.
    ///
    /// It is limited to 60 requests a minute per client IP address rather than
    /// per organization, since there is no organization until it answers, an
    /// IPv6 address counted by its `/64` prefix. Every request counts, a `404`
    /// included, and one past the limit is a `429` carrying `Retry-After`, the
    /// seconds left in the minute. The limit is best effort.
    public func postOrganizationLookup(
      body: RestSchema.OrganizationLookupParams,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.Organization, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationLookup,
        body: .json(body)
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
