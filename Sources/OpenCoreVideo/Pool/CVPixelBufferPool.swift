/// A recyclable pool of packed pixel-buffer storage.
///
/// Allocation thresholds apply only when a new storage allocation is required;
/// an available storage lease is always reused first, matching Core Video.
public final class CVPixelBufferPool<
    Allocator: CVPixelBufferPoolAllocator
>: CVPlatformConcurrencyContract {
    public let layout: CVPackedPixelBufferLayout
    public let configuration: CVPixelBufferPoolConfiguration

    private let core: CVPixelBufferPoolCore<Allocator>

    public init(
        layout: CVPackedPixelBufferLayout,
        configuration: CVPixelBufferPoolConfiguration =
            .default,
        allocator: Allocator,
        timestamp: @escaping @Sendable () -> UInt64 = { 0 }
    ) {
        self.layout = layout
        self.configuration = configuration
        self.core = CVPixelBufferPoolCore(
            allocator: allocator,
            configuration: configuration,
            timestamp: timestamp
        )
    }

    public func makePixelBuffer(
        allocationThreshold: Int? = nil
    ) throws(CVPixelBufferError) -> CVPackedPixelBuffer<
        CVPooledPixelBufferStorage<Allocator>,
        CVBufferAttachments
    > {
        let storage = try core.checkout(
            byteCount: layout.byteCount,
            allocationThreshold: allocationThreshold
        )
        let pooledStorage = CVPooledPixelBufferStorage(
            storage: storage,
            pool: core
        )
        return try CVPackedPixelBuffer(
            layout: layout,
            storage: pooledStorage
        )
    }

    public func flush(
        _ flags: CVPixelBufferPoolFlushFlags = []
    ) {
        core.flush(flags)
    }
}

extension CVPixelBufferPool
where
    Allocator ==
        CVOwnedPixelBufferPoolAllocator<
            CVNoOpPixelBufferAccessCoordinator
        >
{
    public convenience init(
        layout: CVPackedPixelBufferLayout,
        configuration: CVPixelBufferPoolConfiguration =
            .default,
        alignment: Int = 64,
        timestamp: @escaping @Sendable () -> UInt64 = { 0 }
    ) throws(CVPixelBufferError) {
        try self.init(
            layout: layout,
            configuration: configuration,
            allocator: CVOwnedPixelBufferPoolAllocator(
                alignment: alignment
            ),
            timestamp: timestamp
        )
    }
}
