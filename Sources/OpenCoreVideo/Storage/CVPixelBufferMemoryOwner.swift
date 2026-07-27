internal final class CVPixelBufferMemoryOwner: Sendable {
    internal enum ReleaseOperation: Sendable {
        case deallocate
        case custom(@Sendable (UnsafeMutableRawPointer, Int) -> Void)
    }

    private struct State: Sendable {
        var baseAddressBits: UInt
        var readerCount = 0
        var isWriting = false
        var isReleased = false
    }

    private let state: CVStateLock<State>
    private let releaseOperation: ReleaseOperation

    internal let byteCount: Int
    internal let accessCapabilities: CVPixelBufferAccessCapabilities

    // The owner retains a non-null allocation whose complete byte range is
    // initialized before this initializer. Pointer borrows remain inside the
    // caller's synchronous scope. State exclusion prevents overlapping writes,
    // and deinit invokes the matching release operation exactly once.
    internal init(
        baseAddress: UnsafeMutableRawPointer,
        byteCount: Int,
        accessCapabilities: CVPixelBufferAccessCapabilities,
        releaseOperation: ReleaseOperation
    ) {
        self.state = CVStateLock(
            State(baseAddressBits: UInt(bitPattern: baseAddress))
        )
        self.releaseOperation = releaseOperation
        self.byteCount = byteCount
        self.accessCapabilities = accessCapabilities
    }

    deinit {
        let releaseAddress: UInt? = state.withLock { state in
            guard !state.isReleased else {
                return nil
            }

            state.isReleased = true
            let releaseAddress = state.baseAddressBits
            state.baseAddressBits = 0
            return releaseAddress
        }

        if let releaseAddress,
           let baseAddress = UnsafeMutableRawPointer(
               bitPattern: releaseAddress
           ) {
            switch releaseOperation {
            case .deallocate:
                baseAddress.deallocate()
            case .custom(let releaseHandler):
                releaseHandler(baseAddress, byteCount)
            }
        }
    }

    internal func acquire(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) -> UInt {
        try state.withLock { state throws(CVPixelBufferError) in
            guard !state.isReleased else {
                throw .storageReleased
            }
            let baseAddressBits = state.baseAddressBits

            switch mode {
            case .read:
                guard accessCapabilities.contains(.read) else {
                    throw .unsupportedAccess(.read)
                }
                guard !state.isWriting else {
                    throw .accessConflict(.read)
                }
                state.readerCount += 1

            case .write:
                guard accessCapabilities.contains(.write) else {
                    throw .unsupportedAccess(.write)
                }
                guard !state.isWriting, state.readerCount == 0 else {
                    throw .accessConflict(.write)
                }
                state.isWriting = true
            }

            return baseAddressBits
        }
    }

    internal func finish(_ mode: CVPixelBufferAccessMode) {
        state.withLock { state in
            switch mode {
            case .read:
                precondition(state.readerCount > 0)
                state.readerCount -= 1
            case .write:
                precondition(state.isWriting)
                state.isWriting = false
            }
        }
    }

    internal func withReadAccess(
        coordinator: CVPixelBufferAccessCoordinatorAdapter,
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let baseAddressBits = try acquire(.read)

        do {
            try coordinator.lock(.read)
        } catch {
            finish(.read)
            throw error
        }

        defer {
            coordinator.unlock(.read)
            finish(.read)
        }

        guard let baseAddress = UnsafeMutableRawPointer(
            bitPattern: baseAddressBits
        ) else {
            throw .storageReleased
        }
        let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
        body(
            Span(
                _unsafeStart: UnsafePointer(bytes),
                count: byteCount
            )
        )
    }

    internal func withWriteAccess(
        coordinator: CVPixelBufferAccessCoordinatorAdapter,
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let baseAddressBits = try acquire(.write)

        do {
            try coordinator.lock(.write)
        } catch {
            finish(.write)
            throw error
        }

        defer {
            coordinator.unlock(.write)
            finish(.write)
        }

        guard let baseAddress = UnsafeMutableRawPointer(
            bitPattern: baseAddressBits
        ) else {
            throw .storageReleased
        }
        var span = MutableSpan(
            _unsafeStart: baseAddress.assumingMemoryBound(to: UInt8.self),
            count: byteCount
        )
        body(&span)
    }
}
