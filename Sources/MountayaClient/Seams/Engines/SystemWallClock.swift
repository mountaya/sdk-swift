import Foundation

/// SystemWallClock reads the current instant from the platform.
package struct SystemWallClock: WallClock {
  package var now: Date { Date() }

  /// Creates the platform's clock.
  package init() {}
}
