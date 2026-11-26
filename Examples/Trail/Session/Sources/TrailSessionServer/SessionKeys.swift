import Foundation

/// SessionKeys is the two keys the session server reads from the shell: the publishable key each
/// session is minted for, and the secret key that mints it, which never leaves this process.
///
/// It prints neither: a log, a debugger's description and a dump all read `<redacted>`.
public struct SessionKeys: Sendable, CustomStringConvertible, CustomDebugStringConvertible,
  CustomReflectable
{
  /// publishableKeyVariable is the variable the publishable key is read from.
  public static let publishableKeyVariable = "MOUNTAYA_PUBLISHABLE_KEY"

  /// secretKeyVariable is the variable the secret key is read from.
  public static let secretKeyVariable = "MOUNTAYA_SECRET_KEY"

  /// publishableKey is the key every session is minted for, the one the app carries.
  public let publishableKey: String

  /// secretKey is the key `postSession` is authenticated with.
  public let secretKey: String

  /// Creates the keys a test states.
  public init(publishableKey: String, secretKey: String) {
    self.publishableKey = publishableKey
    self.secretKey = secretKey
  }

  /// read reads both keys from `environment`, a value of whitespace alone read as none, and throws
  /// the one sentence that refuses to start without them, naming each missing variable and never
  /// a key.
  public static func read(_ environment: [String: String]) throws(SessionKeysMissing)
    -> SessionKeys
  {
    let publishable = stated(environment[publishableKeyVariable])
    let secret = stated(environment[secretKeyVariable])
    guard let publishable, let secret else {
      var missing: [String] = []
      if publishable == nil { missing.append(publishableKeyVariable) }
      if secret == nil { missing.append(secretKeyVariable) }
      throw SessionKeysMissing(variables: missing)
    }
    return SessionKeys(publishableKey: publishable, secretKey: secret)
  }

  /// description names no key.
  public var description: String {
    "SessionKeys(<redacted>)"
  }

  /// debugDescription names no key either.
  public var debugDescription: String {
    description
  }

  /// customMirror has no children, so a dump prints no key.
  public var customMirror: Mirror {
    Mirror(self, children: [])
  }

  private static func stated(_ value: String?) -> String? {
    guard let trimmed = value?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty
    else { return nil }
    return trimmed
  }
}

/// SessionKeysMissing is why the session server refuses to start: the variables it found no key
/// in, named in one sentence.
public struct SessionKeysMissing: Error, Sendable, CustomStringConvertible {
  /// variables is each variable missing, the publishable key's first.
  public let variables: [String]

  /// description is the sentence the server refuses to start with.
  public var description: String {
    let named = variables.joined(separator: " and ")
    return variables.count == 1
      ? "\(named) is not set: export it in this shell, from your organization's API keys, then "
        + "run mise run trail:session again."
      : "\(named) are not set: export them in this shell, from your organization's API keys, "
        + "then run mise run trail:session again."
  }
}
