import Foundation

/// EventStreamReader reads one operation's event stream through the transport, by the rules of
/// `sdk/SPEC.md` section 12: when it is over, when it is opened again, after how long, and from
/// which record.
///
/// It reads a frame only as its iteration asks for one, so the time a consumer's loop holds a
/// frame is the consumer's: the silence clock runs only while the reader is waiting on the
/// network. A `CancellationError` an open or a read throws, the exchange's for a request the
/// platform cancelled as much as the task's, ends the stream as it is: it is never a dropped
/// connection, and nothing after it is opened again.
///
/// It reads the stream by the rules of the stream its operation opens, an editor stream's apart
/// from a list stream's though both carry one vocabulary, and as the user its session token names,
/// where the client is told one, or else as `member`, the user its caller says it reads the
/// stream as: an editor stream's `presence.join` of that user is no progress. A reader that knows
/// no user reads every `presence.join` as progress.
struct EventStreamReader<Event: StreamedEvent>: Sendable {
  let transport: Transport
  let call: Transport.Call
  /// member is the user the caller says it reads the stream as, or nil where it says none.
  let member: String?
  /// observer is told how each open ended: the failure it failed with, or nil for a close and for
  /// a `reconnect`, whether the reader reopens after it or stops. Nothing it does changes the
  /// stream.
  let observer: (@Sendable (MountayaError?) -> Void)?

  init(
    transport: Transport,
    call: Transport.Call,
    member: String? = nil,
    observer: (@Sendable (MountayaError?) -> Void)? = nil
  ) {
    self.transport = transport
    self.call = call
    self.member = member
    self.observer = observer
  }

  /// makeIterator starts one iteration of the stream, which opens it.
  func makeIterator() -> any FrameReading<Event> {
    Reading(transport: transport, call: call, member: member, observer: observer)
  }

  /// Reading is one iteration's state: the open it reads, the position it resumes from, and the
  /// count of its opens since the last that made progress. It is not Sendable: it is the state of
  /// one `EventStream.Iterator`, read by the one task iterating it and never shared across tasks.
  final class Reading: FrameReading {
    private let transport: Transport
    private let call: Transport.Call
    private let member: String?
    private let rules: EventStreamRules
    private var position: String?
    private var count = ReconnectSchedule.Count()
    private var nextWait: Duration?
    private var opens = 0
    private var finished = false
    private var body: ExchangeBody?
    private var framer = EventFramer()
    /// pending is the records the last chunk ended, handed on in order from `nextPending`, so a
    /// chunk's records cost one step each however many it ends.
    private var pending: [EventFramer.Framed] = []
    /// nextPending is the index in `pending` of the next record to hand on.
    private var nextPending = 0
    /// frames counts what this open delivered that is progress.
    private var frames = 0
    private var leadingSnapshots: Set<String> = []
    private var pastLeadingSnapshots = false
    /// tokenExpiry is when the session token this open was made with expires, where the client
    /// knows it.
    private var tokenExpiry: Date?
    /// ownMember is the user this open reads the stream as, or nil where the reader can name none.
    private var ownMember: String?

    private let observer: (@Sendable (MountayaError?) -> Void)?

    init(
      transport: Transport,
      call: Transport.Call,
      member: String?,
      observer: (@Sendable (MountayaError?) -> Void)?
    ) {
      self.transport = transport
      self.call = call
      self.member = member
      self.rules = Event.rules(for: call.facts.operationId)
      self.observer = observer
    }

    func next() async throws -> EventFrame<Event>? {
      while !finished {
        guard body != nil else {
          try await open()
          continue
        }
        if nextPending < pending.count {
          let framed = pending[nextPending]
          nextPending += 1
          if let frame = take(framed) {
            return frame
          }
          continue
        }
        try await read()
      }
      return nil
    }

    /// Opened is how one open ended.
    private enum Opened: Sendable {
      case opened(ExchangeResponse)
      case refused(Transport.Answer)
      case dropped((any Error)?)
    }

