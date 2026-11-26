/// OperationFacts is what one operation declares, printed from the contract beside the method
/// that sends it.
///
/// The transport reads every fact here and infers none from the method: a read may act as a
/// user, a write may take no credential, and only `idempotent` says whether a repeat after a
/// dropped socket is safe.
package struct OperationFacts: Sendable, Hashable {
  /// Surface is the public surface an operation belongs to.
  package typealias Surface = MountayaClient.Surface

  /// Success is the shape of a successful answer.
  package enum Success: String, Sendable, Hashable {
    /// envelope is a JSON body carrying `data` and `extensions.metadata`.
    case envelope
    /// eventStream is a stream of server-sent events.
    case eventStream = "event-stream"
    /// binary is a file.
    case binary
    /// result is a Data API answer, whose `data` holds the operation's result.
    case result
  }

  /// SuccessResponse is one status a success arrives with, and the headers the contract declares
  /// on it.
  package struct SuccessResponse: Sendable, Hashable {
    let status: Int
    /// headers is every header the contract declares on the answer, by name, in the contract's
    /// order. They are facts the gate compares with the model, and none decides anything here:
    /// a `Response` reads its `X-Request-Id`, `Location` and `ETag` wherever an answer sent one.
    let headers: [String]

    /// Creates a status a success arrives with, as a printed table states it.
    package init(status: Int, headers: [String]) {
      self.status = status
      self.headers = headers
    }
  }

  /// Pagination is how an operation that pages by cursor sorts its pages.
  package struct Pagination: Sendable, Hashable {
    /// sort is every order its `sort` parameter takes, in the contract's order, and empty where
    /// it takes no `sort`.
    let sort: [String]
    /// defaultSort is the order it sorts by where the caller names none, and nil where it takes
    /// no `sort`.
    let defaultSort: String?

    /// Creates how an operation pages, as a printed table states it.
    package init(sort: [String], defaultSort: String?) {
      self.sort = sort
      self.defaultSort = defaultSort
    }
  }

  let surface: Surface
  /// operationId is the contract's name for the operation, which is also the method's.
  let operationId: String
  /// method is the HTTP method, uppercase.
  let method: String
  /// path is the path template, with each path parameter in braces.
  let path: String
  /// idempotent is the contract's promise that a repeat has no second effect.
  let idempotent: Bool
  /// credentials is what the operation takes, and so what it refuses locally.
  let credentials: CredentialDeclaration
  /// timeout is the most the API spends on the operation before it answers a 504 itself, its
  /// `x-timeout-ms`, from which an attempt's budget is derived. It is nil for an event stream,
  /// which declares none.
  let timeout: Duration?
  /// declaresIdempotencyKey is true where the operation takes an `Idempotency-Key`, which every
  /// call to it sends.
  let declaresIdempotencyKey: Bool
  /// isConditional is true where the operation takes an `If-Match`, which a call sends only
  /// where its caller names a tag.
  let isConditional: Bool
  /// answersNotModified is true where the operation answers a conditional read from the
  /// caller's copy with a 304.
  let answersNotModified: Bool
  /// pagination is how the operation pages, or nil where it does not page by cursor.
  let pagination: Pagination?
  let success: Success
  /// successResponses is every status a success arrives with and the headers each declares, in
  /// the contract's order.
  let successResponses: [SuccessResponse]
  /// errorStatuses is every failing status the operation declares, in ascending order.
  let errorStatuses: [Int]
  /// tasks is every task the operation triggers, as the contract's `tasks.yaml` names them, in
  /// the contract's order: one, or several where the request decides which, and none for a read.
  /// Each is the `task` a webhook event the write records carries. They are facts the gate
  /// compares with the model, and none decides anything here.
  let tasks: [String]

  /// Creates an operation's facts, as a printed table states them, the admin unit's among them.
  package init(
    surface: Surface,
    operationId: String,
    method: String,
    path: String,
    idempotent: Bool,
    credentials: CredentialDeclaration,
    timeout: Duration?,
    declaresIdempotencyKey: Bool,
    isConditional: Bool,
    answersNotModified: Bool,
    pagination: Pagination?,
    success: Success,
    successResponses: [SuccessResponse],
    errorStatuses: [Int],
    tasks: [String]
  ) {
    self.surface = surface
    self.operationId = operationId
    self.method = method
    self.path = path
    self.idempotent = idempotent
    self.credentials = credentials
    self.timeout = timeout
    self.declaresIdempotencyKey = declaresIdempotencyKey
    self.isConditional = isConditional
    self.answersNotModified = answersNotModified
    self.pagination = pagination
    self.success = success
    self.successResponses = successResponses
    self.errorStatuses = errorStatuses
    self.tasks = tasks
  }
}

extension OperationFacts {
  /// Creates the facts a caller's declaration states, for an operation this build prints no
  /// method for: its success an envelope, its path the caller's, its statuses and its tasks
  /// unknown.
  init(_ declaration: OperationDeclaration, path: String, success: Success = .envelope) {
    self.init(
      surface: declaration.surface,
      operationId: declaration.operationId,
      method: declaration.method,
      path: path,
      idempotent: declaration.idempotent,
      credentials: declaration.credentials,
      timeout: declaration.timeout,
      declaresIdempotencyKey: declaration.declaresIdempotencyKey,
      isConditional: declaration.isConditional,
      answersNotModified: false,
      pagination: nil,
      success: success,
      successResponses: [],
      errorStatuses: [],
      tasks: []
    )
  }

  /// Creates the facts of a Data API operation a caller declares, for one this build prints no
  /// method for: what every Data API operation declares in the model, as the printed ones do, sent
  /// to the endpoint they are sent to, idempotent, a read whatever its method, carrying a session
  /// token, acting as nobody and answered 200, and its own name and budget.
  init(declaring operation: DataOperation) {
    self.init(
      surface: .data,
      operationId: operation.name,
      method: "POST",
      path: Self.dataEndpoint,
      idempotent: true,
      credentials: CredentialDeclaration(requiresSession: true, isRead: true),
      timeout: operation.timeout,
      declaresIdempotencyKey: false,
      isConditional: false,
      answersNotModified: false,
      pagination: nil,
      success: .result,
      successResponses: [SuccessResponse(status: 200, headers: [])],
      errorStatuses: [],
      tasks: []
    )
  }
}
