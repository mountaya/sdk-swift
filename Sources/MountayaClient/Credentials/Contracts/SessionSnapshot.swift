import Foundation

/// SessionSnapshot is what a session source holds at one moment, as one value replaced on every
/// change rather than changed in place.
public struct SessionSnapshot: Sendable, Equatable {
  /// token is the session token, or nil where the source holds none.
  public let token: String?
  /// expiresAt is when the token expires, or nil where the source does not know.
  public let expiresAt: Date?
  /// userId is the user the token was minted for, or nil where it was minted without `user_id`,
  /// which refuses an operation that acts as a user before any request.
  public let userId: String?
  /// isMinting is true while a mint is on its way: a request made while the source holds no
  /// token waits for it.
  public let isMinting: Bool
  /// error is the last mint's failure, or nil where the last one succeeded: an operation that
  /// requires a session, refused for want of a token, carries it as its underlying error.
  public let error: (any Error)?

  /// Creates a snapshot, every part left out being none.
  public init(
    token: String? = nil,
    expiresAt: Date? = nil,
    userId: String? = nil,
    isMinting: Bool = false,
    error: (any Error)? = nil
  ) {
    self.token = token
    self.expiresAt = expiresAt
    self.userId = userId
    self.isMinting = isMinting
    self.error = error
  }

  /// Two snapshots are equal where they hold the same token, expiry and user, and agree on
  /// whether a mint is on its way and whether the last one failed.
  public static func == (lhs: SessionSnapshot, rhs: SessionSnapshot) -> Bool {
    lhs.token == rhs.token && lhs.expiresAt == rhs.expiresAt && lhs.userId == rhs.userId
      && lhs.isMinting == rhs.isMinting && (lhs.error == nil) == (rhs.error == nil)
  }
}

/// A snapshot prints its token by its prefix alone, as a credential does.
extension SessionSnapshot: CustomStringConvertible, CustomReflectable {
  /// description is the snapshot as a log may show it.
  public var description: String {
    var parts = ["token: \(token.map(CredentialHeaders.redacted) ?? "nil")"]
    if let expiresAt {
      parts.append("expiresAt: \(Timestamp.string(from: expiresAt))")
    }
    if isMinting {
      parts.append("isMinting: true")
    }
    if error != nil {
      parts.append("failed")
    }
    return "SessionSnapshot(\(parts.joined(separator: ", ")))"
  }

  /// customMirror has no children, so `dump` prints the redacted description.
  public var customMirror: Mirror {
    Mirror(self, children: [], displayStyle: .struct)
  }
}
