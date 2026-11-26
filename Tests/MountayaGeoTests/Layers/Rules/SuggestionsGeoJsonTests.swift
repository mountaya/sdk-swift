import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("suggestionsGeoJson")
struct SuggestionsGeoJsonTests {
  private let two = DataSchema.SuggestionsResult {
    $0.routes = [
      DataSchema.SuggestionRoute { $0.seed = 1 }, DataSchema.SuggestionRoute { $0.seed = 2 },
    ]
  }

  @Test("the first is chosen unless another is named")
  func chosen() throws {
    let first = suggestionsGeoJson(two).features
    try #require(first.count == 2)
    #expect(first[0].properties["chosen"] == true)
    #expect(first[0].properties["seed"] == 1)
    #expect(first[0].properties[featureColorProperty] == .string(suggestionChosenColor))
    #expect(first[1].properties[featureColorProperty] == .string(suggestionAlternativeColor))
    let second = suggestionsGeoJson(two, chosen: 1).features
    try #require(second.count == 2)
    #expect(second[0].properties["chosen"] == false)
    #expect(second[1].properties["chosen"] == true)
    // A place no suggestion holds chooses none.
    #expect(
      suggestionsGeoJson(two, chosen: 5).features.map { $0.properties["chosen"] } == [false, false])
  }
}
