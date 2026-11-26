/// NamedError is an error that declares the contract's name of its class as data, such as
/// `PreconditionFailedError`, which is what `isMountayaError(_:)` and `isAPIError(_:)` read.
///
/// Every error the client reports is one, through `MountayaError`. A type of another module's may
/// be one too: a failure that crossed a boundary the client's own types did not, rebuilt on the far
/// side by code of its own, declares the name it was raised under, and the two predicates recognise
/// it by that name as they recognise one of the client's own (`transport.errors.structural`). A
/// cast to `MountayaError` still tells the client's own apart.
public protocol NamedError: Error {
  /// name is the contract's name for the failure's class, such as `PreconditionFailedError`.
  var name: String { get }
}
