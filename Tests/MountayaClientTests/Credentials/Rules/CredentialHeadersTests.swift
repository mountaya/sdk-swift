import Foundation
import Testing

@testable import MountayaClient

@Suite("CredentialHeaders")
struct CredentialHeadersTests {
  private static func session(user: String?) -> SessionToken {
    .minted(
      RestSchema.Session(
        expires_at: Date(timeIntervalSince1970: 1_800_000_000),
        user_id: user,
        token: "sess_abc"
      )
    )
  }

  private static let member = session(user: "7a4e1c98-3b52-4f60-9d81-c05e2f7a83b1")
  private static let nobody = session(user: nil)
  private static let actsAsUser = CredentialDeclaration(
    actingUser: .required, requiresSession: true)

  private static func refusal(
    _ credential: Credential,
    language: String? = nil,
    for declaration: CredentialDeclaration = CredentialDeclaration()
  ) -> String? {
    do {
      _ = try CredentialHeaders.headers(credential, language: language, for: declaration)
      return nil
    } catch {
      guard case .configuration(let refusal) = error else { return "not a configuration error" }
      return refusal.message
    }
  }

  private static func refused(
    _ credential: Credential,
    language: String? = nil,
    for declaration: CredentialDeclaration = CredentialDeclaration()
  ) -> Bool {
    refusal(credential, language: language, for: declaration) != nil
  }

