import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("stepsTile")
struct StepsTileTests {
  private func steps(_ ranges: ClosedRange<Int>...) -> [NavigationStep] {
    ranges.map {
      NavigationStep(
        fromIndex: $0.lowerBound, toIndex: $0.upperBound, maneuver: .continue)
    }
  }

  private func step(from: Int, to: Int) -> NavigationStep {
    NavigationStep(fromIndex: from, toIndex: to, maneuver: .continue)
  }

  @Test("steps tile where they cover the geometry once, in travel order")
  func tiling() {
    #expect(stepsTile(steps(0...1, 1...2), coordinateCount: 3))
    #expect(stepsTile(steps(0...2, 2...2), coordinateCount: 3))
    #expect(stepsTile(steps(0...0), coordinateCount: 1))
  }

  /// A step may start and end on one vertex, wherever it stands.
  @Test("a step of one vertex tiles its vertex")
  func oneVertex() {
    #expect(stepsTile(steps(0...1, 1...1, 1...2), coordinateCount: 3))
    #expect(stepsTile(steps(0...0, 0...2), coordinateCount: 3))
  }

  @Test("a list that breaks the tiling does not tile")
  func breaches() {
    #expect(
      !stepsTile(
        [step(from: 0, to: 2), step(from: 2, to: 1), step(from: 1, to: 2)], coordinateCount: 3),
      "a range reversed")
    #expect(!stepsTile(steps(0...1, 1...3), coordinateCount: 3), "an index past the geometry")
    #expect(!stepsTile(steps(0...2, 1...3), coordinateCount: 4), "two steps overlapping")
    #expect(!stepsTile(steps(0...1, 2...3, 1...2), coordinateCount: 4), "steps out of order")
    #expect(!stepsTile(steps(0...1, 2...3), coordinateCount: 4), "a stretch no step covers")
    #expect(!stepsTile(steps(0...1, 1...2), coordinateCount: 4), "short of the last vertex")
    #expect(!stepsTile(steps(1...2, 2...3), coordinateCount: 4), "past the first vertex")
    #expect(!stepsTile(steps(-1...1), coordinateCount: 2), "an index before the geometry")
  }

  @Test("an empty list tiles nothing")
  func empty() {
    #expect(!stepsTile([], coordinateCount: 3))
    #expect(!stepsTile([], coordinateCount: 0))
  }

  /// A refused list reads as no steps, never as a repair of them; an empty one is no refusal.
  @Test("a reading is the list whole, or refused")
  func reading() {
    let tiling = steps(0...1, 1...2)

    #expect(stepsReading(tiling, coordinateCount: 3).steps == tiling)
    #expect(!stepsReading(tiling, coordinateCount: 3).refused)
    #expect(stepsReading(steps(0...1), coordinateCount: 3) == refusedSteps)
    #expect(stepsReading(steps(0...1), coordinateCount: 3).steps.isEmpty)
    #expect(!stepsReading([], coordinateCount: 3).refused)
  }
}
