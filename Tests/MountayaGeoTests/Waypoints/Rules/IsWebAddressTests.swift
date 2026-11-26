import Testing

@testable import MountayaGeo

@Suite("isWebAddress")
struct IsWebAddressTests {
  @Test("an absolute http or https address with a host is accepted")
  func accepted() {
    for address in [
      "https://refuge.example/topo",
      "http://refuge.example/reserver?jour=12",
      "https://marie:secret@refuge.example:8443/",
      "https://[2001:db8::1]/",
      "https://refuge.example/carte du refuge.pdf",
      "https://refuge.example/?remise=50%",
      "https://refuge.example/caf%C3%A9",
      "https://refuge.example",
      "https://caf%C3%A9.example/",
      "https://192.168.1.10:80/",
      "https://[::ffff:192.0.2.1]/",
      "https://refuge.example:/",
    ] {
      #expect(isWebAddress(address), "`\(address)` is accepted")
    }
  }

  @Test("any other scheme or shape is refused")
  func otherShapes() {
    for address in [
      "javascript:alert(1)",
      " javascript:alert(1)",
      "data:text/html,<script>alert(1)</script>",
      "file:///etc/passwd",
      "ask at the bar",
      "",
      "refuge.example",
      "/reserver",
      "Https://refuge.example",
      "https:refuge.example",
      "https:/refuge.example",
      "https:///refuge.example",
      "https://\\refuge.example",
      "https://",
      "https://?jour=12",
      "  https://refuge.example/topo ",
    ] {
      #expect(!isWebAddress(address), "`\(address)` is refused")
    }
  }

  /// A carriage return and a line feed are one Character and two scalars; each is a control
  /// character here.
  @Test("a character the API's parser refuses is refused")
  func refusedCharacters() {
    for address in [
      "https://refu ge.example",
      "https://refuge.example/a\tb",
      "https://refuge.example/a\u{1}b",
      "https://refuge.example/a\u{7F}b",
      "https://refuge.example/topo\n",
      "https://refuge.example/topo\r\n",
      "https://refuge.example/sale-50%-off",
      "https://refuge.example/#%",
      "https://refu%67e.example/",
    ] {
      #expect(!isWebAddress(address), "`\(address)` is refused")
    }
  }

  /// What a URL parser refuses in a host the shape lets through.
  @Test("a host a URL parser cannot read is refused")
  func unreadableHosts() {
    for address in [
      "https://:8443/",
      "https://user@/",
      "https://refuge.example:99999/",
      "https://refuge.example:8a/",
      "https://[2001:db8::1/",
      "https://[2001:db8:::1]/",
      "https://[1:2:3:4:5:6:7:8:9]/",
      "https://[::1]x/",
      "https://ref<uge.example/",
      "https://ref|uge.example/",
      "https://%C3%C3.example/",
      "https://999.1.1.1/",
      "https://1.2.3.4.5/",
      "https://refuge.123/",
    ] {
      #expect(!isWebAddress(address), "`\(address)` is refused")
    }
  }

  /// The WHATWG parser reads 0x7f.1 and 017700000001 as IPv4 addresses. A name ending in a number
  /// of another script's digits, or fullwidth ones, is refused, as `sdk-kotlin` and a URL parser
  /// refuse it; a port is ASCII digits alone.
  @Test("a name ending in a number is read as an IPv4 address in any of its radixes")
  func ipv4Radixes() {
    #expect(isWebAddress("https://0x7f.1/"))
    #expect(isWebAddress("https://017700000001/"))
    #expect(isWebAddress("https://4294967295/"))
    #expect(!isWebAddress("https://4294967296/"))
    #expect(!isWebAddress("https://08.1.1.1/"))
    #expect(!isWebAddress("https://refuge.\u{661}\u{662}\u{663}/"))
    #expect(!isWebAddress("https://refuge.\u{FF11}\u{FF12}\u{FF13}/"))
    #expect(!isWebAddress("https://refuge.example:\u{661}\u{662}/"))
    #expect(isWebAddress("https://refuge.example:0080/"))
  }
}
