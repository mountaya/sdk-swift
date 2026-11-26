/// ClientIdentification is how a request names the SDK that made it (`sdk/SPEC.md` §1):
/// `X-Mountaya-Client: mountaya-swift/<version>`, `<version>` being this package's own version and
/// never the contract tag it speaks, which `schemaVersion` records.
///
/// Every request the transport makes carries it, an event stream's open and an operation that
/// takes no credential included, and so does every request a map makes for itself to the Tile API,
/// beside the credential its hook attaches. It is the client's, as `Accept-Language` is: no method
/// takes it, and a call made by its declaration may not name it. It is no part of a credential's
/// projection, and rides beside it.
enum ClientIdentification {
  /// header is the name of the header.
  static let header = "X-Mountaya-Client"

  /// version is this package's version, and the one place the source writes it. A release
  /// refuses a version other than this one (`scripts/release.sh`), so the version is moved here,
  /// in a commit of its own, before the tag that releases it.
  static let version = "0.1.0"

  /// value is what the header carries.
  static let value = "mountaya-swift/\(version)"
}
