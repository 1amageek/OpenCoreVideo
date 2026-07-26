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
        var isShutdown = false
    }

    private let allocator: Allocator
    private let configuration: CVPixelBufferPoolConfiguration
    private let timestamp: @Sendable () -> UInt64
    private let state = CVStateLock(State())
    private let availabilitySource =
        CVPixelBufferPoolAvailabilitySource()

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
        if allocationThreshold != nil {
            availabilitySource.enableNotifications()
        }

        let available = try state.withLock {
            state throws(CVPixelBufferError) -> Allocator.Storage? in
            guard !state.isShutdown else {
                throw .poolShutdown
            }
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
        let accepted = state.withLock { state in
            guard !state.isShutdown else {
                precondition(state.allocatedCount > 0)
                state.allocatedCount -= 1
                return false
            }
            return true
        }
        committedReservation = true
        guard accepted else {
            throw .poolShutdown
        }
        return storage
    }

    internal func recycle(_ storage: Allocator.Storage) {
        let needsTimestamp = state.withLock { state in
            guard !state.isShutdown else {
                precondition(state.allocatedCount > 0)
                state.allocatedCount -= 1
                return false
            }
            return true
        }
        guard needsTimestamp else {
            return
        }
        let recycledAt = timestamp()
        let shouldNotify = state.withLock { state in
            guard !state.isShutdown else {
                precondition(state.allocatedCount > 0)
                state.allocatedCount -= 1
                return false
            }
            state.available.append(
                AvailableStorage(
                    storage: storage,
                    recycledAt: recycledAt
                )
            )
            return true
        }
        if shouldNotify {
            availabilitySource.yieldBufferAvailable()
        }
    }

    internal func availabilityNotifications()
        -> AsyncStream<CVPixelBufferPoolAvailability>
    {
        availabilitySource.makeStream()
    }

    internal func shutdown() {
        let discarded: [Allocator.Storage] = state.withLock { state in
            guard !state.isShutdown else {
                return []
            }
            state.isShutdown = true
            var discarded: [Allocator.Storage] = []
            discarded.reserveCapacity(state.available.count)
            for entry in state.available {
                discarded.append(entry.storage)
            }
            state.allocatedCount -= state.available.count
            state.available.removeAll(keepingCapacity: false)
            return discarded
        }
        availabilitySource.shutdown()
        withExtendedLifetime(discarded) {}
    }

    internal func flush(_ flags: CVPixelBufferPoolFlushFlags) {
        if flags.contains(.excessBuffers) {
            let discarded: [Allocator.Storage] = state.withLock { state in
                // Retaining small storage references defers native release
                // callbacks until after the pool mutex is unlocked.
                var discarded: [Allocator.Storage] = []
                discarded.reserveCapacity(state.available.count)
                for entry in state.available {
                    discarded.append(entry.storage)
                }
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
        let discarded: [Allocator.Storage] = state.withLock { state in
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
