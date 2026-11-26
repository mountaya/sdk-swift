// Printed by `swift run GenerateClient` from `sdk/model.json`, contract v0.9.0,
// model digest f9ded6dd4ca71cb8f89c6974c42adec77509ee9a19e5afd01c31b6ea9dcc33ea.
// Never edit it: a wrong shape is a defect in `mountaya/schemas`, fixed there and printed
// again. Every name is the contract's, an enum member's by its words (SPEC.md section 3).

import Foundation

extension Mountaya.Agent {
  /// Runs is every operation of `agent.runs`, one method to an operation.
  public struct Runs: Sendable {
    let sender: any OperationSending

    /// Stream an agent run's events over Server-Sent Events.
    ///
    /// Opens a Server-Sent Events (SSE) stream of the run's live output. The
    /// response Content-Type is `text/event-stream` and the connection stays open
    /// until the run reaches its terminal `done` event, the credential it was
    /// opened with ends, the member's hold on the run is lost, the server cannot
    /// keep delivering it, or the client disconnects.
    ///
    /// Each event is framed as `id: <stream-id>`, `event: <type>`, and `data:
    /// <json>`. The `id:` field is the durable, monotonic stream id within the run;
    /// the `event:` field is the event type; the `data:` field is the type-specific
    /// JSON payload for that type. A `message-delta` is the one frame without an
    /// `id:`: deltas are live-only and never replayed, and the `message` that ends
    /// the turn is durable.
    ///
    /// To resume after a dropped connection, the client reconnects with the
    /// `Last-Event-ID` request header set to the last `id:` it received; the server
    /// replays events after that id from the run's durable stream before resuming
    /// the live feed. Without the header, the replay starts from the oldest event
    /// the stream still holds. The durable stream keeps about the last thousand
    /// events, for an hour after the run's latest event and for five minutes after
    /// its `done`. Past that a reconnect replays nothing, and the stream of a run
    /// that has ended closes at once. A `Last-Event-ID` that is not a stream id
    /// (two numbers joined by a hyphen, the form of every `id:`) is a **400**,
    /// answered before the stream opens.
    ///
    /// The stream ends with its credential. When the session token it was opened
    /// with expires, or the publishable key is revoked, loses the
    /// `studio-embedded` scope, or its organization is canceled, the stream
    /// writes one last record, `event: reconnect` with the data
    /// `{"type":"reconnect","reason":"credential-expired"}` or
    /// `{"type":"reconnect","reason":"credential-revoked"}`, and closes. It is not
    /// a failure and the run goes on: reopen the stream at once with a fresh
    /// session token and `Last-Event-ID`, and the events written in between are
    /// replayed. A `401` on that reopen means the credential itself is gone, and
    /// the stream ends there.
    ///
    /// The stream also ends when the member it was opened for loses their hold on
    /// the run while it is open: removed from the organization, left without the
    /// role a run asks, or in an organization that has lost Map Studio.
    /// That is not the credential ending, so no `reconnect` event is written: the
    /// stream writes the comment `: session-ended` and closes, and a reopen is
    /// answered as the run's grant now stands.
    ///
    /// And it ends when the server cannot keep delivering its events, because
    /// the reader fell behind or the server's subscription was lost: it writes a
    /// last `reconnect` event whose `reason` is `interrupted`, and closes. Reopen
    /// at once with `Last-Event-ID`, and the events written in between are
    /// replayed.
    ///
    /// A replay can hold a call that has its outcome: one the client
    /// answered before a page reload, after which it reconnects without the
    /// header, or one that timed out while the client was away. A replayed
    /// `tool-call` or `confirm-required` whose outcome the replay also holds, a
    /// `tool-result` or a `tool-abandoned` for the same `tool_call_id`, carries
    /// `settled: true`. The client neither runs it nor asks about it again. One
    /// replayed without the marker has no outcome on the stream yet, and the
    /// client answers it as it would a live one.
    ///
    /// While the stream is open past its replay, the server writes a comment (a
    /// line beginning with a colon) every 15 seconds, whatever else the stream
    /// carries. A comment is not an event: it has no `id:` and no `data:`, and a
    /// client discards it. It keeps the connection, and any proxy in between,
    /// from closing a quiet stream as idle.
    ///
    /// A run that the rate limit of the organization's AI provider ended answers
    /// **409** (`CONFLICT`) here rather than opening a stream, so its closing
    /// frames are not replayed. The run is over; after a short wait start a new
    /// run with `postAgentRun`.
    ///
    /// The `event:` type and the shape of the matching `data:` payload are the
    /// AgentRunEvent schema: it is a union discriminated on `type`, so every frame
    /// kind, the run's terminal reason, and the per-call abandon reason are stated
    /// once and cannot drift from one another.
    ///
    /// A `HEAD` request on this path is answered with the headers a `GET` would
    /// get, and opens no subscription.
    ///
    /// Opening the stream is limited to 60 opens a minute for each user and 1200
    /// for each organization. Past either, the answer is a **429** with
    /// `Retry-After`, and no stream opens. Like every read made with a session
    /// token, each open also counts toward the 1200 reads a minute each user is
    /// allowed and the 6000 each organization is allowed.
    ///
    /// At most 20 streams are held open at once for each user, 50 for each client
    /// IP address and 1,000 for each organization, counted across every event
    /// stream. An open past any of them is a `429` with `Retry-After`, and no
    /// stream starts; a stream gives its place back when it ends.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, the member who started
    /// the run. Whether that member may still follow the run is answered by the
    /// run itself, as the **404** states, and not by the key or the token. A
    /// publishable key without a session token minted for `studio-embedded` naming
    /// a user, a token minted for another surface included, is refused with
    /// **401**.
    public func getAgentRunEvents(
      run_id: String,
      options: RequestOptions = RequestOptions()
    ) throws -> EventStream<RestSchema.AgentRunEvent> {
      let request = OperationRequest(
        facts: .getAgentRunEvents,
        pathParameters: ["run_id": run_id]
      )
      return try sender.events(request, options: options)
    }

