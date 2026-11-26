/// convertDataSize converts a value from one data size unit to another through the whole number
/// of bits each holds: eight to a byte, decimal prefixes under the kilo and mega names and binary
/// ones under the kibi and mebi names, so a megabyte is 1,000,000 bytes and a mebibyte 1,048,576.
public func convertDataSize(_ value: Double, from: DataSizeUnit, to: DataSizeUnit) -> Double {
  scaleByRatio(value, numerator: from.bits, denominator: to.bits)
}

extension DataSizeUnit {
  /// bits is the unit's size in bits.
  fileprivate var bits: Int64 {
    let byte: Int64 = 8
    let kibibyte = 1_024 * byte
    switch self {
    case .bit: return 1
    case .byte: return byte
    case .kibibyte: return kibibyte
    case .kilobit: return 1_000
    case .kilobyte: return 1_000 * byte
    case .mebibyte: return 1_024 * kibibyte
    case .megabit: return 1_000_000
    case .megabyte: return 1_000_000 * byte
    }
  }
}
