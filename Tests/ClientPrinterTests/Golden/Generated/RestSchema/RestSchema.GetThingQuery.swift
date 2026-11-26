// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// GetThingQuery is the query of `getThing`, one property to a parameter.
  public struct GetThingQuery: Sendable, Hashable {
    /// Whether to expand.
    public var expand: Bool?
    /// The contract's `fields`.
    public var fields: [String]?
    /// The contract's `at`.
    public var at: Date?
    /// The kind to read. Use the path instead.
    @available(*, deprecated, message: "The kind to read.")
    public var kind: RestSchema.ThingKind? {
      get { _kind }
      set { _kind = newValue }
    }

    var _kind: RestSchema.ThingKind?

    /// Creates a `GetThingQuery` from the properties the contract requires, the optional ones being
    /// set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.expand = nil
      self.fields = nil
      self.at = nil
      self._kind = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.expand {
        items.append(.init(name: "expand", value: String(value)))
      }
      if let value = self.fields {
        for element in value {
          items.append(.init(name: "fields", value: element))
        }
      }
      if let value = self.at {
        items.append(.init(name: "at", value: Timestamp.string(from: value)))
      }
      if let value = self._kind {
        items.append(.init(name: "kind", value: value.rawValue))
      }
      return items
    }
  }
}
