import Foundation
import MountayaClient
import Testing

@testable import MountayaAdmin

/// `constructWebhookEvent` is what stands between a receiver and a forged delivery, so each way a
/// delivery can be wrong is driven here and named by the reason it is refused for: a header that is
/// missing or malformed, a signature no `v1` matches, a timestamp outside the tolerance. The order
/// matters as much as the rules, since `t` is signed: a forged delivery is refused for its
/// signature whatever time it claims, and never for its time.
///
/// The first case is the contract's own vector, which pins the signatures every other case signs
/// with, so the suite agrees with the contract as well as with itself.
@Suite("constructWebhookEvent")
struct ConstructWebhookEventTests {
  /// The secret of the contract's first signature vector.
  static let secret = "whsk_8f3c2a71b845d0e4c7a6b3f180d92e5a17c4e9b0d36f2a58e1c7b4093d6a2f15"
  /// The secret the vectors rotate to, which signs the second `v1` of a rotation.
  static let rotatedSecret = "whsk_2d9e41f7a0c35b86e2f1d4c907a3b58e6c1f2d4a9b07e35c8d6f1a2b4c3e5d70"
  /// The `t` of the contract's vectors: the Unix second the delivery was signed at.
  static let signedAt: Int64 = 1_763_111_564
  /// The body of the contract's vectors, an `organization.member.updated` event.
  static let body =
    #"{"id":"019a8eed-e1ad-7753-b049-b0e20d79577a","object":"webhook_event","type":"organization.member.updated","api_version":"0.8.0","created_at":"2026-11-14T09:12:44Z","organization_id":"d5a83e17-92c6-4b0f-a7d3-1e6482f9c05b","task":"organization.member.update","related_object":{"type":"organization.member","id":"7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1"},"data":{"object":{"object":"organization.member","user_id":"7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1","role":"contributor","joined_at":"2026-03-11T14:02:09Z"},"previous_attributes":{"role":"viewer"}},"request":{"id":"2c5ed6d8b8f7c706e9a0d5c5144ed90b"},"actor":{"type":"user","user_id":"1b9d4e72-0c35-4a8f-b6e1-5f2c7d904a18","key_id":"3b1f9c02-6d4e-4a87-b5c1-70e2af3d8916"}}"#
  /// The signature the contract's vectors give for `body` under `secret`.
  static let vectorSignature = "ad18de77c0892dba398f210f0f3205666e41c17025feaf8d42ae5998d8545f5d"

  /// signatureOf is the signature of `body` signed at `stated` under `secret`, its `t` written as
  /// given, as `WebhookSignature.expected(stated:body:secret:)` computes it.
  static func signatureOf(stated: String, body: String, secret: String) -> String {
    WebhookSignature.expected(stated: stated, body: Data(body.utf8), secret: secret)
  }

  /// after is the receiver's clock `seconds` after the vectors' `t`.
  static func after(_ seconds: Double) -> Date {
    Date(timeIntervalSince1970: Double(signedAt) + seconds)
  }

  /// headerOf is the header of a delivery signed at the vectors' `t` with each signature given.
  static func headerOf(_ signatures: String...) -> String {
    (["t=\(signedAt)"] + signatures.map { "v1=\($0)" }).joined(separator: ",")
  }

  /// verify verifies a delivery whose clock is `seconds` after the vectors' `t`, held to the
  /// function's own tolerance where none is given.
  static func verify(
    _ body: String = body,
    header: String?,
    secret: String = secret,
    tolerance: Duration? = nil,
    after seconds: Double = 5
  ) throws(MountayaError) -> WebhookEvent {
    guard let tolerance else {
      return try constructWebhookEvent(
        rawBody: body, signatureHeader: header, secret: secret, now: after(seconds))
    }
    return try constructWebhookEvent(
      rawBody: body, signatureHeader: header, secret: secret, tolerance: tolerance,
      now: after(seconds))
  }

