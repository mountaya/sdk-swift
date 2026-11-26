/// CredentialDeclaration is what an operation declares about the credentials it takes.
///
/// Each fact is read from the contract per operation, never inferred from the method: a read
/// may act as a user, and a write may take no credential at all. An absent fact is false, and
/// an absent acting user is `none`.
public struct CredentialDeclaration: Sendable, Hashable {
  /// ActingUser is what an operation needs of the user its session token was minted for, its
  /// `x-acting-user`.
  ///
  /// No header names a user: the user an operation acts as is the one its session token names,
  /// so this says what the token must name, never what is sent.
  @nonexhaustive
  public enum ActingUser: String, Sendable, Hashable {
    /// required acts as the user, so its token must name one. A token a session source reports
    /// as minted without `user_id` is refused locally, since the API answers it with a 401.
    case required
    /// optional is a read a token minted without `user_id` may make, which holds a user the token
    /// names to the role the read asks for.
    case optional
    /// none acts as nobody, and a user the token names is ignored.
    case none
  }

  /// actingUser is what the operation needs of the user its session token names.
  public let actingUser: ActingUser
  /// acceptsShareToken is true where a share token on its own authenticates the operation,
  /// which is true of the reads of a shared resource and of nothing else.
  public let acceptsShareToken: Bool
  /// requiresSession is true where every way to authenticate the operation names a session
  /// token.
  public let requiresSession: Bool
  /// requiresSecretKey is true where a secret key authenticates the operation, which is the
  /// one that mints a session token.
  public let requiresSecretKey: Bool
  /// takesNoCredential is true where the operation takes no credential at all, so it is sent
  /// none and refuses none.
  public let takesNoCredential: Bool
  /// pendingInvitee is true where a user whose invitation is still waiting is answered as a
  /// member is, the operation's `x-pending-invitee`. It decides nothing the client checks.
  public let pendingInvitee: Bool
  /// isRead is true where the operation is declared a read whatever its method, as every Data API
  /// query is over its `POST`. A request sent with `GET`, `HEAD` or `OPTIONS`, in any letter case,
  /// is a read whatever this says, and every other is a write. A share token that asks for the
  /// visitor's cookies sends a read of an operation that takes no share token on the visitor's
  /// session alone, one that requires a session token included, for the server to judge.
  public let isRead: Bool

  /// Creates a declaration, every fact left out being false and the acting user `none`.
  public init(
    actingUser: ActingUser = ActingUser.none,
    acceptsShareToken: Bool = false,
    requiresSession: Bool = false,
    requiresSecretKey: Bool = false,
    takesNoCredential: Bool = false,
    pendingInvitee: Bool = false,
    isRead: Bool = false
  ) {
    self.actingUser = actingUser
    self.acceptsShareToken = acceptsShareToken
    self.requiresSession = requiresSession
    self.requiresSecretKey = requiresSecretKey
    self.takesNoCredential = takesNoCredential
    self.pendingInvitee = pendingInvitee
    self.isRead = isRead
  }
}
