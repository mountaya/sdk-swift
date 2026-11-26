/// PageMetadata is the metadata a page of a listing carries: where the page after it starts.
public protocol PageMetadata: Sendable {
  /// nextCursor is the cursor of the page after this one, or nil on the last page.
  var nextCursor: String? { get }
}

extension RestSchema.ListMetadata: PageMetadata {
  /// nextCursor is `pagination.next_cursor`, null on the last page.
  public var nextCursor: String? {
    pagination.next_cursor
  }
}
