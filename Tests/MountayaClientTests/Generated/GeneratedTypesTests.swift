import Foundation
import Testing

@testable import MountayaClient

/// The printed types' coding, read and written against the wire the contract describes.
@Suite("Generated types")
struct GeneratedTypesTests {
  /// A secret the model marks is printed by no generated type, in any form Swift prints a value
  /// in, and stays readable to a caller (`sdk/SPEC.md` §1).
  @Test("a printed type never prints a secret the model marks, and a caller still reads it")
  func secretsRedacted() {
    let session = RestSchema.Session(
      expires_at: Date(timeIntervalSince1970: 1_800_000_000), user_id: "u1", token: "sess_9f2c4e")
    var dumped = ""
    dump(session, to: &dumped)

    for printed in [String(describing: session), String(reflecting: session), "\(session)", dumped]
    {
      #expect(!printed.contains("9f2c4e"), "\(printed)")
      #expect(printed.contains("token: <redacted>"), "\(printed)")
      #expect(printed.contains("user_id"), "\(printed)")
    }
    #expect(session.token == "sess_9f2c4e")
  }

  @Test("an enum value this build has never seen decodes as itself and is written back")
  func openEnum() throws {
    let unseen = try ScriptedSender.decode(RestSchema.ActivitySlug.self, from: #""zz-new""#)

    #expect(unseen.rawValue == "zz-new")
    #expect(try ScriptedSender.json(unseen) == #""zz-new""#)
    #expect(
      try ScriptedSender.decode(RestSchema.ActivitySlug.self, from: #""hiking-and-trail""#)
        == .hikingAndTrail
    )
  }

  @Test("an open enum keys a map as a JSON object, an unseen key included")
  func enumKeyedMap() throws {
    let map = try ScriptedSender.decode(
      [RestSchema.ActivitySlug: Bool].self,
      from: #"{"hiking-and-trail": true, "zz-new": false}"#
    )

    #expect(map[.hikingAndTrail] == true)
    #expect(map["zz-new"] == false)
    #expect(try ScriptedSender.json(map) == #"{"hiking-and-trail":true,"zz-new":false}"#)
  }

  @Test("a union member this build has never seen decodes as unknown, holding what arrived")
  func unionUnknown() throws {
    let text = #"{"type":"brand-new","x":1}"#
    let event = try ScriptedSender.decode(RestSchema.AgentRunEvent.self, from: text)

    #expect(event == .unknown(["type": "brand-new", "x": 1]))
    #expect(try ScriptedSender.json(event) == text)
  }

  @Test("a timestamp is read through the anchored rule and written in UTC")
  func timestamp() throws {
    let session = try ScriptedSender.decode(
      RestSchema.Session.self,
      from: #"{"expires_at": "2026-03-14T10:26:53+01:00", "token": "sess_x"}"#
    )

    #expect(session.expires_at == Date(timeIntervalSince1970: 1_773_480_413))
    #expect(session.user_id == nil)
    #expect(
      try ScriptedSender.json(session)
        == #"{"expires_at":"2026-03-14T09:26:53.000Z","token":"sess_x","user_id":null}"#
    )
  }

  @Test("a timestamp that fails the anchor fails the decode")
  func timestampRefused() {
    for value in ["2026-03-14", "2026-03-14T09:26:53", "on 2026-03-14T09:26:53Z"] {
      #expect(throws: DecodingError.self) {
        try ScriptedSender.decode(
          RestSchema.Session.self,
          from: #"{"expires_at": "\#(value)", "token": "sess_x"}"#
        )
      }
    }
  }

  @Test("a merge property reads its three states apart")
  func mergeRead() throws {
    let absent = try ScriptedSender.decode(RestSchema.SegmentUpdateParams.self, from: "{}")
    let cleared = try ScriptedSender.decode(
      RestSchema.SegmentUpdateParams.self,
      from: #"{"description": null}"#
    )
    let set = try ScriptedSender.decode(
      RestSchema.SegmentUpdateParams.self,
      from: #"{"description": "Ridge"}"#
    )

    #expect(absent.description == .none)
    #expect(cleared.description == .some(nil))
    #expect(set.description == .some("Ridge"))
  }

  @Test("a value object a merge body embeds has three states too, and writes each apart")
  func embeddedThreeStates() throws {
    var contact = RestSchema.WaypointContact()
    contact.phone = .some(nil)
    contact.email = "hut@example.com"

    #expect(try ScriptedSender.json(contact) == #"{"email":"hut@example.com","phone":null}"#)
    #expect(
      try ScriptedSender.decode(RestSchema.WaypointContact.self, from: #"{"phone": null}"#).phone
        == .some(nil)
    )
    #expect(try ScriptedSender.decode(RestSchema.WaypointContact.self, from: "{}").phone == .none)
  }

  @Test("a schema version, a model digest and the full selection of every operation are printed")
  func printedConstants() {
    #expect(schemaVersion.hasPrefix("v"))
    #expect(modelDigest.count == 64)
    #expect(modelDigest.allSatisfy { $0.isHexDigit && !$0.isUppercase })
    #expect(
      DataOperation.directions.document.hasPrefix("query Directions($input: DirectionsInput!)"))
    #expect(OperationFacts.dataOperations.allSatisfy { $0.idempotent })
  }
}
