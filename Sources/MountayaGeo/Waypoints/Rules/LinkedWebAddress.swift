/// linkedWebAddress is the address a card links for one a place records: a contact's website and
/// booking address, a custom field declared `url`, a photo's or a link's address. It is the address
/// read past the white space at its ends, where that is one `isWebAddress(_:)` accepts, and nil for
/// any other, which a card states as text and never puts in a link.
///
/// It is the one answer for every address a card links, so `javascript:` and `data:` reach no link
/// through any of them.
public func linkedWebAddress(_ address: String?) -> String? {
  guard let address else { return nil }
  let trimmed = trimWhiteSpace(address)
  return isWebAddress(trimmed) ? trimmed : nil
}
