import Foundation
import MountayaClient
import MountayaElements
import MountayaGeo

#if os(iOS) && !targetEnvironment(macCatalyst)
  import SwiftUI
#endif

/// Search reads the search as an app does: an engine over the app's own client, typed into,
/// confined to a camera, configured again and read as a list a screen of its own draws; the rules
/// under it, a pick's camera and mark, a result's second line and a failed branch; the map's search
/// highlight; and, in an iOS build with the Elements trait, the control over a map and over a
/// transport of the app's own.
enum Search {
  /// engine drives a search over the app's client and reads what its list shows.
  @MainActor
  static func engine(_ mountaya: Mountaya) async -> [String] {
    var configuration = SearchConfiguration(
      fetch: { try await mountaya.data.search(input: $0) }, language: dataLanguageFor("fr-CH"),
      limit: SearchLimit(5), targets: [.pois, .places],
      wording: SearchWording(units: UnitPreferences(language: "fr"), resolveLabel: { _ in nil }),
      onError: { error in _ = error })
    let search = SearchEngine(
      configuration: configuration, query: "refuge",
      camera: MapViewport(center: [6.8652, 45.9237], zoom: 12), isOpen: true, isConfined: true,
      pause: .standard, refreshPause: searchViewportRefreshPause,
      sleep: { try await Task.sleep(for: $0) })
    search.setQuery("refuge du")
    search.setCamera(MapViewport(center: [6.87, 45.92], zoom: 13))
    search.setOpen(false)
    search.setConfined(false)
    configuration.targets = searchSectionOrder
    search.configure(configuration)
    search.retry()
    _ = (search.query, search.isOpen, search.isConfined, search.camera)
    _ = search.configuration.limit?.value
    var read: [String] = []
    for await state in search.subscribe() {
      let list = searchListState(state, filter: .places)
      read += list.rows.map(\.title)
      for section in list.failed {
        if let failure = section.state.failure as? SearchBranchError {
          read.append(
            "\(failure.target.rawValue) \(failure.code?.rawValue ?? "") \(failure.message ?? "")")
        }
      }
      switch list.status {
      case .resultCount(let count)?: read.append("\(count)")
      case let status?: read.append(status.key)
      case nil: break
      }
      _ = (state.query, state.isSearching, state.isSettled, state.hasFallenBack)
      _ = (list.isNothingFound, list.hasFallbackNote)
      _ = state.sections.map { ($0.id, $0.state.isLoading, $0.state.isSettled, $0.rows.count) }
      break
    }
    search.close()
    return read
  }

  /// rules reads the rules under the search: a pick, a list's state, a result's second line and
  /// the language a search asks in.
  static func rules() -> [String] {
    var read: [String] = []
    let pick = pickTarget(
      .way(anchor: [6.86, 45.83], bounds: [6.8, 45.8, 6.9, 45.9], coordinates: nil))
    switch pick.camera {
    case .fit(let bounds)?: read.append("\(bounds)")
    case .fly(let center, let zoom)?: read.append("\(center) \(zoom)")
    case nil: break
    }
    switch pick.mark {
    case .place(let point)?: read.append("\(point)")
    case .poi(let point, let category)?: read.append("\(point) \(category?.rawValue ?? "")")
    case .way(let anchor, let bounds, let coordinates)?:
      read.append("\(anchor) \(bounds ?? []) \(coordinates ?? [])")
    case nil: break
    }
    _ = (
      pointZoom, searchSectionOrder, SearchPick(camera: nil, mark: .place(point: [6.86, 45.83]))
    )
    _ = SearchPickCamera.fly(center: [6.86, 45.83], zoom: pointZoom)
    let snapshot = SearchSnapshot(
      query: "refuge", isSettled: true,
      sections: [
        SearchSection(
          id: .pois,
          state: .failed(SearchBranchError(target: .pois, code: .badGateway, message: "down")))
      ])
    let list = searchListState(snapshot, filter: .all)
    _ = SearchListState(
      rows: list.rows, failed: list.failed, isNothingFound: list.isNothingFound,
      hasFallbackNote: list.hasFallbackNote, status: list.status)
    read.append(
      describePoi(
        DataSchema.POI {
          $0.category = .hut
          $0.elevation = 3_835
          $0.name = "Refuge du Go\u{FB}ter"
        }))
    read.append(
      describePlace(
        DataSchema.Place {
          $0.category = .populatedPlace
          $0.name = "Annecy"
        },
        wording: SearchWording(units: UnitPreferences(language: "en", length: .imperial))
      ))
    read.append(
      describeWay(
        DataSchema.Way {
          $0.highway = "path"
          $0.surface = "gravel"
        }))
    read.append(dataLanguageFor(nil).rawValue)
    let fetch: SearchFetch = { input in DataSchema.SearchResult { $0.query = input.query } }
    _ = fetch
    return read
  }

  /// highlight draws a picked result on the map and takes it down.
  @MainActor
  static func highlight(on map: MapEngine) {
    map.setSearchHighlight(
      .poi(point: [6.86, 45.83], category: .hut), accent: HexColor(hex: "#e9501e"))
    map.setSearchHighlight(.place(point: [6.86, 45.83]))
    map.setSearchHighlight(nil)
  }

  #if os(iOS) && !targetEnvironment(macCatalyst)
    /// TrailSearch is the README's search, compiled for iOS with the Elements trait: the control
    /// over the map, its text and its scope held by the app, in French words.
    struct TrailSearch: View {
      @State private var map: MapEngine
      @State private var query = ""
      @State private var confined = true

      init(mountaya: Mountaya) {
        _map = State(initialValue: MapEngine(client: mountaya))
      }

      var body: some View {
        MapView(map)
          .overlay(alignment: .topLeading) {
            SearchControl(
              map: map, query: $query, isConfined: $confined,
              targets: [.places, .pois, .itineraries], limit: SearchLimit(8),
              units: UnitPreferences(language: "fr"), onError: { error in _ = error }
            )
            .padding()
          }
          .mountayaScope(ElementsScopeStatement(language: .fr))
      }
    }

    /// OwnSearch is a control of no map, searching through a transport of the app's own and routing
    /// a pick its own way.
    struct OwnSearch: View {
      let mountaya: Mountaya
      @State private var picked: SearchRowPayload?

      var body: some View {
        SearchControl(
          map: nil, language: .en, wording: SearchWording(resolveLabel: { _ in nil }),
          fetch: { try await mountaya.data.search(input: $0) },
          strings: ["search.placeholder": "A summit, a hut"],
          onSelect: { row in picked = row.payload })
      }
    }

    /// HeldSearch is a control over an engine the app holds, a typing pause of its own among it,
    /// confined to the visible area of its map as the control's own engine is.
    struct HeldSearch: View {
      let map: MapEngine
      @State private var search: SearchEngine

      init(mountaya: Mountaya, map: MapEngine) {
        self.map = map
        _search = State(
          initialValue: SearchEngine(
            configuration: SearchConfiguration(fetch: { try await mountaya.data.search(input: $0) }
            ),
            isConfined: true, pause: SearchPause(.milliseconds(250)) ?? .standard))
      }

      var body: some View {
        SearchControl(map: map, engine: search)
      }
    }
  #endif
}
