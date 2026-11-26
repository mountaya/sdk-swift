import Foundation
import Testing

@testable import MountayaClient

@Suite("AnswerError")
struct AnswerErrorTests {
  private static let now = Date(timeIntervalSince1970: 784_111_777)

  @Test("an error carries the answer's request id, tag, wait and rate-limit state as sent")
  func carriesTheAnswer() {
    let error = AnswerError.error(
      status: 412,
      headers: [
        "x-request-id": "a3ce929d0e0e47364bf92f3577b34da6", "ETag": "\"d43\"", "Retry-After": "7",
        "RateLimit-Policy": "\"minute\";q=60;w=60", "RateLimit": "\"minute\";r=0;t=17",
      ],
      envelope: ErrorEnvelope.read(
        Data(#"{"errors":[{"message":"stale","extensions":{"code":"PRECONDITION_FAILED"}}]}"#.utf8)),
      now: Self.now,
      idempotencyKey: "order-7f3a"
    )

    #expect(error.kind == .preconditionFailed)
    #expect(error.code == "PRECONDITION_FAILED")
    #expect(error.requestId == "a3ce929d0e0e47364bf92f3577b34da6")
    #expect(error.etag == "\"d43\"")
    #expect(error.retryAfter == .seconds(7))
    #expect(error.rateLimit?.policies.first?.remaining == 0)
    #expect(error.idempotencyKey == "order-7f3a")
  }

  @Test("a wait named as an HTTP date is carried in whole seconds, rounded up")
  func dateRoundsUp() {
    let headers = ["Retry-After": "Sun, 06 Nov 1994 08:49:37 GMT"]
    let halfSecondEarlier = Date(timeIntervalSince1970: 784_111_777 - 3.5)

    #expect(AnswerError.retryAfter(in: headers, now: halfSecondEarlier) == .seconds(4))
    #expect(AnswerError.retryAfter(in: ["Retry-After": "soon"], now: Self.now) == nil)
    #expect(AnswerError.retryAfter(in: [:], now: Self.now) == nil)
  }
}
