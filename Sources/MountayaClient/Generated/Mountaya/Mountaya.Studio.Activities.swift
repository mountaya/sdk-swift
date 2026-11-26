// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Studio {
  /// Activities is every operation of `studio.activities`, one method to an operation.
  public struct Activities: Sendable {
    let sender: any OperationSending

    /// List all activity categories and their activities.
    ///
    /// Returns all available activities grouped by category. Each activity includes
    /// its capabilities (e.g., routing support, elevation profiles). It is a
    /// catalog, the same for every caller, so it is not paged: every category
    /// comes back at once.
    ///
    /// Reads are limited per minute. A publishable key sent without a session
    /// token, or with one minted without `user_id`, is held to 600 per client IP
    /// address and then 6000 per organization; a key with a session token naming a
    /// user to 1200 per user the token names and then 6000 per organization,
    /// counted apart from the reads made under the key alone; and a share token to
    /// 600 per client IP address and then 6000 per organization that owns the link.
    /// Past any of them the read is a `429` carrying `Retry-After`. A share token
    /// not resolved moments earlier is refused the same way when its client IP
    /// address has had 60 unknown share tokens refused within the minute.
    ///
    /// Requires a publishable key with the `publishing` scope, or the
    /// `studio-embedded` scope that includes it, or a share token: a share view
    /// names each segment's activity from the same catalog an embed does.
    public func getActivities(
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<[RestSchema.CategoryActivities], [String: JSONValue]?> {
      let request = OperationRequest(facts: .getActivities)
      return try await sender.envelope(request, options: options)
    }
  }
}
