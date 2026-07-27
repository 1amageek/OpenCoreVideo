internal struct CVPixelBufferAccessCoordinatorAdapter: Sendable {
    private let lockOperation:
        @Sendable (CVPixelBufferAccessMode) throws(CVPixelBufferError) -> Void
    private let unlockOperation:
        @Sendable (CVPixelBufferAccessMode) -> Void

    internal init() {
        lockOperation = { _ in }
        unlockOperation = { _ in }
    }

    internal init<Coordinator: CVPixelBufferAccessCoordinator>(
        _ coordinator: Coordinator
    ) {
        lockOperation = {
            (mode: CVPixelBufferAccessMode) throws(CVPixelBufferError) in
            try coordinator.lock(mode)
        }
        unlockOperation = { mode in
            coordinator.unlock(mode)
        }
    }

    internal func lock(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) {
        try lockOperation(mode)
    }

    internal func unlock(_ mode: CVPixelBufferAccessMode) {
        unlockOperation(mode)
    }
}
