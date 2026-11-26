import Testing

@testable import MountayaElements

@Suite("SlotRequests")
@MainActor
struct SlotRequestsTests {
  @Test("the latest request owns its slot, a request a later one superseded no longer does")
  func latest() {
    let slots = SlotRequests()
    let first = slots.claim(.itinerary)
    let second = slots.claim(.itinerary)

    #expect(!slots.owns(.itinerary, token: first))
    #expect(slots.owns(.itinerary, token: second))
    #expect(
      slots.owns(.collection, token: second) == false, "a slot is a kind of content of its own")
    #expect(second > first, "tokens only grow")
    slots.release(.itinerary)
    #expect(!slots.owns(.itinerary, token: second))
    #expect(slots.requestedSlots().isEmpty)
  }

  @Test("a call withdrawn before it drew gives the slot back to the request it superseded")
  func givesBack() {
    let slots = SlotRequests()
    let first = slots.claim(.itinerary)
    let second = slots.claim(.itinerary)
    slots.giveBack(.itinerary, token: second)

    #expect(slots.owns(.itinerary, token: first))
    let third = slots.claim(.collection)
    slots.giveBack(.collection, token: third)
    #expect(
      !slots.owns(.collection, token: third), "a slot given back by its first request asks nothing")
    #expect(slots.requestedSlots() == [.itinerary])
  }

  @Test("a superseded request waits for the call that took its slot, and learns whether it lost")
  func regains() async {
    let slots = SlotRequests()
    let first = slots.claim(.itinerary)
    let second = slots.claim(.itinerary)
    let waiting = Task { await slots.regains(.itinerary, token: first) }
    for _ in 0..<5 { await Task.yield() }
    slots.giveBack(.itinerary, token: second)
    #expect(await waiting.value, "given back, the request owns its slot again")

    let third = slots.claim(.itinerary)
    let lost = Task { await slots.regains(.itinerary, token: first) }
    for _ in 0..<5 { await Task.yield() }
    slots.settle(third)
    #expect(await lost.value == false, "the call that drew took the slot for good")
  }

  @Test("a request that takes its slot for good, and a clear, end every wait")
  func takes() async {
    let slots = SlotRequests()
    let first = slots.claim(.zones)
    _ = slots.claim(.zones)
    let waiting = Task { await slots.regains(.zones, token: first) }
    for _ in 0..<5 { await Task.yield() }
    let taken = slots.take(.zones)
    #expect(await waiting.value == false)
    #expect(slots.owns(.zones, token: taken))

    let again = slots.claim(.zones)
    let cleared = Task { await slots.regains(.zones, token: taken) }
    for _ in 0..<5 { await Task.yield() }
    slots.release(.zones)
    #expect(await cleared.value == false)
    #expect(!slots.owns(.zones, token: again))
  }

  @Test("a request no later call superseded has nothing to wait for")
  func nothingToWait() async {
    let slots = SlotRequests()
    let only = slots.claim(.collection)
    #expect(await slots.regains(.collection, token: only))
  }

  @Test("a wait whose task is cancelled ends with nothing given back")
  func cancelled() async {
    let slots = SlotRequests()
    let first = slots.claim(.itinerary)
    let second = slots.claim(.itinerary)
    let waiting = Task { await slots.regains(.itinerary, token: first) }
    for _ in 0..<5 { await Task.yield() }
    waiting.cancel()
    #expect(await waiting.value == false)
    slots.giveBack(.itinerary, token: second)
    #expect(
      !slots.owns(.itinerary, token: first), "a request withdrawn while it waited is given nothing")
  }
}
