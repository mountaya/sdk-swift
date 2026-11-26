import Testing

@testable import MountayaElements

@Suite("accessStandingAfter")
struct AccessStandingAfterTests {
  private static func play(_ answers: [AccessAnswer], holding held: Set<String>)
    -> [(standing: Bool, restored: Bool)]
  {
    var standing = StandingRefusals()
    return answers.map { answer in
      let after = accessStandingAfter(standing, answer: answer, holdsSource: held.contains)
      standing = after.standing
      return (!after.standing.isEmpty, after.restored)
    }
  }

  @Test("a source's refusal ends with a tile of its own, and the end of the last is told once")
  func tiles() {
    let played = Self.play(
      [
        .refused(source: "slope"), .refused(source: "zones"), .tile(source: "slope"),
        .tile(source: "zones"), .tile(source: "zones"),
      ], holding: ["slope", "zones"])
    #expect(played.map(\.standing) == [true, true, true, false, false])
    #expect(played.map(\.restored) == [false, false, false, true, false])
  }

  @Test("a refusal naming no source ends with the next style, which keeps one it still holds")
  func styles() {
    let unsourced = Self.play(
      [.refused(source: nil), .tile(source: "slope"), .style], holding: ["slope"])
    #expect(unsourced.map(\.standing) == [true, true, false])
    #expect(unsourced.map(\.restored) == [false, false, true])
    let kept = Self.play(
      [.refused(source: "slope"), .style, .tile(source: "slope")], holding: ["slope"])
    #expect(kept.map(\.standing) == [true, true, false])
  }

  @Test("a source the style no longer holds takes its refusal with it at the next answer")
  func leftTheStyle() {
    let played = Self.play(
      [.refused(source: "slope"), .refused(source: "zones"), .tile(source: "zones")],
      holding: ["zones"])
    #expect(played.map(\.restored) == [false, false, true])
    #expect(
      Self.play([.refused(source: "slope"), .style], holding: []).map(\.restored) == [false, true])
    #expect(
      Self.play([.refused(source: "slope"), .tile(source: "zones")], holding: ["slope", "zones"])
        .map(\.standing) == [true, true], "a tile of another source ends nothing")
  }

  @Test("an answer while nothing stands ends nothing, and a refusal after the end stands again")
  func again() {
    #expect(
      Self.play([.tile(source: "slope"), .style], holding: ["slope"]).map(\.restored) == [
        false, false,
      ])
    let played = Self.play(
      [
        .refused(source: "slope"), .tile(source: "slope"), .refused(source: "slope"),
        .tile(source: "slope"),
      ], holding: ["slope"])
    #expect(played.map(\.restored) == [false, true, false, true])
    var twice = StandingRefusals()
    twice =
      accessStandingAfter(twice, answer: .refused(source: "a"), holdsSource: { _ in true }).standing
    twice =
      accessStandingAfter(twice, answer: .refused(source: "a"), holdsSource: { _ in true }).standing
    #expect(twice.sources == ["a"], "a source refused twice stands once")
  }
}
