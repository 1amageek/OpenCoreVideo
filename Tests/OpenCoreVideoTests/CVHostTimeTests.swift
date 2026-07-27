#if canImport(CoreVideo)
import CoreVideo
#endif
import OpenCoreVideo
import Testing

@Suite("Core Video host time")
struct CVHostTimeTests {
    @Test("Portable host time is monotonic with a declared nanosecond timebase")
    func monotonicTime() {
        let first = OpenCoreVideo.CVGetCurrentHostTime()
        let second = OpenCoreVideo.CVGetCurrentHostTime()

        #expect(second >= first)
        #expect(OpenCoreVideo.CVGetHostClockFrequency() == 1_000_000_000)
        #expect(OpenCoreVideo.CVGetHostClockMinimumTimeDelta() == 1)
    }

    @Test("An unconfigured provider reports a typed failure")
    func unconfiguredProvider() {
        let provider = CVHostClockProvider()

        #expect(throws: CVHostClockError.unconfigured) {
            try provider.current()
        }
    }

    @Test("A provider freezes its timebase after first use")
    func providerLifecycle() throws {
        let provider = CVHostClockProvider()
        let clock = TestHostClock(time: 42)

        try provider.install(clock)
        let activeClock = try provider.current()

        #expect(activeClock.currentHostTime() == 42)
        #expect(activeClock.frequency == 24_000_000)
        #expect(activeClock.minimumTimeDelta == 1)
        #expect(throws: CVHostClockError.alreadyInUse) {
            try provider.install(TestHostClock(time: 84))
        }
    }

    @Test("Concurrent installation and reads preserve one active timebase")
    func concurrentProviderAccess() async throws {
        let provider = CVHostClockProvider(
            initialClock: TestHostClock(time: 0)
        )

        await withTaskGroup(of: Void.self) { group in
            for index in 1 ... 64 {
                group.addTask {
                    if index.isMultiple(of: 2) {
                        do {
                            try provider.install(
                                TestHostClock(time: UInt64(index))
                            )
                        } catch CVHostClockError.alreadyInUse {
                            // Activation won the race, so replacement is closed.
                        } catch {
                            Issue.record(
                                "Unexpected host clock installation error"
                            )
                        }
                    } else {
                        do {
                            let clock = try provider.current()
                            #expect(clock.currentHostTime() <= 64)
                        } catch {
                            Issue.record("Configured provider became unavailable")
                        }
                    }
                }
            }
        }

        let activeClock = try provider.current()
        #expect(activeClock.currentHostTime() <= 64)
        #expect(throws: CVHostClockError.alreadyInUse) {
            try provider.install(TestHostClock(time: 128))
        }
    }

    #if canImport(CoreVideo)
    @Test("Apple and portable clocks each satisfy their declared timebase")
    func appleContract() {
        let appleFirst = CoreVideo.CVGetCurrentHostTime()
        let appleSecond = CoreVideo.CVGetCurrentHostTime()

        #expect(appleSecond >= appleFirst)
        #expect(CoreVideo.CVGetHostClockFrequency() > 0)
        #expect(CoreVideo.CVGetHostClockMinimumTimeDelta() > 0)
        #expect(OpenCoreVideo.CVGetHostClockFrequency() > 0)
        #expect(OpenCoreVideo.CVGetHostClockMinimumTimeDelta() > 0)
    }
    #endif
}

private struct TestHostClock: CVHostClock {
    let time: UInt64
    let frequency: Double = 24_000_000
    let minimumTimeDelta: UInt32 = 1

    func currentHostTime() -> UInt64 {
        time
    }
}
