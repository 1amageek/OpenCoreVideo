internal final class CVPixelBufferPoolCore<
    Allocator: CVPixelBufferPoolAllocator
>: CVPlatformConcurrencyContract {
    private struct AvailableStorage: CVPlatformConcurrencyContract {
        let storage: Allocator.Storage
        let recycledAt: UInt64
    }

    private struct State: CVPlatformConcurrencyContract {
        var available: [AvailableStorage] = []
        var allocatedCount = 0
    }

    private let allocator: Allocator
    private let configuration: CVPixelBufferPoolConfiguration
    private let timestamp: @Sendable () -> UInt64
    private let state = CVStateLock(State())

    internal init(
        allocator: Allocator,
        configuration: CVPixelBufferPoolConfiguration,
        timestamp: @escaping @Sendable () -> UInt64
    ) {
        self.allocator = allocator
        self.configuration = configuration
        self.timestamp = timestamp
    }

    internal func checkout(
        byteCount: Int,
        allocationThreshold: Int?
    ) throws(CVPixelBufferError) -> Allocator.Storage {
        if let allocationThreshold, allocationThreshold <= 0 {
            throw .invalidAllocationThreshold(allocationThreshold)
        }

        let available = try state.withLock {
            state throws(CVPixelBufferError) -> Allocator.Storage? in
            if let storage = state.available.popLast()?.storage {
                return storage
            }

            if
                let allocationThreshold,
                state.allocatedCount >= allocationThreshold
            {
                throw .wouldExceedAllocationThreshold(
                    allocationThreshold
                )
            }

            state.allocatedCount += 1
            return nil
        }

        if let available {
            return available
        }

        var committedReservation = false
        defer {
            if !committedReservation {
                state.withLock { state in
                    precondition(state.allocatedCount > 0)
                    state.allocatedCount -= 1
                }
            }
        }

        let storage = try allocator.storage(byteCount: byteCount)
        guard storage.byteCount >= byteCount else {
            throw CVPixelBufferError.storageTooSmall(
                required: byteCount,
                actual: storage.byteCount
            )
        }
        committedReservation = true
        return storage
    }

    internal func recycle(_ storage: Allocator.Storage) {
        let recycledAt = timestamp()
        state.withLock { state in
            state.available.append(
                AvailableStorage(
                    storage: storage,
                    recycledAt: recycledAt
                )
            )
        }
    }

    internal func flush(_ flags: CVPixelBufferPoolFlushFlags) {
        if flags.contains(.excessBuffers) {
            let discarded = state.withLock { state in
                // Retaining small storage references defers native release
                // callbacks until after the pool mutex is unlocked.
                let discarded = state.available.map(\.storage)
                state.allocatedCount -= state.available.count
                state.available.removeAll(keepingCapacity: true)
                return discarded
            }
            withExtendedLifetime(discarded) {}
            return
        }

        guard
            let maximumAge =
                configuration.maximumBufferAgeNanoseconds
        else {
            return
        }

        let currentTimestamp = timestamp()
        let discarded = state.withLock { state in
            var retained: [AvailableStorage] = []
            retained.reserveCapacity(state.available.count)
            // This metadata-only array prevents storage deinitializers from
            // executing while the pool mutex is held.
            var discarded: [Allocator.Storage] = []
            var removableCount = max(
                0,
                state.allocatedCount
                    - configuration.minimumBufferCount
            )

            for entry in state.available {
                let age: UInt64
                if currentTimestamp >= entry.recycledAt {
                    age = currentTimestamp - entry.recycledAt
                } else {
                    age = 0
                }

                if age >= maximumAge, removableCount > 0 {
                    state.allocatedCount -= 1
                    removableCount -= 1
                    discarded.append(entry.storage)
                } else {
                    retained.append(entry)
                }
            }
            state.available = retained
            return discarded
        }
        withExtendedLifetime(discarded) {}
    }
}