    /// Start a new agent run.
    ///
    /// Starts a new agent run for the user the session token names. The run is
    /// created and then continues on its own: this call returns as soon as it has
    /// an identifier, live output arrives over the run's event stream
    /// (`getAgentRunEvents`), and follow-up input is sent to the running
    /// conversation (`postAgentRunInput`).
    ///
    /// The run is scoped to `organization_id`, the organization that owns the
    /// opened resource, which must be the key's organization: any other is a
    /// **403**, whether or not it exists. The server enforces the gate, and any
    /// client-side check is presentation only: the user the session token names
    /// must hold a write role (owner, admin or contributor) in that organization,
    /// so a viewer is refused with **403**. The organization must also have an AI
    /// provider credential configured, else **409** with the machine code
    /// `AI_PROVIDER_NOT_CONFIGURED` (distinct from the 403 authorization failure).
    ///
    /// The response is 202 Accepted carrying the run at `data`. Its `id` is a
    /// plain UUID and is what the input, events and feedback operations take as
    /// their `run_id` path parameter.
    ///
    /// A start is made at most once per `Idempotency-Key`: a retried start with
    /// the same key resolves to the same run, answered with the first one's
    /// 202, and begins no second conversation and no second budget. Without the
    /// header every request starts a run of its own, so send one on every start.
    ///
    /// Under a publishable key a run calls no server tool: what a server tool
    /// reads and computes is the Data API's, which the key's own `data` scope
    /// answers for. A non-empty `server_tools` is therefore a **400** naming it,
    /// and nothing is started.
    ///
    /// Starts are limited to 10 a minute for each user and 100 a minute for each
    /// organization, and the bodies of starts and inputs together to 8 MiB a
    /// minute for each user and 80 MiB a minute for each organization, a request
    /// counting the bytes of its body. Past any of them, the answer is a **429**
    /// with `Retry-After`, and no run is started.
    ///
    /// Every run is bounded: at most 24 provider turns, and $5.00 of spend on the
    /// organization's AI provider, as estimated after each turn. The spend is
    /// checked before a turn starts, so the run stops before a turn once its
    /// estimated spend has reached $5.00, and the turn that reached it can take
    /// it past that figure. Reaching either ceiling ends the run with the
    /// `budget-exhausted` reason.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, a member with a write
    /// role, whom the request acts as. A publishable key without a session token
    /// minted for `studio-embedded` naming a user, a token minted for another
    /// surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postAgentRun(
      body: RestSchema.AgentRunCreateParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<RestSchema.AgentRun, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postAgentRun,
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Record the user's rating of one assistant message in a run.
    ///
    /// Records a thumbs up or thumbs down against one assistant message. It is the
    /// explicit outcome label for the run: the tool sequence already implies
    /// whether the work was taken up, but only for runs that ended in an edit, and
    /// says nothing about a run that ended in an answer.
    ///
    /// The rating is recorded for quality measurement and carries no message
    /// content. It is accepted after the run has ended, which is when a user
    /// usually presses it, so it is NOT a signal into the run, and for as long as
    /// the run stays reachable: 24 hours from its start.
    ///
    /// Every press is recorded, and none replaces another: a rating sent again for
    /// the same message is kept beside the earlier ones, so a change of mind stays
    /// observable, and the latest press for a message is the rating that counts.
    /// A retry carrying the same `Idempotency-Key` is answered the first request's
    /// 202 and records nothing again, while the same body sent without one is a
    /// second press. Recording is best-effort. A run that does not exist, or that
    /// the user the session token names did not start, answers 404 and records
    /// nothing.
    ///
    /// Ratings are limited to 60 a minute for each user and 600 a minute for each
    /// organization; past either, the answer is a **429** with `Retry-After`, and
    /// nothing is recorded.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, the member who started
    /// the run. The rating is accepted whatever role that member holds in the
    /// organization now, and whatever the organization holds beside Embedded
    /// Studio, for as long as the run stays reachable: it spends nothing, and
    /// reaches none of the organization's data. A publishable key without a
    /// session token minted for `studio-embedded` naming a user, a token minted
    /// for another surface included, is refused with **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postAgentRunFeedback(
      run_id: String,
      body: RestSchema.AgentRunFeedbackParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postAgentRunFeedback,
        pathParameters: ["run_id": run_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }

