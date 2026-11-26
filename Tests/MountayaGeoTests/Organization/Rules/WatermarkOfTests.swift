import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("watermarkOf")
struct WatermarkOfTests {
  @Test("no mark while the read waits or once it answers white label")
  func none() {
    #expect(watermarkOf(.waiting, language: .en) == nil)
    #expect(watermarkOf(.answered(whiteLabel: true), language: .fr) == nil)
  }

  @Test("the mark once the read answers none, fails, or where no key reads anything")
  func drawn() throws {
    let mark = try #require(watermarkOf(.answered(whiteLabel: false), language: .en))
    #expect(mark.drawing == "watermark")
    #expect(mark.x == -4 && mark.y == -4 && mark.width == 180)
    #expect(abs(mark.height - 75.65217391304348) < 1e-12)
    #expect(mark.href == "https://www.mountaya.com/en/")
    #expect(mark.label == "watermark.label")
    #expect(watermarkOf(.failed, language: .fr)?.href == "https://www.mountaya.com/fr/")
    #expect(watermarkOf(.noKey, language: .ja)?.href == "https://www.mountaya.com/")
  }

  @Test("the mark once one attempt's budget has passed with no answer, retries going on or not")
  func timedOut() {
    #expect(watermarkOf(.timedOut, language: .de)?.href == "https://www.mountaya.com/")
  }

  @Test("a browser's top-level page on Mountaya's own origin omits it, a framed one keeps it")
  func page() {
    #expect(
      watermarkOf(.failed, language: .en, page: ("https://app.mountaya.com", true)) == nil)
    #expect(
      watermarkOf(.failed, language: .en, page: ("https://app.mountaya.com", false)) != nil)
    #expect(
      watermarkOf(.failed, language: .en, page: ("https://studio.mountaya.com", true)) != nil)
  }
}
