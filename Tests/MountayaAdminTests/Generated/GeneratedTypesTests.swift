import Foundation
import MountayaClient
import Testing

@testable import MountayaAdmin

/// The admin unit's printed types, read and written against the wire the contract describes, as
/// the core's are: the webhook event, the types only the admin unit's operations carry, and the
/// secrets among them.
@Suite("Generated admin types")
struct GeneratedTypesTests {
  /// A secret the model marks is printed by no generated type of either unit, in any form Swift
  /// prints a value in, and stays readable to a caller (`sdk/SPEC.md` §1).
  @Test("a printed type of the admin unit never prints a secret the model marks")
  func secretsRedacted() throws {
    let endpoint = try ScriptedSender.decode(
      AdminSchema.WebhookEndpointWithSecret.self,
      from: #"{"id": "we_1", "organization_id": "org", "url": "https://example.com/hooks", "#
        + #""description": null, "enabled_events": ["collection.created"], "status": "enabled", "#
        + #""disabled_reason": null, "disabled_at": null, "failing_since": null, "etag": "\"e1\"", "#
        + #""created_by": null, "created_at": "2026-11-14T09:12:44.000Z", "#
        + #""updated_at": "2026-11-14T09:12:44.000Z", "secret": "whsk_9f2c4e"}"#)
    var dumped = ""
    dump(endpoint, to: &dumped)

    for printed in [
      String(describing: endpoint), String(reflecting: endpoint), "\(endpoint)", dumped,
    ] {
      #expect(!printed.contains("9f2c4e"), "\(printed)")
      #expect(printed.contains("secret: <redacted>"), "\(printed)")
      #expect(printed.contains("enabled_events"), "\(printed)")
    }
    #expect(endpoint.secret == "whsk_9f2c4e")
  }

  @Test("an open enum of the admin unit keys a map as a JSON object, an unseen key included")
  func enumKeyedMap() throws {
    let map = try ScriptedSender.decode(
      [AdminSchema.Capability: Bool].self,
      from: #"{"studio-online": true, "zz-new": false}"#
    )

    #expect(map[.studioOnline] == true)
    #expect(map["zz-new"] == false)
    #expect(try ScriptedSender.json(map) == #"{"studio-online":true,"zz-new":false}"#)
  }

  @Test("an int64 keeps every digit, past what a double holds")
  func int64() throws {
    let preview = try ScriptedSender.decode(
      AdminSchema.PromotionCodePreview.self,
      from: #"{"valid": true, "amount_off": 9007199254740993}"#
    )

    #expect(preview.amount_off == 9_007_199_254_740_993)
    #expect(try ScriptedSender.json(preview) == #"{"amount_off":9007199254740993,"valid":true}"#)
  }

  /// collectionEvent is a webhook event of `type` about a collection, its `data` written by the
  /// caller.
  private static func collectionEvent(type: String, data: String) -> String {
    #"{"actor":{"type":"mountaya"},"api_version":"0.8.0","created_at":"2026-11-14T09:12:44.000Z","#
      + #""data":\#(data),"id":"019a8eed-e1ad-7753-b049-b0e20d79577a","object":"webhook_event","#
      + #""organization_id":"org","related_object":{"id":"col","type":"collection"},"#
      + #""request":null,"task":"collection.create","type":"\#(type)"}"#
  }

  /// collection is a collection as a webhook event carries it.
  private static let collection =
    #"{"created_at":"2026-11-14T09:12:44.000Z","created_by":{"id":"user"},"description":null,"#
    + #""id":"col","is_private":false,"name":"Alps","object":"collection","#
    + #""organization_id":"org","updated_at":"2026-11-14T09:12:44.000Z","version":3}"#

  @Test("a webhook event of a known type is its case, and is written back as it arrived")
  func webhookEventKnown() throws {
    let text = Self.collectionEvent(
      type: "collection.created", data: #"{"object":\#(Self.collection)}"#)

    let event = try ScriptedSender.decode(WebhookEvent.self, from: text)

    guard case .collectionCreated(let payload) = event else {
      Issue.record("a collection.created event is read as \(event)")
      return
    }
    #expect(event.type == .collectionCreated)
    #expect(payload.object == "webhook_event")
    #expect(payload.data.object.name == "Alps")
    #expect(payload.data.object.version == 3)
    #expect(payload.request == nil)
    #expect(try ScriptedSender.json(event) == text)
  }

  @Test("a type whose change moves no field reads none, whatever its body carries")
  func webhookEventWithoutPreviousAttributes() throws {
    let text = Self.collectionEvent(
      type: "collection.deleted",
      data: #"{"object":\#(Self.collection),"previous_attributes":{"name":"Old"}}"#)

    let event = try ScriptedSender.decode(WebhookEvent.self, from: text)

    guard case .collectionDeleted(let payload) = event else {
      Issue.record("a collection.deleted event is read as \(event)")
      return
    }
    #expect(payload.data.previous_attributes == nil)
  }

  @Test("previous attributes hold the named fields alone, each in its three states")
  func webhookEventPreviousAttributes() throws {
    let text = Self.collectionEvent(
      type: "collection.updated",
      data:
        #"{"object":\#(Self.collection),"previous_attributes":{"description":null,"name":"Old","zz":1}}"#
    )

    let event = try ScriptedSender.decode(WebhookEvent.self, from: text)

    guard case .collectionUpdated(let payload) = event else {
      Issue.record("a collection.updated event is read as \(event)")
      return
    }
    let previous = try #require(payload.data.previous_attributes)
    #expect(previous.name == "Old")
    #expect(previous.description == .some(nil))
    #expect(previous.is_private == nil)
    #expect(
      try ScriptedSender.json(event)
        == text.replacingOccurrences(of: #","zz":1"#, with: ""))
  }

  @Test("a webhook event of a type this build does not know is the envelope, written back whole")
  func webhookEventUnknown() throws {
    let text = Self.collectionEvent(
      type: "collection.teleported", data: #"{"object":{"object":"collection.teleport"}}"#)

    let event = try ScriptedSender.decode(WebhookEvent.self, from: text)

    guard case .unknown(let envelope) = event else {
      Issue.record("a type this build does not know is read as \(event)")
      return
    }
    #expect(event.type == "collection.teleported")
    #expect(envelope.data.object == .unknown(["object": "collection.teleport"]))
    #expect(try ScriptedSender.json(event) == text)
  }

  @Test("a payload its types do not read is the envelope, read off as the cases are, written whole")
  func webhookEventUntyped() throws {
    // A collection carrying no version: the collection's own type reads none of it.
    let object = Self.collection.replacingOccurrences(of: #","version":3"#, with: "")
    let text = Self.collectionEvent(
      type: "collection.updated",
      data: #"{"object":\#(object),"previous_attributes":{"name":"Old"}}"#)

    let event = try ScriptedSender.decode(WebhookEvent.self, from: text)

    guard case .unknown(let envelope) = event,
      case .unknown(.object(let held)) = envelope.data.object
    else {
      Issue.record("an object its types do not read is held as it arrived, read as \(event)")
      return
    }
    #expect(held["name"] == "Alps")
    #expect(held["version"] == nil)
    #expect(event.type == .collectionUpdated)
    #expect(event.id == "019a8eed-e1ad-7753-b049-b0e20d79577a")
    #expect(event.created_at == Date(timeIntervalSince1970: 1_794_647_564))
    #expect(event.organization_id == "org")
    #expect(event.related_object.type == "collection")
    #expect(event.request == nil)
    #expect(event.actor.type == .mountaya)
    #expect(try ScriptedSender.json(event) == text)
  }

  @Test("a body that is no envelope fails the decode, whatever type it names")
  func webhookEventNoEnvelope() {
    let missing = Self.collectionEvent(
      type: "collection.created", data: #"{"object":\#(Self.collection)}"#
    ).replacingOccurrences(of: #""task":"collection.create","#, with: "")

    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(WebhookEvent.self, from: missing)
    }
    #expect(throws: DecodingError.self) {
      try ScriptedSender.decode(WebhookEvent.self, from: #"{"id":"e"}"#)
    }
  }
}
