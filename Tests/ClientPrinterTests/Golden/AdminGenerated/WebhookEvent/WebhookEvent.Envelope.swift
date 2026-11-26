// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v9.9.9,
// model digest c285dcfe8cdd86ccfcc64265c373d2f4307bdc1ceca9328599c2e2830240c57c.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension WebhookEvent {
  /// Envelope is what every event carries beside its `type` and its `data`, whichever case holds
  /// it, which a typed payload and the contract's envelope each hold.
  protocol Envelope {
    var id: String { get }
    var object: String { get }
    var created_at: Date { get }
    var request_id: String? { get }
    var livemode: Bool? { get }
    var _legacy_id: String? { get }
  }
}

extension WebhookEvent.Payload: WebhookEvent.Envelope {}

extension AdminSchema.WebhookEvent: WebhookEvent.Envelope {}
