import Foundation
import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("itineraryWaypoints")
struct ItineraryWaypointsTests {
  /// The wrapper the API stores a waypoint's point in: a collection of one Point.
  private func stored(longitude: Double, latitude: Double, altitude: Double = 1_035)
    -> GeoJSONGeometry
  {
    collectionOf(pointAt(longitude, latitude, altitude))
  }

  /// The one place a waypoint configured by `configure` reads as, standing at 6, 45.
  private func place(_ configure: (inout RestSchema.ItineraryWaypoint) -> Void) throws
    -> ItineraryPlace
  {
    let waypoint = restPlace("w", geojson: stored(longitude: 6, latitude: 45), configure: configure)
    return try #require(itineraryWaypoints([waypoint]).first)
  }

  private func url(_ text: String) throws -> URI {
    URI(text)
  }

  /// The API stores every waypoint's point in a collection: a reader that matched a Point alone
  /// would draw no waypoint of any real itinerary, and say nothing.
  @Test("a waypoint stands at the first point its geometry holds, its altitude left out")
  func firstPoint() {
    let places = itineraryWaypoints([
      restPlace("nowhere", position: 0, geojson: nil),
      restPlace("line", position: 1, geojson: lineString([6, 45], [6.1, 45])),
      restPlace(
        "real", position: 2,
        geojson: collectionOf(
          lineString([7, 46], [7.1, 46]), pointAt(6, 45, 1_200), pointAt(8, 47))),
    ])

    #expect(places == [ItineraryPlace(id: "real", lngLat: [6, 45])])
  }

  @Test("a bare point is read too, so a place a caller builds is not turned away")
  func barePoint() {
    let places = itineraryWaypoints([restPlace("bare", geojson: pointAt(6.87, 45.92))])

    #expect(places.map(\.lngLat) == [[6.87, 45.92]])
  }

  @Test("a point is found at any depth of the collections it nests in")
  func nestedCollections() {
    let nested = collectionOf(
      collectionOf(lineString([7, 46], [7.1, 46])), collectionOf(collectionOf(pointAt(6, 45))))

    #expect(itineraryWaypoints([restPlace("deep", geojson: nested)]).map(\.lngLat) == [[6, 45]])
  }

  /// A MultiPoint is a directions segment's vias, never the one place a waypoint is.
  @Test("a MultiPoint is no point, and a waypoint holding only one is left out")
  func multiPoint() {
    let vias: GeoJSONGeometry = .multiPoint(GeoJSONMultiPoint(coordinates: [[6, 45]]))

    #expect(itineraryWaypoints([restPlace("vias", geojson: vias)]).isEmpty)
  }

  @Test("a point that names no place is passed over for the next one, and none is no place")
  func pointNamingNoPlace() {
    let places = itineraryWaypoints([
      restPlace("next", position: 0, geojson: collectionOf(pointAt(.nan, 45), pointAt(6, 45))),
      restPlace("short", position: 1, geojson: pointAt(6)),
      restPlace("infinite", position: 2, geojson: pointAt(6, .infinity)),
    ])

    #expect(places == [ItineraryPlace(id: "next", lngLat: [6, 45])])
  }

  /// A position is the API's ordinal: nothing on a waypoint states a distance, so it is placed by
  /// its point.
  @Test("the waypoints read in chain order, two at one position as listed")
  func chainOrder() {
    let places = itineraryWaypoints([
      restPlace(
        "finish", position: 2, geojson: stored(longitude: 6.86, latitude: 45.83), name: "Chamonix"),
      restPlace(
        "start", position: 0, geojson: stored(longitude: 6.86, latitude: 45.83), name: "Les Houches"
      ),
      restPlace(
        "hut", position: 1, geojson: stored(longitude: 6.86, latitude: 45.83),
        name: "Refuge de Miage"),
      restPlace("hut-2", position: 1, geojson: stored(longitude: 6.86, latitude: 45.83)),
    ])

    #expect(places.map(\.id) == ["start", "hut", "hut-2", "finish"])
    #expect(places.map(\.name) == ["Les Houches", "Refuge de Miage", nil, "Chamonix"])
    #expect(places.allSatisfy { $0.lngLat == [6.86, 45.83] })
  }

