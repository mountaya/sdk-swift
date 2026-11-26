// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation
import MountayaClient

extension AdminSchema {
  /// The person a notification email was sent to. It names who received the
  /// email and never what it said: the content of a notification is not kept.
  /// A member is named by their account, and `email` is the address that account
  /// holds when the delivery is read, answered only while the account is still a
  /// member of the organization: an address is never kept beyond the account it
  /// belongs to, and never answered once that person has left. An invitation's
  /// address, which the organization typed, is kept with the delivery. Either way
  /// at least one of the two is present.
  public struct WebhookDeliveryRecipient: Sendable, Hashable, Codable {
    /// Identifier of the recipient's account. Absent for an invitation, which
    /// is sent to the address invited whatever account it belongs to, so the
    /// delivery never tells whether one does.
    public var user_id: String?
    /// The address of the invitation the email was sent for, or the address the
    /// recipient's account holds when the delivery is read. Absent beside a
    /// `user_id` when that account has left the organization or been deleted,
    /// or when its address could not be read just then: the delivery is
    /// answered all the same, and a later read may carry it.
    public var email: String?

    /// Creates a `WebhookDeliveryRecipient` from the properties the contract requires, the optional
    /// ones being set in `configure`.
    public init(
      configure: (inout Self) -> Void = { _ in }
    ) {
      self.user_id = nil
      self.email = nil
      configure(&self)
    }

    /// Reads a `WebhookDeliveryRecipient` from the JSON object the contract describes.
    public init(from decoder: any Decoder) throws {
      let container = try decoder.container(keyedBy: WireKey.self)
      self.user_id = try container.decodeIfPresent(String.self, forKey: "user_id")
      self.email = try container.decodeIfPresent(String.self, forKey: "email")
    }

    /// Writes a `WebhookDeliveryRecipient` as the JSON object the contract describes.
    public func encode(to encoder: any Encoder) throws {
      var container = encoder.container(keyedBy: WireKey.self)
      try container.encodeIfPresent(self.user_id, forKey: "user_id")
      try container.encodeIfPresent(self.email, forKey: "email")
    }
  }
}
