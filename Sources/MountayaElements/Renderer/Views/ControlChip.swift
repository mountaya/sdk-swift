#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import MountayaGeo
  internal import SwiftUI

  /// ControlChip is the chip a map's controls stand on, one control or a flush group of them, top
  /// to bottom: its ground is the `control-bg` token under the scheme in force, lifted off the map
  /// by the two shadows `control-shadow` colours, a rounded square, or a disc for the compass.
  struct ControlChip<Content: View>: View {
    var isRound = false
    @ViewBuilder let content: () -> Content

    @Environment(\.sharedTokens) private var tokens
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
      let scheme = themeScheme(colorScheme)
      let shadows = themeTokenValue(tokens.controlShadow, in: scheme).map(hexColor)
      let shape = isRound ? AnyShape(Circle()) : AnyShape(RoundedRectangle(cornerRadius: 8))
      VStack(spacing: 0) {
        content()
      }
      .background(tokenColor(tokens.controlBg, in: scheme))
      .clipShape(shape)
      .shadow(color: shadows.first ?? .clear, radius: 1, y: 1)
      .shadow(color: shadows.dropFirst().first ?? .clear, radius: 4, y: 2)
    }
  }
#endif
