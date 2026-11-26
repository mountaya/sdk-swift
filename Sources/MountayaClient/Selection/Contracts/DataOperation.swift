/// DataOperation is one Data API operation as the contract declares it: its name, the type of
/// its input, the tree of every field its result can carry, and its budget.
///
/// Every printed method of `data` carries its operation's already; one written by the caller,
/// from the contract, calls an operation this build prints no method for through
/// `Mountaya.query(_:input:select:options:)`.
public struct DataOperation: Sendable, Hashable {
  /// name is the operation's field on the Data API's query type, such as `directions`.
  public let name: String
  /// inputType is the GraphQL type of its `input` argument, such as `DirectionsInput!`.
  public let inputType: String
  /// selection is the operation's field tree: every field of its result, in the schema's
  /// order, which is also the full selection.
  public let selection: FieldSelection
  /// timeout is the most the API spends on the operation before it answers a 504 itself, its
  /// `x-timeout-ms`, from which an attempt's budget is derived, or nil where the caller states
  /// none: an attempt then waits the client's own budget.
  public let timeout: Duration?
  /// document is the GraphQL document of the full selection, which is what a call that
  /// narrows nothing sends.
  public let document: String

  /// Creates an operation from what the contract declares about it.
  public init(
    name: String, inputType: String, selection: FieldSelection, timeout: Duration? = nil
  ) {
    self.name = name
    self.inputType = inputType
    self.selection = selection
    self.timeout = timeout
    self.document = QueryDocument.print(name: name, inputType: inputType, selection: selection)
  }

  /// document returns the GraphQL document a call sends: the full document where `selecting`
  /// is nil, and otherwise the document of the fields it names, in the field tree's order.
  ///
  /// It throws `SelectionError` for a selection naming a field outside the field tree, rather
  /// than sending a request the server would refuse.
  public func document(selecting fields: FieldSelection?) throws(MountayaError) -> String {
    guard let fields else {
      return document
    }
    let narrowed = try SelectionNarrowing.narrow(selection, to: fields)
    return QueryDocument.print(name: name, inputType: inputType, selection: narrowed)
  }
}
