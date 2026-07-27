public func CVGetCurrentHostTime() -> UInt64 {
    requiredCVHostClock().currentHostTime()
}

public func CVGetHostClockFrequency() -> Double {
    requiredCVHostClock().frequency
}

public func CVGetHostClockMinimumTimeDelta() -> UInt32 {
    requiredCVHostClock().minimumTimeDelta
}

private func requiredCVHostClock() -> any CVHostClock {
    do {
        return try CVHostClockProvider.system.current()
    } catch {
        preconditionFailure(
            "A CVHostClock must be installed before using host-time operations"
        )
    }
}
