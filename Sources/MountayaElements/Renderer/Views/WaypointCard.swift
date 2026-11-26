#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import Foundation
  import MountayaClient
  public import MountayaGeo
  public import SwiftUI

  /// WaypointCard is a card about one place of an itinerary: its mark and its name, the line under
  /// it, and what it records, its services by name, when it can be used, how to reach it, its own
  /// fields, its links and its photos, each section drawn only where it states a line
  /// (`geo.profile.waypoint-card`).
  ///
  /// ```swift
  /// WaypointCard(place: place, formatCutoffAt: { $0.formatted(date: .omitted, time: .shortened) })
  /// ```
  ///
  /// The line under the name is the author's description, else the summary the place's record
  /// assembles. A cut-off, and a `date` field, are written only by `formatCutoffAt`, the time zone
  /// being the app's. A phone, an email, a website, a booking page, a link field and a media link
  /// are each a link only where `waypointCard(_:scope:units:formatCutoffAt:)` gives it an address,
  /// a website or a booking page only at a web address, so no script is ever tapped; a photo is
  /// drawn only from a web address, by the view the app's `photo` builds where it hands one, its
  /// own image loader's or its cache's, and loaded by `AsyncImage` otherwise. A place that records
  /// nothing says so.
  ///
  /// ```swift
  /// WaypointCard(place: place) { photo in
  ///   CachedImage(url: photo.url).accessibilityLabel(photo.caption ?? "")
  /// }
  /// ```
  ///
  /// Its words are the scope's `waypointCard` and `amenities` sections, each replaced by `strings`
  /// where it names the word's path, its glyphs the scope's marker set, its figures written in
  /// `units`, and its colours the tokens'.
  public struct WaypointCard: View {
    private let place: ItineraryPlace
    private let units: UnitPreferences?
    private let formatCutoffAt: ((Date) -> String)?
    private let strings: [String: String]?
    /// photo draws each photo, where the app hands a view of its own for it.
    private let photo: ((WaypointDetails.Photo) -> AnyView)?

    @ViewScope private var scope: ElementsScope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    /// Creates the card of `place`, its figures in `units`, a cut-off written by `formatCutoffAt`,
    /// its words replaced by `strings` where it names theirs, each photo loaded from its web address
    /// by `AsyncImage`.
    public init(
      place: ItineraryPlace, units: UnitPreferences? = nil,
      formatCutoffAt: ((Date) -> String)? = nil, strings: [String: String]? = nil
    ) {
      self.place = place
      self.units = units
      self.formatCutoffAt = formatCutoffAt
      self.strings = strings
      photo = nil
      _scope = ViewScope(strings: strings)
    }

    /// Creates the card of `place`, its figures in `units`, a cut-off written by `formatCutoffAt`,
    /// its words replaced by `strings` where it names theirs, each photo at a web address drawn by
    /// the view `photo` builds for it, the app's own image loader's or its cache's.
    public init<Photo: View>(
      place: ItineraryPlace, units: UnitPreferences? = nil,
      formatCutoffAt: ((Date) -> String)? = nil, strings: [String: String]? = nil,
      @ViewBuilder photo: @escaping (WaypointDetails.Photo) -> Photo
    ) {
      self.place = place
      self.units = units
      self.formatCutoffAt = formatCutoffAt
      self.strings = strings
      self.photo = { AnyView(photo($0)) }
      _scope = ViewScope(strings: strings)
    }

    /// body is the card on the panel's ground.
    public var body: some View {
      let scheme = themeScheme(colorScheme)
      let facts = waypointCard(
        place.details, scope: scope, units: units ?? UnitPreferences(language: scope.locale),
        formatCutoffAt: formatCutoffAt)
      PanelSurface {
        header(facts, scheme: scheme)
        if facts.isEmpty {
          VStack(alignment: .leading, spacing: 2) {
            Text(verbatim: scope.word("waypointCard.empty")).font(.subheadline.weight(.semibold))
            Text(verbatim: scope.word("waypointCard.emptyHint")).font(.footnote)
              .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
          }
        }
        if !facts.services.isEmpty {
          section("waypointCard.amenities") {
            FlowingServices(services: facts.services)
          }
        }
        if !facts.timing.isEmpty {
          section("waypointCard.timing") { lines(facts.timing) }
        }
        if !facts.contact.isEmpty {
          section("waypointCard.contact") { lines(facts.contact) }
        }
        if !facts.fields.isEmpty {
          section("waypointCard.properties") {
            lines(
              facts.fields.map {
                WaypointCardFacts.Line(
                  label: $0.label, value: $0.value, href: $0.href, isExternal: $0.href != nil)
              })
          }
        }
        if !facts.links.isEmpty || !facts.photos.isEmpty {
          section("waypointCard.media") {
            ForEach(Array(facts.photos.enumerated()), id: \.offset) { _, photo in
              if let drawn = self.photo {
                drawn(photo)
              } else if let url = URL(string: photo.url) {
                AsyncImage(url: url) { image in
                  image.resizable().scaledToFit()
                } placeholder: {
                  tokenColor(tokens.panelBorder, in: scheme)
                }
                .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 160)
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .accessibilityLabel(Text(verbatim: photo.caption ?? place.name ?? ""))
              }
            }
            ForEach(Array(facts.links.enumerated()), id: \.offset) { _, link in
              if let href = link.href, let url = URL(string: href) {
                Link(destination: url) { Text(verbatim: link.label) }.font(.subheadline)
              } else {
                Text(verbatim: link.label).font(.subheadline)
              }
            }
          }
        }
      }
      .viewWords(scope, stated: strings)
    }

    /// The card's head: the place's mark, its name and the line under it.
    private func header(_ facts: WaypointCardFacts, scheme: ThemeScheme) -> some View {
      HStack(alignment: .top, spacing: 10) {
        let glyph = placeGlyph(place.glyph?.rawValue, in: scope.markerGlyphs)
        Circle()
          .fill(
            place.color.map { hexColor(HexColor(hex: $0)) }
              ?? tokenColor(tokens.waypointCardMarkColor, in: scheme)
          )
          .overlay {
            if let glyph {
              Glyph(glyph, in: scope.markerGlyphs, size: 18, ink: .foreground)
                .foregroundStyle(tokenColor(tokens.waypointCardMarkFg, in: scheme))
            }
          }
          .frame(width: 32, height: 32)
          .accessibilityHidden(true)
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: place.name ?? scope.word("profile.unlabelledWaypoint"))
            .font(.headline)
            .accessibilityAddTraits(.isHeader)
          if let headline = facts.headline {
            Text(verbatim: headline).font(.footnote)
              .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
          }
        }
      }
    }

    /// A section of the card under its heading.
    private func section(_ word: String, @ViewBuilder _ content: () -> some View) -> some View {
      VStack(alignment: .leading, spacing: 4) {
        PanelHeading(text: scope.word(word))
        content()
      }
    }

    /// Labelled lines, each a link where it has an address.
    private func lines(_ lines: [WaypointCardFacts.Line]) -> some View {
      ForEach(Array(lines.enumerated()), id: \.offset) { _, line in
        HStack(alignment: .firstTextBaseline, spacing: 8) {
          Text(verbatim: line.label).font(.footnote).opacity(0.7)
          if let href = line.href, let url = URL(string: href) {
            Link(destination: url) { Text(verbatim: line.value) }.font(.subheadline)
          } else {
            Text(verbatim: line.value).font(.subheadline)
          }
        }
        .accessibilityElement(children: .combine)
      }
    }
  }

  /// FlowingServices is a place's services, each its glyph of the scope's marker set and its name,
  /// laid in rows that wrap.
  struct FlowingServices: View {
    let services: [WaypointCardFacts.Service]

    @Environment(\.sharedScope) private var scope

    var body: some View {
      VStack(alignment: .leading, spacing: 4) {
        ForEach(Array(services.enumerated()), id: \.offset) { _, service in
          HStack(spacing: 6) {
            let glyph = amenityGlyph(service.amenity)
            if scope.markerGlyphs.markup[glyph] != nil {
              Glyph(glyph, in: scope.markerGlyphs, size: 14, ink: .foreground)
            }
            Text(verbatim: service.name).font(.subheadline)
          }
          .accessibilityElement(children: .combine)
        }
      }
    }
  }
#endif
