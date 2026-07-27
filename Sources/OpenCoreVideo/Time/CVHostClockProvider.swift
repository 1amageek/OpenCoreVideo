import Synchronization

public final class CVHostClockProvider: Sendable {
    public static let system = CVHostClockProvider(
        initialClock: defaultCVHostClock()
    )

    private enum State: Sendable {
        case configurable(CVHostClockReference?)
        case active(CVHostClockReference)
    }

    private typealias ClockResult = Result<
        CVHostClockReference,
        CVHostClockError
    >

    private let state: Mutex<State>

    public init<Clock: CVHostClock>(initialClock: Clock?) {
        state = Mutex(
            .configurable(initialClock.map(CVHostClockReference.init))
        )
    }

    public convenience init() {
        self.init(initialClock: Optional<CVHostClockReference>.none)
    }

    public func install<Clock: CVHostClock>(
        _ clock: Clock
    ) throws(CVHostClockError) {
        let clock = CVHostClockReference(clock)
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

    public func current() throws(CVHostClockError) -> CVHostClockReference {
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

private func defaultCVHostClock() -> CVHostClockReference? {
    #if hasFeature(Embedded)
    nil
    #else
    CVHostClockReference(CVSystemHostClock())
    #endif
}
