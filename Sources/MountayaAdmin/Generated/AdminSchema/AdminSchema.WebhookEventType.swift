// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// A webhook event type: the path of the resource the event is about, each segment's
  /// hyphens written as underscores, then what happened to it, in the past tense.
  /// Everything before the last dot is the type's family, the kind of object `data.object`
  /// holds, which `related_object.type` names too. The members are the public types: each
  /// is an entry of this document's `webhooks`, which describes its payload, and
  /// `getWebhookEventTypes` lists them with their families.
  ///
  /// The set is open: a value this build has never seen decodes as itself rather than failing the
  /// response, and a value the contract adds is one more static member.
  public struct WebhookEventType: RawRepresentable, Sendable, Hashable, Codable,
    CodingKeyRepresentable, ExpressibleByStringLiteral
  {
    /// An organization was created, with the user who created it as its owner.
    public static let organizationCreated: Self = "organization.created"
    /// An organization's own fields were changed, which is its name.
    public static let organizationUpdated: Self = "organization.updated"
    /// Somebody joined the organization: the owner of an organization just created, or a person
    /// accepting an invitation.
    public static let organizationMemberCreated: Self = "organization.member.created"
    /// A member's role changed: through `patchOrganizationMember`, or when ownership was handed on,
    /// which records one for each of the two members.
    public static let organizationMemberUpdated: Self = "organization.member.updated"
    /// A membership ended: the member was removed by somebody else, or left. `reason` says which.
    public static let organizationMemberDeleted: Self = "organization.member.deleted"
    /// An invitation was made.
    public static let organizationInvitationCreated: Self = "organization.invitation.created"
    /// The person invited accepted the invitation, and is a member from then on.
    public static let organizationInvitationAccepted: Self = "organization.invitation.accepted"
    /// The person invited declined the invitation.
    public static let organizationInvitationDeclined: Self = "organization.invitation.declined"
    /// A member withdrew an invitation still waiting for an answer.
    public static let organizationInvitationRevoked: Self = "organization.invitation.revoked"
    /// An invitation lapsed unanswered thirty days after it was made, and was cleared away.
    public static let organizationInvitationExpired: Self = "organization.invitation.expired"
    /// An invitation was cleared because the person it names joined the organization through
    /// another invitation.
    public static let organizationInvitationDeleted: Self = "organization.invitation.deleted"
    /// A collection was created.
    public static let collectionCreated: Self = "collection.created"
    /// A collection's own fields were changed.
    public static let collectionUpdated: Self = "collection.updated"
    /// A collection was deleted. What it held and its share link go with it, and record no event of
    /// their own.
    public static let collectionDeleted: Self = "collection.deleted"
    /// An itinerary the collection did not hold was added to it.
    public static let collectionItineraryAdded: Self = "collection.itinerary.added"
    /// An itinerary left a collection: it was removed from it, or the itinerary was deleted.
    public static let collectionItineraryRemoved: Self = "collection.itinerary.removed"
    /// An itinerary moved to another position in a collection.
    public static let collectionItineraryMoved: Self = "collection.itinerary.moved"
    /// A zone the collection did not hold was added to it.
    public static let collectionZoneAdded: Self = "collection.zone.added"
    /// A zone left a collection: it was removed from it, or the zone was deleted.
    public static let collectionZoneRemoved: Self = "collection.zone.removed"
    /// A collection's share link was minted, the first time it was asked for.
    public static let collectionShareLinkCreated: Self = "collection.share_link.created"
    /// A collection's share link was given a new token, which disables the old one.
    public static let collectionShareLinkRotated: Self = "collection.share_link.rotated"
    /// A collection's share link was removed, which disables its token.
    public static let collectionShareLinkDeleted: Self = "collection.share_link.deleted"
    /// An itinerary was created, imported from a file or copied. `origin` says which.
    public static let itineraryCreated: Self = "itinerary.created"
    /// An itinerary's own fields were written. A change to its segments, segment groups or
    /// waypoints is an event of their own.
    public static let itineraryUpdated: Self = "itinerary.updated"
    /// An itinerary was deleted, with its segments, segment groups, waypoints, publication and
    /// share link, which record no event of their own.
    public static let itineraryDeleted: Self = "itinerary.deleted"
    /// An itinerary was published: a first publication, or a republication replacing the live one.
    public static let itineraryPublished: Self = "itinerary.published"
    /// An itinerary's live publication was taken down.
    public static let itineraryUnpublished: Self = "itinerary.unpublished"
    /// A segment was appended or inserted, or made by a split as its second half.
    public static let itinerarySegmentCreated: Self = "itinerary.segment.created"
    /// A segment was changed, or re-routed to meet a neighbour whose shared point a change moved.
    public static let itinerarySegmentUpdated: Self = "itinerary.segment.updated"
    /// A segment was removed, or absorbed by the segment before it in a merge.
    public static let itinerarySegmentDeleted: Self = "itinerary.segment.deleted"
    /// A segment was merged with the one after it and now runs over both. The one absorbed records
    /// `itinerary.segment.deleted`.
    public static let itinerarySegmentMerged: Self = "itinerary.segment.merged"
    /// A segment was cut in two and is now the first half. The second half records
    /// `itinerary.segment.created`.
    public static let itinerarySegmentSplit: Self = "itinerary.segment.split"
    /// A segment was converted between routed and freehand.
    public static let itinerarySegmentConverted: Self = "itinerary.segment.converted"
    /// A segment group was created.
    public static let itinerarySegmentGroupCreated: Self = "itinerary.segment_group.created"
    /// A segment group's name, colour, speed or segments changed.
    public static let itinerarySegmentGroupUpdated: Self = "itinerary.segment_group.updated"
    /// A segment group was deleted, or dissolved because a change left it fewer than two segments.
    /// Its segments are kept.
    public static let itinerarySegmentGroupDeleted: Self = "itinerary.segment_group.deleted"
    /// A waypoint was added.
    public static let itineraryWaypointCreated: Self = "itinerary.waypoint.created"
    /// A waypoint was changed.
    public static let itineraryWaypointUpdated: Self = "itinerary.waypoint.updated"
    /// A waypoint was removed.
    public static let itineraryWaypointDeleted: Self = "itinerary.waypoint.deleted"
    /// An itinerary's share link was minted, the first time it was asked for.
    public static let itineraryShareLinkCreated: Self = "itinerary.share_link.created"
    /// An itinerary's share link was given a new token, which disables the old one.
    public static let itineraryShareLinkRotated: Self = "itinerary.share_link.rotated"
    /// An itinerary's share link was removed, which disables its token.
    public static let itineraryShareLinkDeleted: Self = "itinerary.share_link.deleted"
    /// A zone was created.
    public static let zoneCreated: Self = "zone.created"
    /// A zone was changed: its fields, its area or its validity window.
    public static let zoneUpdated: Self = "zone.updated"
    /// A zone was deleted, with its publication, which records no event of its own.
    public static let zoneDeleted: Self = "zone.deleted"
    /// A zone was published: a first publication, or a republication replacing the live one.
    public static let zonePublished: Self = "zone.published"
    /// A zone's live publication was taken down.
    public static let zoneUnpublished: Self = "zone.unpublished"
    /// A publishable key was created.
    public static let organizationPublishableKeyCreated: Self =
      "organization.publishable_key.created"
    /// A publishable key's name or scopes were written.
    public static let organizationPublishableKeyUpdated: Self =
      "organization.publishable_key.updated"
    /// A publishable key was revoked.
    public static let organizationPublishableKeyRevoked: Self =
      "organization.publishable_key.revoked"
    /// A secret key was created, signed in to Mountaya's web application.
    public static let organizationSecretKeyCreated: Self = "organization.secret_key.created"
    /// A secret key's name was written, signed in to Mountaya's web application.
    public static let organizationSecretKeyUpdated: Self = "organization.secret_key.updated"
    /// A secret key was revoked, signed in to Mountaya's web application.
    public static let organizationSecretKeyRevoked: Self = "organization.secret_key.revoked"
    /// An organization's AI provider configuration was created.
    public static let organizationAiProviderConfigCreated: Self =
      "organization.ai_provider_config.created"
    /// An organization's AI provider configuration was written: its model, its credential or its
    /// base URL.
    public static let organizationAiProviderConfigUpdated: Self =
      "organization.ai_provider_config.updated"
    /// An organization's AI provider configuration was deleted, its credential with it.
    public static let organizationAiProviderConfigDeleted: Self =
      "organization.ai_provider_config.deleted"
    /// An organization's Map Publishing settings were written: by a member, or by Mountaya where
    /// the organization's agreement fixes a setting.
    public static let organizationSettingsUpdated: Self = "organization.settings.updated"
    /// The capabilities or studio features an organization holds changed: its agreement with
    /// Mountaya changed, or its Data API subscription started or ended.
    public static let organizationEntitlementsUpdated: Self = "organization.entitlements.updated"
    /// An organization's Data API subscription was opened: by its first card, or by
    /// `postOrganizationBillingSubscription`.
    public static let organizationBillingSubscriptionCreated: Self =
      "organization.billing.subscription.created"
    /// An organization's Data API subscription changed: an end was scheduled or taken back, its
    /// status moved, or a new period began.
    public static let organizationBillingSubscriptionUpdated: Self =
      "organization.billing.subscription.updated"
    /// Collection on an organization's Data API subscription was paused.
    public static let organizationBillingSubscriptionPaused: Self =
      "organization.billing.subscription.paused"
    /// Collection on an organization's paused Data API subscription was resumed.
    public static let organizationBillingSubscriptionResumed: Self =
      "organization.billing.subscription.resumed"
    /// An organization's Data API subscription ended, at the end of its period or because it could
    /// not be paid.
    public static let organizationBillingSubscriptionCanceled: Self =
      "organization.billing.subscription.canceled"
    /// An invoice addressed to the organization was paid.
    public static let organizationBillingInvoicePaid: Self = "organization.billing.invoice.paid"
    /// A payment of an invoice addressed to the organization failed. The payment provider tries
    /// again on its own schedule.
    public static let organizationBillingInvoicePaymentFailed: Self =
      "organization.billing.invoice.payment_failed"
    /// A payment of an invoice addressed to the organization needs the payer to confirm it, as a
    /// card's own authentication asks.
    public static let organizationBillingInvoicePaymentActionRequired: Self =
      "organization.billing.invoice.payment_action_required"
    /// A payment method was saved to the organization.
    public static let organizationBillingPaymentMethodAttached: Self =
      "organization.billing.payment_method.attached"
    /// Which payment method the organization is charged on changed: one records it for the new
    /// default and one for the former.
    public static let organizationBillingPaymentMethodUpdated: Self =
      "organization.billing.payment_method.updated"
    /// A payment method was removed from the organization.
    public static let organizationBillingPaymentMethodDetached: Self =
      "organization.billing.payment_method.detached"
    /// What the organization's invoices are addressed to was written.
    public static let organizationBillingInfoUpdated: Self = "organization.billing.info.updated"
    /// A webhook endpoint was created.
    public static let organizationWebhookEndpointCreated: Self =
      "organization.webhook_endpoint.created"
    /// A webhook endpoint's URL, description or event types were written.
    public static let organizationWebhookEndpointUpdated: Self =
      "organization.webhook_endpoint.updated"
    /// A webhook endpoint was deleted, and nothing is delivered to it from then on.
    public static let organizationWebhookEndpointDeleted: Self =
      "organization.webhook_endpoint.deleted"
    /// A disabled webhook endpoint was enabled again.
    public static let organizationWebhookEndpointEnabled: Self =
      "organization.webhook_endpoint.enabled"
    /// A webhook endpoint was disabled: by a member, or by Mountaya after 72 hours of failed
    /// deliveries. `disabled_reason` says which.
    public static let organizationWebhookEndpointDisabled: Self =
      "organization.webhook_endpoint.disabled"
    /// Every delivery to a webhook endpoint has failed for 24 hours. Mountaya disables it at 72
    /// hours unless one succeeds.
    public static let organizationWebhookEndpointFailing: Self =
      "organization.webhook_endpoint.failing"
    /// A delivery succeeded to a webhook endpoint reported failing: its run of failed deliveries is
    /// over.
    public static let organizationWebhookEndpointRecovered: Self =
      "organization.webhook_endpoint.recovered"
    /// A webhook endpoint's signing secret was replaced, signed in to Mountaya's web application.
    /// Both secrets sign deliveries for up to 7 days.
    public static let organizationWebhookEndpointSecretRotated: Self =
      "organization.webhook_endpoint.secret_rotated"

    /// rawValue is the value as the wire spells it.
    public let rawValue: String

    /// Creates a value from its wire spelling, which may be one this build has never seen.
    public init(rawValue: String) {
      self.rawValue = rawValue
    }

    /// Creates a value from a string literal, which is its wire spelling.
    public init(stringLiteral value: String) {
      self.rawValue = value
    }

    /// codingKey is the value as an object's key, where the contract keys a map by it.
    public var codingKey: any CodingKey {
      WireKey(stringValue: rawValue)
    }

    /// Creates a value from an object's key.
    public init?<Key: CodingKey>(codingKey: Key) {
      self.rawValue = codingKey.stringValue
    }

    /// Reads the value from its wire spelling.
    public init(from decoder: any Decoder) throws {
      self.rawValue = try decoder.singleValueContainer().decode(String.self)
    }

    /// Writes the value as the wire spells it.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.singleValueContainer()
      try container.encode(rawValue)
    }
  }
}