    /// Send an input signal into a running agent run.
    ///
    /// Delivers an input signal into a running agent run. The request body shape is
    /// selected by its `type` discriminator:
    ///
    /// - `user-message`: a follow-up user message delivered into the conversation
    ///   (AgentUserMessageInput).
    ///
    /// - `tool-result`: the outcome of a browser-executed client tool, correlated
    ///   by tool call id (AgentToolResultInput).
    ///
    /// - `confirm`: an approval or rejection of a destructive server tool gated
    ///   behind a confirmation (AgentConfirmInput).
    ///
    /// - `close`: a request that the run finish; the run ends successfully with a
    ///   `done` terminal event (AgentCloseInput).
    ///
    /// - `manifest-update`: a replacement client-tool manifest, sent when the set
    ///   of tools the browser can service changes mid-run
    ///   (AgentManifestUpdateInput).
    ///
    /// The response is 202 Accepted with no data once the signal is accepted; the
    /// run's reaction is observed over the event stream (`getAgentRunEvents`).
    /// The run must have been started by the user the session token names. A
    /// signal is delivered once per `Idempotency-Key`: a retried request with the
    /// same key is answered the first one's 202 and delivers nothing again, while
    /// the same body sent without one is a second signal, a second message
    /// among them.
    ///
    /// A **409** (`CONFLICT`) means the run has already ended, however it ended:
    /// it went quiet and completed, was closed, exhausted its budget, was stopped
    /// for looping, failed, or was ended by the rate limit of the organization's
    /// AI provider. It takes no more input, so start a new run, after a short
    /// wait when the provider's rate limit ended it. It is returned only for
    /// `user-message` and `close`, which are the caller's own instructions. A
    /// `tool-result`, a `confirm` and a `manifest-update`
    /// answer something the run asked for, so if the run is gone the pending call
    /// is already orphaned and they are accepted with 202 rather than paying for
    /// the check. So is a `tool-result` or a `confirm` sent more than two minutes
    /// after the frame that asked for it: the run has already given up on that
    /// call (`tool-abandoned`) and ignores the late answer.
    ///
    /// Inputs are limited to 120 a minute for each user and 1,200 a minute for
    /// each organization, and the bodies of inputs and run starts together to
    /// 8 MiB a minute for each user and 80 MiB a minute for each organization, a
    /// request counting the bytes of its body. Past any of them, the answer is a
    /// **429** with `Retry-After`, and the signal is not delivered.
    ///
    /// Requires a publishable key with the `studio-embedded` scope AND a session
    /// token minted for `studio-embedded` naming a user, the member who started
    /// the run. Whether that member may still send to the run is answered by the
    /// run itself, as the **404** states, and not by the key or the token. A
    /// publishable key without a session token minted for `studio-embedded` naming
    /// a user, a token minted for another surface included, is refused with
    /// **401**.
    ///
    /// `idempotencyKey` is the `Idempotency-Key` every attempt of the call sends: the caller's,
    /// which makes two of its calls one write, or one the client draws once.
    public func postAgentRunInput(
      run_id: String,
      body: RestSchema.AgentRunInputParams,
      idempotencyKey: String? = nil,
      options: RequestOptions = RequestOptions()
    ) async throws -> Response<JSONValue, [String: JSONValue]?> {
      let request = OperationRequest(
        facts: .postAgentRunInput,
        pathParameters: ["run_id": run_id],
        body: .json(body),
        idempotencyKey: idempotencyKey
      )
      return try await sender.envelope(request, options: options)
    }
  }
}
