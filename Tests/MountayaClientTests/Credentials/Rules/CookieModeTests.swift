import Testing

@testable import MountayaClient

@Suite("CookieMode")
struct CookieModeTests {
  private static let cookies: CookieSource = { _ in "session=visitor" }

  @Test("only a share token that asks for cookies asks for them, and never where nothing is taken")
  func mode() {
    let asking = Credential.share(token: "share_abc", cookies: Self.cookies)

    #expect(CookieMode.mode(asking, for: CredentialDeclaration()) == .include)
    #expect(
      CookieMode.mode(asking, for: CredentialDeclaration(acceptsShareToken: true)) == .include)
    #expect(CookieMode.mode(asking, for: CredentialDeclaration(takesNoCredential: true)) == .omit)
    #expect(
      CookieMode.mode(
        .share(token: "share_abc"), for: CredentialDeclaration(acceptsShareToken: true)) == .omit)
    #expect(
      CookieMode.mode(
        .publishable(key: "pk_test_abc", sessionToken: "sess_abc"), for: CredentialDeclaration())
        == .omit)
  }

  @Test(
    "a read that takes no share token rides the visitor's session alone, and a write is refused")
  func readsAloneWritesRefused() throws {
    let asking = Credential.share(token: "share_abc", cookies: Self.cookies)
    let read = try CredentialHeaders.project(
      asking, session: nil, language: nil, for: CredentialDeclaration(), isRead: true)

    #expect(read.headers == ["Accept-Language": "*"], "no share token, the language alone")
    #expect(read.cookies != nil)
    #expect(throws: MountayaError.self) {
      try CredentialHeaders.project(
        asking, session: nil, language: nil, for: CredentialDeclaration(), isRead: false)
    }
  }
}
