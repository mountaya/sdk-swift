#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  import MountayaClient
  import MountayaGeo
  internal import SwiftUI
  internal import UIKit

  /// ReadoutCard is the readout a right-click or a long press opens on a map, `readout-width`, 288
  /// points, wide, its top-left corner at the point it opened at, flipped to the left of the point
  /// or above it where it would leave the map's safe area, then moved clear of the watermark's frame
  /// by the smallest move, the frame held clear while the read of the organization waits too,
  /// `readoutPlacement` (`map.readout.open`, `geo.readout.rows`, `sdk/SPEC.md` §15), the map's
  /// points read from its left edge in a layout that runs right to left too, and clipped to the
  /// map, so the map's edge cuts a card no place inside the safe area clears the frame for. It
  /// states each row `readoutRows(_:wording:)` answers for what the engine held there, the moment
  /// the map shows read live on the clock of its environment while the card is open
  /// (`geo.layers.overlay-instant`), the band as it was read at the press, in the scope's words and
  /// figures and the SDK's default units, each moment in the time zone the device keeps, `zone`,
  /// never one the app states, and the row or the line that would carry a moment the locale
  /// services cannot write there left out, never written in UTC, as an ISO string or as an empty
  /// word, the classic overlay named in the scope's language as every other word, and the aspect
  /// in whole degrees beside its direction's word, on the panel's ground under the scheme in
  /// force, in the reader's direction. A copy button writes the coordinates' pair to the pasteboard
  /// and reads `readout.copied` for a second.
  ///
  /// It reads the engine's readout, its read of its organization and the map's safe area, which a
  /// press, a tap, a camera move, an answer and a turn of the device change, so SwiftUI draws it
  /// again for those and never per frame of the map.
  struct ReadoutCard: View {
    let engine: MapEngine

    @ViewScope private var scope: ElementsScope
    @Environment(\.mountayaClock) private var clock
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.layoutDirection) private var direction
    /// copied is the readout whose coordinates were copied last, which reads `readout.copied`
    /// until a second has passed.
    @State private var copied: Int?
    /// height is how tall the card was laid out last, which it is held within the map by, a card's
    /// usual height before it was.
    @State private var height: CGFloat = 160

    init(engine: MapEngine) {
      self.engine = engine
      _scope = ViewScope(strings: nil)
    }

    /// zone is how the card reads the time zone it writes each moment in: the one the device keeps,
    /// `deviceTimeZone()`, unless a test of this package states another.
    static var zone: () -> String = deviceTimeZone

    var body: some View {
      if let readout = engine.readout {
        GeometryReader { proxy in
          let placed = Self.anchor(
            readout.point, in: proxy.size, safeArea: engine.safeArea, height: height,
            clearOf: isWatermarkKeptClear(engine.organizationRead)
              ? MeasuredMapView.cgRect(watermarkFrame(safeArea: engine.safeArea)) : nil)
          card(readout)
            .environment(\.layoutDirection, direction)
            .frame(width: ElementLayout.readoutWidth)
            .fixedSize(horizontal: false, vertical: true)
            .onGeometryChange(for: CGFloat.self) { proxy in
              proxy.size.height
            } action: { measured in
              height = measured
            }
            .offset(placed)
        }
        // The map's edge cuts a card that no place inside the safe area clears the frame for.
        .clipped()
        // The map's points run from its left edge whatever the reader's direction.
        .environment(\.layoutDirection, .leftToRight)
      }
    }

    /// anchor is where the card's top-left corner stands for a readout opened at `point`, the card
    /// `height` tall, on a map of `size` whose safe area stands `safeArea` inside its edges and whose
    /// watermark's frame, held clear, is `frame`: at the point, flipped to stay inside the safe area,
    /// then moved clear of the frame by the smallest move (`readoutPlacement`).
    static func anchor(
      _ point: [Double], in size: CGSize, safeArea: PixelPadding, height: CGFloat,
      clearOf frame: CGRect?
    ) -> CGSize {
      let placed = readoutPlacement(
        at: point, cardHeight: Double(height),
        within: safeAreaBounds(safeArea, width: Double(size.width), height: Double(size.height)),
        clearOf: frame.map(MeasuredMapView.screenRect))
      return CGSize(width: placed.x, height: placed.y)
    }

    /// card is the readout's rows, on the panel's ground.
    private func card(_ readout: MapReadout) -> some View {
      let scheme = themeScheme(colorScheme)
      var facts = readout.facts(in: scope.language)
      facts.instant = overlayInstant(pinned: engine.instant, now: clock.now)
      let rows = readoutRows(facts, wording: SearchWording())
      let shape = RoundedRectangle(cornerRadius: 8)
      return VStack(alignment: .leading, spacing: 8) {
        ForEach(Array(rows.enumerated()), id: \.offset) { _, row in
          self.row(row, number: readout.number)
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
      .font(.footnote)
      .foregroundStyle(tokenColor(tokens.value.panelFg, in: scheme))
      .background(tokenColor(tokens.value.panelBg, in: scheme), in: shape)
      .overlay(shape.strokeBorder(tokenColor(tokens.value.panelBorder, in: scheme)))
    }

    /// units is how the readout states its figures: the SDK's default units in the scope's
    /// language.
    private var units: UnitPreferences {
      UnitPreferences(language: scope.language.rawValue)
    }

    /// moment writes an instant as a medium date with a short time in the time zone the device
    /// keeps, or nothing where the locale services know no zone of its name.
    private func moment(_ instant: Date) -> String? {
      Self.moment(instant, locale: scope.locale)
    }

    /// moment writes `instant` as a medium date with a short time in `locale`, in the time zone the
    /// device keeps, `zone`, whatever time zone the view's environment states, or nil where the
    /// locale services know no zone of that name, so the row that would carry it is left out
    /// rather than written in another zone, as an ISO string or as an empty word
    /// (`sdk/SPEC.md` §15).
    static func moment(_ instant: Date, locale: String) -> String? {
      formatDateTime(
        instant, locale: locale, timeZone: zone(), dateLength: .medium, timeLength: .short)
    }

    /// windowMoments writes the bounds a zone's window states, `start` and `end`, each a moment
    /// in `locale` and the device's zone (`moment(_:locale:)`), as the values its word is filled
    /// with, or nil where a bound it states cannot be written, so the window is left out whole
    /// rather than written with a bound missing.
    static func windowMoments(start: Date?, end: Date?, locale: String) -> [String: String]? {
      switch (start.map { moment($0, locale: locale) }, end.map { moment($0, locale: locale) }) {
      case (.some(nil), _), (_, .some(nil)): nil
      case (.some(.some(let start)), .some(.some(let end))): ["start": start, "end": end]
      case (.some(.some(let start)), nil): ["start": start]
      case (nil, .some(.some(let end))): ["end": end]
      case (nil, nil): [:]
      }
    }

    /// figure writes a band's value in its measure.
    private func figure(_ value: Double, measure: ReadoutMeasure, pace: RestSchema.UnitPace?)
      -> String
    {
      var units = units
      if let pace { units.pace = pace }
      switch measure {
      case .temperature: return formatTemperature(value, units: units)
      case .humidity: return formatHumidity(value, units: units)
      case .snowfall: return formatSnowfall(value, units: units)
      case .distance: return formatDistance(value, units: units)
      case .speed: return formatSpeed(value, units: units)
      }
    }

    /// row draws one row of the readout.
    @ViewBuilder
    private func row(_ row: ReadoutRow, number: Int) -> some View {
      switch row {
      case .poi(let name, _, let label):
        VStack(alignment: .leading, spacing: 2) {
          if let name { Text(verbatim: name).font(.subheadline.weight(.semibold)) }
          Text(verbatim: label).foregroundStyle(.secondary)
        }
      case .band(let overlay, let measure, let pace, let values, let word, let time):
        let written = values.map { figure($0, measure: measure, pace: pace) }
        let band =
          word.map {
            filledText(
              scope.word($0), values: ["min": written.first ?? "", "max": written.last ?? ""])
          } ?? (written.first ?? "")
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: overlay).font(.subheadline.weight(.semibold))
          Text(verbatim: band)
          if let time, let written = moment(time) {
            Text(
              verbatim: filledText(scope.word("readout.overlayTime"), values: ["moment": written])
            )
            .foregroundStyle(.secondary)
          }
        }
      case .terrain(let readings):
        VStack(alignment: .leading, spacing: 2) {
          ForEach(Array(readings.enumerated()), id: \.offset) { _, reading in
            self.reading(reading)
          }
        }
      case .instant(let instant):
        if let written = moment(instant) {
          Text(
            verbatim: filledText(scope.word("readout.overlayTime"), values: ["moment": written]))
        }
      case .coordinates(let text, let copy):
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: scope.word("readout.coordinates")).foregroundStyle(.secondary)
          Text(verbatim: text).monospacedDigit()
          Button {
            UIPasteboard.general.string = copy
            copied = number
            Task { @MainActor in
              try? await Task.sleep(for: .seconds(1))
              if copied == number { copied = nil }
            }
          } label: {
            Text(
              verbatim: scope.word(
                copied == number ? "readout.copied" : "readout.copyCoordinates"))
          }
          .buttonStyle(.borderless)
          .tint(tokenColor(tokens.value.accent, in: themeScheme(colorScheme)))
        }
      case .zoomIn:
        Text(verbatim: scope.word("readout.zoomInForDetails")).foregroundStyle(.secondary)
      case .zone(let name, let description, let level, let levelWord, let color, let window):
        VStack(alignment: .leading, spacing: 2) {
          Text(verbatim: scope.word("readout.zone")).foregroundStyle(.secondary)
          if let name { Text(verbatim: name).font(.subheadline.weight(.semibold)) }
          if let description { Text(verbatim: description) }
          Text(verbatim: levelWord.map { scope.word($0) } ?? level.rawValue)
            .foregroundStyle(hexColor(HexColor(hex: color)))
          if let window,
            let values = Self.windowMoments(
              start: window.start, end: window.end, locale: scope.locale)
          {
            Text(verbatim: filledText(scope.word(window.word), values: values))
          }
        }
      }
    }

    /// reading draws one reading of the terrain, under its word.
    @ViewBuilder
    private func reading(_ reading: ReadoutRow.Reading) -> some View {
      HStack(spacing: 6) {
        Text(verbatim: scope.word(reading.word)).foregroundStyle(.secondary)
        switch reading {
        case .altitude(let meters):
          Text(verbatim: formatElevation(meters, units: units))
        case .slope(let degrees, let color):
          Circle().fill(hexColor(HexColor(hex: color))).frame(width: 8, height: 8)
          Text(verbatim: formatSlope(degrees, units: units))
        case .aspect(let degrees, let cardinal):
          Text(
            verbatim: formatAspect(
              degrees, cardinalWord: scope.word("readout.aspects.\(cardinal.rawValue)"),
              language: scope.language.rawValue))
        }
      }
    }
  }
#endif
