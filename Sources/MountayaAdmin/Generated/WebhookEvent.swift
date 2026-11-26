// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

/// WebhookEvent is a webhook event as Mountaya delivers it to an endpoint, typed by its `type`: one
/// case to each public type the contract's `webhooks` lists, carrying every member of the envelope,
/// the object the type carries at `data.object` and, at `data.previous_attributes`, the former
/// value of each field its change moved.
///
/// An event this build cannot type is `unknown`, holding the contract's envelope,
/// `AdminSchema.WebhookEvent`: one of a type it does not know, which a later contract adds, or one
/// whose payload its types do not read. It is delivered rather than refused, so a receiver still
/// acknowledges it and deduplicates it by its `id`, and every member of the envelope is read off
/// every case alike. A type the contract adds is a case of the build made after it, so a `switch`
/// over it outside this module ends in `@unknown default`.
@nonexhaustive
public enum WebhookEvent: Sendable, Hashable, Codable {
  /// `collection.created`: A collection was created.
  case collectionCreated(Payload<AdminSchema.CollectionEventObject, Never>)
  /// `collection.deleted`: A collection was deleted.
  case collectionDeleted(Payload<AdminSchema.CollectionEventObject, Never>)
  /// `collection.itinerary.added`: An itinerary was added to a collection.
  case collectionItineraryAdded(Payload<AdminSchema.CollectionItineraryEventObject, Never>)
  /// `collection.itinerary.moved`: An itinerary moved within a collection.
  case collectionItineraryMoved(
    Payload<AdminSchema.CollectionItineraryEventObject, CollectionItineraryMovedPreviousAttributes>)
  /// `collection.itinerary.removed`: An itinerary left a collection.
  case collectionItineraryRemoved(Payload<AdminSchema.CollectionItineraryEventObject, Never>)
  /// `collection.share_link.created`: A collection's share link was created.
  case collectionShareLinkCreated(Payload<AdminSchema.CollectionShareLinkEventObject, Never>)
  /// `collection.share_link.deleted`: A collection's share link was removed.
  case collectionShareLinkDeleted(Payload<AdminSchema.CollectionShareLinkEventObject, Never>)
  /// `collection.share_link.rotated`: A collection's share link was rotated.
  case collectionShareLinkRotated(Payload<AdminSchema.CollectionShareLinkEventObject, Never>)
  /// `collection.updated`: A collection's name, description or privacy changed.
  case collectionUpdated(
    Payload<AdminSchema.CollectionEventObject, CollectionUpdatedPreviousAttributes>)
  /// `collection.zone.added`: A zone was added to a collection.
  case collectionZoneAdded(Payload<AdminSchema.CollectionZoneEventObject, Never>)
  /// `collection.zone.removed`: A zone left a collection.
  case collectionZoneRemoved(Payload<AdminSchema.CollectionZoneEventObject, Never>)
  /// `itinerary.created`: An itinerary was created.
  case itineraryCreated(Payload<AdminSchema.ItineraryEventObject, Never>)
  /// `itinerary.deleted`: An itinerary was deleted.
  case itineraryDeleted(Payload<AdminSchema.ItineraryEventObject, Never>)
  /// `itinerary.published`: An itinerary was published.
  case itineraryPublished(Payload<AdminSchema.ItineraryEventObject, Never>)
  /// `itinerary.segment.converted`: A segment's mode changed.
  case itinerarySegmentConverted(
    Payload<AdminSchema.ItinerarySegmentEventObject, ItinerarySegmentConvertedPreviousAttributes>)
  /// `itinerary.segment.created`: A segment was added to an itinerary.
  case itinerarySegmentCreated(Payload<AdminSchema.ItinerarySegmentEventObject, Never>)
  /// `itinerary.segment.deleted`: A segment was removed from an itinerary.
  case itinerarySegmentDeleted(Payload<AdminSchema.ItinerarySegmentEventObject, Never>)
  /// `itinerary.segment.merged`: A segment absorbed the one after it.
  case itinerarySegmentMerged(Payload<AdminSchema.ItinerarySegmentEventObject, Never>)
  /// `itinerary.segment.split`: A segment was cut in two.
  case itinerarySegmentSplit(Payload<AdminSchema.ItinerarySegmentEventObject, Never>)
  /// `itinerary.segment.updated`: A segment changed.
  case itinerarySegmentUpdated(
    Payload<AdminSchema.ItinerarySegmentEventObject, ItinerarySegmentUpdatedPreviousAttributes>)
  /// `itinerary.segment_group.created`: A segment group was created.
  case itinerarySegmentGroupCreated(Payload<AdminSchema.ItinerarySegmentGroupEventObject, Never>)
  /// `itinerary.segment_group.deleted`: A segment group was dissolved.
  case itinerarySegmentGroupDeleted(Payload<AdminSchema.ItinerarySegmentGroupEventObject, Never>)
  /// `itinerary.segment_group.updated`: A segment group changed.
  case itinerarySegmentGroupUpdated(
    Payload<
      AdminSchema.ItinerarySegmentGroupEventObject, ItinerarySegmentGroupUpdatedPreviousAttributes
    >)
  /// `itinerary.share_link.created`: An itinerary's share link was created.
  case itineraryShareLinkCreated(Payload<AdminSchema.ItineraryShareLinkEventObject, Never>)
  /// `itinerary.share_link.deleted`: An itinerary's share link was removed.
  case itineraryShareLinkDeleted(Payload<AdminSchema.ItineraryShareLinkEventObject, Never>)
  /// `itinerary.share_link.rotated`: An itinerary's share link was rotated.
  case itineraryShareLinkRotated(Payload<AdminSchema.ItineraryShareLinkEventObject, Never>)
  /// `itinerary.unpublished`: An itinerary was taken down.
  case itineraryUnpublished(Payload<AdminSchema.ItineraryEventObject, Never>)
  /// `itinerary.updated`: An itinerary's name, description or privacy changed.
  case itineraryUpdated(
    Payload<AdminSchema.ItineraryEventObject, ItineraryUpdatedPreviousAttributes>)
  /// `itinerary.waypoint.created`: A waypoint was added to an itinerary.
  case itineraryWaypointCreated(Payload<AdminSchema.ItineraryWaypointEventObject, Never>)
  /// `itinerary.waypoint.deleted`: A waypoint was removed from an itinerary.
  case itineraryWaypointDeleted(Payload<AdminSchema.ItineraryWaypointEventObject, Never>)
  /// `itinerary.waypoint.updated`: A waypoint changed.
  case itineraryWaypointUpdated(
    Payload<AdminSchema.ItineraryWaypointEventObject, ItineraryWaypointUpdatedPreviousAttributes>)
  /// `organization.ai_provider_config.created`: An AI provider was configured.
  case organizationAiProviderConfigCreated(Payload<AdminSchema.AiProviderConfigEventObject, Never>)
  /// `organization.ai_provider_config.deleted`: An AI provider configuration was deleted.
  case organizationAiProviderConfigDeleted(Payload<AdminSchema.AiProviderConfigEventObject, Never>)
  /// `organization.ai_provider_config.updated`: An AI provider configuration changed.
  case organizationAiProviderConfigUpdated(
    Payload<
      AdminSchema.AiProviderConfigEventObject, OrganizationAiProviderConfigUpdatedPreviousAttributes
    >)
  /// `organization.billing.info.updated`: An organization's billing information changed.
  case organizationBillingInfoUpdated(Payload<AdminSchema.BillingInfoEventObject, Never>)
  /// `organization.billing.invoice.paid`: An invoice was paid.
  case organizationBillingInvoicePaid(Payload<AdminSchema.InvoiceEventObject, Never>)
  /// `organization.billing.invoice.payment_action_required`: An invoice's payment needs the payer's
  /// action.
  case organizationBillingInvoicePaymentActionRequired(
    Payload<AdminSchema.InvoiceEventObject, Never>)
  /// `organization.billing.invoice.payment_failed`: An invoice's payment failed.
  case organizationBillingInvoicePaymentFailed(Payload<AdminSchema.InvoiceEventObject, Never>)
  /// `organization.billing.payment_method.attached`: A payment method was saved.
  case organizationBillingPaymentMethodAttached(
    Payload<AdminSchema.PaymentMethodEventObject, Never>)
  /// `organization.billing.payment_method.detached`: A payment method was removed.
  case organizationBillingPaymentMethodDetached(
    Payload<AdminSchema.PaymentMethodEventObject, Never>)
  /// `organization.billing.payment_method.updated`: A payment method became, or stopped being, the
  /// default.
  case organizationBillingPaymentMethodUpdated(
    Payload<
      AdminSchema.PaymentMethodEventObject,
      OrganizationBillingPaymentMethodUpdatedPreviousAttributes
    >)
  /// `organization.billing.subscription.canceled`: A Data API subscription ended.
  case organizationBillingSubscriptionCanceled(
    Payload<AdminSchema.OrganizationSubscriptionEventObject, Never>)
  /// `organization.billing.subscription.created`: A Data API subscription was opened.
  case organizationBillingSubscriptionCreated(
    Payload<AdminSchema.OrganizationSubscriptionEventObject, Never>)
  /// `organization.billing.subscription.paused`: A Data API subscription was paused.
  case organizationBillingSubscriptionPaused(
    Payload<AdminSchema.OrganizationSubscriptionEventObject, Never>)
  /// `organization.billing.subscription.resumed`: A Data API subscription was resumed.
  case organizationBillingSubscriptionResumed(
    Payload<AdminSchema.OrganizationSubscriptionEventObject, Never>)
  /// `organization.billing.subscription.updated`: A Data API subscription changed.
  case organizationBillingSubscriptionUpdated(
    Payload<
      AdminSchema.OrganizationSubscriptionEventObject,
      OrganizationBillingSubscriptionUpdatedPreviousAttributes
    >)
  /// `organization.created`: An organization was created.
  case organizationCreated(Payload<AdminSchema.OrganizationEventObject, Never>)
  /// `organization.entitlements.updated`: What an organization holds changed.
  case organizationEntitlementsUpdated(
    Payload<
      AdminSchema.OrganizationEntitlementsEventObject,
      OrganizationEntitlementsUpdatedPreviousAttributes
    >)
  /// `organization.invitation.accepted`: An invitation was accepted.
  case organizationInvitationAccepted(Payload<AdminSchema.OrganizationInvitationEventObject, Never>)
  /// `organization.invitation.created`: Somebody was invited to an organization.
  case organizationInvitationCreated(Payload<AdminSchema.OrganizationInvitationEventObject, Never>)
  /// `organization.invitation.declined`: An invitation was declined.
  case organizationInvitationDeclined(Payload<AdminSchema.OrganizationInvitationEventObject, Never>)
  /// `organization.invitation.deleted`: An invitation was superseded.
  case organizationInvitationDeleted(Payload<AdminSchema.OrganizationInvitationEventObject, Never>)
  /// `organization.invitation.expired`: An invitation lapsed unanswered.
  case organizationInvitationExpired(Payload<AdminSchema.OrganizationInvitationEventObject, Never>)
  /// `organization.invitation.revoked`: An invitation was withdrawn.
  case organizationInvitationRevoked(Payload<AdminSchema.OrganizationInvitationEventObject, Never>)
  /// `organization.member.created`: Somebody joined an organization.
  case organizationMemberCreated(Payload<AdminSchema.OrganizationMemberEventObject, Never>)
  /// `organization.member.deleted`: A member left an organization or was removed from it.
  case organizationMemberDeleted(Payload<AdminSchema.OrganizationMemberEventObject, Never>)
  /// `organization.member.updated`: A member's role changed.
  case organizationMemberUpdated(
    Payload<AdminSchema.OrganizationMemberEventObject, OrganizationMemberUpdatedPreviousAttributes>)
  /// `organization.publishable_key.created`: A publishable key was created.
  case organizationPublishableKeyCreated(Payload<AdminSchema.PublishableKeyEventObject, Never>)
  /// `organization.publishable_key.revoked`: A publishable key was revoked.
  case organizationPublishableKeyRevoked(Payload<AdminSchema.PublishableKeyEventObject, Never>)
  /// `organization.publishable_key.updated`: A publishable key's name or scopes changed.
  case organizationPublishableKeyUpdated(
    Payload<
      AdminSchema.PublishableKeyEventObject, OrganizationPublishableKeyUpdatedPreviousAttributes
    >)
  /// `organization.secret_key.created`: A secret key was created.
  case organizationSecretKeyCreated(Payload<AdminSchema.SecretKeyEventObject, Never>)
  /// `organization.secret_key.revoked`: A secret key was revoked.
  case organizationSecretKeyRevoked(Payload<AdminSchema.SecretKeyEventObject, Never>)
  /// `organization.secret_key.updated`: A secret key was renamed.
  case organizationSecretKeyUpdated(
    Payload<AdminSchema.SecretKeyEventObject, OrganizationSecretKeyUpdatedPreviousAttributes>)
  /// `organization.settings.updated`: An organization's Map Publishing settings changed.
  case organizationSettingsUpdated(Payload<AdminSchema.OrganizationSettingsEventObject, Never>)
  /// `organization.updated`: An organization's name changed.
  case organizationUpdated(
    Payload<AdminSchema.OrganizationEventObject, OrganizationUpdatedPreviousAttributes>)
  /// `organization.webhook_endpoint.created`: A webhook endpoint was created.
  case organizationWebhookEndpointCreated(Payload<AdminSchema.WebhookEndpointEventObject, Never>)
  /// `organization.webhook_endpoint.deleted`: A webhook endpoint was deleted.
  case organizationWebhookEndpointDeleted(Payload<AdminSchema.WebhookEndpointEventObject, Never>)
  /// `organization.webhook_endpoint.disabled`: A webhook endpoint was disabled.
  case organizationWebhookEndpointDisabled(Payload<AdminSchema.WebhookEndpointEventObject, Never>)
  /// `organization.webhook_endpoint.enabled`: A webhook endpoint was enabled.
  case organizationWebhookEndpointEnabled(Payload<AdminSchema.WebhookEndpointEventObject, Never>)
  /// `organization.webhook_endpoint.failing`: A webhook endpoint has failed for 24 hours.
  case organizationWebhookEndpointFailing(Payload<AdminSchema.WebhookEndpointEventObject, Never>)
  /// `organization.webhook_endpoint.recovered`: A webhook endpoint reported failing succeeded
  /// again.
  case organizationWebhookEndpointRecovered(Payload<AdminSchema.WebhookEndpointEventObject, Never>)
  /// `organization.webhook_endpoint.secret_rotated`: A webhook endpoint's secret was rotated.
  case organizationWebhookEndpointSecretRotated(
    Payload<AdminSchema.WebhookEndpointEventObject, Never>)
  /// `organization.webhook_endpoint.updated`: A webhook endpoint changed.
  case organizationWebhookEndpointUpdated(
    Payload<
      AdminSchema.WebhookEndpointEventObject, OrganizationWebhookEndpointUpdatedPreviousAttributes
    >)
  /// `zone.created`: A zone was created.
  case zoneCreated(Payload<AdminSchema.ZoneEventObject, Never>)
  /// `zone.deleted`: A zone was deleted.
  case zoneDeleted(Payload<AdminSchema.ZoneEventObject, Never>)
  /// `zone.published`: A zone was published.
  case zonePublished(Payload<AdminSchema.ZoneEventObject, Never>)
  /// `zone.unpublished`: A zone was taken down.
  case zoneUnpublished(Payload<AdminSchema.ZoneEventObject, Never>)
  /// `zone.updated`: A zone changed.
  case zoneUpdated(Payload<AdminSchema.ZoneEventObject, ZoneUpdatedPreviousAttributes>)
  /// unknown is an event this build cannot type: a type it does not know, or a payload its types do
  /// not read, as the envelope holds it.
  case unknown(AdminSchema.WebhookEvent)