  /// refusal is the reason a call was refused for, or nil where it was not refused as a
  /// signature.
  static func refusal(_ call: () throws(MountayaError) -> WebhookEvent)
    -> WebhookSignatureError.Reason?
  {
    do {
      _ = try call()
      return nil
    } catch {
      guard case .webhookSignature(let refusal) = error else { return nil }
      return refusal.reason
    }
  }

  /// configurationMessage is the message a call was refused with as set up wrong, or nil where it
  /// was not.
  static func configurationMessage(_ call: () throws(MountayaError) -> WebhookEvent) -> String? {
    do {
      _ = try call()
      return nil
    } catch {
      guard case .configuration(let refusal) = error else { return nil }
      return refusal.message
    }
  }

  @Test("the contract's vector is the event it carries, its instants decoded")
  func vector() throws {
    // The signature the rule computes is the vector's: the rule and the contract agree before
    // either signs anything else here.
    #expect(
      Self.signatureOf(stated: "\(Self.signedAt)", body: Self.body, secret: Self.secret)
        == Self.vectorSignature)

    let event = try Self.verify(header: Self.headerOf(Self.vectorSignature))

    #expect(event.type == .organizationMemberUpdated)
    guard case .organizationMemberUpdated(let payload) = event else {
      Issue.record("the vector is an organization.member.updated event, read as \(event)")
      return
    }
    #expect(payload.id == "019a8eed-e1ad-7753-b049-b0e20d79577a")
    #expect(payload.created_at == Date(timeIntervalSince1970: 1_794_647_564))
    #expect(payload.data.object.role == .contributor)
    #expect(payload.data.object.joined_at == Date(timeIntervalSince1970: 1_773_237_729))
    #expect(payload.data.previous_attributes?.role == .viewer)
    #expect(payload.request?.id == "2c5ed6d8b8f7c706e9a0d5c5144ed90b")
  }

  @Test("bytes verify as the text they spell does")
  func bytes() throws {
    let event = try constructWebhookEvent(
      rawBody: Data(Self.body.utf8),
      signatureHeader: Self.headerOf(Self.vectorSignature),
      secret: Self.secret,
      now: Self.after(5)
    )

    #expect(event.type == .organizationMemberUpdated)
  }

  @Test("a body that is not ASCII verifies by its UTF-8 bytes, as text and as bytes")
  func nonAscii() throws {
    let body = Self.body.replacingOccurrences(
      of: #""task":"organization.member.update""#, with: #""task":"organisation.café""#)
    let header = Self.headerOf(
      Self.signatureOf(stated: "\(Self.signedAt)", body: body, secret: Self.secret))

    let fromText = try Self.verify(body, header: header, after: 0)
    let fromBytes = try constructWebhookEvent(
      rawBody: Data(body.utf8), signatureHeader: header, secret: Self.secret, now: Self.after(0))

    guard case .organizationMemberUpdated(let text) = fromText,
      case .organizationMemberUpdated(let bytes) = fromBytes
    else {
      Issue.record("the body is an organization.member.updated event")
      return
    }
    #expect(text.task == "organisation.café")
    #expect(bytes.task == "organisation.café")
  }

  @Test("the header's t is signed as written, a leading zero included")
  func statedAsWritten() throws {
    let written = "0\(Self.signedAt)"
    let asWritten = Self.signatureOf(stated: written, body: Self.body, secret: Self.secret)
    let asNumber = Self.signatureOf(
      stated: "\(Self.signedAt)", body: Self.body, secret: Self.secret)

    let event = try Self.verify(header: "t=\(written),v1=\(asWritten)", after: 30)
    #expect(event.type == .organizationMemberUpdated)
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: "t=\(written),v1=\(asNumber)", after: 30)
      } == .signature)
  }

  @Test("any v1 that matches verifies, so either secret of a rotation does")
  func rotation() throws {
    let rotated = Self.signatureOf(
      stated: "\(Self.signedAt)", body: Self.body, secret: Self.rotatedSecret)
    let header = Self.headerOf(Self.vectorSignature, rotated)

    #expect(try Self.verify(header: header, after: 30).type == "organization.member.updated")
    #expect(
      try Self.verify(header: header, secret: Self.rotatedSecret, after: 30).type
        == "organization.member.updated")
    // The control: a secret neither `v1` was signed with matches neither.
    let other = String(Self.secret.dropLast()) + "0"
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header, secret: other, after: 30)
      } == .signature)
  }

  @Test("a body changed on the way, and one signed with another secret, are refused for it")
  func tampered() {
    let tampered = Self.body.replacingOccurrences(
      of: #""role":"contributor""#, with: #""role":"admin""#)

    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(tampered, header: Self.headerOf(Self.vectorSignature))
      } == .signature)
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: Self.headerOf(Self.vectorSignature), secret: Self.rotatedSecret)
      } == .signature)
    // One character off at the end, and a signature of another length, are each no match.
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: Self.headerOf(String(Self.vectorSignature.dropLast()) + "e"))
      } == .signature)
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: Self.headerOf(String(Self.vectorSignature.dropLast(2))))
      } == .signature)
    // The comparison is of the bytes written: an uppercase spelling of the signature is another.
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: Self.headerOf(Self.vectorSignature.uppercased()))
      } == .signature)
  }

  @Test("a timestamp past the tolerance either way is refused, and one at it accepted")
  func tolerance() throws {
    let header = Self.headerOf(Self.vectorSignature)

    #expect(try Self.verify(header: header, after: 300).type == "organization.member.updated")
    #expect(try Self.verify(header: header, after: -300).type == "organization.member.updated")
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header, after: 301)
      } == .timestamp)
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header, after: -301)
      } == .timestamp)
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header, after: 300.5)
      } == .timestamp)
  }

  @Test("the signature is judged before the time, so a forged delivery is refused for it")
  func signatureBeforeTime() {
    let tampered = Self.body.replacingOccurrences(
      of: #""role":"contributor""#, with: #""role":"admin""#)

    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(tampered, header: Self.headerOf(Self.vectorSignature), after: 9000)
      } == .signature)
  }

  @Test("the timestamp is held to the tolerance a receiver states")
  func statedTolerance() throws {
    let header = Self.headerOf(Self.vectorSignature)

    #expect(
      try Self.verify(header: header, tolerance: .seconds(600), after: 599).type
        == "organization.member.updated")
    #expect(
      try Self.verify(header: header, tolerance: .zero, after: 0).type
        == "organization.member.updated")
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header, tolerance: .zero, after: 1)
      } == .timestamp)
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header, tolerance: .seconds(600), after: 601)
      } == .timestamp)
  }

  @Test("a tolerance is a span, so a fraction of a second holds as it is stated")
  func fractionalTolerance() throws {
    let header = Self.headerOf(Self.vectorSignature)

    #expect(
      try Self.verify(header: header, tolerance: .milliseconds(1500), after: 1.5).type
        == "organization.member.updated")
    #expect(
      try Self.verify(header: header, tolerance: .milliseconds(1500), after: -1.5).type
        == "organization.member.updated")
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header, tolerance: .milliseconds(1500), after: 1.6)
      } == .timestamp)
  }

  @Test(
    "a header the request does not carry, an empty one and a blank one are missing",
    arguments: [nil, "", "  ", "\t\u{3000}"] as [String?]
  )
  func missingHeader(header: String?) {
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header)
      } == .missingHeader)
  }

  @Test(
    "a header that is not t=<unix seconds>,v1=<signature> is malformed",
    arguments: [
      "v1=\(vectorSignature)",
      "t=\(signedAt)",
      "t=\(signedAt),t=\(signedAt),v1=\(vectorSignature)",
      "t=yesterday,v1=\(vectorSignature)",
      "t=\(signedAt).5,v1=\(vectorSignature)",
      "t=-\(signedAt),v1=\(vectorSignature)",
      "t=,v1=\(vectorSignature)",
      "t=99999999999999999999,v1=\(vectorSignature)",
      "t=9007199254740992,v1=\(vectorSignature)",
      "t=\(signedAt),v1",
      "t=\(signedAt),v1=\(vectorSignature),",
      "t=\(signedAt),v0=\(vectorSignature)",
      "t=١٧٦٣١١١٥٦٤,v1=\(vectorSignature)",
    ]
  )
  func malformedHeader(header: String) {
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Self.verify(header: header)
      } == .malformedHeader)
  }

  @Test("a scheme it does not compute is passed over, and white space around an element trimmed")
  func passedOver() throws {
    #expect(
      try Self.verify(header: "t=\(Self.signedAt),v0=00ff,v1=\(Self.vectorSignature)").type
        == "organization.member.updated")
    #expect(
      try Self.verify(header: "t=\(Self.signedAt), v1=\(Self.vectorSignature)").type
        == "organization.member.updated")
    #expect(
      try Self.verify(header: " t = \(Self.signedAt) ,\tv1 =\u{A0}\(Self.vectorSignature)\u{FEFF}")
        .type == "organization.member.updated")
  }

  @Test("the instants of previous attributes are decoded as the object's own")
  func previousInstants() throws {
    let body =
      #"{"actor":{"type":"user","user_id":"1b9d4e72-0c35-4a8f-b6e1-5f2c7d904a18"},"api_version":"0.8.0","created_at":"2026-11-14T09:12:44Z","data":{"object":{"object":"zone","id":"5f1c8a94-2d63-4e07-b9a1-0c4e7d2f8b36","organization_id":"d5a83e17-92c6-4b0f-a7d3-1e6482f9c05b","name":"Rockfall","description":null,"level":"danger","mode":"polygon","status":"published","is_private":false,"start_at":"2026-11-20T06:00:00Z","end_at":null,"version":7,"created_by":{"id":"1b9d4e72-0c35-4a8f-b6e1-5f2c7d904a18"},"created_at":"2026-05-02T10:14:51Z","updated_at":"2026-11-14T09:12:44Z"},"previous_attributes":{"name":"2026-01-01T00:00:00Z","start_at":"2026-11-18T06:00:00Z","end_at":null}},"id":"019a8d5b-1059-73c5-849c-ffaf86349866","object":"webhook_event","organization_id":"d5a83e17-92c6-4b0f-a7d3-1e6482f9c05b","related_object":{"id":"5f1c8a94-2d63-4e07-b9a1-0c4e7d2f8b36","type":"zone"},"request":null,"task":"zone.update","type":"zone.updated"}"#
    let header = Self.headerOf(
      Self.signatureOf(stated: "\(Self.signedAt)", body: body, secret: Self.secret))

    let event = try Self.verify(body, header: header, after: 1)

    guard case .zoneUpdated(let payload) = event else {
      Issue.record("the body is a zone.updated event, read as \(event)")
      return
    }
    let previous = try #require(payload.data.previous_attributes)
    #expect(payload.data.object.start_at == Date(timeIntervalSince1970: 1_795_154_400))
    #expect(previous.start_at == .some(Date(timeIntervalSince1970: 1_794_981_600)))
    // A field the contract types as a string stays one, whatever it holds.
    #expect(previous.name == "2026-01-01T00:00:00Z")
    // A field that moved from null holds null, and one that did not move holds nothing.
    #expect(previous.end_at == .some(nil))
    #expect(previous.description == nil)
    #expect(payload.request == nil)
  }

  @Test("an event of a type this build does not know is delivered as the envelope, not refused")
  func unknownType() throws {
    let body = Self.body
      .replacingOccurrences(
        of: #""type":"organization.member.updated""#,
        with: #""type":"organization.member.teleported""#
      )
      .replacingOccurrences(
        of: #""object":"organization.member","user_id""#,
        with: #""object":"organization.teleport","user_id""#)
    let header = Self.headerOf(
      Self.signatureOf(stated: "\(Self.signedAt)", body: body, secret: Self.secret))

    let event = try Self.verify(body, header: header)

    #expect(event.type == "organization.member.teleported")
    guard case .unknown(let envelope) = event else {
      Issue.record("a type this build does not know is unknown, read as \(event)")
      return
    }
    #expect(envelope.id == "019a8eed-e1ad-7753-b049-b0e20d79577a")
    #expect(
      envelope.data.object
        == .unknown(
          [
            "object": "organization.teleport", "user_id": "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1",
            "role": "contributor", "joined_at": "2026-03-11T14:02:09Z",
          ]))
  }

  @Test(
    "a body that verifies and holds no envelope at all is refused as set up wrong",
    arguments: [
      #"{"hello":"world"}"#,
      #"not json"#,
      // An envelope member missing: no event is delivered without its `id`.
      #"{"type":"zone.updated","object":"webhook_event","api_version":"0.8.0","created_at":"2026-11-14T09:12:44Z","organization_id":"o","task":"zone.update","related_object":{"id":"z","type":"zone"},"data":{"object":{"object":"zone"}},"request":null,"actor":{"type":"mountaya"}}"#,
    ]
  )
  func undecodable(body: String) throws {
    let header = Self.headerOf(
      Self.signatureOf(stated: "\(Self.signedAt)", body: body, secret: Self.secret))

    do {
      _ = try Self.verify(body, header: header)
      Issue.record("a body that is no event was read as one")
    } catch {
      guard case .configuration(let refusal) = error else {
        Issue.record("refused as \(error.name), and not as set up wrong")
        return
      }
      #expect(refusal.cause is DecodingError)
      #expect(refusal.message.hasPrefix("The body verified, and holds no webhook event"))
    }
  }

  @Test("a known type whose object its types do not read is delivered as the envelope, held whole")
  func untypedObject() throws {
    // A zone carrying its name alone: the zone's own type reads none of it, and the envelope's
    // union reads it as the zone it says it is, so it is held as it arrived.
    let body =
      #"{"actor":{"type":"user","user_id":"1b9d4e72-0c35-4a8f-b6e1-5f2c7d904a18"},"api_version":"0.8.0","created_at":"2026-11-14T09:12:44Z","data":{"object":{"object":"zone","name":"Rockfall"},"previous_attributes":{"name":"Old"}},"id":"019a8d5b-1059-73c5-849c-ffaf86349866","object":"webhook_event","organization_id":"d5a83e17-92c6-4b0f-a7d3-1e6482f9c05b","related_object":{"id":"5f1c8a94-2d63-4e07-b9a1-0c4e7d2f8b36","type":"zone"},"request":null,"task":"zone.update","type":"zone.updated"}"#
    let header = Self.headerOf(
      Self.signatureOf(stated: "\(Self.signedAt)", body: body, secret: Self.secret))

    let event = try Self.verify(body, header: header)

    guard case .unknown(let envelope) = event else {
      Issue.record("a payload its types do not read is unknown, read as \(event)")
      return
    }
    #expect(event.type == "zone.updated")
    #expect(event.id == "019a8d5b-1059-73c5-849c-ffaf86349866")
    #expect(envelope.data.object == .unknown(["object": "zone", "name": "Rockfall"]))
    #expect(envelope.data.previous_attributes == ["name": "Old"])
  }

  @Test("previous attributes its types do not read deliver the envelope, the object typed")
  func untypedAttributes() throws {
    let body = Self.body.replacingOccurrences(
      of: #""previous_attributes":{"role":"viewer"}"#, with: #""previous_attributes":{"role":5}"#)
    let header = Self.headerOf(
      Self.signatureOf(stated: "\(Self.signedAt)", body: body, secret: Self.secret))

    let event = try Self.verify(body, header: header)

    guard case .unknown(let envelope) = event,
      case .OrganizationMemberEventObject(let member) = envelope.data.object
    else {
      Issue.record("the envelope's own types read the object, read as \(event)")
      return
    }
    #expect(member.role == .contributor)
    #expect(envelope.data.previous_attributes == ["role": 5])
    #expect(event.task == "organization.member.update")
  }

  @Test("every member of the envelope is read off every case alike, an untyped one included")
  func accessors() throws {
    let typed = try Self.verify(header: Self.headerOf(Self.vectorSignature))
    let body = Self.body.replacingOccurrences(
      of: #""type":"organization.member.updated""#, with: #""type":"organization.member.moved""#)
    let untyped = try Self.verify(
      body,
      header: Self.headerOf(
        Self.signatureOf(stated: "\(Self.signedAt)", body: body, secret: Self.secret)))

    for event in [typed, untyped] {
      #expect(event.id == "019a8eed-e1ad-7753-b049-b0e20d79577a")
      #expect(event.object == "webhook_event")
      #expect(event.api_version == "0.8.0")
      #expect(event.created_at == Date(timeIntervalSince1970: 1_794_647_564))
      #expect(event.organization_id == "d5a83e17-92c6-4b0f-a7d3-1e6482f9c05b")
      #expect(event.task == "organization.member.update")
      #expect(event.related_object.id == "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1")
      #expect(event.request?.id == "2c5ed6d8b8f7c706e9a0d5c5144ed90b")
      #expect(event.actor.type == .user)
    }
    #expect(typed.type == "organization.member.updated")
    #expect(untyped.type == "organization.member.moved")
  }

  @Test("a secret without its prefix is refused, and never quoted")
  func bareSecret() throws {
    let bare = String(Self.secret.dropFirst("whsk_".count))

    let message = try #require(
      Self.configurationMessage { () throws(MountayaError) in
        try Self.verify(header: Self.headerOf(Self.vectorSignature), secret: bare)
      })
    #expect(message.contains("whsk_"))
    #expect(!message.contains(bare))
  }

  @Test("a secret key in place of the signing secret is refused, though it verifies its own MAC")
  func secretKey() throws {
    let secretKey = "sk_" + String(Self.secret.dropFirst("whsk_".count))
    let header = Self.headerOf(
      Self.signatureOf(stated: "\(Self.signedAt)", body: Self.body, secret: secretKey))

    let message = try #require(
      Self.configurationMessage { () throws(MountayaError) in
        try Self.verify(header: header, secret: secretKey)
      })
    #expect(message.contains("does not start with `whsk_`"))
    #expect(!message.contains(secretKey))
  }

  /// A `Duration` is always a finite span, so a tolerance can only be refused for lying below 0.
  @Test(
    "a tolerance below 0 is refused, naming it in seconds",
    arguments: [(Duration.seconds(-1), "-1"), (.milliseconds(-1500), "-1.5")]
  )
  func refusedTolerance(tolerance: Duration, printed: String) throws {
    let message = try #require(
      Self.configurationMessage { () throws(MountayaError) in
        try Self.verify(header: Self.headerOf(Self.vectorSignature), tolerance: tolerance)
      })

    #expect(
      message
        == "A tolerance of \(printed) seconds is no number of seconds from 0: pass one, or leave "
        + "it out for 300.")
  }

  @Test("a clock that is no finite instant is refused", arguments: [Double.nan, .infinity])
  func refusedClock(seconds: Double) {
    #expect(
      Self.configurationMessage { () throws(MountayaError) in
        try constructWebhookEvent(
          rawBody: Self.body, signatureHeader: Self.headerOf(Self.vectorSignature),
          secret: Self.secret, now: Date(timeIntervalSince1970: seconds))
      } == "The receiver's clock is no finite instant: pass one, or leave it out.")
  }

  @Test("a call set up wrong is refused before its header is read")
  func configurationFirst() {
    #expect(
      Self.configurationMessage { () throws(MountayaError) in
        try Self.verify(header: nil, secret: "sk_bare")
      } != nil)
  }

  @Test("a refusal is an error of the family, named by the contract and no answer of the API")
  func family() {
    do {
      _ = try Self.verify(header: nil)
      Issue.record("a delivery with no header verified")
    } catch {
      #expect(error.name == "WebhookSignatureError")
      #expect(isMountayaError(error))
      #expect(!isAPIError(error))
      #expect(error.idempotencyKey == nil)
      guard case .webhookSignature(let refusal) = error else {
        Issue.record("refused as \(error.name)")
        return
      }
      #expect(refusal.reason == .missingHeader)
      #expect(refusal.reason.rawValue == "missing-header")
      #expect(refusal.message.hasPrefix("The request carries no `Mountaya-Signature` header"))
      #expect(error.description == "WebhookSignatureError: \(refusal.message)")
    }
  }

  /// An app catches every failure of the SDK by one pattern, `catch let error as MountayaError`,
  /// so a delivery's refusal is a case of the core's ladder though the admin unit raises it
  /// (SPEC.md section 4). The receiver below throws whatever it throws, as a server's handler does,
  /// so the catch is the cast an app makes and not the typed throw's own.
  @Test("the SDK-wide catch catches a delivery's refusal, its reason the contract's")
  func caughtAsEveryFailure() {
    func receive(_ header: String?) throws -> WebhookEvent {
      try Self.verify(header: header)
    }

    for (header, reason) in [
      (nil, WebhookSignatureError.Reason.missingHeader),
      ("t=1", .malformedHeader),
      (Self.headerOf(String(repeating: "0", count: 64)), .signature),
    ] {
      do {
        _ = try receive(header)
        Issue.record("a delivery that cannot be trusted verified")
      } catch let error as MountayaError {
        guard case .webhookSignature(let refusal) = error else {
          Issue.record("caught as \(error.name)")
          continue
        }
        #expect(refusal.reason == reason)
        #expect(isMountayaError(error))
      } catch {
        Issue.record("a refusal the SDK-wide catch misses: \(error)")
      }
    }
  }

  @Test("the time is judged by the platform's clock where no clock is stated")
  func platformClock() throws {
    let stated = "\(Int64(Date().timeIntervalSince1970))"
    let header =
      "t=\(stated),v1=\(Self.signatureOf(stated: stated, body: Self.body, secret: Self.secret))"

    let event = try constructWebhookEvent(
      rawBody: Self.body, signatureHeader: header, secret: Self.secret)
    #expect(event.type == "organization.member.updated")
    // The vectors' `t` lies a year and more behind any clock this runs on.
    #expect(
      Self.refusal { () throws(MountayaError) in
        try constructWebhookEvent(
          rawBody: Self.body, signatureHeader: Self.headerOf(Self.vectorSignature),
          secret: Self.secret)
      } == .timestamp)
    #expect(
      try constructWebhookEvent(
        rawBody: Self.body, signatureHeader: Self.headerOf(Self.vectorSignature),
        secret: Self.secret, tolerance: .seconds(1e12)
      ).type == "organization.member.updated")
  }

  @Test("a timestamp refusal names the instant signed at and the distance from the clock")
  func timestampMessage() {
    do {
      _ = try Self.verify(header: Self.headerOf(Self.vectorSignature), after: 301)
      Issue.record("a delivery past the tolerance verified")
    } catch {
      #expect(
        error.description
          == "WebhookSignatureError: The delivery was signed at 2025-11-14T09:12:44.000Z, 301 "
          + "seconds from this clock, past the tolerance of 300 seconds: a delivery replayed later "
          + "is refused this way, and where the clock is wrong, set it right.")
    }
  }
}
