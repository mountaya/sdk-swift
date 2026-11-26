/// QueryItem is one name and value of a request's query, before it is percent-encoded.
///
/// An array parameter is one item per element, each under the parameter's name, which is the
/// form OpenAPI writes a query array in when it says nothing else.
package struct QueryItem: Sendable, Hashable {
  let name: String
  let value: String

  /// Creates the item a printed query writes for one value of a parameter.
  package init(name: String, value: String) {
    self.name = name
    self.value = value
  }
}