    /// open opens the stream, after the wait the last open left, within one attempt's budget.
    ///
    /// A position no header can carry, an id of the stream's last record holding a character
    /// outside printable ASCII, ends the stream with a `ConfigurationError` before anything is
    /// sent: the loader would send a position other than the one the server wrote, or refuse the
    /// header and have a feed that never stops on its own open again forever.
    private func open() async throws {
      if let wait = nextWait {
        nextWait = nil
        try await transport.sleeper.sleep(for: wait)
      }
      try Task.checkCancellation()
      if let position, !HeaderValue.isCarried(position) {
        finished = true
        let refusal = MountayaError.configuration(
          ConfigurationError(
            message:
              "The id of the stream's last record holds \(HeaderValue.uncarried), so the stream "
              + "cannot be opened again from it: open it anew."
          ))
        observer?(refusal)
        throw refusal
      }
      let attempt = opens
      opens += 1
      let transport = self.transport
      let call = self.call
      let position = self.position
      let raced: Deadline.Raced<Opened>
      do {
        raced = try await opening(transport: transport, call: call, position: position)
      } catch let refusal as MountayaError {
        // A credential refused locally ends the stream, since opening again repeats it.
        finished = true
        observer?(refusal)
        throw refusal
      } catch let cancellation as CancellationError {
        // A cancellation ends the stream, the exchange's as much as the task's: nothing after it
        // is opened again.
        finished = true
        throw cancellation
      }
      try settle(raced, attempt: attempt)
    }

    /// opening makes one open within one attempt's budget.
    private func opening(transport: Transport, call: Transport.Call, position: String?)
      async throws -> Deadline.Raced<Opened>
    {
      try await Deadline.run(within: call.budget, sleeper: transport.sleeper) {
        () async throws -> Opened in
        var request = try await transport.request(for: call)
        if let position {
          request.headers[EventStreamRules.lastEventIdHeader] = position
        }
        do {
          let response = try await transport.exchange.send(request)
          guard (200...299).contains(response.status) else {
            let bytes = try await response.body.collect()
            return .refused(
              Transport.Answer(status: response.status, headers: response.headers, body: bytes))
          }
          return .opened(response)
        } catch let cancellation as CancellationError {
          // A cancellation the exchange reports ends the stream as it is, and is never a dropped
          // open, which the reader would open again.
          throw cancellation
        } catch {
          try Task.checkCancellation()
          return .dropped(error)
        }
      }
    }

    /// settle reads how one open ended.
    private func settle(_ raced: Deadline.Raced<Opened>, attempt: Int) throws {
      switch raced {
      case .expired:
        let failure = MountayaError.connection(ConnectionError())
        observer?(failure)
        try failed(failure)
      case .finished(.dropped(let underlying)):
        let failure = MountayaError.connection(ConnectionError(cause: underlying))
        observer?(failure)
        try failed(failure)
      case .finished(.refused(let answer)):
        transport.report(answer, of: call, attempt: attempt)
        let error = transport.failure(answer, of: call)
        observer?(error)
        if OpenFailure.ends(error, rules: rules) {
          finished = true
          throw error
        }
        try failed(error)
      case .finished(.opened(let response)):
        transport.report(
          Transport.Answer(status: response.status, headers: response.headers, body: Data()),
          of: call,
          attempt: attempt
        )
        body = response.body
        framer = EventFramer()
        dropPending()
        frames = 0
        leadingSnapshots = []
        pastLeadingSnapshots = false
        tokenExpiry = Self.expiry(of: transport.configuration.credential)
        ownMember = Self.user(of: transport.configuration.credential) ?? member
      }
    }

    /// read reads the next chunk of the open stream within the silence window.
    private func read() async throws {
      guard let body else { return }
      let raced: Deadline.Raced<Data?>
      do {
        raced = try await Deadline.run(
          within: EventStreamRules.stallWindow,
          sleeper: transport.sleeper
        ) {
          try await body.next()
        }
      } catch let cancellation as CancellationError {
        finished = true
        self.body = nil
        throw cancellation
      } catch {
        try Task.checkCancellation()
        try ended(dropped: .connection(ConnectionError(cause: error)))
        return
      }
      switch raced {
      case .expired:
        try ended(dropped: .connection(ConnectionError()))
      case .finished(nil):
        try ended(dropped: nil)
      case .finished(let chunk?):
        // A chunk is read only once every record before it is handed on, so the records it ends
        // take their place.
        pending = framer.feed(chunk)
        nextPending = 0
      }
    }

