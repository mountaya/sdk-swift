import Foundation
import MountayaClient

/// OrganizationReads is every read of an organization the process's maps share
/// (`map.organization.read`): one read per publishable key and Map Studio API origin, through
/// `postOrganizationLookup`, the key in the body and no credential sent, shared by every map whose
/// client holds that key and sends its Map Studio API requests to that origin, `baseUrls.rest`, for
/// as long as the process lives. The origin is part of what a read is kept under, so a client
/// pointed at a staging origin never shares an answer with one pointed at production, even under
/// the same key. A read in flight is waited on rather than sent again, and an answer is kept; a
/// read that fails, one that reached the transport's own time budget among them, is kept by nobody,
/// so every map waiting on it is handed its failure and the next asks again.
///
/// The process's is `shared`, which every `MapEngine` reads through; a test hands an engine one
/// of its own. It is bound to the main actor, as every engine is.
@MainActor
final class OrganizationReads {
  /// Kept is what one read is kept under: the publishable key, and the origin the client sends its
  /// Map Studio API requests to, as its `baseUrls.rest` spells it.
  struct Kept: Hashable {
    let key: String
    let origin: String
  }

  /// shared is the process's reads, which every map shares.
  static let shared = OrganizationReads()

  /// held is each organization read, by what it was read under.
  private var held: [Kept: RestSchema.Organization] = [:]
  /// waiting is each read in flight, by what it is read under, with every read waiting on it.
  private var waiting: [Kept: [CheckedContinuation<RestSchema.Organization, any Error>]] = [:]

  /// organization is the organization read with `key` through a client sending to `origin`, or nil
  /// where none is held.
  func organization(_ key: String, origin: String) -> RestSchema.Organization? {
    held[Kept(key: key, origin: origin)]
  }

  /// read answers the organization `key` was minted for, as read through `client`'s Map Studio API
  /// origin: the one held, else the answer of the read in flight, else that of a read sent now
  /// through `client`, in the task of the caller. It throws what the read fails with.
  func read(_ key: String, through client: Mountaya) async throws -> RestSchema.Organization {
    let kept = Kept(key: key, origin: client.baseUrls.rest.absoluteString)
    if let organization = held[kept] { return organization }
    if waiting[kept] != nil {
      return try await withCheckedThrowingContinuation { waiting[kept]?.append($0) }
    }
    waiting[kept] = []
    let answer: Result<RestSchema.Organization, any Error>
    do {
      answer = .success(
        try await client.studio.organizations.postOrganizationLookup(
          body: RestSchema.OrganizationLookupParams(publishable_key: key)
        ).data)
    } catch {
      answer = .failure(error)
    }
    if case .success(let organization) = answer {
      held[kept] = organization
    }
    for waiter in waiting.removeValue(forKey: kept) ?? [] {
      waiter.resume(with: answer)
    }
    return try answer.get()
  }
}
