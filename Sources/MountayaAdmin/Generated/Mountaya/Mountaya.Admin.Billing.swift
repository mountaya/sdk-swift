// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya.Admin {
  /// Billing is every operation of `admin.billing`, one method to an operation.
  public struct Billing: Sendable {
    let sender: any OperationSending

    /// Detach a payment method from an organization.
    ///
    /// Removes a saved payment method from the organization.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403).
    /// - The method must belong to this organization: an identifier naming none of
    ///   its methods is a 404, whether it names another organization's method or
    ///   nothing at all, and the two answer alike. A method already detached names
    ///   none of them, so a second detach is that 404 too; send a retried detach
    ///   with the same `Idempotency-Key` and it is answered with the first one's
    ///   200.
    /// - Detaching the default while another method is saved is a 409: make
    ///   another one the default with
    ///   `postOrganizationBillingPaymentMethodSetDefault` first. Detaching the
    ///   default when it is the only method leaves the organization without one:
    ///   while its Data API subscription is in force, a key's Data API request
    ///   then answers 402 until another is saved.
    /// - The organization must already have a billing account, which
    ///   creating the organization opens, or `postOrganizationBillingProvision` when
    ///   it comes first. One that does not answers 404.
    ///
    /// The payment provider is asked as the call is made, so it is limited,
    /// together with the six other billing writes this document's introduction
    /// lists, to 30 a minute per user the token names and then to 300 a minute
    /// per organization, an allowance apart from the billing reads'. Past
    /// either, the answer is a `429` carrying `Retry-After`, and nothing is done.
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
    public func deleteOrganizationBillingPaymentMethod(
      organization_id: String,
      payment_method_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteOrganizationBillingPaymentMethod,
        pathParameters: [
          "organization_id": organization_id, "payment_method_id": payment_method_id,
        ],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// End an organization's Data API subscription at the end of its period.
    ///
    /// Ends the organization's metered Data API subscription when its current
    /// period does. Nothing changes before then: the organization keeps `data`,
    /// its requests are still counted, and the period is invoiced at its end, as
    /// every period is, its usage up to the moment it ends included, its last day
    /// among it. The subscription then ends, and from then the organization does
    /// not hold `data`.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403). An agreement ends
    ///   a subscription the organization still holds at the end of its period on
    ///   its own.
    /// - The subscription is returned with `cancel_at_period_end` true, and
    ///   `current_period_end_at` the moment it ends.
    /// - An organization that holds no Data API subscription, or only one that
    ///   has ended, has nothing to end. It is answered 200 with the subscription
    ///   as `getOrganizationBillingSubscription` reads it, `data` null where it
    ///   never held one, and nothing changes.
    /// - `postOrganizationBillingSubscription` takes the end back while the period
    ///   runs, and runs the Data API again once it has ended.
    /// - Calling it again changes nothing: an end already scheduled is answered as
    ///   it stands.
    ///
    /// The payment provider is asked as the call is made, so it is limited,
    /// together with the six other billing writes this document's introduction
    /// lists, to 30 a minute per user the token names and then to 300 a minute
    /// per organization, an allowance apart from the billing reads'. Past
    /// either, the answer is a `429` carrying `Retry-After`, and nothing is done.
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
    public func deleteOrganizationBillingSubscription(
      organization_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.OrganizationSubscriptionSummary?, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .deleteOrganizationBillingSubscription,
        pathParameters: ["organization_id": organization_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// List the billing catalog.
    ///
    /// Returns what an organization can buy: one entry per unit of access, with the
    /// capabilities it grants, how it is counted, and the price it is sold on. It
    /// is the catalog a client builds a checkout from, so the figures it shows are
    /// the ones that will be charged rather than a copy kept in step by hand. The
    /// Data API is the one product sold this way, metered by the month on the
    /// requests made, and the first card an organization saves is what opens
    /// it, unless the customer, or that card, still owes an invoice, which is the
    /// `402` and opens nothing. Map Studio, Map Publishing, the Tile API, Embedded Studio and White
    /// label are granted by an organization's agreement with Mountaya and are
    /// not in the catalog.
    /// - The catalog is the same for every organization, and it asks no member
    ///   role, so a session token is answered alike whoever it names, or, minted
    ///   for `api`, with no user at all; one minted for `studio-embedded` without
    ///   `user_id` is a `401`. A product with no price set is left out rather than
    ///   returned without one, so an entry that is here is one that can be bought.
    ///   A product whose prices cannot be read from the payment provider at the
    ///   moment is still listed, with `prices` empty: read that as an amount
    ///   unavailable, not as a product that cannot be bought.
    /// - It is a catalog, not a listing of what an organization made, so it is
    ///   not paged: every product comes back at once.
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
    public func getBillingProducts(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.BillingProduct], [String: JSONValue]?> {
      let request = OperationRequest(facts: .getBillingProducts)
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve an organization's billing information.
    ///
    /// Returns what an invoice is addressed to: the name, the email, the billing
    /// address when one is on file, and the tax identifier when one is registered.
    /// Read it against the same object `patchOrganizationBillingInfo` writes: this
    /// is the whole of what that operation changes.
    /// - A session token minted for `api` without `user_id` is what authorizes this
    ///   read, and no member role is checked on top of it; one minted for
    ///   `studio-embedded` without `user_id` is the `401` a key alone gets. One
    ///   that names a user is answered only while that user holds the owner or
    ///   admin role in the organization, and is a 403 otherwise. The path names the
    ///   key's own organization: another is a 403, whether or not it exists.
    /// - `data` is null for an organization that has no billing account yet,
    ///   which `postOrganizationBillingProvision` opens: there is nothing to
    ///   address an invoice to until then.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization. The payment provider answers it as it is asked, so it
    /// is also limited, together with `getOrganizationBillingPaymentMethods`,
    /// `getOrganizationBillingInvoices`, `getOrganizationBillingPromotionCode` and
    /// `postOrganizationBillingProvision`, to 60 a minute per user the token names
    /// and then to 300 a minute per organization. Past any of these, the answer is
    /// a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationBillingInfo(
      organization_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.BillingInfo?, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationBillingInfo,
        pathParameters: ["organization_id": organization_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// List an organization's invoices.
    ///
    /// Returns the organization's invoices, most recent first, each with its
    /// number, date, total, what is still owed, and the links a payer follows to
    /// view or download it. Amounts are in the currency's minor unit and are
    /// reported as the payment provider holds them: nothing here is recomputed.
    /// - A session token minted for `api` without `user_id` is what authorizes this
    ///   read, and no member role is checked on top of it; one minted for
    ///   `studio-embedded` without `user_id` is the `401` a key alone gets. One
    ///   that names a user is answered only while that user holds the owner or
    ///   admin role in the organization, and is a 403 otherwise. The path names the
    ///   key's own organization: another is a 403, whether or not it exists.
    /// - The organization must already have a billing account, which
    ///   creating the organization opens, or `postOrganizationBillingProvision` when
    ///   it comes first. One that does not answers 404.
    /// - For a self-serve organization, the history is empty until its first
    ///   card opens its Data API subscription. From then it grows by one invoice
    ///   for each billing period the subscription is in force, a period running
    ///   from the day of the month it opened to the same day of the next, each
    ///   billing the Data API requests of the period that has just closed, and by
    ///   the closing invoice of a subscription that ends. It never shrinks.
    /// - For an organization billed by its agreement with Mountaya, or awaiting
    ///   one, the history holds the invoices issued to it and never a draft, so
    ///   `status=draft` lists none for it. Its invoices carry no
    ///   `hosted_invoice_url`: it settles them as its agreement says, never through
    ///   the payment provider's page, and downloads each one as a PDF.
    /// - A void invoice is never listed: it was withdrawn and nobody owes it, so
    ///   `status=void` lists none.
    /// - `status` keeps the invoices that stand at it, so `status=open` lists
    ///   what is still to be paid.
    /// - The listing is paged, 50 invoices to a page unless `limit` says
    ///   otherwise, the most recent first, as the payment provider returns them;
    ///   the order is not the caller's to choose, so the listing takes no `sort`.
    ///   Send the page's `next_cursor` back as `cursor` for the next one; the
    ///   last page reports `next_cursor: null`.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization. The payment provider answers it as it is asked, so it
    /// is also limited, together with `getOrganizationBillingPaymentMethods`,
    /// `getOrganizationBillingInfo`, `getOrganizationBillingPromotionCode` and
    /// `postOrganizationBillingProvision`, to 60 a minute per user the token names
    /// and then to 300 a minute per organization. Past any of these, the answer is
    /// a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationBillingInvoices(
      organization_id: String,
      query: AdminSchema.GetOrganizationBillingInvoicesQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.Invoice], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationBillingInvoices,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationBillingInvoices walks the listing `getOrganizationBillingInvoices`
    /// answers, one row at a time, requesting a page only as the rows before it are read
    /// (`transport.pagination.walk`).
    ///
    /// Every request sends `query`, its filters and `sort` included, with its `limit` replaced by
    /// `pageSize`, from 1 to 100, and its `cursor` by the one the walk has reached, starting from
    /// `query`'s own, so a walk resumes where an earlier one stopped. It follows every page for as
    /// long as a `next_cursor` names one, an empty page included, and stops at a null
    /// `next_cursor`, at `maxPages` requests, which raises nothing, or at a cursor it has already
    /// sent, which raises the base `APIError`. A cancelled task requests no further page.
    ///
    /// `options` overrides what every request of the walk may of the client's configuration. It
    /// throws `ConfigurationError` for a `pageSize` or a `maxPages` out of its range, before any
    /// request.
    public func walkGetOrganizationBillingInvoices(
      organization_id: String,
      query: AdminSchema.GetOrganizationBillingInvoicesQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationBillingInvoicesQuery, AdminSchema.Invoice
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationBillingInvoices(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// List an organization's saved payment methods.
    ///
    /// Returns the payment methods saved against the organization, each marked with
    /// whether it is the one invoices and subscriptions charge. Only display detail
    /// is carried: a card's brand, last four digits and expiry, or a mandate's last
    /// four and country. No card number and no IBAN passes through this contract.
    /// - A session token minted for `api` without `user_id` is what authorizes this
    ///   read, and no member role is checked on top of it; one minted for
    ///   `studio-embedded` without `user_id` is the `401` a key alone gets. One
    ///   that names a user is answered only while that user holds the owner or
    ///   admin role in the organization, and is a 403 otherwise. The path names the
    ///   key's own organization: another is a 403, whether or not it exists.
    /// - The organization must already have a billing account, which
    ///   creating the organization opens, or `postOrganizationBillingProvision` when
    ///   it comes first. One that does not answers 404.
    /// - The listing is paged, 50 methods to a page unless `limit` says
    ///   otherwise, the most recently saved first; the order is not the
    ///   caller's to choose, so the listing takes no `sort`. Send the page's
    ///   `next_cursor` back as `cursor` for the next one; the last page reports
    ///   `next_cursor: null`.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization. The payment provider answers it as it is asked, so it
    /// is also limited, together with `getOrganizationBillingInvoices`,
    /// `getOrganizationBillingInfo`, `getOrganizationBillingPromotionCode` and
    /// `postOrganizationBillingProvision`, to 60 a minute per user the token names
    /// and then to 300 a minute per organization. Past any of these, the answer is
    /// a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationBillingPaymentMethods(
      organization_id: String,
      query: AdminSchema.GetOrganizationBillingPaymentMethodsQuery = .init(),
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[AdminSchema.PaymentMethod], RestSchema.ListMetadata> {
      let request = OperationRequest(
        facts: .getOrganizationBillingPaymentMethods,
        pathParameters: ["organization_id": organization_id],
        query: query.items
      )
      return try await sender.envelope(request, options: options)
    }

    /// walkGetOrganizationBillingPaymentMethods walks the listing
    /// `getOrganizationBillingPaymentMethods` answers, one row at a time, requesting a page only as
    /// the rows before it are read (`transport.pagination.walk`).
    ///
    /// Every request sends `query`, its filters and `sort` included, with its `limit` replaced by
    /// `pageSize`, from 1 to 100, and its `cursor` by the one the walk has reached, starting from
    /// `query`'s own, so a walk resumes where an earlier one stopped. It follows every page for as
    /// long as a `next_cursor` names one, an empty page included, and stops at a null
    /// `next_cursor`, at `maxPages` requests, which raises nothing, or at a cursor it has already
    /// sent, which raises the base `APIError`. A cancelled task requests no further page.
    ///
    /// `options` overrides what every request of the walk may of the client's configuration. It
    /// throws `ConfigurationError` for a `pageSize` or a `maxPages` out of its range, before any
    /// request.
    public func walkGetOrganizationBillingPaymentMethods(
      organization_id: String,
      query: AdminSchema.GetOrganizationBillingPaymentMethodsQuery = .init(),
      pageSize: Int = 50,
      maxPages: Int? = nil,
      options: RequestOptions = RequestOptions()
    ) throws(MountayaError) -> PageWalk<
      AdminSchema.GetOrganizationBillingPaymentMethodsQuery, AdminSchema.PaymentMethod
    > {
      try PageWalk(query: query, pageSize: pageSize, maxPages: maxPages) { page in
        try await getOrganizationBillingPaymentMethods(
          organization_id: organization_id, query: page, options: options)
      }
    }

    /// Check what a promotion code is worth to an organization.
    ///
    /// Checks a promotion code against this organization and returns what it would
    /// be worth, so a client can show the discount before the code is given to
    /// `postOrganizationBillingProvision`, which records it for the organization's
    /// first Data API subscription.
    ///
    /// It reads nothing and changes nothing: a code that is valid here has still
    /// not been recorded or applied to anything. A code discounts the first Data
    /// API subscription only, opened by the organization's first card, and no
    /// operation puts one on a subscription that is already running.
    /// - A session token minted for `api` without `user_id` is what authorizes this
    ///   read, and no member role is checked on top of it; one minted for
    ///   `studio-embedded` without `user_id` is the `401` a key alone gets. One
    ///   that names a user is answered only while that user holds the owner or
    ///   admin role in the organization, and is a 403 otherwise. The path names the
    ///   key's own organization: another is a 403, whether or not it exists.
    /// - A code that is unrestricted is valid for anyone. One restricted to a
    ///   customer is valid only for that customer.
    /// - An unknown code, an expired one, and one restricted to somebody else all
    ///   answer 200 with `valid: false` and nothing further. They are deliberately
    ///   indistinguishable, so this operation cannot be used to discover which
    ///   codes exist. An ineligible code is not an error.
    /// - An organization that has no billing account yet can still check
    ///   unrestricted codes, and is answered 200 either way.
    ///
    /// Like every read made with a session token naming a user, it is limited to
    /// 1200 a minute per user the token names and then to 6000 a minute per
    /// organization, and one made with a session token minted without `user_id` is
    /// held as the key alone is, to 600 a minute per client IP address and then
    /// 6000 per organization. The payment provider answers it as it is asked, so it
    /// is also limited, together with `getOrganizationBillingPaymentMethods`,
    /// `getOrganizationBillingInvoices`, `getOrganizationBillingInfo` and
    /// `postOrganizationBillingProvision`, to 60 a minute per user the token names
    /// and then to 300 a minute per organization. Past any of these, the answer is
    /// a `429` carrying `Retry-After`.
    ///
    /// Requires a publishable key with the `management` scope AND a session token.
    /// A publishable key without a session token is not accepted here: a key
    /// written to be shipped in a browser cannot be sufficient on its own to read
    /// or change an organization's account.
    public func getOrganizationBillingPromotionCode(
      organization_id: String,
      code: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.PromotionCodePreview, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationBillingPromotionCode,
        pathParameters: ["organization_id": organization_id, "code": code]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Retrieve an organization's subscription.
    ///
    /// Returns the organization's subscription: the metered Data API
    /// subscription, billed by the month on the Data API requests the
    /// organization makes, which is the one subscription an operation in this
    /// contract opens. It is the read to branch a Data API payment refusal on:
    /// `has_payment_method` says whether a default payment method is on file, and
    /// the subscription's `status`, read with its `paused` flag, says whether
    /// what it grants is in force. What an agreement with Mountaya grants is not
    /// a subscription and is not reported here, so an organization whose billing
    /// its agreement settles can read `data` null too, and is never asked for a
    /// card. For an owner or an admin of the key's organization, a `403` from
    /// `postOrganizationBillingProvision`, `postOrganizationBillingPaymentMethodSetup`
    /// or `postOrganizationBillingPaymentMethod` means exactly that: billing is
    /// settled by the agreement, and no card is asked for.
    /// - A session token minted for `api` without `user_id` is what authorizes this
    ///   read, and no member role is checked on top of it; one minted for
    ///   `studio-embedded` without `user_id` is the `401` a key alone gets. One
    ///   that names a user is answered only while that user holds the owner or
    ///   admin role in the organization, and is a 403 otherwise. The path names the
    ///   key's own organization: another is a 403, whether or not it exists.
    /// - `data` is null for an organization that has never held a subscription,
    ///   which is where an organization stands until its first card opens its
    ///   Data API subscription: opening billing opens none, and a card that is
    ///   still processing leaves it null with the card saved. A subscription that
    ///   has ended stays in its slot with the status it ended on, so `api` reads
    ///   `status: canceled` once the Data API subscription has ended.
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
    public func getOrganizationBillingSubscription(
      organization_id: String,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.OrganizationSubscriptionSummary?, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .getOrganizationBillingSubscription,
        pathParameters: ["organization_id": organization_id]
      )
      return try await sender.envelope(request, options: options)
    }

    /// Update an organization's billing information.
    ///
    /// Writes what invoices are addressed to, and returns the whole record after
    /// the change. Every field is optional and every field present is a
    /// replacement: an omitted field is left alone, an address whose fields are all
    /// empty clears the address, and a `tax_id` with an empty value clears the tax
    /// identifier. Sending `name` as the empty string restores the organization's
    /// own name rather than clearing it.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403).
    /// - The organization must already have a billing account, which
    ///   creating the organization opens, or `postOrganizationBillingProvision` when
    ///   it comes first. One that does not answers
    ///   409, and nothing is written.
    /// - A tax identifier the payment provider refuses is a 400 at `tax_id.value`,
    ///   or at `tax_id.type` when the type is at fault, and nothing is changed: the
    ///   previous tax identifier is replaced only once the new one is accepted.
    /// - An address that would leave the organization's running Data API
    ///   subscription without a location its tax can be computed from (the
    ///   address cleared, its country removed, or one the payment provider cannot
    ///   place) is a 400 at `address`, and the name, email and address are left
    ///   as they were.
    /// - It is refused with 503 while another billing change for the
    ///   organization is running, and nothing is written.
    /// - Changing the organization's own name through `patchOrganization` never
    ///   changes the name invoices are addressed to. That name stays the
    ///   organization's name as it was when billing was opened until it is changed
    ///   here.
    ///
    /// The payment provider is asked as the call is made, so it is limited,
    /// together with the six other billing writes this document's introduction
    /// lists, to 30 a minute per user the token names and then to 300 a minute
    /// per organization, an allowance apart from the billing reads'. Past
    /// either, the answer is a `429` carrying `Retry-After`, and nothing is done.
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
    public func patchOrganizationBillingInfo(
      organization_id: String,
      body: AdminSchema.BillingInfoUpdateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.BillingInfo, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .patchOrganizationBillingInfo,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Save a confirmed card against an organization.
    ///
    /// Completes the card collection started by
    /// `postOrganizationBillingPaymentMethodSetup`, and returns the payment method
    /// saved. The confirmed setup intent is checked, the metered Data API
    /// subscription is opened on its card where the organization holds none, or
    /// only one that has ended, and the card then becomes the organization's
    /// default and the card every subscription that is charged automatically and
    /// has not ended charges: one already charging another card moves onto it,
    /// and every invoice such a subscription still has outstanding is charged to
    /// it. A subscription billed by invoice is left as it is. When no billing
    /// address is on file and the card carries one, the card's address becomes
    /// the billing address, which is what lets tax be computed on the
    /// organization's invoices. Read `getOrganizationBillingSubscription` for the
    /// subscription the card opened or moved.
    /// - The answer is `201`, with `Location` naming the payment method, when
    ///   this request attached it to the organization, and `200` with the same
    ///   payment method when it was already the organization's default card, by
    ///   an earlier call or by the steps that run on their own once the setup
    ///   succeeds. A card still confirming is not the default yet, so a repeat
    ///   for it answers `201` again. A client treats both as the card being
    ///   saved.
    /// - The first card is what opens the Data API subscription, the one product
    ///   an organization obtains by card. Where the organization has never held
    ///   one, or the one it held has ended, one is opened on the card, and from
    ///   then the organization holds `data`, which a key carrying `data` or `mcp`
    ///   needs. It is metered: nothing is charged as it opens, and the requests the
    ///   organization made are invoiced with tax at the end of each billing
    ///   period, a month counted from the day it opened.
    ///   The promotion code recorded by `postOrganizationBillingProvision` is
    ///   applied to the organization's first subscription and to no later one.
    ///   Where a subscription has not ended, none is opened, and its outstanding
    ///   invoices are what the card is charged.
    /// - Map Studio, Map Publishing, the Tile API, Embedded Studio and White label
    ///   are granted by the organization's agreement with Mountaya. No card opens
    ///   any of them, and saving one changes none of them.
    /// - Where a subscription has not ended, a charge of its outstanding invoices
    ///   the card's issuer refuses does not undo the save: the answer is still
    ///   a success, the card stays the default, and the invoice it was for stays
    ///   open.
    ///   An issuer that answers by asking the cardholder to authenticate
    ///   refuses in the same way, since the charge is made without the cardholder
    ///   present: the card is saved, and another card, or the cardholder paying
    ///   the invoice, is the remedy.
    /// - The subscription's invoices are taxed. When the payment provider cannot
    ///   tell where the organization is taxed, which is the case when no billing
    ///   address is on file and the card carries none, the answer is a 400 naming
    ///   `setup_intent_id`, the intent whose card has no address to be taxed at;
    ///   its message is what asks for a billing address. The card is saved
    ///   but is not made the default, and nothing is opened or charged. Set a
    ///   billing address with `patchOrganizationBillingInfo` and call this again
    ///   with the same setup intent: the repeat opens the subscription.
    /// - When the promotion code recorded for the organization is refused by the
    ///   payment provider as it is redeemed, the answer is a 400 whose entry
    ///   names no field, since the code is no part of this request. Nothing is
    ///   opened or charged, and the card is saved but is not made the default.
    ///   Call `postOrganizationBillingProvision` again with another code, or
    ///   with none, then call this again with the same setup intent.
    /// - Before a subscription is opened, every invoice the organization still
    ///   owes, open or uncollectible, those of a subscription that has ended
    ///   included, is collected on the card being saved. When one cannot be
    ///   collected on it, the answer is a 402: nothing is opened, and the card is
    ///   saved but is not made the default. The organization does not start a
    ///   new subscription while it owes for an earlier one: pay what is owed, or
    ///   save a card that can pay it, and call this again.
    /// - Nor is a subscription opened on a card another organization still owes
    ///   on. A card is recognized by its number, whichever organization saved
    ///   it, and while any other organization owes an invoice that a payment on
    ///   a card of the same number failed to pay, one marked uncollectible or
    ///   one still open after that attempt, the answer is the same 402: nothing
    ///   is opened, nothing the other organization owes is charged here, and the
    ///   card is saved but is not made the default. Only what the card itself
    ///   failed to pay refuses it: a card the other organization merely has on
    ///   file, or used to pay something else, blocks nothing, and neither does
    ///   an invoice whose payment is still processing. What that organization
    ///   owes is settled on it, and this is called again once it is.
    /// - The subscription is opened on the card being saved. Nothing is charged
    ///   as it opens, unless the organization already owes an amount outside any
    ///   subscription, which its first invoice collects on that card at once.
    ///   When the card is refused as the subscription opens, the answer is a 400
    ///   naming `setup_intent_id`: nothing is opened, and the card is saved but is
    ///   not made the default. Another card opens the subscription.
    /// - Confirming the setup intent in the browser is enough on its own: once the
    ///   payment provider reports it succeeded, the same steps run shortly after,
    ///   whether or not this operation is called, the Data API subscription
    ///   opened where they open one. For a card, calling it runs them before it
    ///   answers, so the card is on file for the very next request. Calling it is
    ///   also how either 400 above is learned of: when the steps run without this
    ///   call, the card is saved without becoming the default and no answer says
    ///   why.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403).
    /// - A setup intent that is unknown, or that belongs to another
    ///   organization, is a 404, and nothing is saved. One of another
    ///   organization is answered as an unknown one is, so a setup intent cannot
    ///   be probed here.
    /// - A setup intent of this organization that has not been confirmed, that
    ///   waits on the cardholder, that failed or was canceled, or that carries no
    ///   payment method, is a 409 naming `setup_intent_id`, and nothing is saved.
    ///   Complete the confirmation in the browser, or start again with
    ///   `postOrganizationBillingPaymentMethodSetup`; sending the same intent
    ///   again is answered the same way until it succeeds.
    /// - The organization must already have a billing account, which
    ///   creating the organization opens, or `postOrganizationBillingProvision` when
    ///   it comes first. One that does not answers 409.
    /// - A method that settles slowly, such as a SEPA Direct Debit mandate, is
    ///   accepted while it is still confirming: it is saved and returned with
    ///   `is_default` false, and the subscription is left as it was. It becomes
    ///   the default once it confirms, so read `is_default` rather than assuming
    ///   the method is live on the answer.
    /// - Calling it twice with the same setup intent answers the same payment
    ///   method (`200` once it is the default card), and changes nothing the
    ///   second time unless the
    ///   first was answered the 400 for a billing address or the one for a
    ///   promotion code, either of which the repeat looks at afresh once its
    ///   cause is put right. A refused card is refused again.
    ///
    /// The payment provider is asked as the call is made, so it is limited,
    /// together with the six other billing writes this document's introduction
    /// lists, to 30 a minute per user the token names and then to 300 a minute
    /// per organization, an allowance apart from the billing reads'. Past
    /// either, the answer is a `429` carrying `Retry-After`, and nothing is done.
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
    public func postOrganizationBillingPaymentMethod(
      organization_id: String,
      body: AdminSchema.OrganizationBillingPaymentMethodParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.PaymentMethod, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationBillingPaymentMethod,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Choose which payment method an organization is charged on.
    ///
    /// Makes one saved payment method the one invoices and subscriptions charge,
    /// and returns it. At most one is the default at a time, so this both sets
    /// the new one and unsets the old.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403).
    /// - The method must belong to this organization: an identifier naming none of
    ///   its methods is a 404, whether it names another organization's method or
    ///   nothing at all, and the two answer alike.
    /// - The organization must already have a billing account, which
    ///   creating the organization opens, or `postOrganizationBillingProvision` when
    ///   it comes first. One that does not answers 404.
    /// - Every subscription that is charged automatically and has not ended moves
    ///   onto this method, and the invoices such a subscription still has
    ///   outstanding are charged to it at once. A charge the issuer refuses does
    ///   not undo the choice: the answer is still 200, the method is the default,
    ///   and that invoice stays open.
    /// - It opens no subscription. An organization with no Data API subscription
    ///   in force that makes a saved method its default has a default and still
    ///   no subscription: opening one takes a card saved through
    ///   `postOrganizationBillingPaymentMethod`, or
    ///   `postOrganizationBillingSubscription`, which opens one on the default
    ///   payment method.
    /// - Setting the same default twice changes nothing the second time, and is
    ///   answered with the method as it stands.
    ///
    /// The payment provider is asked as the call is made, so it is limited,
    /// together with the six other billing writes this document's introduction
    /// lists, to 30 a minute per user the token names and then to 300 a minute
    /// per organization, an allowance apart from the billing reads'. Past
    /// either, the answer is a `429` carrying `Retry-After`, and nothing is done.
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
    public func postOrganizationBillingPaymentMethodSetDefault(
      organization_id: String,
      payment_method_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.PaymentMethod, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationBillingPaymentMethodSetDefault,
        pathParameters: [
          "organization_id": organization_id, "payment_method_id": payment_method_id,
        ],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Start collecting a card for an organization.
    ///
    /// Returns a single-use secret for collecting a card inside the caller's own
    /// page rather than sending the payer somewhere else. Hand it to Stripe
    /// Elements, which confirms the card in the browser, then name the confirmed
    /// setup intent on `postOrganizationBillingPaymentMethod` to save the card
    /// against the organization. Each call starts a collection of its own with a
    /// secret of its own. Nothing is saved by this operation on its own: a
    /// secret that is never confirmed leaves the organization exactly as it was.
    /// One that is confirmed is saved even if that call never comes: once the
    /// payment provider reports the setup succeeded, the steps
    /// `postOrganizationBillingPaymentMethod` describes run shortly after. Where
    /// the organization holds no Data API subscription, or only one that has
    /// ended, the card opens one, metered and invoiced by the month for what is
    /// used, then becomes the default.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403).
    /// - The organization must already have a billing account, which
    ///   creating the organization opens, or `postOrganizationBillingProvision` when
    ///   it comes first. One that does not answers 409.
    ///
    /// The payment provider is asked as the call is made, so it is limited,
    /// together with the six other billing writes this document's introduction
    /// lists, to 30 a minute per user the token names and then to 300 a minute
    /// per organization, an allowance apart from the billing reads'. Past
    /// either, the answer is a `429` carrying `Retry-After`, and nothing is done.
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
    public func postOrganizationBillingPaymentMethodSetup(
      organization_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.SetupIntentSession, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationBillingPaymentMethodSetup,
        pathParameters: ["organization_id": organization_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Open an organization's billing.
    ///
    /// Opens the organization's billing account, which collecting a card needs,
    /// records the promotion code it is given, and returns the billing
    /// information invoices will be addressed to. It opens no subscription,
    /// raises no invoice and charges nothing. The Data API is the one product an
    /// organization obtains by card: the first card saved through
    /// `postOrganizationBillingPaymentMethodSetup` and
    /// `postOrganizationBillingPaymentMethod` opens the metered Data API
    /// subscription, billed by the month on the requests the organization makes,
    /// and from then the organization holds `data`. Until then it holds no
    /// product and owes nothing. Map Studio, Map Publishing, the Tile API,
    /// Embedded Studio and White label are granted by the organization's
    /// agreement with Mountaya, and no card opens any of them.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403).
    /// - Until the first card, a key carrying `data` or `mcp` answers 402
    ///   wherever it is used.
    /// - `promotion_code` is kept for the organization's first Data API
    ///   subscription and applied when the first card opens it. The last call
    ///   decides: a call carrying another code replaces the one recorded, and a
    ///   call carrying none clears it.
    /// - A `promotion_code` this organization cannot use is a 400 naming the
    ///   field, and nothing is created or recorded. That includes every code
    ///   given to an organization that has already held a Data API subscription:
    ///   a code applies to the first one only, and a call carrying none still
    ///   succeeds. One accepted here that the payment provider refuses as it is
    ///   redeemed is answered by the call that would have opened the
    ///   subscription: `postOrganizationBillingPaymentMethod` for a card, or
    ///   `postOrganizationBillingSubscription` on the default payment method.
    /// - The billing information starts with the organization's own name and
    ///   the email address of the user the session token names. Change either
    ///   with `patchOrganizationBillingInfo`.
    /// - Safe to repeat: a double-submit or a retry opens no second account, and
    ///   two calls sent at the same moment open one billing account. A call on
    ///   an organization whose billing is already open records the promotion
    ///   code it carries, or clears it, and answers the billing information as
    ///   it stands.
    /// - The subscription the first card opens bills by the month, in arrears,
    ///   on what the organization used. There is no interval to choose, here or
    ///   afterwards.
    ///
    /// The promotion code is checked with the payment provider as its preview
    /// checks it, so this operation is limited, together with
    /// `getOrganizationBillingPaymentMethods`, `getOrganizationBillingInvoices`,
    /// `getOrganizationBillingInfo` and `getOrganizationBillingPromotionCode`, to
    /// 60 a minute per user the token names and then to 300 a minute per
    /// organization, whether or not the call carries a code. Past either, the
    /// answer is a `429` carrying `Retry-After`, and nothing is opened or
    /// recorded.
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
    public func postOrganizationBillingProvision(
      organization_id: String,
      body: AdminSchema.OrganizationBillingProvisionParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.BillingInfo, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationBillingProvision,
        pathParameters: ["organization_id": organization_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Run an organization's Data API subscription.
    ///
    /// Runs the organization's metered Data API subscription, whatever state it is
    /// in, and returns it.
    /// - An end scheduled by `deleteOrganizationBillingSubscription` is taken back,
    ///   and the subscription carries on into its next period.
    /// - A subscription that is past due or unpaid has its outstanding invoices
    ///   charged to the organization's default payment method, as saving a card
    ///   charges them. A charge the card refuses does not fail the call: the
    ///   subscription is returned as the charge left it. With no default payment
    ///   method on file there is nothing to charge, and it is returned as it is.
    /// - A paused subscription is returned as it is, and nothing changes.
    /// - A subscription already running is returned as it is, and nothing changes.
    /// - Where the organization holds none, because the one it held has ended, its
    ///   agreement with Mountaya has ended, or it never held one, one is opened on
    ///   the organization's default payment method, exactly as the first card
    ///   opens one: billed by the month on the requests the organization makes,
    ///   with tax. From then the organization holds `data`. The promotion code
    ///   recorded by `postOrganizationBillingProvision` applies only to the
    ///   organization's first Data API subscription.
    /// - With no default payment method on file, or no billing account, the
    ///   answer is a 402 and nothing is opened. Saving a card through
    ///   `postOrganizationBillingPaymentMethodSetup` and
    ///   `postOrganizationBillingPaymentMethod` opens the subscription on its own.
    /// - Before one is opened, every invoice the organization still owes, open or
    ///   uncollectible, those of a subscription that has ended included, is
    ///   collected on the default payment method. When one cannot be collected
    ///   on it, the answer is a 402 and nothing is opened: the organization does
    ///   not start a new subscription while it owes for an earlier one. Pay what
    ///   is owed, or make a card that can pay it the default, and call this
    ///   again.
    /// - Nor is one opened on a default card another organization still owes on.
    ///   A card is recognized by its number, whichever organization saved it,
    ///   and while any other organization owes an invoice that a payment on a
    ///   card of the same number failed to pay, one marked uncollectible or one
    ///   still open after that attempt, the answer is the same 402 and nothing
    ///   is opened. Only what the card itself failed to pay refuses it: a card
    ///   the other organization merely has on file, or used to pay something
    ///   else, blocks nothing, and neither does an invoice whose payment is
    ///   still processing. Nothing the other organization owes is charged here:
    ///   it is settled on that organization.
    /// - The subscription's invoices are taxed. When the payment provider cannot
    ///   tell where the organization is taxed, the answer is a 400 whose entry
    ///   names no field, since nothing in this request is what is missing; its
    ///   message asks for a billing address. Nothing is opened. Set one with
    ///   `patchOrganizationBillingInfo` and call this again.
    /// - When the payment provider refuses the default payment method as the
    ///   subscription opens, the answer is a 400 whose entry names no field, and
    ///   nothing is opened. The refusal is remembered for a day: calling this
    ///   again while the same method is the default is answered the same 400.
    ///   Make another saved method the default with
    ///   `postOrganizationBillingPaymentMethodSetDefault` and call this again, or
    ///   save another card, which opens the subscription on its own. Each method
    ///   is an attempt of its own, and a card saved again is a new method, so
    ///   it is one too.
    /// - When the promotion code recorded by `postOrganizationBillingProvision`
    ///   for the organization's first Data API subscription is refused by the
    ///   payment provider as it is redeemed, expired or used up since it was
    ///   recorded, the answer is a 400 whose entry names no field, since the
    ///   code is no part of this request. Nothing is opened or charged. Call
    ///   `postOrganizationBillingProvision` again with another code, or with
    ///   none, then call this again.
    /// - Owner or admin only (403 otherwise), and refused for an organization whose
    ///   billing is settled by its agreement with Mountaya (403).
    /// - Calling it again changes nothing for a subscription that runs or is
    ///   paused. One that is past due or unpaid is charged again: each call
    ///   charges its outstanding invoices to the default payment method, so a
    ///   call repeated after a refusal is another attempt on that method. An
    ///   invoice already paid is not charged twice.
    ///
    /// The payment provider is asked as the call is made, so it is limited,
    /// together with the six other billing writes this document's introduction
    /// lists, to 30 a minute per user the token names and then to 300 a minute
    /// per organization, an allowance apart from the billing reads'. Past
    /// either, the answer is a `429` carrying `Retry-After`, and nothing is done.
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
    public func postOrganizationBillingSubscription(
      organization_id: String,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<AdminSchema.OrganizationSubscriptionSummary, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postOrganizationBillingSubscription,
        pathParameters: ["organization_id": organization_id],
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
