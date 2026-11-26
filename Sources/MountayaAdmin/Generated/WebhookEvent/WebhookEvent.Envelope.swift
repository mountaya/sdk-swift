// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
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
    var api_version: String { get }
    var created_at: Date { get }
    var organization_id: String { get }
    var task: String { get }
    var related_object: AdminSchema.WebhookEventRelatedObject { get }
    var request: AdminSchema.WebhookEventRequest? { get }
    var actor: AdminSchema.WebhookEventActor { get }
  }
}

extension WebhookEvent.Payload: WebhookEvent.Envelope {}

extension AdminSchema.WebhookEvent: WebhookEvent.Envelope {}
