import MountayaClient
import Testing

@testable import MountayaGeo

@Suite("SearchPick")
struct SearchPickTests {
  @Test("a pick holds its camera move and its mark, and is equal where both are")
  func members() {
    let pick = SearchPick(camera: .fly(center: [6, 45], zoom: 13), mark: .place(point: [6, 45]))

    #expect(pick.camera == .fly(center: [6, 45], zoom: 13))
    #expect(pick.mark == .place(point: [6, 45]))
    #expect(
      pick == SearchPick(camera: .fly(center: [6, 45], zoom: 13), mark: .place(point: [6, 45])))
    #expect(pick != SearchPick(camera: .fly(center: [6, 45], zoom: 13), mark: nil))
    #expect(SearchPick(camera: nil, mark: nil) == SearchPick(camera: nil, mark: nil))
  }
}
