#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  internal import SwiftUI

  /// MapCorner is the corner of a map a control stack sits in, as the reader sees it, whatever way
  /// the text around it runs: top right unless the app names another.
  public enum MapCorner: Sendable, Hashable, CaseIterable {
    /// topRight is the map's top right corner, where a stack sits unless another is named.
    case topRight
    /// topLeft is the map's top left corner.
    case topLeft
    /// bottomRight is the map's bottom right corner.
    case bottomRight
    /// bottomLeft is the map's bottom left corner.
    case bottomLeft

    /// alignment is where the corner stands in a frame laid out in `direction`, so a corner stays
    /// where the reader sees it in a layout that runs right to left.
    func alignment(in direction: LayoutDirection) -> Alignment {
      let isLeftToRight = direction == .leftToRight
      switch self {
      case .topRight: return isLeftToRight ? .topTrailing : .topLeading
      case .topLeft: return isLeftToRight ? .topLeading : .topTrailing
      case .bottomRight: return isLeftToRight ? .bottomTrailing : .bottomLeading
      case .bottomLeft: return isLeftToRight ? .bottomLeading : .bottomTrailing
      }
    }
  }
#endif
