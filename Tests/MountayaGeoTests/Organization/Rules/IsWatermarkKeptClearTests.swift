import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("isWatermarkKeptClear")
struct IsWatermarkKeptClearTests {
  @Test("the frame is held while the read waits, and in every state that draws the mark")
  func held() {
    #expect(isWatermarkKeptClear(.waiting), "held from the map's first drawing")
    #expect(isWatermarkKeptClear(.timedOut))
    #expect(isWatermarkKeptClear(.failed))
    #expect(isWatermarkKeptClear(.noKey))
    #expect(isWatermarkKeptClear(.answered(whiteLabel: false)))
  }

  @Test("the frame is released once the read answers white label, which draws no mark")
  func released() {
    #expect(!isWatermarkKeptClear(.answered(whiteLabel: true)))
  }

  @Test("the frame is held wherever the rule draws the mark, and while the read waits on one")
  func followsTheMark() {
    let reads: [OrganizationRead] = [
      .waiting, .answered(whiteLabel: true), .answered(whiteLabel: false), .failed, .timedOut,
      .noKey,
    ]
    for read in reads {
      let isDrawn = watermarkOf(read, language: .en) != nil
      #expect(isWatermarkKeptClear(read) == (isDrawn || read == .waiting), "\(read)")
    }
  }
}
