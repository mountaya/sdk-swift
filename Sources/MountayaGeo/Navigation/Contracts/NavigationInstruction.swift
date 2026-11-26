/// NavigationInstruction is the copy key a step's instruction is said with and the arguments the
/// key takes, never the sentence (`geo.navigation.instruction-keys`). The words are the host's: its
/// strings hold a sentence for each `key`, and a language puts the `name` and the `exit` where its
/// own grammar does, so one step reads alike in every SDK and in every language a host ships.
///
/// `name` is stated exactly where the key's arguments hold `NavigationInstructionArgument.name`,
/// and `exit` exactly where they hold `NavigationInstructionArgument.exit`: `stepInstruction(_:)`
/// alone builds one, so the two never disagree with the key. Two are equal where all three members
/// are, the name by its scalars.
public struct NavigationInstruction: Sendable, Hashable {
  /// key is the copy key the instruction is said with.
  public let key: NavigationInstructionKey
  /// name is the name of the way, where the key takes one, and nil where it takes none.
  public let name: String?
  /// exit is the roundabout exit to take, from 1, where the key takes one, and nil where it takes
  /// none.
  public let exit: Int?

  /// Creates the instruction a key says, with the arguments it takes.
  init(key: NavigationInstructionKey, name: String? = nil, exit: Int? = nil) {
    self.key = key
    self.name = name
    self.exit = exit
  }

  /// Two instructions are equal where they hold one key, the same name, scalar for scalar, and one
  /// exit.
  public static func == (lhs: Self, rhs: Self) -> Bool {
    lhs.key == rhs.key && sameText(lhs.name, rhs.name) && lhs.exit == rhs.exit
  }

  /// hash feeds the key, the name and the exit.
  public func hash(into hasher: inout Hasher) {
    hasher.combine(key)
    hasher.combine(name)
    hasher.combine(exit)
  }
}
