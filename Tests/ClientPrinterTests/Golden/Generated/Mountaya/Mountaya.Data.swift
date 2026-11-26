// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya {
  /// data is every operation of the Data API.
  public var data: Data {
    Data(sender: sender)
  }

  /// Data is the Data API's operations, one method to an operation. A `select` narrows the document
  /// sent and never the type returned: a field left out is `nil` in the result.
  public struct Data: Sendable {
    let sender: any OperationSending

    /// Looks things up.
    public func lookup(
      input: DataSchema.LookupInput,
      select: FieldSelection? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> DataSchema.LookupResult {
      try await sender.query(
        .lookup,
        facts: .lookup,
        input: input,
        select: select,
        options: options
      )
    }
  }
}
