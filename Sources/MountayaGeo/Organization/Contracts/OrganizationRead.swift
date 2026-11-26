/// OrganizationRead is where a map's read of its organization stands (`map.organization.read`), in
/// the five states its watermark is drawn by (`geo.organization.watermark`): waiting on its answer;
/// answered, with whether the organization holds white label, the organization itself being
/// `MapEngine.organization`; failed, a read that reached the transport's own time budget among the
/// failures; timed out, one attempt's time budget passed with no answer while further attempts may
/// go on; and no key, a client holding no publishable key, which makes no read.
///
/// The contract names these five and no more (`sdk/SPEC.md` §15), so a `switch` over it lists
/// them all.
public enum OrganizationRead: Sendable, Hashable {
  /// waiting is a read sent and not yet answered, within one attempt's time budget: no mark yet,
  /// and its frame held clear for it.
  case waiting
  /// answered is a read the API answered, the organization holding white label or not; the mark
  /// is drawn unless it does.
  case answered(whiteLabel: Bool)
  /// failed is a read that failed, or reached the transport's own time budget, which fails it as
  /// any failure does: the mark is drawn.
  case failed
  /// timedOut is a read that has gone one attempt's time budget with no answer, its further
  /// attempts going on or not: the mark is drawn until an answer says white label.
  case timedOut
  /// noKey is a client holding no publishable key, a share token, a secret key or a seam of its
  /// own, which makes no read: the mark is drawn.
  case noKey
}
