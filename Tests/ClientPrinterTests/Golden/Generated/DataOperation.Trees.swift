// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension DataOperation {
  /// lookup is the Data API's `lookup`, with every field of its result in the schema's order, which
  /// is its full selection, and its budget.
  static let lookup = DataOperation(
    name: "lookup",
    inputType: "LookupInput!",
    selection: [
      "items": [
        "name": true,
        "when": true,
      ],
      "total": true,
    ],
    timeout: .milliseconds(30000)
  )
}
