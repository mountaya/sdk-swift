// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The object a webhook event carries at `data.object`: one lean object per kind, told
  /// apart by its `object`, which is the family of the event's type.
  ///
  /// A member this build has never seen decodes as `unknown`, holding what arrived, so a member the
  /// contract adds decodes in a build made before it. A build made after it reads that member as a
  /// case of its own, so a `switch` over it outside this module ends in `@unknown default`.
  @nonexhaustive
  public enum WebhookEventObject: Sendable, Hashable, Codable {
    /// `organization`.
    case OrganizationEventObject(AdminSchema.OrganizationEventObject)
    /// `organization.member`.
    case OrganizationMemberEventObject(AdminSchema.OrganizationMemberEventObject)
    /// `organization.invitation`.
    case OrganizationInvitationEventObject(AdminSchema.OrganizationInvitationEventObject)
    /// `collection`.
    case CollectionEventObject(AdminSchema.CollectionEventObject)
    /// `collection.itinerary`.
    case CollectionItineraryEventObject(AdminSchema.CollectionItineraryEventObject)
    /// `collection.zone`.
    case CollectionZoneEventObject(AdminSchema.CollectionZoneEventObject)
    /// `collection.share_link`.
    case CollectionShareLinkEventObject(AdminSchema.CollectionShareLinkEventObject)
    /// `itinerary`.
    case ItineraryEventObject(AdminSchema.ItineraryEventObject)
    /// `itinerary.segment`.
    case ItinerarySegmentEventObject(AdminSchema.ItinerarySegmentEventObject)
    /// `itinerary.segment_group`.
    case ItinerarySegmentGroupEventObject(AdminSchema.ItinerarySegmentGroupEventObject)
    /// `itinerary.waypoint`.
    case ItineraryWaypointEventObject(AdminSchema.ItineraryWaypointEventObject)
    /// `itinerary.share_link`.
    case ItineraryShareLinkEventObject(AdminSchema.ItineraryShareLinkEventObject)
    /// `zone`.
    case ZoneEventObject(AdminSchema.ZoneEventObject)
    /// `organization.publishable_key`.
    case PublishableKeyEventObject(AdminSchema.PublishableKeyEventObject)
    /// `organization.secret_key`.
    case SecretKeyEventObject(AdminSchema.SecretKeyEventObject)
    /// `organization.ai_provider_config`.
    case AiProviderConfigEventObject(AdminSchema.AiProviderConfigEventObject)
    /// `organization.settings`.
    case OrganizationSettingsEventObject(AdminSchema.OrganizationSettingsEventObject)
    /// `organization.entitlements`.
    case OrganizationEntitlementsEventObject(AdminSchema.OrganizationEntitlementsEventObject)
    /// `organization.billing.subscription`.
    case OrganizationSubscriptionEventObject(AdminSchema.OrganizationSubscriptionEventObject)
    /// `organization.billing.invoice`.
    case InvoiceEventObject(AdminSchema.InvoiceEventObject)
    /// `organization.billing.payment_method`.
    case PaymentMethodEventObject(AdminSchema.PaymentMethodEventObject)
    /// `organization.billing.info`.
    case BillingInfoEventObject(AdminSchema.BillingInfoEventObject)
    /// `organization.webhook_endpoint`.
    case WebhookEndpointEventObject(AdminSchema.WebhookEndpointEventObject)
    /// unknown is a member this build has never seen, holding what arrived.
    case unknown(JSONValue)

    /// Reads the member its `object` names, or `unknown` for one this build has never seen.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      switch try? container.decode(String.self, forKey: "object") {
      case "organization":
        self = .OrganizationEventObject(try AdminSchema.OrganizationEventObject(from: decoder))
      case "organization.member":
        self = .OrganizationMemberEventObject(
          try AdminSchema.OrganizationMemberEventObject(from: decoder))
      case "organization.invitation":
        self = .OrganizationInvitationEventObject(
          try AdminSchema.OrganizationInvitationEventObject(from: decoder))
      case "collection":
        self = .CollectionEventObject(try AdminSchema.CollectionEventObject(from: decoder))
      case "collection.itinerary":
        self = .CollectionItineraryEventObject(
          try AdminSchema.CollectionItineraryEventObject(from: decoder))
      case "collection.zone":
        self = .CollectionZoneEventObject(try AdminSchema.CollectionZoneEventObject(from: decoder))
      case "collection.share_link":
        self = .CollectionShareLinkEventObject(
          try AdminSchema.CollectionShareLinkEventObject(from: decoder))
      case "itinerary":
        self = .ItineraryEventObject(try AdminSchema.ItineraryEventObject(from: decoder))
      case "itinerary.segment":
        self = .ItinerarySegmentEventObject(
          try AdminSchema.ItinerarySegmentEventObject(from: decoder))
      case "itinerary.segment_group":
        self = .ItinerarySegmentGroupEventObject(
          try AdminSchema.ItinerarySegmentGroupEventObject(from: decoder))
      case "itinerary.waypoint":
        self = .ItineraryWaypointEventObject(
          try AdminSchema.ItineraryWaypointEventObject(from: decoder))
      case "itinerary.share_link":
        self = .ItineraryShareLinkEventObject(
          try AdminSchema.ItineraryShareLinkEventObject(from: decoder))
      case "zone":
        self = .ZoneEventObject(try AdminSchema.ZoneEventObject(from: decoder))
      case "organization.publishable_key":
        self = .PublishableKeyEventObject(try AdminSchema.PublishableKeyEventObject(from: decoder))
      case "organization.secret_key":
        self = .SecretKeyEventObject(try AdminSchema.SecretKeyEventObject(from: decoder))
      case "organization.ai_provider_config":
        self = .AiProviderConfigEventObject(
          try AdminSchema.AiProviderConfigEventObject(from: decoder))
      case "organization.settings":
        self = .OrganizationSettingsEventObject(
          try AdminSchema.OrganizationSettingsEventObject(from: decoder))
      case "organization.entitlements":
        self = .OrganizationEntitlementsEventObject(
          try AdminSchema.OrganizationEntitlementsEventObject(from: decoder))
      case "organization.billing.subscription":
        self = .OrganizationSubscriptionEventObject(
          try AdminSchema.OrganizationSubscriptionEventObject(from: decoder))
      case "organization.billing.invoice":
        self = .InvoiceEventObject(try AdminSchema.InvoiceEventObject(from: decoder))
      case "organization.billing.payment_method":
        self = .PaymentMethodEventObject(try AdminSchema.PaymentMethodEventObject(from: decoder))
      case "organization.billing.info":
        self = .BillingInfoEventObject(try AdminSchema.BillingInfoEventObject(from: decoder))
      case "organization.webhook_endpoint":
        self = .WebhookEndpointEventObject(
          try AdminSchema.WebhookEndpointEventObject(from: decoder))
      default:
        self = .unknown(try JSONValue(from: decoder))
      }
    }

    /// Writes the member it holds.
    public func encode(to encoder: any Encoder) throws {
      switch self {
      case .OrganizationEventObject(let member):
        try member.encode(to: encoder)
      case .OrganizationMemberEventObject(let member):
        try member.encode(to: encoder)
      case .OrganizationInvitationEventObject(let member):
        try member.encode(to: encoder)
      case .CollectionEventObject(let member):
        try member.encode(to: encoder)
      case .CollectionItineraryEventObject(let member):
        try member.encode(to: encoder)
      case .CollectionZoneEventObject(let member):
        try member.encode(to: encoder)
      case .CollectionShareLinkEventObject(let member):
        try member.encode(to: encoder)
      case .ItineraryEventObject(let member):
        try member.encode(to: encoder)
      case .ItinerarySegmentEventObject(let member):
        try member.encode(to: encoder)
      case .ItinerarySegmentGroupEventObject(let member):
        try member.encode(to: encoder)
      case .ItineraryWaypointEventObject(let member):
        try member.encode(to: encoder)
      case .ItineraryShareLinkEventObject(let member):
        try member.encode(to: encoder)
      case .ZoneEventObject(let member):
        try member.encode(to: encoder)
      case .PublishableKeyEventObject(let member):
        try member.encode(to: encoder)
      case .SecretKeyEventObject(let member):
        try member.encode(to: encoder)
      case .AiProviderConfigEventObject(let member):
        try member.encode(to: encoder)
      case .OrganizationSettingsEventObject(let member):
        try member.encode(to: encoder)
      case .OrganizationEntitlementsEventObject(let member):
        try member.encode(to: encoder)
      case .OrganizationSubscriptionEventObject(let member):
        try member.encode(to: encoder)
      case .InvoiceEventObject(let member):
        try member.encode(to: encoder)
      case .PaymentMethodEventObject(let member):
        try member.encode(to: encoder)
      case .BillingInfoEventObject(let member):
        try member.encode(to: encoder)
      case .WebhookEndpointEventObject(let member):
        try member.encode(to: encoder)
      case .unknown(let value):
        try value.encode(to: encoder)
      }
    }
  }
}
