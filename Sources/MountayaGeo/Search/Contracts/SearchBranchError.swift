import MountayaClient

/// SearchBranchError is one branch of a search round the Data API answered as failed: the answer
/// arrived, and its `errors` name the branch (`geo.search.live-round`). The API answers the branches
/// that worked beside it, so only that branch's section reads the failure.
///
/// `code` is why the branch failed, the code querying that target alone would have raised, and
/// `message` the API's sentence for it, in the language the request asked for, each nil where the
/// answer states none. Two are equal where they name the same branch and say the same, a text by
/// its scalars.
public struct SearchBranchError: Error, Sendable, Hashable {
  /// target is the branch that failed.
  public var target: DataSchema.SearchTarget
  /// code is why the branch failed, or nil where the answer states no code.
  public var code: DataSchema.ErrorCode?
  /// message is the API's sentence for the failure, or nil where the answer states none.
  public var message: String?

  /// Creates the failure of the branch `target`, with the code and the sentence the answer states.
  public init(
    target: DataSchema.SearchTarget, code: DataSchema.ErrorCode? = nil, message: String? = nil
  ) {
    self.target = target
    self.code = code
    self.message = message
  }

  /// Two failures are equal where they name one branch, one code and one sentence, by their scalars.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    sameText(lhs.target, rhs.target) && sameText(lhs.code, rhs.code)
      && sameText(lhs.message, rhs.message)
  }

  /// hash feeds the branch, the code and the sentence.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(target)
    hasher.combine(code)
    hasher.combine(message)
  }
}