  /// type is the event's type, as the wire spells it.
  public var type: AdminSchema.WebhookEventType {
    switch self {
    case .collectionCreated: "collection.created"
    case .collectionDeleted: "collection.deleted"
    case .collectionItineraryAdded: "collection.itinerary.added"
    case .collectionItineraryMoved: "collection.itinerary.moved"
    case .collectionItineraryRemoved: "collection.itinerary.removed"
    case .collectionShareLinkCreated: "collection.share_link.created"
    case .collectionShareLinkDeleted: "collection.share_link.deleted"
    case .collectionShareLinkRotated: "collection.share_link.rotated"
    case .collectionUpdated: "collection.updated"
    case .collectionZoneAdded: "collection.zone.added"
    case .collectionZoneRemoved: "collection.zone.removed"
    case .itineraryCreated: "itinerary.created"
    case .itineraryDeleted: "itinerary.deleted"
    case .itineraryPublished: "itinerary.published"
    case .itinerarySegmentConverted: "itinerary.segment.converted"
    case .itinerarySegmentCreated: "itinerary.segment.created"
    case .itinerarySegmentDeleted: "itinerary.segment.deleted"
    case .itinerarySegmentMerged: "itinerary.segment.merged"
    case .itinerarySegmentSplit: "itinerary.segment.split"
    case .itinerarySegmentUpdated: "itinerary.segment.updated"
    case .itinerarySegmentGroupCreated: "itinerary.segment_group.created"
    case .itinerarySegmentGroupDeleted: "itinerary.segment_group.deleted"
    case .itinerarySegmentGroupUpdated: "itinerary.segment_group.updated"
    case .itineraryShareLinkCreated: "itinerary.share_link.created"
    case .itineraryShareLinkDeleted: "itinerary.share_link.deleted"
    case .itineraryShareLinkRotated: "itinerary.share_link.rotated"
    case .itineraryUnpublished: "itinerary.unpublished"
    case .itineraryUpdated: "itinerary.updated"
    case .itineraryWaypointCreated: "itinerary.waypoint.created"
    case .itineraryWaypointDeleted: "itinerary.waypoint.deleted"
    case .itineraryWaypointUpdated: "itinerary.waypoint.updated"
    case .organizationAiProviderConfigCreated: "organization.ai_provider_config.created"
    case .organizationAiProviderConfigDeleted: "organization.ai_provider_config.deleted"
    case .organizationAiProviderConfigUpdated: "organization.ai_provider_config.updated"
    case .organizationBillingInfoUpdated: "organization.billing.info.updated"
    case .organizationBillingInvoicePaid: "organization.billing.invoice.paid"
    case .organizationBillingInvoicePaymentActionRequired:
      "organization.billing.invoice.payment_action_required"
    case .organizationBillingInvoicePaymentFailed: "organization.billing.invoice.payment_failed"
    case .organizationBillingPaymentMethodAttached: "organization.billing.payment_method.attached"
    case .organizationBillingPaymentMethodDetached: "organization.billing.payment_method.detached"
    case .organizationBillingPaymentMethodUpdated: "organization.billing.payment_method.updated"
    case .organizationBillingSubscriptionCanceled: "organization.billing.subscription.canceled"
    case .organizationBillingSubscriptionCreated: "organization.billing.subscription.created"
    case .organizationBillingSubscriptionPaused: "organization.billing.subscription.paused"
    case .organizationBillingSubscriptionResumed: "organization.billing.subscription.resumed"
    case .organizationBillingSubscriptionUpdated: "organization.billing.subscription.updated"
    case .organizationCreated: "organization.created"
    case .organizationEntitlementsUpdated: "organization.entitlements.updated"
    case .organizationInvitationAccepted: "organization.invitation.accepted"
    case .organizationInvitationCreated: "organization.invitation.created"
    case .organizationInvitationDeclined: "organization.invitation.declined"
    case .organizationInvitationDeleted: "organization.invitation.deleted"
    case .organizationInvitationExpired: "organization.invitation.expired"
    case .organizationInvitationRevoked: "organization.invitation.revoked"
    case .organizationMemberCreated: "organization.member.created"
    case .organizationMemberDeleted: "organization.member.deleted"
    case .organizationMemberUpdated: "organization.member.updated"
    case .organizationPublishableKeyCreated: "organization.publishable_key.created"
    case .organizationPublishableKeyRevoked: "organization.publishable_key.revoked"
    case .organizationPublishableKeyUpdated: "organization.publishable_key.updated"
    case .organizationSecretKeyCreated: "organization.secret_key.created"
    case .organizationSecretKeyRevoked: "organization.secret_key.revoked"
    case .organizationSecretKeyUpdated: "organization.secret_key.updated"
    case .organizationSettingsUpdated: "organization.settings.updated"
    case .organizationUpdated: "organization.updated"
    case .organizationWebhookEndpointCreated: "organization.webhook_endpoint.created"
    case .organizationWebhookEndpointDeleted: "organization.webhook_endpoint.deleted"
    case .organizationWebhookEndpointDisabled: "organization.webhook_endpoint.disabled"
    case .organizationWebhookEndpointEnabled: "organization.webhook_endpoint.enabled"
    case .organizationWebhookEndpointFailing: "organization.webhook_endpoint.failing"
    case .organizationWebhookEndpointRecovered: "organization.webhook_endpoint.recovered"
    case .organizationWebhookEndpointSecretRotated: "organization.webhook_endpoint.secret_rotated"
    case .organizationWebhookEndpointUpdated: "organization.webhook_endpoint.updated"
    case .zoneCreated: "zone.created"
    case .zoneDeleted: "zone.deleted"
    case .zonePublished: "zone.published"
    case .zoneUnpublished: "zone.unpublished"
    case .zoneUpdated: "zone.updated"
    case .unknown(let event): event.type
    }
  }

