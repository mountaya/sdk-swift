import Testing

@testable import MountayaClient

@Suite("NamedError")
struct NamedErrorTests {
  /// Rebuilt is an error another module rebuilt on its side of a boundary, declaring the name it was
  /// raised under, as a second copy of the SDK or code that never linked it hands one over.
  private struct Rebuilt: NamedError {
    let name: String
    let status: Int?
  }

  /// Unnamed is an error that declares no name, whatever status it carries.
  private struct Unnamed: Error {
    let status: Int
  }

  @Test("an error of the client's is named, and the predicates read its name")
  func ownErrors() {
    let named: any NamedError = MountayaError.api(APIError(status: 409))
    #expect(named.name == "ConflictError")
    #expect(isMountayaError(named))
    #expect(isAPIError(named))
  }

  @Test("a value of another type declaring a name of the family is recognised by that name")
  func foreignValues() {
    #expect(isMountayaError(Rebuilt(name: "PreconditionFailedError", status: 412)))
    #expect(isAPIError(Rebuilt(name: "PreconditionFailedError", status: 412)))
    #expect(isAPIError(Rebuilt(name: "DataError", status: 200)))
    #expect(isMountayaError(Rebuilt(name: "WebhookSignatureError", status: nil)))
    #expect(!isAPIError(Rebuilt(name: "WebhookSignatureError", status: nil)))
    #expect(isMountayaError(Rebuilt(name: "ConfigurationError", status: nil)))
    #expect(!isAPIError(Rebuilt(name: "ConfigurationError", status: nil)))
  }

  @Test("a name outside the family, or none at all, is none of its errors, whatever its status")
  func strangers() {
    #expect(!isMountayaError(Rebuilt(name: "TypeError", status: 409)))
    #expect(!isAPIError(Rebuilt(name: "TypeError", status: 409)))
    #expect(!isMountayaError(Unnamed(status: 500)))
    #expect(!isAPIError(Unnamed(status: 500)))
    #expect(!isMountayaError(nil))
  }
}
