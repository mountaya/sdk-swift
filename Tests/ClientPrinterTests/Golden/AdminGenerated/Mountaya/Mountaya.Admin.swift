// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension Mountaya {
  /// admin is every operation of the contract's `admin` group. The client's admin unit declares it,
  /// so importing `MountayaAdmin` is the whole of what a call into it asks.
  public var admin: Admin {
    Admin(sender: sender)
  }

  /// Admin is the `admin` group's resources, one accessor to a resource.
  public struct Admin: Sendable {
    let sender: any OperationSending

    /// exports is every operation of `admin.exports`.
    public var exports: Exports {
      Exports(sender: sender)
    }
  }
}
