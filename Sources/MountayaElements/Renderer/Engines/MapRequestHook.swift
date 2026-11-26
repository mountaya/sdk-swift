#if Elements && os(iOS) && !targetEnvironment(macCatalyst)
  import Foundation
  internal import MapLibre
  import MountayaClient
  internal import os

  /// MapRequestHook is MapLibre's one request hook, the delegate of its network configuration,
  /// held for the process: every request MapLibre makes for itself, for a style, a tile, a sprite
  /// or a glyph, passes through it before it leaves, and leaves on the session it hands MapLibre.
  ///
  /// Every map shown holds the hook at once, each with its own client and its app's own hook,
  /// `MapEngine`'s `transformRequest`, from its renderer's making to its renderer's end. A request
  /// is handed the app's hook of the map shown last that names one, which is called first, and the
  /// URL it answers is the one a credential is claimed by: the request is given the credential and
  /// the language of the map shown last whose client's Tile API it lies under, read for that
  /// request (`Mountaya.mapRequestHeaders(for:)`), so a refreshed session token reaches the next
  /// tile, and `X-Mountaya-Client`, which names this SDK and its version beside them, a header the
  /// app's hook set standing over the client's; a request to any other host a style names, a base
  /// map's fonts or another provider's tiles, is given nothing, and so is every request while no map
  /// is shown. Two maps whose clients reach one Tile API send the credential of the one shown last
  /// (SPEC.md section 11). A request whose session token the client refuses at that read never
  /// leaves: it is handed back unable to load, and MapLibre reports its resource failed, a failure
  /// carrying what the read threw.
  ///
  /// A redirect is followed on the hook's own session, whose delegate takes off every header the
  /// hook and the app's hook set, gives a header they replaced back MapLibre's own, and applies the
  /// maps' rules again for the address it leads to, so a credential reaches the Tile API alone, a
  /// redirect to another host carrying none. The session is made from the configuration MapLibre
  /// holds, the app's own where it set one, and made again where that configuration is replaced.
  ///
  /// Every answer passes through it too, and one that failed, a status from 400 up, is told at the
  /// address MapLibre asked for, not one a redirect led to, to every map shown whose sources' tile
  /// templates, up to their first `{`, or whose style's directory, its address up to its last `/`,
  /// that address lies under, each telling its engine: a refusal of access, a 401, a 402 or a 403,
  /// or any other failure (`map.events.access-refused`). So is a request that reached no answer, an
  /// offline tile, which MapLibre repeats on its own schedule: its failure names the address its
  /// last hop went to, and it is told as a failure with no status at the address MapLibre asked
  /// for, but one MapLibre withdrew, `NSURLErrorCancelled`, which is no failure. An answer no map
  /// claims is told to the one map shown where only one is, and to none where several are (SPEC.md
  /// section 11).
  ///
  /// An answer names no request, and only the address its last hop went to, so the hook keeps, by
  /// that address, what each request left with: the address MapLibre asked for, before the app's
  /// hook and any redirect, and the client's headers its last hop was sent, a redirect moving both
  /// to the address it leads to, until its answer, for at most `keptLimit` addresses, the oldest
  /// forgotten first, so what a request MapLibre withdrew and never had answered left with goes
  /// before what a request still awaiting its answer did. As an answer
  /// arrives, the headers the client of the map shown last whose client claims the address the
  /// last hop went to gives a request to it are read again: where they differ from those kept, a
  /// session token since replaced or minted after the request left under the key alone, or a
  /// visitor's cookie since changed, or where the client refuses what it reads now, the request
  /// left under a credential the client no longer sends, which each map is told with the failure,
  /// and whose 401 or 403 its engine tells nobody (`refusesSupersededCredential(_:superseded:)`).
  ///
  /// The hook hears an answer before MapLibre does, so it keeps how it told each failed answer at
  /// the address of a style a map shown asks for, a refusal of access told or told to nobody, or a
  /// failure told, a status or no answer, until the address is asked for again, for the map's
  /// renderer to find at its style's own address as MapLibre tells the style failed: a style that
  /// failed is told once, as the hook told it, never also as a style that did not arrive, and one
  /// refused a credential the client no longer sends is asked for again instead, once. A tile's
  /// answer is kept for nobody, so a storm of refused tiles never pushes a style's out.
  ///
  /// What MapLibre's threads tell the maps, each failed answer the hook hears and each tile a map
  /// parses, reaches the main actor in the order it was told, a burst of it in one hop: the first
  /// of a burst asks for the hop, and the hop hands on everything told until it runs, each failure
  /// to the maps that claim it, every map's claims read once a hop. A storm of refused tiles is
  /// then a hop, not a hop per tile, and a map parsing tile after tile asks the main actor once.
  ///
  /// MapLibre holds its delegate weakly and calls it on threads of its own, so the hook is one
  /// object the process keeps. It is Sendable: what it reads sits behind a lock.
  final class MapRequestHook: NSObject, MLNNetworkConfigurationDelegate, URLSessionTaskDelegate,
    Sendable
  {
    /// shared is the process's one hook.
    static let shared = MapRequestHook()

    /// StyleAnswer is how the hook told the last failed answer it heard at a style's address:
    /// `refused`, a refusal of access, a 401, a 402 or a 403, told to the maps that claim it;
    /// `dropped`, a 401 or a 403 of a credential the client no longer sends, which their engines
    /// tell nobody; or `failed`, any other status from 400 up, or no answer at all, told as a
    /// failure.
    enum StyleAnswer: Sendable, Equatable {
      case refused
      case dropped
      case failed
    }

    /// KeptAddresses is what the hook keeps by address, at most `limit` addresses: an address kept
    /// again is the newest, and past the limit the oldest is forgotten first, as `sdk-typescript`'s
    /// map forgets the credentials its requests left with. MapLibre may never answer a request it
    /// withdrew, so what such a request left with is forgotten before what a request still awaiting
    /// its answer did, which forgetting everything at once would drop too.
    struct KeptAddresses<Value: Sendable>: Sendable {
      /// limit is the most addresses kept.
      let limit: Int
      /// values is what each address keeps, with the order it was kept in.
      private var values: [String: (value: Value, order: Int)] = [:]
      /// arrivals is each address as it was kept, oldest first from `oldest`, with its order: an
      /// arrival whose address was kept again since, or taken, no longer names its order and is
      /// passed over.
      private var arrivals: [(address: String, order: Int)] = []
      private var oldest = 0
      private var next = 0

      /// Creates a table keeping at most `limit` addresses.
      init(limit: Int) {
        self.limit = limit
      }

      /// count is how many addresses are kept.
      var count: Int {
        values.count
      }

      /// keep keeps `value` at `address`, as the newest, forgetting what the address kept before,
      /// and the oldest address kept where that makes one more than the limit.
      mutating func keep(_ value: Value, at address: String) {
        values[address] = (value, next)
        arrivals.append((address, next))
        next += 1
        while values.count > limit, oldest < arrivals.count {
          let arrival = arrivals[oldest]
          oldest += 1
          if values[arrival.address]?.order == arrival.order {
            values.removeValue(forKey: arrival.address)
          }
        }
        // Arrivals passed over are let go once they are twice the limit, so the table holds no
        // more than that whatever it is asked, each keep paying for its own arrival once.
        if arrivals.count > 2 * limit {
          arrivals = arrivals[oldest...].filter { values[$0.address]?.order == $0.order }
          oldest = 0
        }
      }

      /// take answers what `address` keeps, and forgets it, or nil where it keeps nothing.
      mutating func take(_ address: String) -> Value? {
        values.removeValue(forKey: address)?.value
      }
    }

    /// Sent is what a request awaiting its answer left with: the address MapLibre asked for, which
    /// a failure is told at, the client's headers its last hop was sent, or nil where no map's
    /// client claimed that hop's address, and, for a request the client refused, what the read of
    /// its credential threw, which its failure carries.
    private struct Sent: Sendable {
      let asked: URL
      let headers: [String: String]?
      var cause: (any Error)? = nil
    }

    /// Heard is what MapLibre's threads tell the maps, kept in the order they tell it until the
    /// main actor hands it on: a request that failed, at the address MapLibre asked for, with its
    /// status, or none where it reached no answer, whether it left under a credential the client no
    /// longer sends, and what the read of its credential threw where the client refused it; or a
    /// tile of the source `source` parsed by the map `renderer` draws.
    private enum Heard: Sendable {
      case failed(url: URL, status: Int?, superseded: Bool, cause: (any Error)?)
      case parsed(source: String, by: Parser)
    }

    /// Parser is the renderer of a map a tile was parsed for, held weakly, as a map that ends
    /// before its tiles are handed on is told nothing.
    private struct Parser: Sendable {
      weak var renderer: MapRenderer?
    }

    /// Installed is a map shown: its client, its app's own hook, the renderer that shows it, which
    /// the map is shown by while it lives, and the address of the style it asks MapLibre for last,
    /// whose failed answers the hook keeps for it.
    private struct Installed: Sendable {
      let client: Mountaya
      let transform: (@Sendable (MapRequest) -> MapRequest)?
      weak var renderer: MapRenderer?
      var style: String?
    }

    /// Sending is the session MapLibre's requests leave on, and the configuration it was made
    /// from.
    private struct Sending: Sendable {
      let configuration: URLSessionConfiguration
      let session: URLSession
    }

    /// refusedScheme is the scheme a request the client refuses is sent to: one no loader serves,
    /// so it fails before it leaves the process.
    private static let refusedScheme = "mountaya-refused"
    /// setHeaders is the key a request carries the names of the headers the hook set under, which
    /// never leaves the process.
    private static let setHeaders = "com.mountaya.elements.request-hook.set"
    /// ownHeaders is the key a request carries the headers MapLibre gave it under, before the hook.
    private static let ownHeaders = "com.mountaya.elements.request-hook.own"
    /// keptLimit is the most addresses the hook keeps what a request left with for, until its
    /// answer, and a style's failed answer for, until the address is asked for again: a request
    /// MapLibre withdraws may never be answered, so past the limit the oldest is forgotten, and an
    /// answer at an address forgotten is told as it is.
    static let keptLimit = 1_024

    /// installed is every map shown, the one shown last at the end.
    private let installed = OSAllocatedUnfairLock<[Installed]>(initialState: [])
    private let sending = OSAllocatedUnfairLock<Sending?>(initialState: nil)
    /// sent is what each request awaiting its answer left with, by the address its last hop went to.
    private let sent = OSAllocatedUnfairLock(
      initialState: KeptAddresses<Sent>(limit: MapRequestHook.keptLimit))
    /// styles is how the hook told the last failed answer at each address a map shown asks its style
    /// at, until the address is asked for again or its renderer finds it.
    private let styles = OSAllocatedUnfairLock(
      initialState: KeptAddresses<StyleAnswer>(limit: MapRequestHook.keptLimit))
    /// refusedRequests counts the requests the client refused, each sent to an address of its own,
    /// numbered in the order they were refused.
    private let refusedRequests = OSAllocatedUnfairLock<UInt64>(initialState: 0)
    /// heard is what MapLibre's threads told the maps since the main actor last handed it on, in
    /// the order they told it.
    private let heard = OSAllocatedUnfairLock<[Heard]>(initialState: [])
    /// probe is told of each hop to the main actor that hands on what MapLibre's threads told,
    /// `hop`, where a test installs one; nil in an app.
    @MainActor var probe: RenderProbe?

    /// install makes the hook MapLibre's, and shows the map `renderer` draws in it: its requests
    /// are sent for `client` through `transform`, it is the map shown last, and it is told of each
    /// failed answer it claims until it ends.
    @MainActor
    func install(
      client: Mountaya, transform: (@Sendable (MapRequest) -> MapRequest)?, renderer: MapRenderer
    ) {
      installed.withLock { installed in
        installed.removeAll { $0.renderer == nil || $0.renderer === renderer }
        installed.append(Installed(client: client, transform: transform, renderer: renderer))
      }
      let configuration = MLNNetworkConfiguration.sharedManager
      if configuration.delegate !== self {
        configuration.delegate = self
      }
    }

    /// askedStyle has the hook know `style` as the one `renderer`'s map asks MapLibre for, before
    /// it is asked, so a failed answer at its address is kept for the renderer, or none where the
    /// map shows nothing.
    @MainActor
    func askedStyle(_ style: URL?, by renderer: MapRenderer) {
      installed.withLock { installed in
        for index in installed.indices where installed[index].renderer === renderer {
          installed[index].style = style?.absoluteString
        }
      }
    }

    // MARK: - Requests

    /// session is the session MapLibre's requests leave on, one for the process, made from the
    /// configuration MapLibre holds and made again where it is replaced. MapLibre asks for it at
    /// each request, on a thread of its own; its delegate hears a redirect and nothing else.
    func session(for configuration: MLNNetworkConfiguration) -> URLSession {
      // MapLibre's configuration is never nil, reset to the default where it is set to none.
      let wanted: URLSessionConfiguration = configuration.sessionConfiguration ?? .default
      return sending.withLock { held in
        if let held, held.configuration === wanted {
          return held.session
        }
        // Requests already on their way finish on the session they left on.
        held?.session.finishTasksAndInvalidate()
        let session = URLSession(configuration: wanted, delegate: self, delegateQueue: nil)
        held = Sending(configuration: wanted, session: session)
        return session
      }
    }

    func willSend(_ request: NSMutableURLRequest) -> NSMutableURLRequest {
      let maps = shown()
      guard !maps.isEmpty, let asked = request.url else { return request }
      // The address is asked for again: how its last answer failed is forgotten.
      styles.withLock { _ = $0.take(asked.absoluteString) }
      do {
        let client = try Self.sign(request, for: maps)
        keep(Sent(asked: asked, headers: client), at: request.url)
        return request
      } catch {
        keep(nil, at: request.url)
        return NSMutableURLRequest(url: refuse(asked, cause: error))
      }
    }

    /// refuse answers where a request MapLibre asked for at `asked` is sent once the client refuses
    /// it, `cause` being what the read of its credential threw: an address of its own under a scheme
    /// no loader serves, numbered, where what it left with is kept, so its failure, which names that
    /// address, is told at the one MapLibre asked for, carrying `cause`.
    private func refuse(_ asked: URL, cause: any Error) -> URL {
      let number = refusedRequests.withLock { count in
        count &+= 1
        return count
      }
      guard let refused = URL(string: "\(Self.refusedScheme):\(number)") else {
        return asked
      }
      keep(Sent(asked: asked, headers: nil, cause: cause), at: refused)
      return refused
    }

    func urlSession(
      _ session: URLSession, task: URLSessionTask,
      willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest,
      completionHandler: @escaping @Sendable (URLRequest?) -> Void
    ) {
      completionHandler(redirected(request, from: task.currentRequest ?? task.originalRequest))
    }

    /// redirected is `request`, the one a redirect from `previous` leads to, as the hook sends it:
    /// every header the hook set on `previous` taken off, one it replaced given back MapLibre's
    /// own, and the rules of the maps shown applied for its address; a request unable to load,
    /// which fails in the process, where the client refuses the session token read for it. What
    /// `previous` left with moves to the redirect's address, the address MapLibre asked for kept and
    /// the client's headers those the redirect is sent.
    func redirected(_ request: URLRequest, from previous: URLRequest?) -> URLRequest {
      guard let redirect = (request as NSURLRequest).mutableCopy() as? NSMutableURLRequest else {
        return request
      }
      var asked = previous?.url
      if let previous {
        let set = URLProtocol.property(forKey: Self.setHeaders, in: previous) as? [String] ?? []
        let own =
          URLProtocol.property(forKey: Self.ownHeaders, in: previous) as? [String: String] ?? [:]
        for name in set {
          redirect.setValue(Self.value(of: name, in: own), forHTTPHeaderField: name)
        }
        if let address = previous.url?.absoluteString,
          let moved = sent.withLock({ $0.take(address) })
        {
          asked = moved.asked
        }
      }
      do {
        let client = try Self.sign(redirect, for: shown())
        if let asked = asked ?? redirect.url {
          keep(Sent(asked: asked, headers: client), at: redirect.url)
        }
        return redirect as URLRequest
      } catch {
        keep(nil, at: redirect.url)
        // Taken off every header the hook set, the redirect carries no credential either way.
        guard let asked = asked ?? redirect.url else { return redirect as URLRequest }
        return URLRequest(url: refuse(asked, cause: error))
      }
    }

    /// sign sends `request` for `maps`, in place: through the app's hook of the map shown last
    /// that names one, then with the headers of the map shown last whose client claims the address
    /// that hook answered, each header the request does not already carry. It records on the
    /// request which headers it set and what MapLibre gave it before, for a redirect to take off,
    /// and answers the client's headers it read, or nil where no map's client claims the address;
    /// it throws where the client refuses the session token read for it.
    private static func sign(_ request: NSMutableURLRequest, for maps: [Installed]) throws
      -> [String: String]?
    {
      let own = request.allHTTPHeaderFields ?? [:]
      if let transform = maps.last(where: { $0.transform != nil })?.transform,
        let url = request.url
      {
        let transformed = transform(MapRequest(url: url, headers: own))
        request.url = transformed.url
        for (name, value) in transformed.headers {
          request.setValue(value, forHTTPHeaderField: name)
        }
      }
      let client = try request.url.flatMap { try clientHeaders(for: $0, of: maps) }
      for (name, value) in client ?? [:] where request.value(forHTTPHeaderField: name) == nil {
        request.setValue(value, forHTTPHeaderField: name)
      }
      let set = (request.allHTTPHeaderFields ?? [:]).compactMap { name, sent in
        Self.value(of: name, in: own) == sent ? nil : name
      }
      URLProtocol.setProperty(set, forKey: setHeaders, in: request)
      URLProtocol.setProperty(own, forKey: ownHeaders, in: request)
      return client
    }

    /// clientHeaders is what the client of the map of `maps` shown last whose client claims `url`
    /// gives a request to it, `Mountaya.mapRequestHeaders(for:)` read now, or nil where no map's
    /// client claims it. It throws where that client refuses what it reads.
    private static func clientHeaders(for url: URL, of maps: [Installed]) throws
      -> [String: String]?
    {
      for map in maps.reversed() {
        if let headers = try map.client.mapRequestHeaders(for: url) {
          return headers
        }
      }
      return nil
    }

    /// keep keeps `sending`, what a request whose last hop goes to `url` left with, until its
    /// answer, forgetting what an earlier request there left with, and keeps nothing where it is nil
    /// or tells nothing an answer at `url` would not: no client's headers, and `url` the address
    /// MapLibre asked for. Past `keptLimit` addresses, the oldest kept is forgotten first.
    private func keep(_ sending: Sent?, at url: URL?) {
      guard let address = url?.absoluteString else { return }
      sent.withLock { sent in
        guard let sending,
          sending.headers != nil || sending.cause != nil || sending.asked.absoluteString != address
        else {
          _ = sent.take(address)
          return
        }
        sent.keep(sending, at: address)
      }
    }

    /// value is the value `headers` give the header `name`, its name read without regard to case.
    private static func value(of name: String, in headers: [String: String]) -> String? {
      headers.first { $0.key.caseInsensitiveCompare(name) == .orderedSame }?.value
    }

    /// shown is every map shown, the one shown last at the end; a map whose renderer ended is let
    /// go.
    private func shown() -> [Installed] {
      installed.withLock { installed in
        installed.removeAll { $0.renderer == nil }
        return installed
      }
    }

    // MARK: - Answers

    func didReceive(_ response: MLNNetworkResponse) -> MLNNetworkResponse {
      guard let answer = response.response as? HTTPURLResponse, let url = answer.url else {
        unanswered(response.error)
        return response
      }
      let kept = sent.withLock { $0.take(url.absoluteString) }
      let status = answer.statusCode
      guard status >= 400 else { return response }
      // A failure is told at the address MapLibre asked for, which lies under a source's tile
      // templates or names the style asked for, and the credential held to the headers the last
      // hop left with, at the address it went to.
      let asked = kept?.asked ?? url
      let superseded = kept?.headers.map { isSuperseded($0, at: url) } ?? false
      let told: StyleAnswer =
        if accessRefusalStatus(status) == nil {
          .failed
        } else if refusesSupersededCredential(status, superseded: superseded) {
          .dropped
        } else {
          .refused
        }
      remember(told, at: asked)
      hear(.failed(url: asked, status: status, superseded: superseded, cause: nil))
      return response
    }

    /// unanswered tells a request that reached no answer, whose `failure` names the address its
    /// last hop went to: as a failure with no status, at the address MapLibre asked for, carrying
    /// what the read of its credential threw where the client refused it, unless MapLibre withdrew
    /// it, which is no failure, or its failure names no address to tell it at.
    private func unanswered(_ failure: (any Error)?) {
      guard let failing = Self.failingAddress(of: failure) else { return }
      let kept = sent.withLock { $0.take(failing.absoluteString) }
      guard !Self.isWithdrawn(failure) else { return }
      let asked = kept?.asked ?? failing
      let cause = kept?.cause
      remember(.failed, at: asked)
      hear(.failed(url: asked, status: nil, superseded: false, cause: cause))
    }

    /// tileParsed hears that the map `renderer` draws parsed a tile of the source `source`, on a
    /// thread of MapLibre's own, which its engine is told on the main actor, in the order of what
    /// else the maps are told.
    func tileParsed(source: String, by renderer: MapRenderer) {
      hear(.parsed(source: source, by: Parser(renderer: renderer)))
    }

    /// hear keeps `told` for the main actor to hand on, asking for a hop to it where nothing told
    /// before it is still waiting for one.
    private func hear(_ told: Heard) {
      let isFirst = heard.withLock { heard in
        heard.append(told)
        return heard.count == 1
      }
      guard isFirst else { return }
      Task { @MainActor [self] in
        handOn()
      }
    }

    /// handOn hands on everything MapLibre's threads told since the last hop, in the order they
    /// told it: a parsed tile to its map's engine, a failure to each map shown that claims it,
    /// every map's claims read once for all the failures of the hop.
    @MainActor
    private func handOn() {
      probe?.report("hop")
      let told = heard.withLock { heard in
        defer { heard = [] }
        return heard
      }
      var maps: (renderers: [MapRenderer], claims: [[String]])?
      for heard in told {
        switch heard {
        case .parsed(let source, let parser):
          parser.renderer?.engine.tileLoaded(source: source)
        case .failed(let url, let status, let superseded, let cause):
          let shown = maps ?? Self.claiming(shown().compactMap(\.renderer))
          maps = shown
          for map in Self.claimants(of: url.absoluteString, claims: shown.claims) {
            shown.renderers[map].failed(
              url: url, status: status, superseded: superseded, cause: cause)
          }
        }
      }
    }

    /// claiming is `renderers` beside the claims of each.
    @MainActor
    private static func claiming(_ renderers: [MapRenderer]) -> (
      renderers: [MapRenderer], claims: [[String]]
    ) {
      (renderers, renderers.map(\.claims))
    }

    /// remember keeps how the hook told the failed answer at `asked`, where it is the address of the
    /// style a map shown asks for, for its renderer to find; a tile's is kept for nobody.
    private func remember(_ told: StyleAnswer, at asked: URL) {
      let address = asked.absoluteString
      let isStyle = installed.withLock { installed in
        installed.contains { $0.renderer != nil && $0.style == address }
      }
      guard isStyle else { return }
      styles.withLock { $0.keep(told, at: address) }
    }

    /// isSuperseded tells whether `kept`, the client's headers a request to `url` left with, are no
    /// longer what the client sends there: the client of the map shown last whose client claims
    /// `url` gives a request to it other headers now, or none, or refuses what it reads now.
    private func isSuperseded(_ kept: [String: String], at url: URL) -> Bool {
      do {
        return try Self.clientHeaders(for: url, of: shown()) != kept
      } catch {
        return true
      }
    }

    /// styleAnswer is how the hook told the last failed answer at `url`, the address of a map's
    /// style, or nil where it told none, which it forgets: a style that failed is told once, as the
    /// hook told it, rather than again as failed, and one refused a credential the client no longer
    /// sends is asked for again.
    func styleAnswer(at url: URL) -> StyleAnswer? {
      styles.withLock { $0.take(url.absoluteString) }
    }

    /// isWithdrawn tells whether `failure` is MapLibre withdrawing its request, a tile it no longer
    /// needs or a style another replaced, which is no failure of the request.
    private static func isWithdrawn(_ failure: (any Error)?) -> Bool {
      guard let failure = failure as NSError? else { return false }
      return failure.domain == NSURLErrorDomain && failure.code == NSURLErrorCancelled
    }

    /// failingAddress is the address a request that reached no answer failed at, as its failure
    /// names it, or nil where it names none.
    private static func failingAddress(of failure: (any Error)?) -> URL? {
      guard let info = (failure as NSError?)?.userInfo else { return nil }
      if let url = info[NSURLErrorFailingURLErrorKey] as? URL {
        return url
      }
      return (info[NSURLErrorFailingURLStringErrorKey] as? String).flatMap(URL.init(string:))
    }

    /// claimants is the maps an answer at `address` is told to, `claims` being the addresses each
    /// map shown claims, by their beginnings: every map one of whose claims the address starts
    /// with, or, where none does, the one map shown where it is the only one, and none where
    /// several are, an answer no map claims being told to no map that might not have asked for it.
    static func claimants(of address: String, claims: [[String]]) -> [Int] {
      let claiming = claims.indices.filter { map in
        claims[map].contains { !$0.isEmpty && address.hasPrefix($0) }
      }
      if !claiming.isEmpty {
        return claiming
      }
      return claims.count == 1 ? [0] : []
    }
  }
#endif
