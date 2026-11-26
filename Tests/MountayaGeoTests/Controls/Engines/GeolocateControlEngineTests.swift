import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("GeolocateControlEngine")
@MainActor
struct GeolocateControlEngineTests {
  /// shown reads a state as `busy|blocked|live`, each `y` or `n`.
  private static func shown(_ state: GeolocateControlState) -> String {
    [state.isBusy, state.isBlocked, state.isLive].map { $0 ? "y" : "n" }.joined(separator: "|")
  }

  @Test("a control reads the permission as it comes to stand over a map, and asks for no fix")
  func mount() async {
    let map = HeldLocateMap()
    let engine = GeolocateControlEngine(map: map)
    #expect(Self.shown(engine.state) == "n|n|y")
    await settled()
    map.answer(0, refused: true)
    await settled()

    #expect(Self.shown(engine.state) == "n|y|y")
    #expect(map.reads == 1)
    #expect(map.fixes == 0)
    map.release()
    engine.close()
  }

  @Test("a press is busy until every fix it asked for settles, each failure reported")
  func busy() async {
    let map = HeldLocateMap()
    let engine = GeolocateControlEngine(map: map)
    var reported = 0
    await settled()
    map.answer(0, refused: false)

    engine.locate(onError: { _ in reported += 1 })
    engine.locate(onError: { _ in reported += 1 })
    #expect(Self.shown(engine.state) == "y|n|y")
    await settled()
    map.land(0)
    await settled()
    #expect(Self.shown(engine.state) == "y|n|y")
    map.refuse(1)
    await settled()

    #expect(Self.shown(engine.state) == "n|n|y")
    #expect(reported == 1)
    #expect(map.fixes == 2)
    // A read after each fix that settled.
    #expect(map.reads == 3)
    map.release()
    engine.close()
  }

  @Test("blocked only on the permission's word: a refused fix with the permission unasked is not")
  func blocked() async {
    let map = HeldLocateMap()
    let engine = GeolocateControlEngine(map: map)
    await settled()
    map.answer(0, refused: false)

    engine.locate()
    await settled()
    map.refuse(0)
    await settled()
    #expect(Self.shown(engine.state) == "n|n|y")
    map.answer(1, refused: false)
    await settled()
    #expect(Self.shown(engine.state) == "n|n|y")

    engine.locate()
    await settled()
    map.refuse(1)
    await settled()
    map.answer(2, refused: true)
    await settled()
    #expect(Self.shown(engine.state) == "n|y|y")

    // A fix that lands lowers the blocked wording once its read says so.
    engine.locate()
    await settled()
    map.land(2)
    await settled()
    #expect(Self.shown(engine.state) == "n|y|y")
    map.answer(3, refused: false)
    await settled()
    #expect(Self.shown(engine.state) == "n|n|y")
    map.release()
    engine.close()
  }

  @Test("a read that fails says nothing is blocked, and one that never answers changes nothing")
  func reads() async {
    let map = HeldLocateMap()
    let engine = GeolocateControlEngine(map: map)
    await settled()
    map.answer(0, refused: true)

    engine.locate()
    await settled()
    map.refuse(0)
    await settled()
    #expect(Self.shown(engine.state) == "n|y|y")
    map.fail(1)
    await settled()
    #expect(Self.shown(engine.state) == "n|n|y")
    map.release()
    engine.close()
  }

  @Test("an answer from an earlier read lands nowhere")
  func earlierRead() async {
    let map = HeldLocateMap()
    let engine = GeolocateControlEngine(map: map)
    engine.locate()
    await settled()
    map.land(0)
    await settled()
    map.answer(1, refused: true)
    await settled()
    map.answer(0, refused: false)
    await settled()

    #expect(Self.shown(engine.state) == "n|y|y")
    map.release()
    engine.close()
  }

  @Test(
    "a map in place of another says nothing is blocked until it is read, owing the other nothing")
  func replaced() async {
    let a = HeldLocateMap()
    let b = HeldLocateMap()
    let engine = GeolocateControlEngine(map: a)
    await settled()
    a.answer(0, refused: true)
    await settled()
    #expect(Self.shown(engine.state) == "n|y|y")

    engine.locate()
    engine.configure(map: b)
    #expect(Self.shown(engine.state) == "y|n|y")
    await settled()
    a.refuse(0)
    await settled()
    // The fix settled after its map was replaced: nothing is read through it.
    #expect(Self.shown(engine.state) == "n|n|y")
    #expect(a.reads == 1)
    b.answer(0, refused: true)
    await settled()
    #expect(Self.shown(engine.state) == "n|y|y")

    engine.configure(map: b)
    #expect(b.reads == 1)
    engine.configure(map: nil)
    #expect(Self.shown(engine.state) == "n|n|n")
    engine.locate()
    await settled()
    #expect(b.fixes == 0)
    a.release()
    b.release()
    engine.close()
  }

  @Test("a control with no map asks nothing and is not live")
  func noMap() async {
    let engine = GeolocateControlEngine()
    engine.locate()
    engine.configure(map: nil)
    await settled()

    #expect(Self.shown(engine.state) == "n|n|n")
    engine.close()
  }

  @Test("a stream yields each state that differs, and a closed engine reports and reads nothing")
  func streamsAndClose() async {
    let map = HeldLocateMap()
    let engine = GeolocateControlEngine(map: map)
    let stream = engine.subscribe()
    var reported = 0
    await settled()
    engine.locate(onError: { _ in reported += 1 })
    await settled()
    engine.close()
    map.refuse(0)
    map.answer(0, refused: true)
    await settled()

    var shown: [String] = []
    for await state in stream {
      shown.append(Self.shown(state))
    }
    #expect(shown == ["n|n|y", "y|n|y"])
    #expect(reported == 0)
    #expect(Self.shown(engine.state) == "y|n|y")
    map.release()
  }
}