  /// Identifier of the event. Its leading bits are the moment it was recorded, so
  /// identifiers sort by time. A delivery can arrive more than once, so a receiver
  /// deduplicates on it.
  public var id: String {
    envelope.id
  }

  /// Always `webhook_event`.
  ///
  /// It is always "webhook_event", which this type writes itself.
  public var object: String {
    envelope.object
  }

  /// The contract version the payload follows: the `info.version` of the document that
  /// describes it.
  public var api_version: String {
    envelope.api_version
  }

  /// When the change was made.
  public var created_at: Date {
    envelope.created_at
  }

  /// Identifier of the organization the change was made in.
  public var organization_id: String {
    envelope.organization_id
  }

  /// The task that recorded the event: the resource's path and what was done, such as
  /// `organization.member.update`. The contract's `tasks.yaml` lists every task with
  /// what triggers it and the event types it records.
  public var task: String {
    envelope.task
  }

  /// The object the event is about.
  public var related_object: AdminSchema.WebhookEventRelatedObject {
    envelope.related_object
  }

  /// The request that made the change, a change made signed in to Mountaya's web
  /// application or by Mountaya's staff included. Null only when Mountaya made the
  /// change on its own: a schedule, work finished after a request was answered, or the
  /// payment provider's report.
  public var request: AdminSchema.WebhookEventRequest? {
    envelope.request
  }

