import Testing

@testable import MountayaClient

@Suite("CredentialDeclaration")
struct CredentialDeclarationTests {
  @Test("a fact left out is false, and an acting user left out is none")
  func absentFacts() {
    let declaration = CredentialDeclaration()

    #expect(declaration.actingUser == CredentialDeclaration.ActingUser.none)
    #expect(!declaration.acceptsShareToken)
    #expect(!declaration.requiresSession)
    #expect(!declaration.requiresSecretKey)
    #expect(!declaration.takesNoCredential)
    #expect(!declaration.pendingInvitee)
  }

  @Test("each fact is set on its own")
  func factsAreIndependent() {
    let declaration = CredentialDeclaration(
      actingUser: .required,
      requiresSession: true,
      pendingInvitee: true
    )

    #expect(declaration.actingUser == .required)
    #expect(declaration.requiresSession)
    #expect(declaration.pendingInvitee)
    #expect(!declaration.acceptsShareToken)
    #expect(declaration != CredentialDeclaration(actingUser: .required, requiresSession: true))
  }

  @Test("the acting user is spelled as the contract's `x-acting-user` spells it")
  func actingUserSpellings() {
    #expect(CredentialDeclaration.ActingUser(rawValue: "required") == .required)
    #expect(CredentialDeclaration.ActingUser(rawValue: "optional") == .optional)
    #expect(
      CredentialDeclaration.ActingUser(rawValue: "none") == CredentialDeclaration.ActingUser.none)
    #expect(CredentialDeclaration.ActingUser(rawValue: "Required") == nil)
  }
}
