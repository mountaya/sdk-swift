import MountayaGeo
import Testing

@testable import MountayaElements

@Suite("readRoadAccessStripeImageId")
struct ReadRoadAccessStripeImageIdTests {
  @Test("each kind's stripe id names that kind, a kind of two words read whole")
  func kinds() {
    for kind in RoadAccessKind.allCases {
      #expect(readRoadAccessStripeImageId(roadAccessStripeImagePrefix + kind.id) == kind)
    }
    #expect(readRoadAccessStripeImageId("road-access-stripe-local-access") == .localAccess)
    #expect(readRoadAccessStripeImageId("road-access-stripe-restricted") == .restricted)
  }

  @Test("a tail that is no kind, or a kind written otherwise, names none")
  func foreignTails() {
    #expect(readRoadAccessStripeImageId("road-access-stripe-") == nil)
    #expect(readRoadAccessStripeImageId("road-access-stripe-toll") == nil)
    #expect(readRoadAccessStripeImageId("road-access-stripe-Permit") == nil)
    #expect(readRoadAccessStripeImageId("road-access-stripe-permit ") == nil)
    #expect(readRoadAccessStripeImageId("road-access-stripe-local_access") == nil)
  }

  @Test("an id under another prefix names none, the waypoint sprite of a kind's warning included")
  func otherIds() {
    #expect(readRoadAccessStripeImageId("permit") == nil)
    #expect(readRoadAccessStripeImageId("section-icon-road-access-permit-9c36b5") == nil)
    #expect(readRoadAccessStripeImageId("road-access-permit") == nil)
    // A prefix read scalar by scalar: a hyphen of another code point is another prefix.
    #expect(readRoadAccessStripeImageId("road\u{2010}access-stripe-permit") == nil)
    #expect(readRoadAccessStripeImageId("Road-access-stripe-permit") == nil)
  }
}