  /// Who made the change.
  public var actor: AdminSchema.WebhookEventActor {
    envelope.actor
  }

  /// envelope is the members every case carries beside its `type` and its `data`, which the
  /// accessors read.
  private var envelope: any Envelope {
    switch self {
    case .collectionCreated(let event): event
    case .collectionDeleted(let event): event
    case .collectionItineraryAdded(let event): event
    case .collectionItineraryMoved(let event): event
    case .collectionItineraryRemoved(let event): event
    case .collectionShareLinkCreated(let event): event
    case .collectionShareLinkDeleted(let event): event
    case .collectionShareLinkRotated(let event): event
    case .collectionUpdated(let event): event
    case .collectionZoneAdded(let event): event
    case .collectionZoneRemoved(let event): event
    case .itineraryCreated(let event): event
    case .itineraryDeleted(let event): event
    case .itineraryPublished(let event): event
    case .itinerarySegmentConverted(let event): event
    case .itinerarySegmentCreated(let event): event
    case .itinerarySegmentDeleted(let event): event
    case .itinerarySegmentMerged(let event): event
    case .itinerarySegmentSplit(let event): event
    case .itinerarySegmentUpdated(let event): event
    case .itinerarySegmentGroupCreated(let event): event
    case .itinerarySegmentGroupDeleted(let event): event
    case .itinerarySegmentGroupUpdated(let event): event
    case .itineraryShareLinkCreated(let event): event
    case .itineraryShareLinkDeleted(let event): event
    case .itineraryShareLinkRotated(let event): event
    case .itineraryUnpublished(let event): event
    case .itineraryUpdated(let event): event
    case .itineraryWaypointCreated(let event): event
    case .itineraryWaypointDeleted(let event): event
    case .itineraryWaypointUpdated(let event): event
    case .organizationAiProviderConfigCreated(let event): event
    case .organizationAiProviderConfigDeleted(let event): event
    case .organizationAiProviderConfigUpdated(let event): event
    case .organizationBillingInfoUpdated(let event): event
    case .organizationBillingInvoicePaid(let event): event
    case .organizationBillingInvoicePaymentActionRequired(let event): event
    case .organizationBillingInvoicePaymentFailed(let event): event
    case .organizationBillingPaymentMethodAttached(let event): event
    case .organizationBillingPaymentMethodDetached(let event): event
    case .organizationBillingPaymentMethodUpdated(let event): event
    case .organizationBillingSubscriptionCanceled(let event): event
    case .organizationBillingSubscriptionCreated(let event): event
    case .organizationBillingSubscriptionPaused(let event): event
    case .organizationBillingSubscriptionResumed(let event): event
    case .organizationBillingSubscriptionUpdated(let event): event
    case .organizationCreated(let event): event
    case .organizationEntitlementsUpdated(let event): event
    case .organizationInvitationAccepted(let event): event
    case .organizationInvitationCreated(let event): event
    case .organizationInvitationDeclined(let event): event
    case .organizationInvitationDeleted(let event): event
    case .organizationInvitationExpired(let event): event
    case .organizationInvitationRevoked(let event): event
    case .organizationMemberCreated(let event): event
    case .organizationMemberDeleted(let event): event
    case .organizationMemberUpdated(let event): event
    case .organizationPublishableKeyCreated(let event): event
    case .organizationPublishableKeyRevoked(let event): event
    case .organizationPublishableKeyUpdated(let event): event
    case .organizationSecretKeyCreated(let event): event
    case .organizationSecretKeyRevoked(let event): event
    case .organizationSecretKeyUpdated(let event): event
    case .organizationSettingsUpdated(let event): event
    case .organizationUpdated(let event): event
    case .organizationWebhookEndpointCreated(let event): event
    case .organizationWebhookEndpointDeleted(let event): event
    case .organizationWebhookEndpointDisabled(let event): event
    case .organizationWebhookEndpointEnabled(let event): event
    case .organizationWebhookEndpointFailing(let event): event
    case .organizationWebhookEndpointRecovered(let event): event
    case .organizationWebhookEndpointSecretRotated(let event): event
    case .organizationWebhookEndpointUpdated(let event): event
    case .zoneCreated(let event): event
    case .zoneDeleted(let event): event
    case .zonePublished(let event): event
    case .zoneUnpublished(let event): event
    case .zoneUpdated(let event): event
    case .unknown(let event): event
    }
  }

