public struct CVHostClockReference: CVHostClock, Sendable {
    public let frequency: Double
    public let minimumTimeDelta: UInt32

    private let currentTimeOperation: @Sendable () -> UInt64

    public init<Clock: CVHostClock>(_ clock: Clock) {
        frequency = clock.frequency
        minimumTimeDelta = clock.minimumTimeDelta
        currentTimeOperation = {
            clock.currentHostTime()
        }
    }

    public func currentHostTime() -> UInt64 {
        currentTimeOperation()
    }
}
