// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// ListThingsQuery is the query of `listThings`, one property to a parameter.
  public struct ListThingsQuery: Sendable, Hashable, PagedQuery {
    /// The contract's `limit`.
    public var limit: Int
    /// The contract's `speed`.
    public var speed: Double?
    /// The contract's `cursor`.
    public var cursor: String?
    /// The contract's `sort`.
    public var sort: RestSchema.ListThingsSort?

    /// Creates a `ListThingsQuery` from the properties the contract requires, the optional ones
    /// being set in `configure`.
    public init(
      limit: Int,
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.limit = limit
      self.speed = nil
      self.cursor = nil
      self.sort = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      items.append(.init(name: "limit", value: String(self.limit)))
      if let value = self.speed {
        items.append(.init(name: "speed", value: String(value)))
      }
      if let value = self.cursor {
        items.append(.init(name: "cursor", value: value))
      }
      if let value = self.sort {
        items.append(.init(name: "sort", value: value.rawValue))
      }
      return items
    }
  }
}
