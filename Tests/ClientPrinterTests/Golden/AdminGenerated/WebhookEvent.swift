// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
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
  /// `thing.created`: A thing was created.
  case thingCreated(Payload<AdminSchema.ThingEventObject, Never>)
  /// `thing.updated`: A thing's count, update time, kind or former name changed.
  case thingUpdated(Payload<AdminSchema.ThingEventObject, ThingUpdatedPreviousAttributes>)
  /// unknown is an event this build cannot type: a type it does not know, or a payload its types do
  /// not read, as the envelope holds it.
  case unknown(AdminSchema.WebhookEvent)

  /// type is the event's type, as the wire spells it.
  public var type: AdminSchema.WebhookEventType {
    switch self {
    case .thingCreated: "thing.created"
    case .thingUpdated: "thing.updated"
    case .unknown(let event): event.type
    }
  }

  /// Identifier of the event.
  public var id: String {
    envelope.id
  }

  /// Always `webhook_event`.
  ///
  /// It is always "webhook_event", which this type writes itself.
  public var object: String {
    envelope.object
  }

  /// When the change was made.
  public var created_at: Date {
    envelope.created_at
  }

  /// The request that made the change, null for a change made on its own.
  public var request_id: String? {
    envelope.request_id
  }

  /// Whether the change was made in a live organization.
  public var livemode: Bool? {
    envelope.livemode
  }

  /// The former identifier of the event. Use `id` instead.
  @available(*, deprecated, message: "The former identifier of the event.")
  public var legacy_id: String? {
    envelope._legacy_id
  }

  /// envelope is the members every case carries beside its `type` and its `data`, which the
  /// accessors read.
  private var envelope: any Envelope {
    switch self {
    case .thingCreated(let event): event
    case .thingUpdated(let event): event
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
    case "thing.created": typed = try? Self.thingCreated(Payload(from: decoder))
    case "thing.updated": typed = try? Self.thingUpdated(Payload(from: decoder))
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
    var event = AdminSchema.WebhookEvent(
      id: payload.id,
      type: AdminSchema.WebhookEventType(rawValue: type),
      created_at: payload.created_at,
      data: data,
      request_id: payload.request_id)
    event.livemode = payload.livemode
    event._legacy_id = payload._legacy_id
    return event
  }

  /// Writes the event as the envelope it was delivered in, its `type` the one its case names.
  public func encode(to encoder: any Encoder) throws {
    switch self {
    case .thingCreated(let event):
      try event.encode(to: encoder)
    case .thingUpdated(let event):
      try event.encode(to: encoder)
    case .unknown(let event):
      try event.encode(to: encoder)
      return
    }
    var container = encoder.container(keyedBy: WireKey.self)
    try container.encode(type, forKey: "type")
  }
}
