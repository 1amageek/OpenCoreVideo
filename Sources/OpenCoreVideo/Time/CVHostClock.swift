public protocol CVHostClock: Sendable {
    var frequency: Double { get }
    var minimumTimeDelta: UInt32 { get }

    func currentHostTime() -> UInt64
}
