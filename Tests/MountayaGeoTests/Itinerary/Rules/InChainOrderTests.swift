import Testing

@testable import MountayaGeo

@Suite("inChainOrder")
struct InChainOrderTests {
  private struct Entry: Equatable {
    let name: String
    let position: Int
  }

  @Test("a chain runs by position, whatever order it arrived in")
  func byPosition() {
    let chain = [
      Entry(name: "c", position: 2), Entry(name: "a", position: 0), Entry(name: "b", position: 1),
    ]

    #expect(inChainOrder(chain, position: \.position).map(\.name) == ["a", "b", "c"])
  }

  /// `sorted(by:)` promises no stability, so two entries at one position would otherwise swap from
  /// one run to the next.
  @Test("two entries at one position keep the order they are listed in")
  func listedOrderAtOnePosition() {
    let chain = (0..<64).map { Entry(name: "\($0)", position: $0 % 2) }

    let ordered = inChainOrder(chain, position: \.position)

    #expect(ordered.map(\.name) == (0..<32).map { "\($0 * 2)" } + (0..<32).map { "\($0 * 2 + 1)" })
  }

  @Test("a position under zero runs first, and an empty chain is empty")
  func negativeAndEmpty() {
    let chain = [Entry(name: "a", position: 0), Entry(name: "before", position: -1)]

    #expect(inChainOrder(chain, position: \.position).map(\.name) == ["before", "a"])
    #expect(inChainOrder([Entry](), position: \.position).isEmpty)
  }
}
