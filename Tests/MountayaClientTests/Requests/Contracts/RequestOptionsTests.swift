import Testing

@testable import MountayaClient

@Suite("RequestOptions")
struct RequestOptionsTests {
  @Test("options left out defer to the client, and one set overrides only itself")
  func defersToTheClient() throws {
    #expect(RequestOptions().retry == nil)
    #expect(try RequestOptions(retry: RetryPolicy(maxRetries: 0)).retry?.maxRetries == 0)
  }
}
