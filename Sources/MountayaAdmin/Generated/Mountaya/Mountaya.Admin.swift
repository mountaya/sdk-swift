// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
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

    /// billing is every operation of `admin.billing`.
    public var billing: Billing {
      Billing(sender: sender)
    }

    /// invitations is every operation of `admin.invitations`.
    public var invitations: Invitations {
      Invitations(sender: sender)
    }

    /// keys is every operation of `admin.keys`.
    public var keys: Keys {
      Keys(sender: sender)
    }

    /// members is every operation of `admin.members`.
    public var members: Members {
      Members(sender: sender)
    }

    /// organizations is every operation of `admin.organizations`.
    public var organizations: Organizations {
      Organizations(sender: sender)
    }

    /// sessions is every operation of `admin.sessions`.
    public var sessions: Sessions {
      Sessions(sender: sender)
    }

    /// users is every operation of `admin.users`.
    public var users: Users {
      Users(sender: sender)
    }

    /// webhooks is every operation of `admin.webhooks`.
    public var webhooks: Webhooks {
      Webhooks(sender: sender)
    }
  }
}