  @Test("a publishable key sends its key and its session token, and no header names a user")
  func publishableProjection() throws {
    let headers = try CredentialHeaders.headers(
      .publishable(key: "pk_test_abc", sessionToken: Self.member),
      language: nil,
      for: CredentialDeclaration()
    )

    #expect(
      headers == [
        "X-API-Key": "pk_test_abc", "X-Session-Token": "sess_abc", "Accept-Language": "*",
      ]
    )
  }

  @Test("the language rides as Accept-Language beside every credential, and `*` where it is unset")
  func language() throws {
    let share = CredentialDeclaration(acceptsShareToken: true)

    #expect(
      try CredentialHeaders.headers(.publishable(key: "pk_test_abc"), language: "fr", for: .init())
        == ["X-API-Key": "pk_test_abc", "Accept-Language": "fr"]
    )
    #expect(
      try CredentialHeaders.headers(.share(token: "share_abc"), language: "de", for: share)
        == ["X-Share-Token": "share_abc", "Accept-Language": "de"]
    )
    #expect(
      try CredentialHeaders.headers(.publishable(key: "pk_test_abc"), language: nil, for: .init())
        == ["X-API-Key": "pk_test_abc", "Accept-Language": "*"]
    )
  }

  @Test("an operation that takes no credential is sent the language alone, whatever the credential")
  func takesNoCredential() throws {
    let declaration = CredentialDeclaration(takesNoCredential: true)

    #expect(
      try CredentialHeaders.headers(.secret(key: "sk_test_abc"), language: nil, for: declaration)
        == ["Accept-Language": "*"]
    )
    #expect(
      try CredentialHeaders.headers(.share(token: "share_abc"), language: nil, for: declaration)
        == ["Accept-Language": "*"]
    )
    #expect(
      try CredentialHeaders.headers(
        .publishable(key: "pk_test_abc", sessionToken: Self.nobody),
        language: "pt-BR",
        for: declaration
      ) == ["Accept-Language": "pt-BR"]
    )
  }

  @Test("a malformed credential or language is refused even where the operation takes none")
  func malformedIsAlwaysRefused() {
    let none = CredentialDeclaration(takesNoCredential: true)

    #expect(Self.refused(.publishable(key: "zz_abc"), for: none))
    #expect(Self.refused(.publishable(key: ""), for: none))
    #expect(Self.refused(.publishable(key: "pk_test_abc"), language: "", for: none))
  }

  @Test(
    "a member that is empty or whitespace alone is missing, and refused as such",
    arguments: ["", " ", "   ", "\t"]
  )
  func blankMembers(value: String) {
    #expect(Self.refusal(.publishable(key: value))?.contains("is empty") == true)
    #expect(
      Self.refusal(.publishable(key: "pk_test_abc", sessionToken: .value(value)))?
        .contains("The session token is empty") == true
    )
    #expect(Self.refusal(.share(token: value))?.contains("The share token is empty") == true)
    #expect(Self.refusal(.secret(key: value))?.contains("The secret key is empty") == true)
    #expect(
      Self.refusal(.publishable(key: "pk_test_abc"), language: value)?.contains("language is empty")
        == true)
  }

  @Test(
    "a member holding a control character or a character outside printable ASCII is refused",
    arguments: [
      "pk_test\nabc", "pk_test\r\nabc", "pk_test\tabc", "pk_test\u{0}abc", "pk_test\u{7F}abc",
      "pk_test\u{85}abc", "pk_test_\u{0101}bc", "pk_test_😀", "pk_test_ébc", "pk_test_a\u{A0}bc",
    ]
  )
  func uncarriedMembers(key: String) {
    #expect(Self.refusal(.publishable(key: key))?.contains("no header carries") == true)
    #expect(
      Self.refusal(.publishable(key: "pk_test_abc"), language: String(key.dropFirst(3)))?
        .contains("no header carries") == true
    )
  }

  /// Apple's loader writes a Latin-1 character as its one byte and FoundationNetworking's as two
  /// UTF-8 bytes a server reads as two other characters, so every platform refuses it before any
  /// request (`sdk/SPEC.md` §1).
  @Test("a letter of Latin-1 is refused on every platform, in a member and in the language")
  func latin1IsRefused() {
    #expect(
      Self.refusal(.publishable(key: "pk_test_é ÿ"))?.contains("outside printable ASCII") == true)
    #expect(
      Self.refusal(.publishable(key: "pk_test_abc"), language: "fr-CH, fré")?
        .contains("no header carries") == true)
  }

  @Test("a visitor's cookie the client writes is held to what a header carries")
  func cookie() throws {
    #expect(throws: Never.self) { try CredentialHeaders.checkCookie("session=visitor; theme=dark") }
    for refused in ["session=vïsitor", "session=a\nb", "session=\u{A0}"] {
      do {
        try CredentialHeaders.checkCookie(refused)
        Issue.record("the cookie \(refused.debugDescription) was carried")
      } catch {
        guard case .configuration(let refusal) = error else {
          Issue.record("not a configuration error")
          continue
        }
        #expect(!refusal.message.contains(refused))
      }
    }
  }

  @Test("a projection prints the names of its headers alone, never a credential")
  func projectionPrintsNames() throws {
    let projection = try CredentialHeaders.project(
      .publishable(key: "pk_test_7c1d", sessionToken: "sess_9f2c4e"),
      session: try ResolvedSession.reading("sess_9f2c4e", snapshot: nil), language: nil,
      for: .init(), isRead: true)
    var dumped = ""
    dump(projection, to: &dumped)

    for printed in [String(describing: projection), String(reflecting: projection), dumped] {
      #expect(!printed.contains("9f2c4e") && !printed.contains("7c1d"), "\(printed)")
      #expect(printed.contains("X-Session-Token"), "\(printed)")
    }
  }

  @Test("a share token asking for cookies reads on the visitor's session and refuses a write")
  func cookieShareByMethod() throws {
    let visitor = Credential.share(token: "share_abc", cookies: { _ in "session=visitor" })

    #expect(
      try CredentialHeaders.headers(visitor, language: nil, for: .init(), method: "GET")
        == ["Accept-Language": "*"]
    )
    #expect(
      try CredentialHeaders.headers(visitor, language: "fr", for: .init(), method: "HEAD")
        == ["Accept-Language": "fr"]
    )
    for write in ["POST", "PUT", "PATCH", "DELETE"] {
      #expect(throws: MountayaError.self) {
        try CredentialHeaders.headers(visitor, language: nil, for: .init(), method: write)
      }
    }
  }

  @Test("a read is a GET, a HEAD or an OPTIONS in any letter case, and every other method a write")
  func readMethods() throws {
    let visitor = Credential.share(token: "share_abc", cookies: { _ in "session=visitor" })

    for read in ["get", "Get", "head", "OPTIONS", "options", "oPtIoNs"] {
      #expect(
        try CredentialHeaders.headers(visitor, language: nil, for: .init(), method: read)
          == ["Accept-Language": "*"],
        "\(read)"
      )
    }
    for write in ["post", "Delete", "TRACE", "CONNECT", "GETS", "ＧＥＴ"] {
      #expect(throws: MountayaError.self, "\(write)") {
        try CredentialHeaders.headers(visitor, language: nil, for: .init(), method: write)
      }
    }
  }

  @Test("a read that requires a session goes out on the visitor's session, and a write is refused")
  func cookieReadRequiringSession() throws {
    let visitor = Credential.share(token: "share_abc", cookies: { _ in "session=visitor" })
    let session = CredentialDeclaration(requiresSession: true)

    let projection = try CredentialHeaders.project(
      visitor, session: nil, language: nil, for: session, isRead: true)
    #expect(projection.headers == ["Accept-Language": "*"])
    #expect(projection.cookies != nil)
    #expect(
      try CredentialHeaders.headers(visitor, language: nil, for: session, method: "GET")
        == ["Accept-Language": "*"]
    )
    #expect(throws: MountayaError.self) {
      try CredentialHeaders.headers(visitor, language: nil, for: session, method: "POST")
    }
    // A share token that asks for no cookies has no session to send, and is refused as before.
    #expect(Self.refused(.share(token: "share_abc"), for: session))
    // The operation a secret key authenticates is refused under every share token.
    #expect(throws: MountayaError.self) {
      try CredentialHeaders.headers(
        visitor, language: nil, for: CredentialDeclaration(requiresSecretKey: true), method: "GET")
    }
  }

  @Test("the credential is checked before the language, and its members key first")
  func refusalOrder() {
    #expect(
      Self.refusal(.publishable(key: "", sessionToken: "tok_abc"), language: "")?
        .hasPrefix("The publishable key") == true
    )
    #expect(
      Self.refusal(.publishable(key: "pk_test_abc", sessionToken: "tok_abc"), language: "")?
        .hasPrefix("The session token") == true
    )
    #expect(
      Self.refusal(.publishable(key: "pk_test_abc"), language: "")?.hasPrefix("The language")
        == true
    )
  }

  @Test("an operation acting as a user is refused under a token a source minted without user_id")
  func requiredUser() throws {
    #expect(
      Self.refusal(
        .publishable(key: "pk_test_abc", sessionToken: Self.nobody), for: Self.actsAsUser)?
        .contains("minted without user_id") == true
    )
    #expect(
      try CredentialHeaders.headers(
        .publishable(key: "pk_test_abc", sessionToken: Self.member),
        language: nil,
        for: Self.actsAsUser
      ) == ["X-API-Key": "pk_test_abc", "X-Session-Token": "sess_abc", "Accept-Language": "*"]
    )
  }

  @Test("a token whose user the client is not told is sent for the API to decide")
  func untoldUser() throws {
    #expect(
      try CredentialHeaders.headers(
        .publishable(key: "pk_test_abc", sessionToken: "sess_abc"),
        language: nil,
        for: Self.actsAsUser
      ) == ["X-API-Key": "pk_test_abc", "X-Session-Token": "sess_abc", "Accept-Language": "*"]
    )
  }

  @Test("an optional user and none are sent whoever the token names")
  func optionalAndNone() {
    #expect(
      !Self.refused(
        .publishable(key: "pk_test_abc", sessionToken: Self.nobody),
        for: CredentialDeclaration(actingUser: .optional, requiresSession: true)
      )
    )
    #expect(!Self.refused(.publishable(key: "pk_test_abc", sessionToken: Self.nobody)))
  }

  @Test("a required user with no session token at all is refused for the session it requires")
  func requiredUserWithoutSession() {
    #expect(
      Self.refusal(.publishable(key: "pk_test_abc"), for: Self.actsAsUser)?
        .contains("requires a session token") == true
    )
  }

  @Test("a secret key authenticates only the operation that declares it")
  func secretKeyScope() throws {
    let mint = CredentialDeclaration(requiresSecretKey: true)

    #expect(
      try CredentialHeaders.headers(.secret(key: "sk_test_abc"), language: nil, for: mint)
        == ["X-API-Key": "sk_test_abc", "Accept-Language": "*"]
    )
    #expect(Self.refused(.secret(key: "sk_test_abc")))
    #expect(
      Self.refused(.secret(key: "sk_test_abc"), for: CredentialDeclaration(requiresSession: true)))
    #expect(Self.refused(.publishable(key: "pk_test_abc", sessionToken: "sess_abc"), for: mint))
    #expect(Self.refused(.share(token: "share_abc"), for: mint))
  }

  @Test("a share token reaches only an operation that declares one, and never a session one")
  func shareTokenScope() throws {
    #expect(
      try CredentialHeaders.headers(
        .share(token: "share_abc"), language: nil,
        for: CredentialDeclaration(acceptsShareToken: true))
        == ["X-Share-Token": "share_abc", "Accept-Language": "*"]
    )
    #expect(Self.refused(.share(token: "share_abc")))
    #expect(
      Self.refused(
        .share(token: "share_abc"),
        for: CredentialDeclaration(acceptsShareToken: true, requiresSession: true)
      )
    )
  }

  @Test("a session operation needs the token")
  func sessionOperation() {
    #expect(
      Self.refused(
        .publishable(key: "pk_test_abc"), for: CredentialDeclaration(requiresSession: true)))
    #expect(
      !Self.refused(
        .publishable(key: "pk_test_abc", sessionToken: "sess_abc"),
        for: CredentialDeclaration(requiresSession: true)
      )
    )
  }

  @Test("a session token a source holds is held to its prefix")
  func mintedPrefix() {
    let minted = SessionToken.minted(
      RestSchema.Session(expires_at: Date(timeIntervalSince1970: 0), user_id: nil, token: "tok_abc")
    )

    #expect(Self.refused(.publishable(key: "pk_test_abc", sessionToken: minted)))
  }

  @Test("a wrong prefix is named by the kind it does have")
  func namesTheKindFound() {
    do {
      try CredentialHeaders.check(.publishable(key: "sk_test_abc"))
      Issue.record("a secret key in the publishable key's place was accepted")
    } catch {
      #expect(error.description.contains("which is a secret key's"))
    }
  }
}
