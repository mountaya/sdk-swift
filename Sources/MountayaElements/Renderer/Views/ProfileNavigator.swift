#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// ProfileNavigator is the strip under a profile's chart showing the whole itinerary, the window
  /// drawn marked on it and the rest veiled: a reader drags either handle to move that end of the
  /// window, or the window itself to move it whole, and each move is held to the itinerary and to
  /// the narrowest window (`geo.profile.window-clamp`). An edge moves to the distance a column of
  /// the strip stands for, never snapped to a sample (`geo.profile.scrub-grid`). Each handle is
  /// adjustable by assistive technologies, a step a twentieth of the itinerary.
  struct ProfileNavigator: View {
    let series: ElevationSeries
    let domain: ElevationDomain
    let window: ProfileRange
    let onChange: (ProfileRange) -> Void

    @Environment(\.sharedScope) private var scope
    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.isEnabled) private var isEnabled
    @Environment(\.renderProbe) private var probe
    @State private var grabbed: Grab?

    /// Grab is what a drag over the strip moves, and the window it started from.
    struct Grab: Equatable {
      enum Part: Equatable { case start, end, whole }
      let part: Part
      let window: ProfileRange
    }

    var body: some View {
      let _ = probe?.report("ProfileNavigator")
      let scheme = themeScheme(colorScheme)
      GeometryReader { proxy in
        let size = proxy.size
        let start = across(window.from, width: size.width)
        let end = across(window.to, width: size.width)
        ZStack(alignment: .topLeading) {
          Canvas { context, size in
            let accent = tokenColor(tokens.accent, in: scheme)
            context.fill(
              plotPath(profileAreaPath(series, domain: domain), in: size),
              with: .color(accent.opacity(0.18)))
            context.stroke(
              plotPath(profilePolyline(series, domain: domain), in: size), with: .color(accent),
              lineWidth: 1)
          }
          let veil = tokenColor(tokens.profileNavigatorVeil, in: scheme)
          veil.frame(width: max(0, start), height: size.height)
          veil.frame(width: max(0, size.width - end), height: size.height).offset(x: end)
          handle(scheme: scheme, word: "profile.rangeStart", edge: \.from)
            .position(x: start, y: size.height / 2)
          handle(scheme: scheme, word: "profile.rangeEnd", edge: \.to)
            .position(x: end, y: size.height / 2)
        }
        .contentShape(Rectangle())
        .gesture(
          drag(width: size.width, start: start, end: end), including: isEnabled ? .all : .subviews)
      }
      .frame(height: 36)
      .accessibilityElement(children: .contain)
      .accessibilityLabel(Text(verbatim: scope.word("profile.navigator")))
    }

    /// A handle at one end of the window, adjustable by assistive technologies.
    private func handle(
      scheme: ThemeScheme, word: String, edge: WritableKeyPath<ProfileRange, Double>
    )
      -> some View
    {
      RoundedRectangle(cornerRadius: 2)
        .fill(tokenColor(tokens.profileNavigatorHandle, in: scheme))
        .frame(width: 6, height: 28)
        .frame(width: 44, height: 36)
        .contentShape(Rectangle())
        .accessibilityElement()
        .accessibilityLabel(Text(verbatim: scope.word(word)))
        .accessibilityValue(
          Text(
            verbatim: formatDistance(
              window[keyPath: edge], units: UnitPreferences(language: scope.locale)))
        )
        .accessibilityAdjustableAction { direction in
          guard isEnabled else { return }
          var moved = window
          let step = series.totalDistance / 20
          moved[keyPath: edge] += direction == .increment ? step : -step
          onChange(clampRange(moved, totalDistance: series.totalDistance))
        }
    }

    /// The drag over the strip: from a handle it moves that end, and from anywhere else the whole
    /// window, by the distance the drag spans.
    private func drag(width: CGFloat, start: CGFloat, end: CGFloat) -> some Gesture {
      DragGesture(minimumDistance: 0)
        .onChanged { value in
          let held =
            grabbed
            ?? Grab(
              part: Self.part(at: value.startLocation.x, start: start, end: end), window: window)
          grabbed = held
          onChange(
            Self.moved(
              held, from: value.startLocation.x, to: value.location.x, width: width,
              total: series.totalDistance))
        }
        .onEnded { _ in grabbed = nil }
    }

    /// part is what a drag starting at `x` grabs: a handle within 22 points of it, else the window.
    static func part(at x: CGFloat, start: CGFloat, end: CGFloat) -> Grab.Part {
      abs(x - start) <= 22 ? .start : abs(x - end) <= 22 ? .end : .whole
    }

    /// moved is the window a drag that grabbed `grab` at `startX` leaves at `x`, across a strip
    /// `width` wide over an itinerary of `total` meters: a handle's end moved to the distance the
    /// column under `x` stands for (`geo.profile.scrub-grid`), a point past the strip read as its
    /// last column, or the whole window moved by the distance between the two columns, kept inside
    /// the itinerary; either is then held to the itinerary and the narrowest window
    /// (`geo.profile.window-clamp`).
    static func moved(
      _ grab: Grab, from startX: CGFloat, to x: CGFloat, width: CGFloat, total: Double
    ) -> ProfileRange {
      guard width > 0 else { return grab.window }
      let whole = ProfileRange(from: 0, to: total)
      let distance = { (x: CGFloat) in
        let column = Int((x / width * CGFloat(profileScrubColumns)).rounded(.down))
        return scrubDistance(
          column: min(max(column, 0), profileScrubColumns - 1), window: whole)
      }
      var moved = grab.window
      switch grab.part {
      case .start: moved.from = distance(x)
      case .end: moved.to = distance(x)
      case .whole:
        let span = grab.window.to - grab.window.from
        let from = min(
          max(grab.window.from + distance(x) - distance(startX), 0), max(0, total - span))
        moved = ProfileRange(from: from, to: from + span)
      }
      return clampRange(moved, totalDistance: total)
    }

    /// Where a distance stands across the strip.
    private func across(_ meters: Double, width: CGFloat) -> CGFloat {
      profileX(meters, totalDistance: series.totalDistance) / profileViewBox * width
    }
  }
#endif
