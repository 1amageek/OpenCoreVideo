internal final class CVPixelBufferMemoryLease<
    Coordinator: CVPixelBufferAccessCoordinator
> {
    private struct State: Sendable {
        var baseAddressBits: UInt?
        var readerCount = 0
        var isWriting = false
        var isReleased = false
    }

    internal let byteCount: Int
    internal let accessCapabilities: CVPixelBufferAccessCapabilities

    private let state: CVStateLock<State>
    private let coordinator: Coordinator
    private let releaseHandler:
        @Sendable (UnsafeMutableRawPointer, Int) -> Void

    internal init(
        baseAddress: UnsafeMutableRawPointer,
        byteCount: Int,
        accessCapabilities: CVPixelBufferAccessCapabilities,
        coordinator: Coordinator,
        releaseHandler:
            @escaping @Sendable (UnsafeMutableRawPointer, Int) -> Void
    ) {
        self.byteCount = byteCount
        self.accessCapabilities = accessCapabilities
        self.state = CVStateLock(
            State(baseAddressBits: UInt(bitPattern: baseAddress))
        )
        self.coordinator = coordinator
        self.releaseHandler = releaseHandler
    }

    deinit {
        let releaseAddress: UInt? = state.withLock { state in
            guard !state.isReleased else {
                return nil
            }

            state.isReleased = true
            let releaseAddress = state.baseAddressBits
            state.baseAddressBits = nil
            return releaseAddress
        }

        if
            let releaseAddress,
            let baseAddress = UnsafeMutableRawPointer(
                bitPattern: releaseAddress
            )
        {
            releaseHandler(baseAddress, byteCount)
        }
    }

    internal func withReadAccess(
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

        guard
            let baseAddress = UnsafeMutableRawPointer(
                bitPattern: baseAddressBits
            )
        else {
            throw CVPixelBufferError.storageReleased
        }
        let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
        let span = Span(
            _unsafeStart: UnsafePointer(bytes),
            count: byteCount
        )
        body(span)
    }

    internal func withWriteAccess(
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

        guard
            let baseAddress = UnsafeMutableRawPointer(
                bitPattern: baseAddressBits
            )
        else {
            throw CVPixelBufferError.storageReleased
        }
        let bytes = baseAddress.assumingMemoryBound(to: UInt8.self)
        var span = MutableSpan(
            _unsafeStart: bytes,
            count: byteCount
        )
        body(&span)
    }

    private func acquire(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) -> UInt {
        try state.withLock { state throws(CVPixelBufferError) in
            guard
                !state.isReleased,
                let baseAddressBits = state.baseAddressBits
            else {
                throw .storageReleased
            }

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

    private func finish(_ mode: CVPixelBufferAccessMode) {
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
}

extension CVPixelBufferMemoryLease: Sendable {}
