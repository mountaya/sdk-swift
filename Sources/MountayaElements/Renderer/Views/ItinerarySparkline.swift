#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  public import MountayaGeo
  public import SwiftUI

  /// ItinerarySparkline is an itinerary's whole curve drawn small, the stretch `lit` drawn over it
  /// in `color`, the accent where it names none: the shape of a leg, or of the stretch reaching a
  /// place, within the itinerary a table row belongs to.
  ///
  /// ```swift
  /// ItinerarySparkline(series: series, lit: ProfileRange(from: 1_200, to: 3_400))
  ///   .frame(width: 96, height: 24)
  /// ```
  ///
  /// The whole curve is drawn in the `table-spark-base` token and the lit stretch in the colour,
  /// each read on the profile's own scale (`geo.profile.plot-scale`, `geo.profile.chart-path`), so
  /// a sparkline and the chart beside it draw one line. It is hidden from assistive technologies,
  /// the row it stands in stating its figures.
  public struct ItinerarySparkline: View {
    private let series: ElevationSeries
    private let lit: ProfileRange?
    private let color: String?

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    /// Creates the sparkline of `series`, the stretch `lit` drawn over it in `color`.
    public init(series: ElevationSeries, lit: ProfileRange? = nil, color: String? = nil) {
      self.series = series
      self.lit = lit
      self.color = color
    }

    /// body is the curve, and the lit stretch over it.
    public var body: some View {
      let scheme = themeScheme(colorScheme)
      let base = tokenColor(tokens.tableSparkBase, in: scheme)
      let shade = color.map { hexColor(HexColor(hex: $0)) } ?? tokenColor(tokens.accent, in: scheme)
      let domain = profileDomain(series)
      let area = profileAreaPath(series, domain: domain)
      let line = profilePolyline(series, domain: domain)
      let total = series.totalDistance
      Canvas { context, size in
        let areaPath = plotPath(area, in: size)
        context.fill(areaPath, with: .color(base))
        guard let lit else { return }
        let start = profileX(lit.from, totalDistance: total) / profileViewBox * size.width
        let end = profileX(lit.to, totalDistance: total) / profileViewBox * size.width
        guard end > start else { return }
        var shown = context
        shown.clip(to: Path(CGRect(x: start, y: 0, width: end - start, height: size.height)))
        shown.fill(areaPath, with: .color(shade.opacity(0.35)))
        shown.stroke(plotPath(line, in: size), with: .color(shade), lineWidth: 1.5)
      }
      .accessibilityHidden(true)
    }
  }
#endif
