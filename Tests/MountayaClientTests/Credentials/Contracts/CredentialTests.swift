import Foundation
import Testing

@testable import MountayaClient

@Suite("Credential")
struct CredentialTests {
  /// parts spells a credential out in full, for a test to compare: a credential is not
  /// `Equatable`, since a session token read per request is a function.
  private static func parts(_ credential: Credential) -> String {
    switch credential {
    case .publishable(let key, nil): "publishable(\(key))"
    case .publishable(let key, .value(let token)?): "publishable(\(key), value(\(token)))"
    case .publishable(let key, .minted(let session)?):
      "publishable(\(key), minted(\(session.token)))"
    case .publishable(let key, .function?): "publishable(\(key), function)"
    case .publishable(let key, .source?): "publishable(\(key), source)"
    case .share(let token, nil): "share(\(token))"
    case .share(let token, .some): "share(\(token), cookies)"
    #if !(os(iOS) || os(tvOS) || os(watchOS) || os(visionOS))
      case .secret(let key): "secret(\(key))"
    #endif
    }
  }

  private static let minted = RestSchema.Session(
    expires_at: Date(timeIntervalSince1970: 1_800_000_000),
    user_id: nil,
    token: "sess_minted"
  )

  private static func refusal(_ make: () throws(MountayaError) -> Credential) -> String? {
    do {
      _ = try make()
      return nil
    } catch {
      guard case .configuration(let refusal) = error else { return "not a configuration error" }
      return refusal.message
    }
  }

  @Test("a share token replaces a key beside it, and the key's companions go with it")
  func shareTokenWins() throws {
    let credential = try Credential(
      publishableKey: "pk_test_abc",
      sessionToken: "sess_abc",
      shareToken: "share_abc"
    )

    #expect(Self.parts(credential) == "share(share_abc)")
  }

  @Test("a publishable key carries its session token, as a value or as postSession answered it")
  func publishableCarriesItsSessionToken() throws {
    #expect(
      Self.parts(try Credential(publishableKey: "pk_test_abc", sessionToken: "sess_abc"))
        == "publishable(pk_test_abc, value(sess_abc))"
    )
    #expect(
      Self.parts(try Credential(publishableKey: "pk_test_abc", sessionToken: .minted(Self.minted)))
        == "publishable(pk_test_abc, minted(\(Self.minted.token)))"
    )
  }

  @Test("parts that make no credential are refused, each saying what is missing")
  func noCredential() {
    #expect(Self.refusal { () throws(MountayaError) in try Credential() } != nil)
    #expect(
      Self.refusal { () throws(MountayaError) in try Credential(sessionToken: "sess_abc") }?
        .contains("accompanies a publishable key") == true
    )
  }

  @Test("a part that is missing or that no header carries is refused at construction")
  func headerSafetyAtConstruction() {
    let empty = Self.refusal { () throws(MountayaError) in try Credential(publishableKey: "") }
    let blankToken = Self.refusal { () throws(MountayaError) in
      try Credential(publishableKey: "pk_test_abc", sessionToken: " ")
    }
    let lineBreak = Self.refusal { () throws(MountayaError) in
      try Credential(publishableKey: "pk_test\nabc")
    }
    let emptyShareBesideAKey = Self.refusal { () throws(MountayaError) in
      try Credential(publishableKey: "pk_test_abc", shareToken: "")
    }

    #expect(empty?.contains("missing") == true)
    #expect(blankToken?.contains("The session token is empty") == true)
    #expect(lineBreak?.contains("no header carries") == true)
    #expect(emptyShareBesideAKey?.contains("The share token is empty") == true)
  }

  @Test("a part with the wrong prefix is refused at construction, without quoting it")
  func prefixAtConstruction() {
    let message = Self.refusal { () throws(MountayaError) in
      try Credential(publishableKey: "sk_live_0123456789")
    }

    #expect(message?.contains("`sk_`") == true)
    #expect(message?.contains("0123456789") == false)
  }

  @Test("a secret key is sent alone, and refused beside any other part")
  func secretKeyAlone() throws {
    #expect(Self.parts(try Credential(secretKey: "sk_test_abc")) == "secret(sk_test_abc)")
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Credential(secretKey: "sk_test_abc", publishableKey: "pk_test_abc")
      } != nil
    )
    #expect(
      Self.refusal { () throws(MountayaError) in
        try Credential(secretKey: "sk_test_abc", shareToken: "share_abc")
      } != nil
    )
  }

  @Test("without a secret key the overload is the plain initializer")
  func overloadWithoutSecretKey() throws {
    let credential = try Credential(secretKey: nil, publishableKey: "pk_test_abc")

    #expect(Self.parts(credential) == "publishable(pk_test_abc)")
  }

  @Test("a case built directly is checked when its headers are")
  func caseBuiltDirectly() {
    let credential = Credential.share(token: "tok_abc")

    #expect(throws: MountayaError.self) {
      try credential.headers(for: CredentialDeclaration(acceptsShareToken: true))
    }
  }

  /// One method answers every call, as `sdk-kotlin`'s and `sdk-dart`'s do: a call that names no
  /// method is a `GET`, so a visitor's cookies answer it as the read it is.
  @Test("its headers answer a call by its method, a GET where it names none")
  func headersByMethod() throws {
    let visitor = Credential.share(token: "share_abc", cookies: { _ in "session=visitor" })
    let declaration = CredentialDeclaration()

    #expect(try visitor.headers(for: declaration) == ["Accept-Language": "*"])
    #expect(
      try visitor.headers(for: declaration, language: "fr")
        == visitor.headers(for: declaration, language: "fr", method: "GET"))
    #expect(throws: MountayaError.self) {
      try visitor.headers(for: declaration, method: "POST")
    }
  }

  @Test("a credential prints each key and token by its prefix alone, however it is printed")
  func redactedWhenPrinted() {
    let publishable = Credential.publishable(key: "pk_test_abc", sessionToken: "sess_abc")
    let expected = "Credential.publishable(key: pk_…, sessionToken: sess_…)"

    #expect("\(publishable)" == expected)
    #expect(String(reflecting: publishable) == expected)
    #expect("\(Credential.publishable(key: "pk_test_abc"))" == "Credential.publishable(key: pk_…)")
    #expect("\(Credential.secret(key: "sk_test_abc"))" == "Credential.secret(key: sk_…)")
    #expect("\(Credential.share(token: "share_abc"))" == "Credential.share(token: share_…)")
    #expect("\(Credential.share(token: "tok_abc"))" == "Credential.share(token: …)")

    var dumped = ""
    dump(publishable, to: &dumped)
    #expect(!dumped.contains("test_abc"))
    #expect(!dumped.contains("sess_abc"))
    #expect(
      "\(Credential.publishable(key: "pk_test_abc", sessionToken: .minted(Self.minted)))"
        == "Credential.publishable(key: pk_…, sessionToken: sess_…)"
    )
  }
}
