import Testing

@testable import MountayaGeo

@Suite("LayerRank")
struct LayerRankTests {
  @Test("the bands stack bottom to top, ten apart but the two that stand over the line")
  func bands() {
    #expect(
      LayerRank.allCases.map(\.rank) == [10, 20, 30, 40, 50, 52, 55, 60, 70, 80, 90, 100])
    #expect(LayerRank.hillshade.rank == 10)
    #expect(LayerRank.overlay.rank == 20)
    #expect(LayerRank(rawValue: 50) == .itineraryLine)
  }

  @Test("the restricted stretches lie over the line they mark, and beneath its direction")
  func restrictions() throws {
    let bands = LayerRank.allCases
    let index = try #require(bands.firstIndex(of: .itineraryRestriction))

    #expect(LayerRank.itineraryRestriction.rank == 55)
    #expect(bands[index - 1] == .itineraryFocus)
    #expect(bands[index + 1] == .itineraryDirection)
  }

  @Test("the focus a map draws from data lies over the itinerary's line, beneath its restrictions")
  func focus() throws {
    let bands = LayerRank.allCases
    let index = try #require(bands.firstIndex(of: .itineraryFocus))

    #expect(LayerRank.itineraryFocus.rank == 52)
    #expect(bands[index - 1] == .itineraryLine)
    #expect(bands[index + 1] == .itineraryRestriction)
  }
}
