// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya {
  /// tiles is every operation of the Tile API a caller awaits.
  public var tiles: Tiles {
    Tiles(sender: sender)
  }

  /// Tiles is the Tile API's operations, one method to an operation. The tile routes themselves are
  /// URL templates a map fetches, and no method here binds one.
  public struct Tiles: Sendable {
    let sender: any OperationSending

    /// The contract's `getSpec`.
    public func getSpec(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<TileSchema.Spec, [String: JSONValue]?> {
      let request = OperationRequest(facts: .getSpec)
      return try await sender.envelope(request, options: options)
    }
  }
}
