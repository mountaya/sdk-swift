import MountayaElements
import MountayaGeo
import MountayaNavigation
import SwiftUI

/// MapScreen is Trail's one portrait screen: the map, drawn full screen under its controls, with
/// a search box over it, and a sheet holding the navigation and the itinerary's elevation profile,
/// and its tables once opened. With no publishable key, a notice stands in place of the map and
/// the search, and the rest runs on the demo itinerary.
///
/// The map is drawn full bleed, under the status bar and around a notch or a Dynamic Island, and
/// its Mountaya watermark stands in the top-left corner of the part of the screen the device leaves
/// visible, where nothing of Trail's own covers it: the search box starts below it, and the sheet,
/// however much it holds, never rises past `watermarkClearance` below that part's top.
struct MapScreen: View {
  @Bindable var model: AppModel

  /// belowTheMark is how far under the top of the screen's visible part the search box starts: the
  /// watermark's frame ends `watermarkClearance` points down, the extent MountayaGeo publishes,
  /// and the box keeps 8 more.
  static let belowTheMark = CGFloat(watermarkClearance) + 8

  /// aboveTheSheet is the least room kept over the sheet, from the top of the screen's visible
  /// part: `watermarkClearance`, the bottom of the frame the watermark stands in, so however much
  /// the sheet holds its top is capped there and the tables it opens onto scroll inside what is
  /// left rather than cover the mark. The search box, standing below the mark, keeps more.
  static let aboveTheSheet = CGFloat(watermarkClearance)

  var body: some View {
    ZStack {
      if let map = model.map {
        // trail: trail.map
        MapView(map, onReady: { _ in model.mapIsReady() })
          .ignoresSafeArea()
          .overlay {
            MapControls(
              map, zoom: true, compass: true, geolocate: true, layers: true, pois: true,
              preferences: true, openPanel: $model.openPanel, unitPreferences: $model.units,
              offersTime: true)
          }
      } else {
        Color(uiColor: .secondarySystemBackground)
          .ignoresSafeArea()
      }
      VStack(spacing: 0) {
        top
          .padding(.horizontal, 12)
          .padding(.top, model.map == nil ? 8 : Self.belowTheMark)
          .frame(minHeight: Self.aboveTheSheet, alignment: .top)
        Spacer(minLength: 0)
        ItinerarySheet(model: model)
      }
    }
    .task { await model.voice.prepare() }
    .task { await model.showTerrain() }
    .task { await model.drawItinerary() }
  }

  /// top is what stands over the map: the search box and the map's own notice, or the notice in
  /// place of both where no key is set.
  @ViewBuilder private var top: some View {
    if let map = model.map {
      VStack(alignment: .leading, spacing: 8) {
        // trail: trail.search
        // The Data API answers a publishable key only beside a session token, so without a
        // session URL the box is disabled and says why.
        SearchControl(
          map: map, units: model.units,
          strings: model.sessions == nil ? ["search.placeholder": Words.searchNeedsSession] : nil
        )
        .disabled(model.sessions == nil)
        // trail: trail.no-key
        // The map holds the refusal itself, until a source it refused loads again.
        if map.state.isAccessRequired {
          NoticeCard(text: Words.mapRefused)
        }
      }
      // Clear of the map's controls, in the top right corner, and of its watermark, above it.
      .padding(.trailing, 60)
      .frame(maxWidth: .infinity, alignment: .leading)
    } else {
      // trail: trail.no-key
      NoticeCard(text: Words.notice)
        .accessibilityIdentifier("trail.notice")
    }
  }
}

/// NoticeCard is a line of Trail's own words on a card, standing where Trail cannot show what it
/// would.
struct NoticeCard: View {
  let text: String

  var body: some View {
    Text(text)
      .font(.callout)
      .foregroundStyle(.primary)
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        Color(uiColor: .systemBackground),
        in: RoundedRectangle(cornerRadius: 12, style: .continuous)
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous).strokeBorder(.orange, lineWidth: 1))
  }
}
