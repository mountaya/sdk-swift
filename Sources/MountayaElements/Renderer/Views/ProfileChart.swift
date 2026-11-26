#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  import MountayaClient
  import MountayaGeo
  internal import SwiftUI

  /// ProfileChart is an itinerary's curve and what stands on it, the plot of an
  /// `ItineraryProfile`: the area under the curve and its line in the accent, or in the gradient
  /// its coloured stretches paint (`geo.profile.curve-stops`), the leg a reader points at tinted
  /// under it, the elevation scale's lines, the drop line under each place that divides the
  /// itinerary, a dashed mark at each cut-off, a pin on the curve at each place with its services
  /// stacked above it, the cursor, and the card that states what the cursor stands on.
  ///
  /// Everything stands where the profile's rules place it in the 100-unit square stretched over the
  /// chart (`geo.profile.plot-scale`, `geo.profile.curve-placement`). The curve is built once for
  /// its series, domain and window and held in `curves`, and drawn in a layer of its own under the
  /// cursor's. The chart never reads where the cursor stands: its cursor's layer, its card and what
  /// assistive technologies read of it each read `cursor`, so a scrub, which moves the cursor alone,
  /// redraws them alone, never the chart, its curve or its pins. A pin a reader can press is pressed
  /// anywhere in the platform's touch target around it. A scrub reads the pointer through the
  /// window's 240 columns, each standing for the sample nearest its centre
  /// (`geo.profile.scrub-grid`), so the cursor stands on a sample and never between two; a key press
  /// or an assistive technology's adjustment steps it a sample at a time. A disabled chart draws
  /// and drives nothing.
  struct ProfileChart: View {
    let series: ElevationSeries
    let domain: ElevationDomain
    let window: ProfileRange
    let painted: [CurveColor]
    let placement: CurvePlacement
    let stacks: [AmenityStack]
    let lit: ProfileRange?
    /// cursor holds where the profile's cursor stands, which the parts it moves read.
    let cursor: ProfileCursor
    /// tooltip is whether the card at the cursor is drawn, naming the stretch of `stretches` the
    /// cursor stands in.
    let tooltip: Bool
    let stretches: [ProfileClass]
    let showsElevationAxis: Bool
    let units: UnitPreferences
    let formatCutoffAt: ((Date) -> String)?
    let onScrub: (Int?) -> Void
    let onWaypointTap: ((String) -> Void)?
    /// curves holds the curve across the chart's renders, which the profile keeps for as long as it
    /// shows; a chart handed none builds its curve for itself.
    var curves = ProfileCurves()

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.renderProbe) private var probe

    /// pinSide is a pin's side, in points.
    static let pinSide: CGFloat = 20

    var body: some View {
      let _ = probe?.report("ProfileChart")
      let _ = probe?.chart(curves: curves, scrub: onScrub)
      let scheme = themeScheme(colorScheme)
      let grid = scrubGrid(series.points, window: window)
      GeometryReader { proxy in
        let size = proxy.size
        ZStack(alignment: .topLeading) {
          plot(in: size, scheme: scheme)
            .accessibilityElement()
            .accessibilityLabel(Text(verbatim: scope.word("profile.chart")))
            .modifier(ProfileCursorValue(cursor: cursor, series: series, units: units))
            .accessibilityAdjustableAction { direction in
              guard isEnabled else { return }
              step(direction == .increment ? 1 : -1)
            }
          if showsElevationAxis {
            ForEach(Array(domainTicks(domain).enumerated()), id: \.offset) { _, tick in
              Text(verbatim: formatElevation(tick, units: units))
                .font(.caption2)
                .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
                .position(
                  x: 4 + 24, y: profileY(tick, domain: domain) / profileViewBox * size.height
                )
                .accessibilityHidden(true)
            }
          }
          ForEach(placement.cutoffs, id: \.key) { cutoff in
            if let formatCutoffAt {
              Text(verbatim: formatCutoffAt(cutoff.cutoffAt))
                .font(.caption2)
                .foregroundStyle(tokenColor(tokens.dimmed, in: scheme))
                .fixedSize()
                .position(x: cutoff.x / profileViewBox * size.width, y: 6)
                .accessibilityLabel(
                  Text(
                    verbatim: scope.word("profile.cutoff") + ", " + formatCutoffAt(cutoff.cutoffAt))
                )
            }
          }
          ForEach(stacks, id: \.pin.key) { stack in
            AmenityStackBadges(stack: stack, scheme: scheme)
              .position(
                x: stack.pin.x / profileViewBox * size.width,
                y: stack.pin.y / profileViewBox * size.height - Self.pinSide - 12)
          }
          ForEach(placement.pins, id: \.key) { pin in
            ProfilePin(
              pin: pin,
              fill: pin.place.color.map { hexColor(HexColor(hex: $0)) }
                ?? tokenColor(tokens.profileWaypointColor, in: scheme),
              name: pin.place.name ?? scope.word("profile.unlabelledWaypoint"),
              onTap: onWaypointTap.map { onTap in { onTap(pin.place.id) } }
            )
            .position(
              x: pin.x / profileViewBox * size.width,
              y: pin.y / profileViewBox * size.height - Self.pinSide / 2)
          }
          if tooltip {
            ProfileCursorCard(
              cursor: cursor, series: series, window: window, stretches: stretches, units: units,
              scheme: scheme, size: size)
          }
        }
        .contentShape(Rectangle())
        .gesture(scrub(grid: grid, width: size.width), including: isEnabled ? .all : .subviews)
        .onContinuousHover { phase in
          guard isEnabled else { return }
          switch phase {
          case .active(let location):
            onScrub(Self.sample(at: location.x, width: size.width, grid: grid))
          case .ended:
            onScrub(nil)
          }
        }
      }
      .accessibilityElement(children: .contain)
    }

    /// The plot: the curve and the marks standing on it in a layer of their own, which SwiftUI draws
    /// again only where one of them changes, and the cursor over them in another, which a scrub
    /// draws again alone.
    private func plot(in size: CGSize, scheme: ThemeScheme) -> some View {
      let accent = tokenColor(tokens.accent, in: scheme)
      let total = series.totalDistance
      let litSpan = lit.map { lit in
        let start = profileX(lit.from, totalDistance: total, window: window)
        return start...max(start, profileX(lit.to, totalDistance: total, window: window))
      }
      return ZStack {
        ProfileCurveLayer(
          curve: curves.curve(series, domain: domain, window: window),
          stops: curveStops(painted, totalDistance: total, window: window), lit: litSpan,
          ticks: showsElevationAxis ? domainTicks(domain).map { profileY($0, domain: domain) } : [],
          dividers: placement.dividers, cutoffs: placement.cutoffs,
          colors: ProfileCurveLayer.Colors(
            accent: themeTokenValue(tokens.accent, in: scheme),
            grid: themeTokenValue(tokens.profileGridColor, in: scheme),
            litFill: themeTokenValue(tokens.profileLitFill, in: scheme),
            dropLine: themeTokenValue(tokens.profileWaypointLine, in: scheme),
            dimmed: themeTokenValue(tokens.dimmed, in: scheme)),
          size: size, curves: curves
        )
        .equatable()
        ProfileCursorLayer(
          cursor: cursor, series: series, domain: domain, window: window,
          rule: tokenColor(tokens.profileCursor, in: scheme), dot: accent,
          dash: themeTokenValue(tokens.profileCursorDash, in: scheme).map { CGFloat($0) },
          curves: curves)
      }
      .frame(width: size.width, height: size.height)
    }

    /// Where the readout card stands: beside the cursor at `sample`, on the side with room, kept in
    /// a chart of `size` drawing `window` of an itinerary `totalDistance` long.
    static func cardPosition(
      for sample: ElevationPoint, totalDistance: Double, window: ProfileRange, in size: CGSize
    ) -> CGPoint {
      let x =
        profileX(sample.distance, totalDistance: totalDistance, window: window)
        / profileViewBox * size.width
      let side: CGFloat = x > size.width / 2 ? -70 : 70
      return CGPoint(x: min(max(x + side, 60), max(60, size.width - 60)), y: 36)
    }

    /// The scrub over the chart: each touch reads the column under it, and lifting it leaves.
    private func scrub(grid: [Int?], width: CGFloat) -> some Gesture {
      DragGesture(minimumDistance: 0)
        .onChanged { onScrub(Self.sample(at: $0.location.x, width: width, grid: grid)) }
        .onEnded { _ in onScrub(nil) }
    }

    /// sample is the sample the column under `x` of a chart `width` wide resolves to.
    static func sample(at x: CGFloat, width: CGFloat, grid: [Int?]) -> Int? {
      guard width > 0, !grid.isEmpty else { return nil }
      let column = Int((x / width * CGFloat(grid.count)).rounded(.down))
      return grid[min(max(column, 0), grid.count - 1)]
    }

    /// Steps the cursor a sample along the window, from its first sample where none stands.
    private func step(_ by: Int) {
      let inside = series.points.filter { $0.distance >= window.from && $0.distance <= window.to }
      guard let first = inside.first, let last = inside.last else { return }
      guard let standing = cursor.sample(in: series) else {
        onScrub(first.index)
        return
      }
      onScrub(min(max(standing.index + by, first.index), last.index))
    }
  }

  /// ProfileCursorValue states what a profile's cursor stands on to assistive technologies, its
  /// distance and its altitude in the reader's units. It reads the cursor apart from the chart, so a
  /// scrub states it again and redraws nothing of the chart.
  struct ProfileCursorValue: ViewModifier {
    let cursor: ProfileCursor
    let series: ElevationSeries
    let units: UnitPreferences

    func body(content: Content) -> some View {
      let text =
        cursor.sample(in: series).map {
          [formatDistance($0.distance, units: units), formatElevation($0.elevation, units: units)]
            .joined(separator: ", ")
        } ?? ""
      content.accessibilityValue(Text(verbatim: text))
    }
  }

  /// ProfileCursorCard is the card at a profile's cursor, standing beside the sample the cursor
  /// stands on and stating it, or nothing where the cursor stands on none. It reads the cursor
  /// itself, so a scrub redraws the card and nothing of the chart around it.
  struct ProfileCursorCard: View {
    let cursor: ProfileCursor
    let series: ElevationSeries
    let window: ProfileRange
    /// stretches is the stretches the card names the one the cursor stands in from.
    let stretches: [ProfileClass]
    let units: UnitPreferences
    let scheme: ThemeScheme
    /// size is the chart's size, in points, which the card is kept in.
    let size: CGSize

    var body: some View {
      if let sample = cursor.sample(in: series) {
        ProfileReadoutCard(
          readout: profileReadout(series, at: sample, stretches: stretches), units: units,
          scheme: scheme
        )
        .fixedSize()
        .position(
          ProfileChart.cardPosition(
            for: sample, totalDistance: series.totalDistance, window: window, in: size))
      }
    }
  }

  /// ProfileCurveLayer is the layer of a profile's chart that the curve and what stands on it are
  /// drawn in: the elevation scale's lines, the leg a reader points at tinted under the curve, the
  /// area under the curve and its line in the accent, or in the gradient its coloured stretches
  /// paint (`geo.profile.curve-stops`), the drop line under each place that divides the itinerary
  /// and a dashed mark at each cut-off. Everything it takes stands in the chart's 100-unit square.
  ///
  /// It is drawn once for what it takes, into an image `ProfileCurves` holds, and shows that image
  /// until what it takes changes, which SwiftUI reads by its `==`: a scrub, which changes none of
  /// it, draws nothing of it again, whatever SwiftUI renders around it.
  struct ProfileCurveLayer: View, Equatable {
    /// Colors is what the layer is drawn in, each token's value under the scheme in force, which
    /// two layers compare by.
    struct Colors: Equatable {
      let accent: HexColor
      let grid: HexColor
      let litFill: HexColor
      let dropLine: HexColor
      let dimmed: HexColor
    }

    let curve: ProfileCurve
    let stops: [CurveStop]
    /// lit is the stretch across the square tinted under the curve, or nil for none.
    let lit: ClosedRange<Double>?
    /// ticks is where each line of the elevation scale stands down the square.
    let ticks: [Double]
    let dividers: [CurveDivider]
    let cutoffs: [CurveCutoff]
    let colors: Colors
    /// size is the chart's size, in points, which the layer is drawn at.
    let size: CGSize
    let curves: ProfileCurves

    @Environment(\.displayScale) private var scale

    var body: some View {
      Image(uiImage: curves.drawn(self, scale: scale))
        .frame(width: size.width, height: size.height)
        .accessibilityHidden(true)
    }

    /// canvas is the layer on a canvas of its size, which `ProfileCurves` renders into the image
    /// the layer shows, once for each thing it takes.
    var canvas: some View {
      let accent = hexColor(colors.accent)
      let grid = hexColor(colors.grid)
      let litFill = hexColor(colors.litFill)
      let dropLine = hexColor(colors.dropLine)
      let dimmed = hexColor(colors.dimmed)
      return Canvas { context, size in
        let across = { (x: Double) in x / profileViewBox * size.width }
        let down = { (y: Double) in y / profileViewBox * size.height }
        let area = ProfileCurve.scaled(curve.area, to: size)
        let line = ProfileCurve.scaled(curve.line, to: size)
        context.clip(to: Path(CGRect(origin: .zero, size: size)))
        for tick in ticks {
          var rule = Path()
          rule.move(to: CGPoint(x: 0, y: down(tick)))
          rule.addLine(to: CGPoint(x: size.width, y: down(tick)))
          context.stroke(rule, with: .color(grid), lineWidth: 1)
        }
        if let lit {
          let start = across(lit.lowerBound)
          let end = across(lit.upperBound)
          var tinted = context
          tinted.clip(to: Path(CGRect(x: start, y: 0, width: end - start, height: size.height)))
          tinted.fill(area, with: .color(litFill))
        }
        if stops.isEmpty {
          context.fill(area, with: .color(accent.opacity(0.18)))
          context.stroke(
            line, with: .color(accent), style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        } else {
          let gradient = Gradient(
            stops: stops.map {
              Gradient.Stop(
                color: $0.color.flatMap { hexColor(HexColor(hex: $0)) } ?? accent,
                location: $0.offset)
            })
          let shading = GraphicsContext.Shading.linearGradient(
            gradient, startPoint: .zero, endPoint: CGPoint(x: size.width, y: 0))
          var faded = context
          faded.opacity = 0.18
          faded.fill(area, with: shading)
          context.stroke(line, with: shading, style: StrokeStyle(lineWidth: 2, lineJoin: .round))
        }
        for divider in dividers {
          guard let y = divider.y else { continue }
          var drop = Path()
          drop.move(to: CGPoint(x: across(divider.x), y: down(y)))
          drop.addLine(to: CGPoint(x: across(divider.x), y: size.height))
          context.stroke(
            drop, with: .color(dropLine), style: StrokeStyle(lineWidth: 1, dash: [2, 2]))
        }
        for cutoff in cutoffs {
          var mark = Path()
          mark.move(to: CGPoint(x: across(cutoff.x), y: 12))
          mark.addLine(to: CGPoint(x: across(cutoff.x), y: size.height))
          context.stroke(
            mark, with: .color(dimmed), style: StrokeStyle(lineWidth: 1, dash: [4, 3]))
        }
      }
      .frame(width: size.width, height: size.height)
    }

    /// Look is everything the layer draws, which two of its images compare by: what it takes but
    /// the store that holds it, so the store keeps a look without keeping itself.
    struct Look: Equatable {
      let curve: ProfileCurve
      let stops: [CurveStop]
      let lit: ClosedRange<Double>?
      let ticks: [Double]
      let dividers: [CurveDivider]
      let cutoffs: [CurveCutoff]
      let colors: Colors
      let size: CGSize
    }

    /// look is everything the layer draws.
    nonisolated var look: Look {
      Look(
        curve: curve, stops: stops, lit: lit, ticks: ticks, dividers: dividers, cutoffs: cutoffs,
        colors: colors, size: size)
    }

    /// Two layers draw alike where they draw the same look, in one chart.
    nonisolated static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.look == rhs.look && lhs.curves === rhs.curves
    }
  }

  /// ProfileCursorLayer is the layer of a profile's chart that its cursor is drawn in: a dashed
  /// rule across the chart at the sample the cursor stands on, and a dot on the curve there in the
  /// accent, ringed in white, or nothing where no cursor stands, placed by the chart's scale. It
  /// reads the cursor itself, so a scrub draws this layer again and nothing under it.
  struct ProfileCursorLayer: View {
    let cursor: ProfileCursor
    let series: ElevationSeries
    let domain: ElevationDomain
    let window: ProfileRange
    let rule: Color
    let dot: Color
    let dash: [CGFloat]
    let curves: ProfileCurves

    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("ProfileCursorLayer")
      // Where the cursor stands in the chart's 100-unit square.
      let standing = cursor.sample(in: series).map { sample in
        CGPoint(
          x: profileX(sample.distance, totalDistance: series.totalDistance, window: window),
          y: profileY(sample.elevation, domain: domain))
      }
      Canvas { context, size in
        curves.drewCursor()
        guard let standing else { return }
        let x = standing.x / profileViewBox * size.width
        let y = standing.y / profileViewBox * size.height
        var line = Path()
        line.move(to: CGPoint(x: x, y: 0))
        line.addLine(to: CGPoint(x: x, y: size.height))
        context.stroke(line, with: .color(rule), style: StrokeStyle(lineWidth: 1, dash: dash))
        let mark = Path(ellipseIn: CGRect(x: x - 4, y: y - 4, width: 8, height: 8))
        context.fill(mark, with: .color(dot))
        context.stroke(mark, with: .color(.white), lineWidth: 1.5)
      }
    }
  }

  /// ProfilePin is a pin standing on a profile's curve: a disc in the place's colour, or the
  /// profile's own, its glyph of the marker set in white, read by the place's name. Where the app
  /// hands `onTap` it is a button, pressed anywhere in the platform's touch target around its disc.
  struct ProfilePin: View {
    let pin: CurvePin
    let fill: Color
    let name: String
    let onTap: (() -> Void)?

    @Environment(\.sharedScope) private var scope
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("ProfilePin")
      let glyph = placeGlyph(pin.place.glyph?.rawValue, in: scope.markerGlyphs)
      let face = Circle()
        .fill(fill)
        .overlay(Circle().strokeBorder(.white, lineWidth: 1.5))
        .overlay {
          if let glyph {
            Glyph(glyph, in: scope.markerGlyphs, size: 12, ink: .foreground).foregroundStyle(.white)
          }
        }
        .frame(width: ProfileChart.pinSide, height: ProfileChart.pinSide)
      if let onTap {
        Button(action: onTap) {
          face.focusRing(cornerRadius: ProfileChart.pinSide / 2).touchTarget()
        }
        .buttonStyle(ElementButtonStyle(ringsLabel: false))
        .focusEffectDisabled()
        .accessibilityLabel(Text(verbatim: name))
      } else {
        face.accessibilityElement().accessibilityLabel(Text(verbatim: name))
      }
    }
  }

  /// AmenityStackBadges is the services a pinned place offers stacked above its pin
  /// (`geo.profile.amenity-stacks`): a badge per service shown, its glyph of the marker set, or its
  /// name's first letter where the set cannot draw it (`geo.icons.glyph-fallback`), and the count
  /// of the rest, read as one label naming every service.
  struct AmenityStackBadges: View {
    let stack: AmenityStack
    let scheme: ThemeScheme

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("AmenityStackBadges")
      HStack(spacing: 2) {
        ForEach(Array(stack.shown.enumerated()), id: \.offset) { _, amenity in
          badge {
            let glyph = amenityGlyph(amenity)
            if scope.markerGlyphs.markup[glyph] != nil {
              Glyph(glyph, in: scope.markerGlyphs, size: 10, ink: .foreground)
            } else {
              Text(verbatim: badgeFallback(amenityName(amenity, in: scope.value), on: .stack) ?? "")
                .font(.system(size: 8, weight: .semibold))
            }
          }
        }
        if stack.counted > 0 {
          badge {
            Text(verbatim: "+\(stack.counted)").font(.system(size: 8, weight: .semibold))
          }
        }
      }
      .foregroundStyle(tokenColor(tokens.panelFg, in: scheme))
      .accessibilityElement(children: .ignore)
      .accessibilityLabel(
        Text(verbatim: stack.named.map { amenityName($0, in: scope.value) }.joined(separator: ", "))
      )
    }

    /// One badge of the stack, on the panel's ground.
    private func badge(@ViewBuilder _ content: () -> some View) -> some View {
      content()
        .frame(width: 14, height: 14)
        .background(tokenColor(tokens.panelBg, in: scheme), in: RoundedRectangle(cornerRadius: 3))
        .overlay(
          RoundedRectangle(cornerRadius: 3).strokeBorder(tokenColor(tokens.panelBorder, in: scheme))
        )
    }
  }

  /// ProfileReadoutCard is the card at a profile's cursor, stating what it stands on
  /// (`geo.profile.cursor-readout`): its figures, its grade, and the stretch it stands in, named
  /// beside its colour, on the tooltip's ground.
  struct ProfileReadoutCard: View {
    let readout: ProfileReadout
    let units: UnitPreferences
    let scheme: ThemeScheme

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("ProfileReadoutCard")
      VStack(alignment: .leading, spacing: 2) {
        if let stretch = readout.stretch {
          HStack(spacing: 4) {
            Circle().fill(hexColor(HexColor(hex: stretch.color))).frame(width: 8, height: 8)
            Text(verbatim: stretch.label).font(.caption.weight(.semibold))
          }
        }
        ForEach(Array(readout.cells.enumerated()), id: \.offset) { _, cell in
          line(Self.word(cell.stat), value: Self.value(cell, units: units))
        }
        if let grade = readout.grade {
          line("profile.grade", value: formatSlope(grade, units: units))
        }
      }
      .font(.caption)
      .padding(8)
      .foregroundStyle(tokenColor(tokens.profileTooltipFg, in: scheme))
      .background(
        tokenColor(tokens.profileTooltipBg, in: scheme), in: RoundedRectangle(cornerRadius: 6)
      )
      .shadow(
        color: themeTokenValue(tokens.profileTooltipShadow, in: scheme).first.map(hexColor)
          ?? .clear,
        radius: 4, y: 1
      )
      .accessibilityElement(children: .combine)
    }

    /// One labelled figure of the card.
    private func line(_ word: String, value: String) -> some View {
      HStack(spacing: 6) {
        Text(verbatim: scope.word(word)).opacity(0.7)
        Text(verbatim: value).monospacedDigit()
      }
    }

    /// word is the path of the word a readout's figure is labelled with.
    static func word(_ stat: ReadoutStat) -> String {
      "profile.\(stat.rawValue)"
    }

    /// value is a readout's figure as the reader's units write it.
    static func value(_ cell: ReadoutCell, units: UnitPreferences) -> String {
      switch cell.stat {
      case .distance: formatDistance(cell.value, units: units)
      case .elevation, .ascent, .descent: formatElevation(cell.value, units: units)
      }
    }
  }
#endif
