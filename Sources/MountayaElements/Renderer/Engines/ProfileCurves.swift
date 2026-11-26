#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI
  internal import UIKit

  /// ProfileCurves holds a profile chart's curve across its renders: the area under the curve and
  /// its line in the chart's 100-unit square, built once for a series, a domain and a window and
  /// drawn at whatever size the chart is, and the image of the curve's layer, drawn once for what
  /// it takes, so a scrub, which changes none of it, builds and draws nothing of it again
  /// (`geo.profile.chart-path`).
  ///
  /// It counts the curves it builds and the times the chart draws its curve and its cursor, which a
  /// test reads. It is bound to the main actor, where SwiftUI draws the chart.
  @MainActor
  final class ProfileCurves {
    /// Held is the curve last built, and what it was built for.
    private struct Held {
      let series: ElevationSeries
      let domain: ElevationDomain
      let window: ProfileRange
      let curve: ProfileCurve
    }

    private var held: Held?
    /// image is the curve's layer last drawn, the look it was drawn for, and at which scale.
    private var image: (look: ProfileCurveLayer.Look, scale: CGFloat, drawn: UIImage)?

    /// generations is how many curves every chart has built, which numbers each curve built, so
    /// no two curves share a number for as long as the process runs.
    private static var generations = 0

    /// built is how many curves it has built, one for each series, domain or window drawn.
    private(set) var built = 0
    /// curveDrawn is how many times the chart has drawn its curve's layer.
    private(set) var curveDrawn = 0
    /// cursorDrawn is how many times the chart has drawn its cursor's layer.
    private(set) var cursorDrawn = 0

    /// curve is the curve of `series` over `window`, scaled by `domain`: the one held where it was
    /// built for the same three, and one built now, and held, otherwise.
    func curve(_ series: ElevationSeries, domain: ElevationDomain, window: ProfileRange)
      -> ProfileCurve
    {
      if let held, held.domain == domain, held.window == window, held.series == series {
        return held.curve
      }
      built += 1
      Self.generations += 1
      let square = CGSize(width: profileViewBox, height: profileViewBox)
      let curve = ProfileCurve(
        area: plotPath(profileAreaPath(series, domain: domain, window: window), in: square),
        line: plotPath(profilePolyline(series, domain: domain, window: window), in: square),
        generation: Self.generations)
      held = Held(series: series, domain: domain, window: window, curve: curve)
      return curve
    }

    /// drawn is the image of `layer` at `scale`: the one held where it was drawn for the same look
    /// at the same scale, and one drawn now, and held, otherwise. A layer of no size draws nothing.
    func drawn(_ layer: ProfileCurveLayer, scale: CGFloat) -> UIImage {
      let look = layer.look
      if let image, image.scale == scale, image.look == look {
        return image.drawn
      }
      guard layer.size.width > 0, layer.size.height > 0 else { return UIImage() }
      curveDrawn += 1
      let renderer = ImageRenderer(content: layer.canvas)
      renderer.scale = scale
      let drawn = renderer.uiImage ?? UIImage()
      image = (look, scale, drawn)
      return drawn
    }

    /// drewCursor counts a drawing of the cursor's layer.
    func drewCursor() {
      cursorDrawn += 1
    }
  }

  /// ProfileCurve is a profile's curve in the chart's 100-unit square: the area under it and its
  /// line, and the build that made them, which two curves compare by.
  struct ProfileCurve: Equatable {
    /// area is the area under the curve, closed along the chart's floor.
    let area: Path
    /// line is the curve itself.
    let line: Path
    /// generation numbers the build that made the curve, each build of every chart its own.
    let generation: Int

    /// scaled is the curve's `path` stretched from the 100-unit square over a box of `size`.
    static func scaled(_ path: Path, to size: CGSize) -> Path {
      path.applying(
        CGAffineTransform(scaleX: size.width / profileViewBox, y: size.height / profileViewBox))
    }

    /// Two curves are one where one build made them.
    static func == (lhs: Self, rhs: Self) -> Bool {
      lhs.generation == rhs.generation
    }
  }
#endif
