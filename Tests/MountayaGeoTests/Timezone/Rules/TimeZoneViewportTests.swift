import Testing

@testable import MountayaGeo

@Suite("timeZoneViewport")
struct TimeZoneViewportTests {
  @Test("a zone opens on its viewport")
  func viewport() {
    #expect(timeZoneViewport("Europe/Zurich") == MapViewport(center: [8.2275, 46.8182], zoom: 6))
    #expect(timeZoneViewport("Europe/Paris") == MapViewport(center: [2.3522, 46.2276], zoom: 5))
    #expect(
      timeZoneViewport("America/Denver") == MapViewport(center: [-104.9903, 39.7392], zoom: 5))
    #expect(timeZoneViewport("Asia/Tokyo") == MapViewport(center: [138.2529, 36.2048], zoom: 4))
    #expect(
      timeZoneViewport("Pacific/Auckland") == MapViewport(center: [174.886, -40.9006], zoom: 4))
    #expect(timeZoneViewport("Africa/Nairobi") == MapViewport(center: [37.9062, -0.0236], zoom: 5))
  }

  @Test("a link a runtime reports answers the zone it names")
  func link() {
    #expect(timeZoneViewport("Asia/Kolkata") == MapViewport(center: [78.9629, 20.5937], zoom: 4))
    #expect(timeZoneViewport("Asia/Calcutta") == timeZoneViewport("Asia/Kolkata"))
    #expect(timeZoneViewport("Europe/Kiev") == MapViewport(center: [31.1656, 48.3794], zoom: 4))
    #expect(timeZoneViewport("Europe/Kiev") == timeZoneViewport("Europe/Kyiv"))
  }

  @Test("a merged zone answers the zone that holds it today")
  func merged() {
    #expect(timeZoneViewport("Europe/Zaporozhye") == timeZoneViewport("Europe/Kyiv"))
    #expect(
      timeZoneViewport("America/Montreal") == MapViewport(center: [-79.3832, 43.6532], zoom: 5))
    #expect(timeZoneViewport("America/Montreal") == timeZoneViewport("America/Toronto"))
  }

  @Test("Macquarie Island, filed under Antarctica, is Australia's")
  func macquarie() {
    #expect(
      timeZoneViewport("Antarctica/Macquarie")
        == MapViewport(center: [133.7751, -25.2744], zoom: 3))
  }

  @Test("a zone of no country, a link no runtime reports and a name that is no zone answer nothing")
  func nothing() {
    for name in ["Antarctica/Casey", "Etc/UTC", "US/Pacific", "Not/AZone", "", "constructor"] {
      #expect(timeZoneViewport(name) == nil, "\(name)")
    }
  }

  /// A name is the platform's own, matched exactly.
  @Test("a name is matched exactly, letter case and white space included")
  func exact() {
    #expect(timeZoneViewport("europe/zurich") == nil)
    #expect(timeZoneViewport(" Europe/Zurich") == nil)
    #expect(timeZoneViewport("Europe/Zurich ") == nil)
  }

  /// The table is the one the contract publishes, every zone of a country and every name a runtime
  /// reports in another form (`geo/timezone-viewport.json`'s constants).
  @Test("every zone of a country answers its viewport, and every reported name its zone's")
  func published() {
    #expect(timeZoneViewport("Europe/Berlin") == MapViewport(center: [10.4515, 51.1657], zoom: 5))
    #expect(
      timeZoneViewport("America/New_York") == MapViewport(center: [-74.006, 40.7128], zoom: 5))
    #expect(timeZoneViewport("Asia/Saigon") == timeZoneViewport("Asia/Ho_Chi_Minh"))
    #expect(timeZoneViewport("Asia/Saigon") != nil)
    #expect(timeZoneViewport("America/Godthab") == timeZoneViewport("America/Nuuk"))
  }
}
