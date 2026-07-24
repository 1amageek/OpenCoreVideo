#if hasFeature(Embedded)
internal final class CVStateLock<State> {
    private var state: State

    internal init(_ state: State) {
        self.state = state
    }

    internal func withLock<Result, Failure: Error>(
        _ body: (inout State) throws(Failure) -> Result
    ) throws(Failure) -> Result {
        try body(&state)
    }
}
#else
import Synchronization

internal final class CVStateLock<State>: Sendable {
    private let state: Mutex<State>

    internal init(_ state: sending State) {
        self.state = Mutex(state)
    }

    internal func withLock<Result, Failure: Error>(
        _ body:
            (inout sending State) throws(Failure) -> sending Result
    ) throws(Failure) -> sending Result {
        try state.withLock(body)
    }
}
#endif
