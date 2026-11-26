import Foundation
import MountayaClient
import TrailSessionServer

// Trail's session server, `mise run trail:session`: it reads your publishable and secret keys from
// the shell and answers the app's `POST /session` on 127.0.0.1:8787 until you stop it, minting
// each session with the secret key, which never leaves this process and is never printed.

/// refuse prints `sentence` and stops the server before it starts.
func refuse(_ sentence: String) -> Never {
  FileHandle.standardError.write(Data((sentence + "\n").utf8))
  exit(1)
}

// Each line is written as it is printed, a log piped to a file included.
setvbuf(stdout, nil, _IOLBF, 0)

// trail: trail.session
let keys: SessionKeys
do {
  keys = try SessionKeys.read(ProcessInfo.processInfo.environment)
} catch {
  refuse("\(error)")
}

// The client holds the secret key to its prefix, and a refusal of it names the prefix, never the
// key.
let mountaya: Mountaya
do {
  mountaya = try Mountaya(credential: .secret(key: keys.secretKey))
} catch {
  refuse("\(error)")
}

let server = SessionServer(
  mint: SessionServer.minting(mountaya, publishableKey: keys.publishableKey),
  onAnswer: { method, path, status in print("\(method) \(path) \(status)") },
  onFailure: { error in
    FileHandle.standardError.write(
      Data("A session could not be minted\(SessionServer.reason(error)).\n".utf8))
  })

let listener: SessionListener
do {
  listener = try await server.listen()
} catch {
  refuse("The session server cannot listen on 127.0.0.1:\(SessionServer.port): \(error).")
}

print(
  "Trail's session server answers POST \(SessionServer.path) on 127.0.0.1:\(listener.port): "
    + "http://localhost:\(listener.port)\(SessionServer.path) from the iOS simulator, "
    + "http://10.0.2.2:\(listener.port)\(SessionServer.path) from the Android emulator. "
    + "Ctrl-C stops it.")

// It answers until it is stopped.
while true {
  try await Task.sleep(for: .seconds(3_600))
}
