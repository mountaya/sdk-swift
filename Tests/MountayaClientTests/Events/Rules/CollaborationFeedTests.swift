import Testing

@testable import MountayaClient

@Suite("CollaborationFeed")
struct CollaborationFeedTests {
  @Test("a change frame moves the position, a live frame does not, and snapshots open the feed")
  func roles() {
    func role(event: String, data: String) -> EventRole? {
      RestSchema.CollabStreamEvent.read(EventRecord(event: event, data: data, id: "1-0"))?.role
    }

    #expect(role(event: "presence.snapshot", data: #"{"members":[]}"#) == .openingSnapshot)
    #expect(role(event: "lock.snapshot", data: #"{"locks":[]}"#) == .openingSnapshot)
    #expect(
      role(
        event: "presence.join",
        data:
          #"{"user_id":"2b8d4f19-6a05-4e73-8c1f-9d3b7e05a24c","connected_at":"2026-05-12T09:14:09Z"}"#
      )
        == .live)
    #expect(
      role(
        event: "segment.changed",
        data:
          #"{"action":"updated","actor_id":"a","id":"s","itinerary_id":"i","kind":"segment","occurred_at":"2026-05-12T09:14:07Z","organization_id":"o","revision":4}"#
      ) == .ordinary)
    #expect(role(event: "reconnect", data: #"{"reason":"interrupted"}"#) == .reconnect)
    #expect(role(event: "brand-new.changed", data: "{}") == nil)
  }

  @Test("an itinerary's and a zone's streams are editor streams, an organization's a list stream")
  func streams() {
    #expect(RestSchema.CollabStreamEvent.rules(for: "getItineraryEvents") == .collaborationEditor)
    #expect(RestSchema.CollabStreamEvent.rules(for: "getZoneEvents") == .collaborationEditor)
    #expect(RestSchema.CollabStreamEvent.rules(for: "getOrganizationEvents") == .collaborationFeed)
    #expect(RestSchema.CollabStreamEvent.rules(for: "getBrandNewEvents") == .collaborationFeed)
  }

  @Test("a presence.join names the member who arrived, and no other event names one")
  func arrivingMember() {
    func member(event: String, data: String) -> String? {
      RestSchema.CollabStreamEvent.read(EventRecord(event: event, data: data, id: nil))?.event
        .arrivingMember
    }

    #expect(
      member(
        event: "presence.join",
        data:
          #"{"user_id":"2b8d4f19-6a05-4e73-8c1f-9d3b7e05a24c","connected_at":"2026-05-12T09:14:09Z"}"#
      ) == "2b8d4f19-6a05-4e73-8c1f-9d3b7e05a24c")
    #expect(
      member(event: "presence.leave", data: #"{"user_id":"2b8d4f19-6a05-4e73-8c1f-9d3b7e05a24c"}"#)
        == nil)
    #expect(member(event: "presence.snapshot", data: #"{"members":[]}"#) == nil)
  }
}
