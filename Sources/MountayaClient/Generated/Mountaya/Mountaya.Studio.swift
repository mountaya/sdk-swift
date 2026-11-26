// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
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

    /// activities is every operation of `studio.activities`.
    public var activities: Activities {
      Activities(sender: sender)
    }

    /// collab is every operation of `studio.collab`.
    public var collab: Collab {
      Collab(sender: sender)
    }

    /// collections is every operation of `studio.collections`.
    public var collections: Collections {
      Collections(sender: sender)
    }

    /// itineraries is every operation of `studio.itineraries`.
    public var itineraries: Itineraries {
      Itineraries(sender: sender)
    }

    /// layers is every operation of `studio.layers`.
    public var layers: Layers {
      Layers(sender: sender)
    }

    /// organizations is every operation of `studio.organizations`.
    public var organizations: Organizations {
      Organizations(sender: sender)
    }

    /// zones is every operation of `studio.zones`.
    public var zones: Zones {
      Zones(sender: sender)
    }
  }
}
