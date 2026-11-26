import Foundation

/// RandomSource is what the client draws at random: the jitter of every wait between two
/// attempts, and the `Idempotency-Key` of every write that declares one.
///
/// A client given none draws from the platform. A conformance stands in for the platform in a
/// test, so that a wait and a key are reproducible.
public protocol RandomSource: Sendable {
  /// unitDraw returns a number drawn uniformly from zero to one.
  func unitDraw() -> Double

  /// cryptographicUuid returns a version 4 UUID drawn from a cryptographic random source, or nil
  /// where the runtime offers none.
  ///
  /// A write whose key could not be drawn sends none, never one drawn from a weaker source: two
  /// calls that drew the same key would each be answered with the other's answer.
  func cryptographicUuid() -> UUID?
}