    /// dropPending drops the records not yet handed on.
    private func dropPending() {
      pending = []
      nextPending = 0
    }

    /// take reads one framed record, and returns the frame it hands on, if any.
    private func take(_ framed: EventFramer.Framed) -> EventFrame<Event>? {
      switch framed {
      case .position(let id):
        position = id
        return nil
      case .record(let record):
        guard let (event, role) = Event.read(record) else {
          frames += 1
          return nil
        }
        if role.isReconnect {
          observer?(nil)
          reopenAtOnce()
          return nil
        }
        // The reader's own member's arrival, sent as its first stream opens, is no progress
        // wherever it comes.
        if !isOwnArrival(event) {
          countFrame(role, named: record.event ?? "")
        }
        if role.movesPosition, let id = record.id {
          position = id
        }
        if role.endsStream {
          finished = true
          body = nil
        }
        return EventFrame(id: record.id, event: event)
      }
    }

    /// ended reads the end of an open stream: a close, or a drop that carries its failure.
    private func ended(dropped failure: MountayaError?) throws {
      observer?(failure)
      if failure == nil, let tokenExpiry, transport.wallClock.now >= tokenExpiry {
        // The last record before a close can be lost on its way, so a close at or after the
        // token's expiry is read as the `reconnect` the API writes when a credential ends.
        reopenAtOnce()
        return
      }
      if frames > rules.framesBeforeProgress {
        reopenAtOnce()
        return
      }
      try failed(failure)
    }

    /// countFrame counts a frame that is progress: any but the roster and lock snapshots an open
    /// begins with, each the first of its kind before any other frame.
    private func countFrame(_ role: EventRole, named name: String) {
      if role.isOpeningSnapshot, !pastLeadingSnapshots, !leadingSnapshots.contains(name) {
        leadingSnapshots.insert(name)
      } else {
        pastLeadingSnapshots = true
        frames += 1
      }
    }

    /// isOwnArrival is true for the `presence.join` of the member this open reads the stream as,
    /// on a stream whose rules read it as no progress.
    private func isOwnArrival(_ event: Event) -> Bool {
      guard !rules.ownArrivalIsProgress, let ownMember, let arriving = event.arrivingMember else {
        return false
      }
      return arriving.unicodeScalars.elementsEqual(ownMember.unicodeScalars)
    }

    /// reopenAtOnce follows an open that made progress, or that ended with its credential, at
    /// once, and resets the count of opens without progress and the time the opens answered 503
    /// are held to.
    private func reopenAtOnce() {
      body = nil
      dropPending()
      count = ReconnectSchedule.Count()
      nextWait = nil
    }

    /// failed reads an open without progress: it waits on the schedule, or the wait its answer
    /// names, before the next, or stops where the schedule says, reporting the failure the open
    /// failed with, or nothing where it closed.
    private func failed(_ failure: MountayaError?) throws {
      body = nil
      dropPending()
      let (counted, wait) = ReconnectSchedule.next(
        after: failure,
        count: count,
        at: transport.sleeper.now,
        rules: rules,
        draw: transport.random.unitDraw()
      )
      count = counted
      guard let wait else {
        finished = true
        if let failure {
          throw failure
        }
        return
      }
      nextWait = wait
    }

    /// user returns the user the session token a credential sends now names, where the client is
    /// told one: a minted session's, or a source's snapshot's.
    private static func user(of credential: Credential) -> String? {
      guard case .publishable(_, let token?) = credential else { return nil }
      switch token {
      case .minted(let session): return session.user_id
      case .source(let source): return source.snapshot.userId
      case .value, .function: return nil
      }
    }

    /// expiry returns when the session token a credential sends now expires, where the client
    /// is told.
    private static func expiry(of credential: Credential) -> Date? {
      guard case .publishable(_, let token?) = credential else { return nil }
      switch token {
      case .minted(let session): return session.expires_at
      case .source(let source): return source.snapshot.expiresAt
      case .value, .function: return nil
      }
    }
  }
}
