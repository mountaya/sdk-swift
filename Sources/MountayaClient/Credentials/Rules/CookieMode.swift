/// CookieMode decides whether a request asks for the visitor's cookies.
enum CookieMode: String, Sendable, Hashable {
  /// include sends the cookies the credential's source answers.
  case include
  /// omit sends none.
  case omit

  /// mode returns whether a request under `credential` to an operation declaring `declaration`
  /// asks for cookies: only under a share token that asks for them, and never to an operation
  /// that takes no credential.
  ///
  /// A key never asks for cookies, publishable or secret, with a session token or without: a
  /// cookie's broader session would outrank it.
  static func mode(_ credential: Credential, for declaration: CredentialDeclaration) -> CookieMode {
    guard !declaration.takesNoCredential, case .share(_, .some) = credential else {
      return .omit
    }
    return .include
  }
}
