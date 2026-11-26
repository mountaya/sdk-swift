import Testing

@testable import MountayaGeo

@Suite("canonicalLongitudes")
struct CanonicalLongitudesTests {
  @Test("a west edge within one world keeps its digits")
  func withinOneWorld() {
    #expect(canonicalLongitudes(west: 6.86, east: 6.9) == [6.86, 6.9])
    #expect(canonicalLongitudes(west: 179.5, east: 180.5) == [179.5, 180.5])
    #expect(canonicalLongitudes(west: 180, east: 181) == [180, 181])
    #expect(canonicalLongitudes(west: -180, east: -179) == [-180, -179])
  }

  @Test("a west edge past the range is brought back by whole turns, and the east edge follows")
  func pastTheRange() {
    #expect(canonicalLongitudes(west: -180.5, east: -179.5) == [179.5, 180.5])
    #expect(canonicalLongitudes(west: 365, east: 367) == [5, 7])
    #expect(canonicalLongitudes(west: 540, east: 550) == [-180, -170])
    #expect(canonicalLongitudes(west: -540, east: -530) == [-180, -170])
  }

  @Test("a turn or more wide is the whole world")
  func turnWide() {
    #expect(canonicalLongitudes(west: 0, east: 360) == [-180, 180])
    #expect(canonicalLongitudes(west: -200, east: 200) == [-180, 180])
    #expect(canonicalLongitudes(west: -.infinity, east: 5) == [-180, 180])
    #expect(canonicalLongitudes(west: 5, east: .infinity) == [-180, 180])
  }

  @Test("an edge at no number places the box nowhere")
  func nowhere() {
    let nowhere: [Double] = [.nan, .nan]
    #expect(sameNumbers(canonicalLongitudes(west: .nan, east: 5), nowhere))
    #expect(sameNumbers(canonicalLongitudes(west: 5, east: .nan), nowhere))
    #expect(sameNumbers(canonicalLongitudes(west: .infinity, east: .infinity), nowhere))
    #expect(sameNumbers(canonicalLongitudes(west: .infinity, east: 5), nowhere))
    #expect(sameNumbers(canonicalLongitudes(west: 5, east: -.infinity), nowhere))
  }
}