  /// Reads the case its `type` names, or `unknown` for a type this build does not know and for a
  /// payload the case's types do not read.
  public init(from decoder: any Decoder) throws {
    let container = try decoder.container(keyedBy: WireKey.self)
    let type = try container.decode(String.self, forKey: "type")
    let typed: Self?
    switch type {
    case "collection.created": typed = try? Self.collectionCreated(Payload(from: decoder))
    case "collection.deleted": typed = try? Self.collectionDeleted(Payload(from: decoder))
    case "collection.itinerary.added":
      typed = try? Self.collectionItineraryAdded(Payload(from: decoder))
    case "collection.itinerary.moved":
      typed = try? Self.collectionItineraryMoved(Payload(from: decoder))
    case "collection.itinerary.removed":
      typed = try? Self.collectionItineraryRemoved(Payload(from: decoder))
    case "collection.share_link.created":
      typed = try? Self.collectionShareLinkCreated(Payload(from: decoder))
    case "collection.share_link.deleted":
      typed = try? Self.collectionShareLinkDeleted(Payload(from: decoder))
    case "collection.share_link.rotated":
      typed = try? Self.collectionShareLinkRotated(Payload(from: decoder))
    case "collection.updated": typed = try? Self.collectionUpdated(Payload(from: decoder))
    case "collection.zone.added": typed = try? Self.collectionZoneAdded(Payload(from: decoder))
    case "collection.zone.removed": typed = try? Self.collectionZoneRemoved(Payload(from: decoder))
    case "itinerary.created": typed = try? Self.itineraryCreated(Payload(from: decoder))
    case "itinerary.deleted": typed = try? Self.itineraryDeleted(Payload(from: decoder))
    case "itinerary.published": typed = try? Self.itineraryPublished(Payload(from: decoder))
    case "itinerary.segment.converted":
      typed = try? Self.itinerarySegmentConverted(Payload(from: decoder))
    case "itinerary.segment.created":
      typed = try? Self.itinerarySegmentCreated(Payload(from: decoder))
    case "itinerary.segment.deleted":
      typed = try? Self.itinerarySegmentDeleted(Payload(from: decoder))
    case "itinerary.segment.merged":
      typed = try? Self.itinerarySegmentMerged(Payload(from: decoder))
    case "itinerary.segment.split": typed = try? Self.itinerarySegmentSplit(Payload(from: decoder))
    case "itinerary.segment.updated":
      typed = try? Self.itinerarySegmentUpdated(Payload(from: decoder))
    case "itinerary.segment_group.created":
      typed = try? Self.itinerarySegmentGroupCreated(Payload(from: decoder))
    case "itinerary.segment_group.deleted":
      typed = try? Self.itinerarySegmentGroupDeleted(Payload(from: decoder))
    case "itinerary.segment_group.updated":
      typed = try? Self.itinerarySegmentGroupUpdated(Payload(from: decoder))
    case "itinerary.share_link.created":
      typed = try? Self.itineraryShareLinkCreated(Payload(from: decoder))
    case "itinerary.share_link.deleted":
      typed = try? Self.itineraryShareLinkDeleted(Payload(from: decoder))
    case "itinerary.share_link.rotated":
      typed = try? Self.itineraryShareLinkRotated(Payload(from: decoder))
    case "itinerary.unpublished": typed = try? Self.itineraryUnpublished(Payload(from: decoder))
    case "itinerary.updated": typed = try? Self.itineraryUpdated(Payload(from: decoder))
    case "itinerary.waypoint.created":
      typed = try? Self.itineraryWaypointCreated(Payload(from: decoder))
    case "itinerary.waypoint.deleted":
      typed = try? Self.itineraryWaypointDeleted(Payload(from: decoder))
    case "itinerary.waypoint.updated":
      typed = try? Self.itineraryWaypointUpdated(Payload(from: decoder))
    case "organization.ai_provider_config.created":
      typed = try? Self.organizationAiProviderConfigCreated(Payload(from: decoder))
    case "organization.ai_provider_config.deleted":
      typed = try? Self.organizationAiProviderConfigDeleted(Payload(from: decoder))
    case "organization.ai_provider_config.updated":
      typed = try? Self.organizationAiProviderConfigUpdated(Payload(from: decoder))
    case "organization.billing.info.updated":
      typed = try? Self.organizationBillingInfoUpdated(Payload(from: decoder))
    case "organization.billing.invoice.paid":
      typed = try? Self.organizationBillingInvoicePaid(Payload(from: decoder))
    case "organization.billing.invoice.payment_action_required":
      typed = try? Self.organizationBillingInvoicePaymentActionRequired(Payload(from: decoder))
    case "organization.billing.invoice.payment_failed":
      typed = try? Self.organizationBillingInvoicePaymentFailed(Payload(from: decoder))
    case "organization.billing.payment_method.attached":
      typed = try? Self.organizationBillingPaymentMethodAttached(Payload(from: decoder))
    case "organization.billing.payment_method.detached":
      typed = try? Self.organizationBillingPaymentMethodDetached(Payload(from: decoder))
    case "organization.billing.payment_method.updated":
      typed = try? Self.organizationBillingPaymentMethodUpdated(Payload(from: decoder))
    case "organization.billing.subscription.canceled":
      typed = try? Self.organizationBillingSubscriptionCanceled(Payload(from: decoder))
    case "organization.billing.subscription.created":
      typed = try? Self.organizationBillingSubscriptionCreated(Payload(from: decoder))
    case "organization.billing.subscription.paused":
      typed = try? Self.organizationBillingSubscriptionPaused(Payload(from: decoder))
    case "organization.billing.subscription.resumed":
      typed = try? Self.organizationBillingSubscriptionResumed(Payload(from: decoder))
    case "organization.billing.subscription.updated":
      typed = try? Self.organizationBillingSubscriptionUpdated(Payload(from: decoder))
    case "organization.created": typed = try? Self.organizationCreated(Payload(from: decoder))
    case "organization.entitlements.updated":
      typed = try? Self.organizationEntitlementsUpdated(Payload(from: decoder))
    case "organization.invitation.accepted":
      typed = try? Self.organizationInvitationAccepted(Payload(from: decoder))
    case "organization.invitation.created":
      typed = try? Self.organizationInvitationCreated(Payload(from: decoder))
    case "organization.invitation.declined":
      typed = try? Self.organizationInvitationDeclined(Payload(from: decoder))
    case "organization.invitation.deleted":
      typed = try? Self.organizationInvitationDeleted(Payload(from: decoder))
    case "organization.invitation.expired":
      typed = try? Self.organizationInvitationExpired(Payload(from: decoder))
    case "organization.invitation.revoked":
      typed = try? Self.organizationInvitationRevoked(Payload(from: decoder))
    case "organization.member.created":
      typed = try? Self.organizationMemberCreated(Payload(from: decoder))
    case "organization.member.deleted":
      typed = try? Self.organizationMemberDeleted(Payload(from: decoder))
    case "organization.member.updated":
      typed = try? Self.organizationMemberUpdated(Payload(from: decoder))
    case "organization.publishable_key.created":
      typed = try? Self.organizationPublishableKeyCreated(Payload(from: decoder))
    case "organization.publishable_key.revoked":
      typed = try? Self.organizationPublishableKeyRevoked(Payload(from: decoder))
    case "organization.publishable_key.updated":
      typed = try? Self.organizationPublishableKeyUpdated(Payload(from: decoder))
    case "organization.secret_key.created":
      typed = try? Self.organizationSecretKeyCreated(Payload(from: decoder))
    case "organization.secret_key.revoked":
      typed = try? Self.organizationSecretKeyRevoked(Payload(from: decoder))
    case "organization.secret_key.updated":
      typed = try? Self.organizationSecretKeyUpdated(Payload(from: decoder))
    case "organization.settings.updated":
      typed = try? Self.organizationSettingsUpdated(Payload(from: decoder))
    case "organization.updated": typed = try? Self.organizationUpdated(Payload(from: decoder))
    case "organization.webhook_endpoint.created":
      typed = try? Self.organizationWebhookEndpointCreated(Payload(from: decoder))
    case "organization.webhook_endpoint.deleted":
      typed = try? Self.organizationWebhookEndpointDeleted(Payload(from: decoder))
    case "organization.webhook_endpoint.disabled":
      typed = try? Self.organizationWebhookEndpointDisabled(Payload(from: decoder))
    case "organization.webhook_endpoint.enabled":
      typed = try? Self.organizationWebhookEndpointEnabled(Payload(from: decoder))
    case "organization.webhook_endpoint.failing":
      typed = try? Self.organizationWebhookEndpointFailing(Payload(from: decoder))
    case "organization.webhook_endpoint.recovered":
      typed = try? Self.organizationWebhookEndpointRecovered(Payload(from: decoder))
    case "organization.webhook_endpoint.secret_rotated":
      typed = try? Self.organizationWebhookEndpointSecretRotated(Payload(from: decoder))
    case "organization.webhook_endpoint.updated":
      typed = try? Self.organizationWebhookEndpointUpdated(Payload(from: decoder))
    case "zone.created": typed = try? Self.zoneCreated(Payload(from: decoder))
    case "zone.deleted": typed = try? Self.zoneDeleted(Payload(from: decoder))
    case "zone.published": typed = try? Self.zonePublished(Payload(from: decoder))
    case "zone.unpublished": typed = try? Self.zoneUnpublished(Payload(from: decoder))
    case "zone.updated": typed = try? Self.zoneUpdated(Payload(from: decoder))
    default: typed = nil
    }
    self = try typed ?? .unknown(Self.untyped(decoder, type: type))
  }

