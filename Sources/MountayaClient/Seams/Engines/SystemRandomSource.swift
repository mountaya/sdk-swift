import Foundation

/// SystemRandomSource draws from the platform's random number generator, which is a
/// cryptographic source on every host this package builds on.
struct SystemRandomSource: RandomSource {
  func unitDraw() -> Double {
    Double.random(in: 0..<1)
  }

  func cryptographicUuid() -> UUID? {
    UUID()
  }
}
