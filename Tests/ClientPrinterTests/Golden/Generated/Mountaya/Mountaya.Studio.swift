// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya {
  /// studio is every operation of the contract's `studio` group.
  public var studio: Studio {
    Studio(sender: sender)
  }

  /// Studio is the `studio` group's resources, one accessor to a resource.
  public struct Studio: Sendable {
    let sender: any OperationSending

    /// things is every operation of `studio.things`.
    public var things: Things {
      Things(sender: sender)
    }
  }
}
