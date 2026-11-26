#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// plotPath is a path drawn in a profile's 100-unit square, scaled into a box of `size`: each
  /// command's point stretched across its width and down its height, as a chart stretches its
  /// square (`geo.profile.chart-path`).
  func plotPath(_ commands: [PlotCommand], in size: CGSize) -> Path {
    var path = Path()
    for command in commands {
      switch command {
      case .move(let point): path.move(to: plotPoint(point, in: size))
      case .line(let point): path.addLine(to: plotPoint(point, in: size))
      case .close: path.closeSubpath()
      }
    }
    return path
  }

  /// plotPath is a line through `points` of a profile's square, scaled into a box of `size`, empty
  /// for no point.
  func plotPath(_ points: [PlotPoint], in size: CGSize) -> Path {
    var path = Path()
    guard let first = points.first else { return path }
    path.move(to: plotPoint(first, in: size))
    for point in points.dropFirst() {
      path.addLine(to: plotPoint(point, in: size))
    }
    return path
  }

  /// plotPoint is where a point of a profile's square stands in a box of `size`.
  func plotPoint(_ point: PlotPoint, in size: CGSize) -> CGPoint {
    CGPoint(x: point.x / profileViewBox * size.width, y: point.y / profileViewBox * size.height)
  }
#endif