  /// untyped reads an event this build cannot type as the envelope: as the envelope's own types
  /// read it, or, where they do not read its object either, with its object and its previous
  /// attributes as they arrived. It throws where the body holds no envelope at all.
  private static func untyped(_ decoder: any Decoder, type: String) throws
    -> AdminSchema.WebhookEvent
  {
    if let event = try? AdminSchema.WebhookEvent(from: decoder) {
      return event
    }
    let payload = try Payload<JSONValue, [String: JSONValue]>(from: decoder)
    var data = AdminSchema.WebhookEventData(object: .unknown(payload.data.object))
    data.previous_attributes = payload.data.previous_attributes
    return AdminSchema.WebhookEvent(
      id: payload.id,
      type: AdminSchema.WebhookEventType(rawValue: type),
      api_version: payload.api_version,
      created_at: payload.created_at,
      organization_id: payload.organization_id,
      task: payload.task,
      related_object: payload.related_object,
      data: data,
      request: payload.request,
      actor: payload.actor)
  }

  /// Writes the event as the envelope it was delivered in, its `type` the one its case names.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .collectionCreated(let event):
      try event.encode(to: encoder)
    case .collectionDeleted(let event):
      try event.encode(to: encoder)
    case .collectionItineraryAdded(let event):
      try event.encode(to: encoder)
    case .collectionItineraryMoved(let event):
      try event.encode(to: encoder)
    case .collectionItineraryRemoved(let event):
      try event.encode(to: encoder)
    case .collectionShareLinkCreated(let event):
      try event.encode(to: encoder)
    case .collectionShareLinkDeleted(let event):
      try event.encode(to: encoder)
    case .collectionShareLinkRotated(let event):
      try event.encode(to: encoder)
    case .collectionUpdated(let event):
      try event.encode(to: encoder)
    case .collectionZoneAdded(let event):
      try event.encode(to: encoder)
    case .collectionZoneRemoved(let event):
      try event.encode(to: encoder)
    case .itineraryCreated(let event):
      try event.encode(to: encoder)
    case .itineraryDeleted(let event):
      try event.encode(to: encoder)
    case .itineraryPublished(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentConverted(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentCreated(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentDeleted(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentMerged(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentSplit(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentUpdated(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentGroupCreated(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentGroupDeleted(let event):
      try event.encode(to: encoder)
    case .itinerarySegmentGroupUpdated(let event):
      try event.encode(to: encoder)
    case .itineraryShareLinkCreated(let event):
      try event.encode(to: encoder)
    case .itineraryShareLinkDeleted(let event):
      try event.encode(to: encoder)
    case .itineraryShareLinkRotated(let event):
      try event.encode(to: encoder)
    case .itineraryUnpublished(let event):
      try event.encode(to: encoder)
    case .itineraryUpdated(let event):
      try event.encode(to: encoder)
    case .itineraryWaypointCreated(let event):
      try event.encode(to: encoder)
    case .itineraryWaypointDeleted(let event):
      try event.encode(to: encoder)
    case .itineraryWaypointUpdated(let event):
      try event.encode(to: encoder)
    case .organizationAiProviderConfigCreated(let event):
      try event.encode(to: encoder)
    case .organizationAiProviderConfigDeleted(let event):
      try event.encode(to: encoder)
    case .organizationAiProviderConfigUpdated(let event):
      try event.encode(to: encoder)
    case .organizationBillingInfoUpdated(let event):
      try event.encode(to: encoder)
    case .organizationBillingInvoicePaid(let event):
      try event.encode(to: encoder)
    case .organizationBillingInvoicePaymentActionRequired(let event):
      try event.encode(to: encoder)
    case .organizationBillingInvoicePaymentFailed(let event):
      try event.encode(to: encoder)
    case .organizationBillingPaymentMethodAttached(let event):
      try event.encode(to: encoder)
    case .organizationBillingPaymentMethodDetached(let event):
      try event.encode(to: encoder)
    case .organizationBillingPaymentMethodUpdated(let event):
      try event.encode(to: encoder)
    case .organizationBillingSubscriptionCanceled(let event):
      try event.encode(to: encoder)
    case .organizationBillingSubscriptionCreated(let event):
      try event.encode(to: encoder)
    case .organizationBillingSubscriptionPaused(let event):
      try event.encode(to: encoder)
    case .organizationBillingSubscriptionResumed(let event):
      try event.encode(to: encoder)
    case .organizationBillingSubscriptionUpdated(let event):
      try event.encode(to: encoder)
    case .organizationCreated(let event):
      try event.encode(to: encoder)
    case .organizationEntitlementsUpdated(let event):
      try event.encode(to: encoder)
    case .organizationInvitationAccepted(let event):
      try event.encode(to: encoder)
    case .organizationInvitationCreated(let event):
      try event.encode(to: encoder)
    case .organizationInvitationDeclined(let event):
      try event.encode(to: encoder)
    case .organizationInvitationDeleted(let event):
      try event.encode(to: encoder)
    case .organizationInvitationExpired(let event):
      try event.encode(to: encoder)
    case .organizationInvitationRevoked(let event):
      try event.encode(to: encoder)
    case .organizationMemberCreated(let event):
      try event.encode(to: encoder)
    case .organizationMemberDeleted(let event):
      try event.encode(to: encoder)
    case .organizationMemberUpdated(let event):
      try event.encode(to: encoder)
    case .organizationPublishableKeyCreated(let event):
      try event.encode(to: encoder)
    case .organizationPublishableKeyRevoked(let event):
      try event.encode(to: encoder)
    case .organizationPublishableKeyUpdated(let event):
      try event.encode(to: encoder)
    case .organizationSecretKeyCreated(let event):
      try event.encode(to: encoder)
    case .organizationSecretKeyRevoked(let event):
      try event.encode(to: encoder)
    case .organizationSecretKeyUpdated(let event):
      try event.encode(to: encoder)
    case .organizationSettingsUpdated(let event):
      try event.encode(to: encoder)
    case .organizationUpdated(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointCreated(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointDeleted(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointDisabled(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointEnabled(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointFailing(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointRecovered(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointSecretRotated(let event):
      try event.encode(to: encoder)
    case .organizationWebhookEndpointUpdated(let event):
      try event.encode(to: encoder)
    case .zoneCreated(let event):
      try event.encode(to: encoder)
    case .zoneDeleted(let event):
      try event.encode(to: encoder)
    case .zonePublished(let event):
      try event.encode(to: encoder)
    case .zoneUnpublished(let event):
      try event.encode(to: encoder)
    case .zoneUpdated(let event):
      try event.encode(to: encoder)
    case .unknown(let event):
      try event.encode(to: encoder)
      return
    }
    var container = encoder.container(keyedBy: WireKey.self)
    try container.encode(type, forKey: "type")
  }
}
