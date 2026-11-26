import MountayaGeo

/// StreamLocationSource states each position an app's own sequence yields between a start and a
/// stop: for an app that already reads the device's location through a stack of its own, and
/// hands the navigation what it reads, `[longitude, latitude]` in degrees.
///
/// Each start iterates `positions` afresh in a task of its own, and a stop cancels it, so the app's
/// sequence runs only while a navigation does. An `AsyncStream` ends once the task iterating it is
/// cancelled, so a stream serves one navigation, from its first start to its stop; an app that
/// starts the navigation again hands a sequence that makes a stream of its own each time it is
/// iterated. A position the engine refuses is told to `onError` and the next one is read, and an
/// error the sequence throws ends the positions and is told to `onError` too, a stop's cancellation
/// aside; with no `onError`, each is dropped.
///
/// It is bound to the main actor, as every source is, and states every position there. The
/// sequence is iterated off the main actor, so a sequence that waits holds no turn of it.
@MainActor
public final class StreamLocationSource<Positions: AsyncSequence & Sendable>: LocationSource
where Positions.Element == [Double] {
  private let positions: Positions
  private let onError: (@MainActor (any Error) -> Void)?
  private var reading: Task<Void, Never>?

  /// Creates a source that states each position `positions` yields while it is started, and
  /// tells `onError` each position the engine refuses and the error that ends the sequence.
  public init(_ positions: Positions, onError: (@MainActor (any Error) -> Void)? = nil) {
    self.positions = positions
    self.onError = onError
  }

  deinit {
    // A source let go of reads no further.
    reading?.cancel()
  }

  /// start begins stating each position the sequence yields, iterating it from its start.
  /// Starting a source that is started does nothing.
  public func start(_ deliver: @escaping @MainActor ([Double]) throws -> Void) {
    guard reading == nil else { return }
    let positions = positions
    let onError = onError
    reading = Task {
      do {
        try await Self.iterate(positions) { position in
          // A stop made while the position was on its way to the main actor states nothing more.
          guard !Task.isCancelled else { return }
          do {
            try deliver(position)
          } catch {
            onError?(error)
          }
        }
      } catch {
        // A stop's cancellation ends the positions; anything else the sequence threw is told.
        guard !Task.isCancelled else { return }
        onError?(error)
      }
    }
  }

  /// stop ends the positions: the task iterating the sequence is cancelled, and nothing more is
  /// stated until the next `start(_:)`.
  public func stop() {
    reading?.cancel()
    reading = nil
  }

  /// iterate hands each position `positions` yields to `state`, on the main actor, until the
  /// sequence ends or throws, iterating it off the main actor.
  private nonisolated static func iterate(
    _ positions: Positions, state: @escaping @MainActor @Sendable ([Double]) -> Void
  ) async throws {
    for try await position in positions {
      await state(position)
    }
  }
}
