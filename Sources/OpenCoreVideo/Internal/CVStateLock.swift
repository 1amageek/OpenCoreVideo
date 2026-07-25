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
