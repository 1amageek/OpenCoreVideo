import Synchronization

public final class CVHostClockProvider: Sendable {
    public static let system = CVHostClockProvider(
        initialClock: defaultCVHostClock()
    )

    private enum State: Sendable {
        case configurable((any CVHostClock)?)
        case active(any CVHostClock)
    }

    private typealias ClockResult = Result<
        any CVHostClock,
        CVHostClockError
    >

    private let state: Mutex<State>

    public init(initialClock: (any CVHostClock)? = nil) {
        state = Mutex(.configurable(initialClock))
    }

    public func install(
        _ clock: any CVHostClock
    ) throws(CVHostClockError) {
        let result: Result<Void, CVHostClockError> = state.withLock { state in
            switch state {
            case .configurable:
                state = .configurable(clock)
                return .success(())
            case .active:
                return .failure(.alreadyInUse)
            }
        }
        if case let .failure(error) = result {
            throw error
        }
    }

    public func current() throws(CVHostClockError) -> any CVHostClock {
        let result: ClockResult = state.withLock { state in
            switch state {
            case let .configurable(clock):
                guard let clock else {
                    return .failure(.unconfigured)
                }
                state = .active(clock)
                return .success(clock)
            case let .active(clock):
                return .success(clock)
            }
        }
        switch result {
        case let .success(clock):
            return clock
        case let .failure(error):
            throw error
        }
    }
}

private func defaultCVHostClock() -> (any CVHostClock)? {
    #if hasFeature(Embedded)
    nil
    #else
    CVSystemHostClock()
    #endif
}
