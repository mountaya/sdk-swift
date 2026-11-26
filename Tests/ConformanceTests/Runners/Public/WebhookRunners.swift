import Foundation
import GateSupport
import MountayaAdmin
import MountayaClient

extension PublicRunners {
  /// webhooksVerifySignature verifies the case's delivery through the published function, its
  /// body as the text it arrived as and its clock the case's `now`, which a native runner states
  /// rather than fakes the wall clock (SPEC.md section 11), and its tolerance the function's own
  /// where the case states none.
  ///
  /// A delivery that verifies answers `valid` and the event's `id` and `type`: the type as the
  /// event names it, and the id as the event writes it back, so the case proves the body was read
  /// whole. One that is refused answers the class the refusal declares and its reason, which the
  /// fixture writes as a value beside `valid`, not as a refusal of the call: a signature refused
  /// answers its `WebhookSignatureError` and that error's reason, and a delivery that verifies and
  /// holds no envelope the `ConfigurationError` it raises, which names no reason.
  static let webhooksVerifySignature = Runner(
    id: "transport.webhooks.verify-signature", table: .public
  ) { _, fixtureCase in
    let input = fixtureCase.input
    let body = try input.string(at: "body")
    let header = try input.optionalString(at: "header")
    let secret = try input.string(at: "secret")
    let now = Date(timeIntervalSince1970: try input.number(at: "now"))
    let tolerance = try input.optionalNumber(at: "toleranceSeconds")
    let event: WebhookEvent
    // An untyped catch that rethrows by hand: Swift 6.2.3, the floor, fails to compile a typed
    // `do` whose pattern catch leaves the other errors to rethrow themselves (an ownership
    // error in SILGen).
    do {
      if let tolerance {
        event = try constructWebhookEvent(
          rawBody: body, signatureHeader: header, secret: secret,
          tolerance: .seconds(tolerance), now: now)
      } else {
        event = try constructWebhookEvent(
          rawBody: body, signatureHeader: header, secret: secret, now: now)
      }
    } catch let error as MountayaError {
      let reason: OrderedJSON
      switch error {
      case .webhookSignature(let refusal): reason = .string(refusal.reason.rawValue)
      case .configuration: reason = .null
      default: throw error
      }
      return .value(
        .object([
          OrderedJSON.Member(key: "valid", value: .bool(false)),
          OrderedJSON.Member(key: "error", value: .string(error.name)),
          OrderedJSON.Member(key: "reason", value: reason),
        ])
      )
    }
    let written = try OrderedJSON.parse(
      String(decoding: try JSONEncoder().encode(event), as: UTF8.self))
    var read = [
      OrderedJSON.Member(key: "id", value: written["id"] ?? .null),
      OrderedJSON.Member(key: "type", value: .string(event.type.rawValue)),
    ]
    // An event of a type this build does not know is read as one, and says so.
    if case .unknown = event {
      read.append(OrderedJSON.Member(key: "known", value: .bool(false)))
    }
    return .value(
      .object([
        OrderedJSON.Member(key: "valid", value: .bool(true)),
        OrderedJSON.Member(key: "event", value: .object(read)),
      ])
    )
  }
}
