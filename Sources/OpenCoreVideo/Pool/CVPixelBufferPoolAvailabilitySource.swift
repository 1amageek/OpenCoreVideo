internal final class CVPixelBufferPoolAvailabilitySource: Sendable {
    private struct Subscriber: Sendable {
        let identifier: UInt
        let continuation:
            AsyncStream<CVPixelBufferPoolAvailability>.Continuation
    }

    private struct State: Sendable {
        var nextIdentifier: UInt = 0
        var subscribers: [Subscriber] = []
        var notificationsEnabled = false
        var isShutdown = false
    }

    private let state = CVStateLock(State())

    internal func makeStream()
        -> AsyncStream<CVPixelBufferPoolAvailability>
    {
        let state = self.state
        return AsyncStream(bufferingPolicy: .bufferingNewest(1)) {
            continuation in
            let identifier = state.withLock { state in
                var identifier = state.nextIdentifier
                while state.subscribers.contains(where: {
                    $0.identifier == identifier
                }) {
                    identifier &+= 1
                }
                state.nextIdentifier = identifier &+ 1
                return identifier
            }
            continuation.onTermination = { @Sendable _ in
                state.withLock { state in
                    state.subscribers.removeAll {
                        $0.identifier == identifier
                    }
                }
            }
            let shouldFinish = state.withLock { state in
                guard !state.isShutdown else {
                    return true
                }
                state.subscribers.append(
                    Subscriber(
                        identifier: identifier,
                        continuation: continuation
                    )
                )
                return false
            }
            if shouldFinish {
                continuation.finish()
            }
        }
    }

    internal func enableNotifications() {
        state.withLock { state in
            guard !state.isShutdown else {
                return
            }
            state.notificationsEnabled = true
        }
    }

    internal func yieldBufferAvailable() {
        let continuations: [
            AsyncStream<CVPixelBufferPoolAvailability>.Continuation
        ] = state.withLock { state in
            guard state.notificationsEnabled, !state.isShutdown else {
                return []
            }
            var continuations: [
                AsyncStream<CVPixelBufferPoolAvailability>.Continuation
            ] = []
            continuations.reserveCapacity(state.subscribers.count)
            for subscriber in state.subscribers {
                continuations.append(subscriber.continuation)
            }
            return continuations
        }
        for continuation in continuations {
            continuation.yield(.bufferAvailable)
        }
    }

    internal func shutdown() {
        let continuations: [
            AsyncStream<CVPixelBufferPoolAvailability>.Continuation
        ] = state.withLock { state in
            guard !state.isShutdown else {
                return []
            }
            state.isShutdown = true
            var continuations: [
                AsyncStream<CVPixelBufferPoolAvailability>.Continuation
            ] = []
            continuations.reserveCapacity(state.subscribers.count)
            for subscriber in state.subscribers {
                continuations.append(subscriber.continuation)
            }
            state.subscribers.removeAll(keepingCapacity: false)
            return continuations
        }
        for continuation in continuations {
            continuation.finish()
        }
    }
}
