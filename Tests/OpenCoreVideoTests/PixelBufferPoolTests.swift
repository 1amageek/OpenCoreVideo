import OpenCoreVideo
import Synchronization
import Testing

@Suite("Pixel buffer pool")
struct PixelBufferPoolTests {
    @Test("Available storage is reused before allocating")
    func storageReuse() throws {
        let probe = PoolAllocatorProbe()
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: probe)
        )

        var firstAddress: UInt?
        do {
            let buffer = try pool.makePixelBuffer(
                allocationThreshold: 1
            )
            try buffer.withWriteBytes { bytes in
                bytes[0] = 41
                firstAddress =
                    bytes.withUnsafeMutableBufferPointer { pointer in
                        pointer.baseAddress.map { UInt(bitPattern: $0) }
                    }
            }
        }

        let second = try pool.makePixelBuffer(allocationThreshold: 1)
        var secondAddress: UInt?
        var retainedValue: UInt8 = 0
        try second.withReadBytes { bytes in
            retainedValue = bytes[0]
            secondAddress = bytes.withUnsafeBufferPointer { pointer in
                pointer.baseAddress.map { UInt(bitPattern: $0) }
            }
        }

        #expect(probe.allocationCount == 1)
        #expect(secondAddress == firstAddress)
        #expect(retainedValue == 41)
    }

    @Test("Allocation threshold fails only when a new allocation is required")
    func allocationThreshold() throws {
        let probe = PoolAllocatorProbe()
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: probe)
        )

        var first: CVPackedPixelBuffer? = try pool.makePixelBuffer(
            allocationThreshold: 1
        )
        #expect(first != nil)

        #expect(throws: CVPixelBufferError
            .wouldExceedAllocationThreshold(1)) {
            _ = try pool.makePixelBuffer(allocationThreshold: 1)
        }

        first = nil
        _ = try pool.makePixelBuffer(allocationThreshold: 1)
        #expect(probe.allocationCount == 1)
    }

    @Test("A failed allocator reservation is rolled back")
    func allocationFailureRollback() throws {
        let probe = PoolAllocatorProbe()
        probe.failNextAllocation()
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: probe)
        )

        #expect(throws: CVPixelBufferError
            .platformAccessFailure(code: 91)) {
            _ = try pool.makePixelBuffer(allocationThreshold: 1)
        }

        _ = try pool.makePixelBuffer(allocationThreshold: 1)
        #expect(probe.allocationAttemptCount == 2)
        #expect(probe.allocationCount == 1)
    }

    @Test("Undersized allocator storage is rejected")
    func undersizedStorage() throws {
        let probe = PoolAllocatorProbe()
        let invalidPool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(
                probe: probe,
                byteCountAdjustment: -4
            )
        )
        #expect(throws: CVPixelBufferError.storageTooSmall(
            required: 8,
            actual: 4
        )) {
            _ = try invalidPool.makePixelBuffer(
                allocationThreshold: 1
            )
        }

        let validPool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: probe)
        )
        _ = try validPool.makePixelBuffer(allocationThreshold: 1)
    }

    @Test("Age flush honors minimum count and excess flush overrides it")
    func flushBehavior() throws {
        let probe = PoolAllocatorProbe()
        let time = Mutex<UInt64>(0)
        let configuration = try CVPixelBufferPoolConfiguration(
            minimumBufferCount: 1,
            maximumBufferAgeNanoseconds: 10
        )
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            configuration: configuration,
            allocator: PoolAllocator(probe: probe)
        ) {
            time.withLock { $0 }
        }

        do {
            _ = try pool.makePixelBuffer()
        }
        time.withLock { $0 = 10 }
        pool.flush()
        do {
            _ = try pool.makePixelBuffer()
        }
        #expect(probe.allocationCount == 1)

        pool.flush(.excessBuffers)
        _ = try pool.makePixelBuffer()
        #expect(probe.allocationCount == 2)
    }

    @Test("Pool configuration and request validation are typed")
    func validation() throws {
        #expect(throws: CVPixelBufferError
            .invalidMinimumBufferCount(-1)) {
            _ = try CVPixelBufferPoolConfiguration(
                minimumBufferCount: -1
            )
        }

        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: PoolAllocatorProbe())
        )
        #expect(throws: CVPixelBufferError
            .invalidAllocationThreshold(0)) {
            _ = try pool.makePixelBuffer(allocationThreshold: 0)
        }
    }

    @Test("Owned allocator creates one access coordinator per storage")
    func coordinatorFactory() throws {
        let coordinatorCount = Mutex(0)
        let allocator = try CVOwnedPixelBufferPoolAllocator(
            alignment: 8
        ) {
            coordinatorCount.withLock { $0 += 1 }
            return CVNoOpPixelBufferAccessCoordinator()
        }

        _ = try allocator.storage(byteCount: 8)
        _ = try allocator.storage(byteCount: 8)
        #expect(coordinatorCount.withLock { $0 } == 2)
    }

    @Test("Excess flush releases cached storage")
    func flushReleasesStorage() throws {
        let releaseCount = PoolReleaseCounter()
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: ReleasingPoolAllocator(
                releaseCount: releaseCount
            )
        )

        do {
            _ = try pool.makePixelBuffer()
        }
        #expect(releaseCount.value == 0)
        pool.flush(.excessBuffers)
        #expect(releaseCount.value == 1)
    }

    @Test("Threshold use enables broadcast availability notifications")
    func availabilityNotifications() async throws {
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: PoolAllocatorProbe())
        )
        let firstStream = pool.availabilityNotifications()
        let secondStream = pool.availabilityNotifications()
        let firstEvent = Task {
            var iterator = firstStream.makeAsyncIterator()
            return await iterator.next()
        }
        let secondEvent = Task {
            var iterator = secondStream.makeAsyncIterator()
            return await iterator.next()
        }

        var checkedOut = try Optional(
            pool.makePixelBuffer(allocationThreshold: 1)
        )
        #expect(checkedOut != nil)
        #expect(
            throws: CVPixelBufferError
                .wouldExceedAllocationThreshold(1)
        ) {
            _ = try pool.makePixelBuffer(allocationThreshold: 1)
        }
        checkedOut = nil

        #expect(await firstEvent.value == .bufferAvailable)
        #expect(await secondEvent.value == .bufferAvailable)
        pool.shutdown()
    }

    @Test("Shutdown finishes notifications and rejects new checkout")
    func shutdown() async throws {
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: PoolAllocatorProbe())
        )
        let stream = pool.availabilityNotifications()
        let event = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        do {
            _ = try pool.makePixelBuffer()
        }
        pool.shutdown()

        #expect(await event.value == nil)
        #expect(throws: CVPixelBufferError.poolShutdown) {
            _ = try pool.makePixelBuffer()
        }
        pool.shutdown()
    }

    @Test("Cancelled availability subscription terminates cleanly")
    func cancelledAvailabilitySubscription() async throws {
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: PoolAllocatorProbe())
        )
        let stream = pool.availabilityNotifications()
        let event = Task {
            var iterator = stream.makeAsyncIterator()
            return await iterator.next()
        }

        event.cancel()
        #expect(await event.value == nil)

        do {
            _ = try pool.makePixelBuffer(allocationThreshold: 1)
        }
        pool.shutdown()
    }

    @Test("Outstanding storage release after shutdown skips timestamp callback")
    func releaseAfterShutdown() throws {
        let timestampCount = Mutex(0)
        let pool = CVPixelBufferPool(
            layout: try makeLayout(),
            allocator: PoolAllocator(probe: PoolAllocatorProbe())
        ) {
            timestampCount.withLock { count in
                count += 1
                return UInt64(count)
            }
        }
        var checkedOut = try Optional(pool.makePixelBuffer())
        #expect(checkedOut != nil)

        pool.shutdown()
        checkedOut = nil

        #expect(timestampCount.withLock { $0 } == 0)
    }

    private func makeLayout() throws -> CVPackedPixelBufferLayout {
        try CVPackedPixelBufferLayout(
            dimensions: CVPixelDimensions(width: 2, height: 1),
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 8
        )
    }
}

