#if !hasFeature(Embedded)
internal struct CVSystemHostClock: CVHostClock, Sendable {
    let frequency: Double = 1_000_000_000
    let minimumTimeDelta: UInt32 = 1

    private let clock: ContinuousClock
    private let epoch: ContinuousClock.Instant

    init() {
        let clock = ContinuousClock()
        self.clock = clock
        self.epoch = clock.now
    }

    func currentHostTime() -> UInt64 {
        let components = epoch.duration(to: clock.now).components
        precondition(components.seconds >= 0)
        precondition(components.attoseconds >= 0)

        let seconds = UInt64(components.seconds)
        let nanosecondsFromSeconds = seconds.multipliedReportingOverflow(
            by: 1_000_000_000
        )
        precondition(!nanosecondsFromSeconds.overflow)

        let subsecondNanoseconds =
            UInt64(components.attoseconds) / 1_000_000_000
        let result = nanosecondsFromSeconds.partialValue
            .addingReportingOverflow(subsecondNanoseconds)
        precondition(!result.overflow)
        return result.partialValue
    }
}
#endif
