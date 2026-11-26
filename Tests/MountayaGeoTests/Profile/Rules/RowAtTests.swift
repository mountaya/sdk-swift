import Testing

@testable import MountayaGeo

@Suite("rowAt")
struct RowAtTests {
  private let rows = [
    ProfileRange(from: 0, to: 500), ProfileRange(from: 500, to: 1_200),
    ProfileRange(from: 1_200, to: 1_800),
  ]

  @Test("the row under a cursor, the later at a shared meter and the last at the end")
  func under() {
    #expect(rowAt(rows, distance: 800) == rows[1])
    #expect(rowAt(rows, distance: 500) == rows[1])
    #expect(rowAt(rows, distance: 1_800) == rows[2])
    #expect(rowAt(rows, distance: 1_900) == nil)
    #expect(rowAt([ProfileRange](), distance: 0) == nil)
  }

  @Test("a row of no length is never under a cursor, and a row is answered as given")
  func noLength() {
    let withTransfer = [
      ProfileClass(from: 0, to: 500, color: "", label: "s1"),
      ProfileClass(from: 500, to: 500, color: "", label: "transfer"),
      ProfileClass(from: 500, to: 900, color: "", label: "s2"),
    ]
    #expect(rowAt(withTransfer, distance: 500)?.label == "s2")
    let overlapping = [ProfileRange(from: 0, to: 600), ProfileRange(from: 400, to: 1_000)]
    #expect(rowAt(overlapping, distance: 700) == ProfileRange(from: 400, to: 1_000))
  }
}
