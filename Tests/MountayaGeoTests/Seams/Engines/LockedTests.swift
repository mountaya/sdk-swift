import Testing

@testable import MountayaGeo

@Suite("Locked")
struct LockedTests {
  @Test("every change under the lock is kept, from any number of tasks at once")
  func changesAreKept() async {
    let counter = Locked(0)
    await withTaskGroup(of: Void.self) { group in
      for _ in 0..<100 {
        group.addTask {
          counter.withLock { $0 += 1 }
        }
      }
    }

    #expect(counter.value == 100)
    #expect(counter.withLock { value -> Int in value * 2 } == 200)
  }
}
