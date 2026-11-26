// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension RestSchema {
  /// PostItineraryDuplicateQuery is the query of `postItineraryDuplicate`, one property to a
  /// parameter.
  public struct PostItineraryDuplicateQuery: Sendable, Hashable {
    /// Copies from the published snapshot where the credential would otherwise
    /// copy the draft. Without it the source is read as `getItinerary` serves it:
    /// a key with a session token reads its own organization's draft, while a key
    /// alone, and any key reading another organization's itinerary, reads the
    /// last publication. `published` is the only accepted value: there is
    /// deliberately no `draft` spelling, because the param only ever narrows what
    /// the caller is served. An unrecognized value is rejected with a validation
    /// error rather than silently ignored.
    ///
    /// It applies to the SOURCE read only. The copy itself always starts as an
    /// unpublished draft, whichever surface it was taken from. Accepted here for
    /// the same reason getItinerary accepts it: a studio surface that shows the
    /// user the published copy must be able to duplicate what it is showing them,
    /// not the draft behind it.
    public var surface: RestSchema.ReadSurface?

    /// Creates a `PostItineraryDuplicateQuery` from the properties the contract requires, the
    /// optional ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.surface = nil
      configure(&self)
    }

    /// items is the query, as the request carries it: one item to a value, in the operation's
    /// order, and none for a parameter left `nil`.
    var items: [QueryItem] {
      var items: [QueryItem] = []
      if let value = self.surface {
        items.append(.init(name: "surface", value: value.rawValue))
      }
      return items
    }
  }
}
