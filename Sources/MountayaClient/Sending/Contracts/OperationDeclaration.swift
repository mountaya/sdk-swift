/// OperationDeclaration is what an operation declares that the client reads at request time,
/// for a call to one this build prints no method for.
///
/// Every printed method carries its operation's declaration already; this one is written by the
/// caller, from the contract, and nothing in it is inferred from the method. A write that
/// declares no `Idempotency-Key` sends none, a read may act as a user, and only `idempotent`
/// says whether a repeat after a dropped connection is safe.
public struct OperationDeclaration: Sendable, Hashable {
  /// surface is the surface the operation belongs to, whose origin the request goes to. Only the
  /// two REST surfaces answer an envelope, so a declaration names `rest` or `tiles`.
  public var surface: Surface
  /// operationId is the contract's name for the operation, which the `onResponse` hook is told.
  public var operationId: String
  /// method is the HTTP method, uppercase.
  public var method: String
  /// idempotent is the operation's `x-idempotent`: a repeat has no second effect.
  public var idempotent: Bool
  /// credentials is what the operation takes, and so what it refuses locally.
  public var credentials: CredentialDeclaration
  /// timeout is the operation's `x-timeout-ms`, the most the API spends on it before it answers
  /// a 504 itself, or nil where it declares none, as an event stream does.
  public var timeout: Duration?
  /// declaresIdempotencyKey is true where the operation takes an `Idempotency-Key`, which
  /// every call to it then sends.
  public var declaresIdempotencyKey: Bool
  /// isConditional is true where the operation takes an `If-Match`, which a call sends only
  /// where its caller names a tag.
  public var isConditional: Bool

  /// Creates a declaration, every fact left out being the one no operation states by default:
  /// not idempotent, no key, no condition, no budget of its own.
  public init(
    surface: Surface = .rest,
    operationId: String,
    method: String,
    idempotent: Bool = false,
    credentials: CredentialDeclaration = CredentialDeclaration(),
    timeout: Duration? = nil,
    declaresIdempotencyKey: Bool = false,
    isConditional: Bool = false
  ) {
    self.surface = surface
    self.operationId = operationId
    self.method = method
    self.idempotent = idempotent
    self.credentials = credentials
    self.timeout = timeout
    self.declaresIdempotencyKey = declaresIdempotencyKey
    self.isConditional = isConditional
  }
}
