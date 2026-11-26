import GateSupport

/// SuppressionLedger is the list of places this repository switches the compiler's concurrency
/// checking off, each with the sentence naming the synchronisation that makes it true.
///
/// The same sentence stands as a comment above the suppression. One with no entry here is a
/// claim nobody made, and the suite fails on it; so is an entry whose suppression is gone.
enum SuppressionLedger {
  static let entries: [BoundaryRules.LedgerEntry] = []
}