private final class PoolAllocatorProbe: Sendable {
    private struct State: Sendable {
        var allocationAttemptCount = 0
        var allocationCount = 0
        var shouldFailNextAllocation = false
    }

    private let state = Mutex(State())

    var allocationAttemptCount: Int {
        state.withLock { $0.allocationAttemptCount }
    }

    var allocationCount: Int {
        state.withLock { $0.allocationCount }
    }

    func failNextAllocation() {
        state.withLock { $0.shouldFailNextAllocation = true }
    }

    func recordAllocation() throws(CVPixelBufferError) {
        let shouldFail = state.withLock { state in
            state.allocationAttemptCount += 1
            if state.shouldFailNextAllocation {
                state.shouldFailNextAllocation = false
                return true
            }
            state.allocationCount += 1
            return false
        }
        if shouldFail {
            throw .platformAccessFailure(code: 91)
        }
    }
}

private struct PoolAllocator: CVPixelBufferPoolAllocator {
    let probe: PoolAllocatorProbe
    let byteCountAdjustment: Int

    init(
        probe: PoolAllocatorProbe,
        byteCountAdjustment: Int = 0
    ) {
        self.probe = probe
        self.byteCountAdjustment = byteCountAdjustment
    }

    func storage(
        byteCount: Int
    ) throws(CVPixelBufferError) -> CVOwnedPixelBufferStorage {
        try probe.recordAllocation()
        return try CVOwnedPixelBufferStorage(
            byteCount: byteCount + byteCountAdjustment
        )
    }
}

private struct ReleasingPoolAllocator: CVPixelBufferPoolAllocator {
    let releaseCount: PoolReleaseCounter

    func storage(
        byteCount: Int
    ) throws(CVPixelBufferError) -> ReleasingPoolStorage {
        try ReleasingPoolStorage(
            byteCount: byteCount,
            releaseCount: releaseCount
        )
    }
}

private final class ReleasingPoolStorage: CVPixelBufferStorage {
    var byteCount: Int {
        storage.byteCount
    }

    var accessCapabilities: CVPixelBufferAccessCapabilities {
        storage.accessCapabilities
    }

    private let storage: CVOwnedPixelBufferStorage
    private let releaseCount: PoolReleaseCounter

    init(
        byteCount: Int,
        releaseCount: PoolReleaseCounter
    ) throws(CVPixelBufferError) {
        self.storage = try CVOwnedPixelBufferStorage(
            byteCount: byteCount
        )
        self.releaseCount = releaseCount
    }

    deinit {
        releaseCount.increment()
    }

    func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withReadAccess(body)
    }

    func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withWriteAccess(body)
    }
}

private final class PoolReleaseCounter: Sendable {
    private let count = Mutex(0)

    var value: Int {
        count.withLock { $0 }
    }

    func increment() {
        count.withLock { $0 += 1 }
    }
}
