import Testing

@testable import MountayaElements

@Suite("mapCredits")
struct MapCreditsTests {
  private static let osm =
    #"<a href="https://www.openstreetmap.org/copyright" target="_blank">&copy; OpenStreetMap contributors</a>"#

  @Test("Mountaya is credited first, then each drawn source's credit once, in order")
  func credits() {
    #expect(mapCredits([]) == [mountayaCredit])
    #expect(
      mapCredits([
        CreditedSource(attribution: mountayaCredit, isDrawn: true),
        CreditedSource(attribution: Self.osm, isDrawn: true),
        CreditedSource(attribution: mountayaCredit, isDrawn: true),
      ]) == [mountayaCredit, Self.osm])
    #expect(
      mapCredits([
        CreditedSource(attribution: "Imagery &copy; Satellite Provider", isDrawn: true),
        CreditedSource(attribution: Self.osm, isDrawn: true),
      ]) == [mountayaCredit, "Imagery &copy; Satellite Provider", Self.osm])
  }

  @Test("a blank credit, an absent one and that of a source no layer draws are left out")
  func leftOut() {
    #expect(
      mapCredits([
        CreditedSource(attribution: nil, isDrawn: true),
        CreditedSource(attribution: "", isDrawn: true),
        CreditedSource(attribution: "   ", isDrawn: true),
        CreditedSource(attribution: "\u{FEFF}\u{3000}\t", isDrawn: true),
        CreditedSource(attribution: Self.osm, isDrawn: false),
      ]) == [mountayaCredit])
    #expect(
      mapCredits([CreditedSource(attribution: "\u{85}", isDrawn: true)]) == [
        mountayaCredit, "\u{85}",
      ],
      "NEL is no white space ECMAScript trims")
  }

  @Test("two spellings of one credit are two credits, compared by their scalars")
  func spellings() {
    let quoted = "<a href='https://mountaya.com/' target='_blank'>&copy; Mountaya</a>"
    #expect(
      mapCredits([CreditedSource(attribution: quoted, isDrawn: true)]) == [mountayaCredit, quoted])
    #expect(
      mapCredits([
        CreditedSource(attribution: "caf\u{E9}", isDrawn: true),
        CreditedSource(attribution: "cafe\u{301}", isDrawn: true),
      ]).count == 3)
    #expect(
      mountayaCredit == #"<a href="https://mountaya.com/" target="_blank">&copy; Mountaya</a>"#)
  }
}
