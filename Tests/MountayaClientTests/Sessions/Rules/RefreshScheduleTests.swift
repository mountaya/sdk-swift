import Foundation
import Testing

@testable import MountayaClient

@Suite("RefreshSchedule")
struct RefreshScheduleTests {
  @Test(
    "a known lifetime is re-minted on a proportional, capped margin",
    arguments: [
      (3_600_000, 3_540_000),
      (300_000, 240_000),
      (120_000, 60_000),
      (60_000, 30_000),
      (10_000, 5_000),
    ]
  )
  func proportionalMargin(lifetime: Int, delay: Int) {
    let plan = RefreshSchedule.plan(lifetime: .milliseconds(lifetime))

    #expect(plan == RefreshSchedule.Plan(delay: .milliseconds(delay), isArmed: true))
  }

  @Test("a delay under the floor is not armed, and a lifetime of zero or less is that case")
  func spentIsNotArmed() {
    #expect(!RefreshSchedule.plan(lifetime: .milliseconds(9_999)).isArmed)
    #expect(RefreshSchedule.plan(lifetime: .zero) == .init(delay: .zero, isArmed: false))
    #expect(
      RefreshSchedule.plan(lifetime: .milliseconds(-5000))
        == .init(delay: .milliseconds(-2500), isArmed: false))
  }

  @Test("an expiry that did not parse takes the flat margin rather than reading as spent")
  func unknownExpiry() {
    #expect(RefreshSchedule.plan(lifetime: nil) == .init(delay: .seconds(60), isArmed: true))
  }

  @Test("each consecutive spent token doubles the wait, up to the margin")
  func spentDoubles() {
    let delays = (1...7).map { RefreshSchedule.plan(consecutiveSpent: $0).delay }

    #expect(
      delays == [
        .seconds(5), .seconds(10), .seconds(20), .seconds(40), .seconds(60), .seconds(60),
        .seconds(60),
      ])
    #expect(RefreshSchedule.plan(consecutiveSpent: Int.max).delay == .seconds(60))
    #expect(RefreshSchedule.plan(consecutiveSpent: 0).delay == .seconds(5))
  }

  @Test("a wait is walked in hops no longer than the ceiling, ending when the deadline passes")
  func hops() {
    let start = Date(timeIntervalSince1970: 1_800_000_000)
    let deadline = start.addingTimeInterval(3540)
    var now = start
    var hops: [Duration] = []
    while let hop = RefreshSchedule.hop(toward: deadline, now: now) {
      hops.append(hop)
      let (seconds, attoseconds) = hop.components
      now = now.addingTimeInterval(Double(seconds) + Double(attoseconds) / 1e18)
    }

    #expect(
      hops == [
        .seconds(600), .seconds(600), .seconds(600), .seconds(600), .seconds(600), .seconds(540),
      ])
  }

  @Test("a device waking past its deadline mints at once rather than waiting out the hop")
  func wakesPastTheDeadline() {
    let deadline = Date(timeIntervalSince1970: 1_800_000_000)

    #expect(RefreshSchedule.hop(toward: deadline, now: deadline.addingTimeInterval(3600)) == nil)
    #expect(RefreshSchedule.hop(toward: deadline, now: deadline) == nil)
    #expect(
      RefreshSchedule.hop(toward: deadline, now: deadline.addingTimeInterval(-1)) == .seconds(1))
  }
}
