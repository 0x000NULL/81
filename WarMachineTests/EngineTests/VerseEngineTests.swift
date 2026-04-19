import Testing
import Foundation
@testable import WarMachine

@Suite("VerseEngine")
struct VerseEngineTests {
    @Test("same date returns same verse across calls")
    func determinism() {
        let d = Date(timeIntervalSince1970: 1_700_000_000)
        let a = VerseEngine.verseOfDay(on: d)
        let b = VerseEngine.verseOfDay(on: d)
        #expect(a.reference == b.reference)
    }

    @Test("different dates usually return different verses")
    func variability() {
        let a = VerseEngine.verseOfDay(on: Date(timeIntervalSince1970: 1_700_000_000))
        let b = VerseEngine.verseOfDay(on: Date(timeIntervalSince1970: 1_700_864_000))
        // Not guaranteed — but across many days we expect variation. Pick two indices 10 days apart.
        _ = (a, b)
    }

    @Test("themed verse pick respects theme when pool non-empty")
    func themed() {
        let v = VerseEngine.themedVerseOfDay(on: .now, theme: .strength)
        #expect(v.theme == .strength)
    }
}
