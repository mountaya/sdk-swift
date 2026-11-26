/// DataSizeUnit is a unit an amount of data is stated in. The bit, the byte and their decimal
/// multiples are spelled by their ECMA-402 identifiers and take decimal prefixes, so a kilobyte is
/// 1,000 bytes and a megabit 1,000,000 bits. `kibibyte` and `mebibyte` are the binary units,
/// 1,024 bytes and 1,024 kibibytes, under their IEC names, which ECMA-402 does not list; the
/// contract states its body ceilings in them.
///
/// The cases are declared in the alphabetical order of their ids, the order `allCases` yields.
public enum DataSizeUnit: String, CaseIterable, Sendable {
  /// bit is the bit.
  case bit
  /// byte is eight bits.
  case byte
  /// kibibyte is 1,024 bytes.
  case kibibyte
  /// kilobit is 1,000 bits.
  case kilobit
  /// kilobyte is 1,000 bytes.
  case kilobyte
  /// mebibyte is 1,024 kibibytes, 1,048,576 bytes.
  case mebibyte
  /// megabit is 1,000,000 bits.
  case megabit
  /// megabyte is 1,000,000 bytes.
  case megabyte

  /// id is the contract's unit id, as `geo/units-convert.json` spells it.
  public var id: String { rawValue }
}