  @Test("the colour, the icon as the glyph and the name are carried as the wire states them")
  func colourIconName() {
    let places = itineraryWaypoints([
      restPlace(
        "summit", position: 0, geojson: stored(longitude: 6.86, latitude: 45.83), name: "Mont Joly",
        color: "#e03131",
        icon: "summit"),
      restPlace("bare", position: 1, geojson: stored(longitude: 6.86, latitude: 45.83)),
    ])

    #expect(
      places == [
        ItineraryPlace(
          id: "summit", lngLat: [6.86, 45.83], name: "Mont Joly", color: "#e03131",
          glyph: "summit"),
        ItineraryPlace(id: "bare", lngLat: [6.86, 45.83]),
      ])
  }

  /// The four ways the wire says nothing at once: an empty list, two nulls and two absent blocks.
  @Test("a waypoint that says nothing about its place has no details")
  func saysNothing() throws {
    #expect(try place { _ in }.details == nil)
  }

  @Test("a block left with nothing reads as none, as does details left with nothing")
  func emptyBlocks() throws {
    let bare = try place {
      $0.contact = RestSchema.WaypointContact {
        $0.address = .some(nil)
        $0.booking_url = .some(nil)
        $0.email = .some(nil)
        $0.opening_hours = .some(nil)
        $0.phone = .some(nil)
        $0.website = .some(nil)
      }
      $0.media = RestSchema.WaypointMedia {
        $0.links = []
        $0.photos = []
      }
      $0.timing = RestSchema.WaypointTiming {
        $0.cutoff_at = .some(nil)
        $0.stop_duration = .some(nil)
      }
      $0.properties = []
    }

    #expect(bare.details == nil)
  }

  @Test("a list written null and a list absent read alike, as none")
  func nullLists() throws {
    let bare = try place {
      $0.media = RestSchema.WaypointMedia {
        $0.links = .some(nil)
        $0.photos = nil
      }
    }

    #expect(bare.details == nil)
  }

  /// An answer is the API's account of what it holds, so an address is the text the wire sent:
  /// one with no scheme, one with a bare percent sign and one Foundation's `URL` would rewrite.
  @Test("an address is carried as the text the wire sent, whatever it holds")
  func addressesAsSent() throws {
    let kept = try place {
      $0.contact = RestSchema.WaypointContact {
        $0.booking_url = URI("HTTPS://REFUGE.example:443/a/../b")
        $0.website = URI("https://refuge.example/sale-50%-off")
      }
      $0.media = RestSchema.WaypointMedia {
        $0.links = [RestSchema.WaypointLink(label: "Topo", url: URI("refuge.example/topo"))]
      }
    }

    #expect(
      kept.details
        == WaypointDetails(
          contact: WaypointDetails.Contact(
            bookingUrl: "HTTPS://REFUGE.example:443/a/../b",
            website: "https://refuge.example/sale-50%-off"),
          media: WaypointDetails.Media(
            links: [WaypointDetails.Link(label: "Topo", url: "refuge.example/topo")])))
  }

  @Test("the services are carried where the wire lists some")
  func amenities() throws {
    let served = try place { $0.amenities = [.water, .hotMeal] }

    #expect(served.details == WaypointDetails(amenities: ["water", "hot-meal"]))
  }

  @Test("a contact keeps the members the wire states, each a line of its own")
  func contact() throws {
    let website = try url("https://refuge.example")
    let reached = try place {
      $0.contact = RestSchema.WaypointContact {
        $0.address = .some(nil)
        $0.phone = "+33 4 50 47 77 70"
        $0.website = website
      }
    }

    #expect(
      reached.details
        == WaypointDetails(
          contact: WaypointDetails.Contact(
            phone: "+33 4 50 47 77 70", website: website.text)))
  }

  @Test("the timing is read onto its own names, a block of nulls reading as none")
  func timing() throws {
    let cutoff = Date(timeIntervalSince1970: 1_782_885_600)
    let stop = try place {
      $0.timing = RestSchema.WaypointTiming {
        $0.cutoff_at = .some(nil)
        $0.stop_duration = 900
      }
    }
    let timed = try place {
      $0.timing = RestSchema.WaypointTiming {
        $0.cutoff_at = cutoff
        $0.stop_duration = 900
      }
    }

    #expect(stop.details == WaypointDetails(timing: WaypointDetails.Timing(stopDuration: 900)))
    #expect(
      timed.details
        == WaypointDetails(timing: WaypointDetails.Timing(cutoffAt: cutoff, stopDuration: 900)))
  }

  /// A `Date` holds any number of seconds, and one whose seconds are not finite is no instant.
  @Test("a cut-off whose seconds are not finite names no instant and is left out")
  func cutoffNamingNoInstant() throws {
    for seconds in [Double.nan, .infinity, -.infinity] {
      let read = try place {
        $0.timing = RestSchema.WaypointTiming {
          $0.cutoff_at = Date(timeIntervalSinceReferenceDate: seconds)
          $0.stop_duration = 600
        }
      }
      let unread = try place {
        $0.timing = RestSchema.WaypointTiming {
          $0.cutoff_at = Date(timeIntervalSinceReferenceDate: seconds)
        }
      }

      #expect(read.details == WaypointDetails(timing: WaypointDetails.Timing(stopDuration: 600)))
      #expect(unread.details == nil)
    }
  }

  @Test("the media keep every photo and link the wire states, each list none where it is empty")
  func media() throws {
    let fountain = try url("https://example.test/fountain.jpg")
    let bench = try url("https://example.test/bench.jpg")
    let timetable = try url("https://example.test/timetable")
    let shown = try place {
      $0.media = RestSchema.WaypointMedia {
        $0.links = [RestSchema.WaypointLink(label: "Timetable", url: timetable)]
        $0.photos = [
          RestSchema.WaypointPhoto(url: fountain) { $0.caption = "The fountain" },
          RestSchema.WaypointPhoto(url: bench) { $0.caption = .some(nil) },
        ]
      }
    }
    let linked = try place {
      $0.media = RestSchema.WaypointMedia {
        $0.links = [RestSchema.WaypointLink(label: "Timetable", url: timetable)]
        $0.photos = []
      }
    }

    #expect(
      shown.details
        == WaypointDetails(
          media: WaypointDetails.Media(
            photos: [
              WaypointDetails.Photo(url: fountain.text, caption: "The fountain"),
              WaypointDetails.Photo(url: bench.text),
            ],
            links: [WaypointDetails.Link(label: "Timetable", url: timetable.text)])))
    #expect(
      linked.details
        == WaypointDetails(
          media: WaypointDetails.Media(
            links: [WaypointDetails.Link(label: "Timetable", url: timetable.text)])))
  }

  /// The order lines a column up across waypoints, and a field with no format reads as text.
  @Test("the fields keep the order they are shown in, each with its format where it states one")
  func properties() throws {
    let fielded = try place {
      $0.properties = [
        RestSchema.WaypointProperty(key: "bib-check", label: "Bib check", value: "Mandatory") {
          $0.format = .some(nil)
        },
        RestSchema.WaypointProperty(key: "drop-bag", label: "Drop bag", value: "3600") {
          $0.format = RestSchema.WaypointPropertyFormat.duration
        },
      ]
    }

    #expect(
      fielded.details
        == WaypointDetails(properties: [
          WaypointDetails.Property(key: "bib-check", label: "Bib check", value: "Mandatory"),
          WaypointDetails.Property(
            key: "drop-bag", label: "Drop bag", value: "3600",
            format: .duration),
        ]))
  }

  /// Text is text: an empty note is what its author wrote, and a card decides what to show.
  @Test("a note is carried as written, an empty one included")
  func description() throws {
    #expect(
      try place { $0.description = "A bench by the fountain." }.details?.description
        == "A bench by the fountain.")
    #expect(try place { $0.description = "" }.details == WaypointDetails(description: ""))
  }

  @Test("an itinerary of no waypoint has no place")
  func empty() {
    #expect(itineraryWaypoints([]).isEmpty)
  }
}
