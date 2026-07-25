public final class CVPooledPixelBufferStorage<
    Allocator: CVPixelBufferPoolAllocator
>: CVPixelBufferStorage {
    public var byteCount: Int {
        storage.byteCount
    }

    public var accessCapabilities: CVPixelBufferAccessCapabilities {
        storage.accessCapabilities
    }

    private let storage: Allocator.Storage
    private let pool: CVPixelBufferPoolCore<Allocator>

    internal init(
        storage: Allocator.Storage,
        pool: CVPixelBufferPoolCore<Allocator>
    ) {
        self.storage = storage
        self.pool = pool
    }

    deinit {
        pool.recycle(storage)
    }

    public func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withReadAccess(body)
    }

    public func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withWriteAccess(body)
    }
}
