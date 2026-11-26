#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// ProfileDistanceAxis is the row under a profile's chart: the distance its window spans,
  /// labelled at the stops of the reader's unit (`distanceTicks(from:to:length:target:)`), and under
  /// them the names of the places that divide the itinerary, each centred under its place, the
  /// first and the last always drawn and a name between them left out where it would crowd its
  /// neighbours (`geo.profile.axis-label-culling`).
  ///
  /// The row is 32 points high at the default text size and grows with Dynamic Type, its stops and
  /// its names placed in it at the same share of its height, so a larger text size is drawn whole
  /// rather than clipped, and its names are measured at the size they are drawn at.
  struct ProfileDistanceAxis: View {
    let totalDistance: Double
    let window: ProfileRange
    let dividers: [CurveDivider]
    let units: UnitPreferences

    /// rowHeight is the row's height, 32 points at the default text size, scaled with the reader's.
    @ScaledMetric(relativeTo: .caption2) private var rowHeight: CGFloat = 32

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.dynamicTypeSize) private var textSize
    @Environment(\.renderProbe) private var probe

    var body: some View {
      let _ = probe?.report("ProfileDistanceAxis")
      let dimmed = tokenColor(tokens.dimmed, in: themeScheme(colorScheme))
      let height = rowHeight
      GeometryReader { proxy in
        let width = proxy.size.width
        let ticks = distanceTicks(from: window.from, to: window.to, length: units.length)
        let shown = Self.shownNames(dividers, width: width, size: textSize)
        ZStack(alignment: .topLeading) {
          ForEach(Array(ticks.enumerated()), id: \.offset) { _, tick in
            Text(verbatim: formatDistanceTick(tick, units: units))
              .font(.caption2)
              .monospacedDigit()
              .foregroundStyle(dimmed)
              .fixedSize()
              .position(x: across(tick.meters, width: width), y: height * Self.ticksLine)
          }
          ForEach(shown, id: \.key) { divider in
            Text(verbatim: divider.name)
              .font(.caption2)
              .fixedSize()
              .position(
                x: Self.centre(divider, width: width, size: textSize), y: height * Self.namesLine)
          }
        }
      }
      .frame(height: height)
    }

    /// ticksLine is where the stops' labels are centred down the row, as a share of its height.
    static let ticksLine: CGFloat = 7 / 32
    /// namesLine is where the places' names are centred down the row, as a share of its height.
    static let namesLine: CGFloat = 24 / 32

    /// Where a distance stands across the row.
    private func across(_ meters: Double, width: CGFloat) -> CGFloat {
      profileX(meters, totalDistance: totalDistance, window: window) / profileViewBox * width
    }

    /// shownNames is the dividers whose names are drawn under a row `width` wide, at the text size
    /// `size`, the reader's where it is nil: each laid out centred under its place and kept in the
    /// row, and a crowded one between the first and the last left out.
    static func shownNames(
      _ dividers: [CurveDivider], width: CGFloat, size: DynamicTypeSize? = nil
    ) -> [CurveDivider] {
      let boxes = dividers.map { divider in
        let half = textWidth(divider.name, style: .caption2, size: size) / 2
        let centre = centre(divider, width: width, size: size)
        return AxisLabelBox(key: divider.key, left: centre - half, right: centre + half)
      }
      let hidden = Set(cullCrowdedLabels(boxes))
      return dividers.filter { !hidden.contains($0.key) }
    }

    /// The centre of a divider's name, under its place, kept so the name stays in the row.
    private static func centre(_ divider: CurveDivider, width: CGFloat, size: DynamicTypeSize?)
      -> CGFloat
    {
      let half = textWidth(divider.name, style: .caption2, size: size) / 2
      let x = divider.x / profileViewBox * width
      return min(max(x, half), max(half, width - half))
    }
  }
#endif
