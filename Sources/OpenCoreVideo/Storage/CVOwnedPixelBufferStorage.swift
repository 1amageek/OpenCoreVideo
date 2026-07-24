public final class CVOwnedPixelBufferStorage<
    Coordinator: CVPixelBufferAccessCoordinator
>:
    CVPixelBufferStorage
{
    public let byteCount: Int
    public let accessCapabilities: CVPixelBufferAccessCapabilities

    private let lease: CVPixelBufferMemoryLease<Coordinator>

    public init(
        byteCount: Int,
        alignment: Int = 64,
        accessCoordinator: Coordinator
    ) throws(CVPixelBufferError) {
        guard byteCount > 0 else {
            throw .invalidStorageSize(byteCount)
        }
        guard alignment > 0, alignment.nonzeroBitCount == 1 else {
            throw .invalidAlignment(alignment)
        }

        let baseAddress = UnsafeMutableRawPointer.allocate(
            byteCount: byteCount,
            alignment: alignment
        )
        baseAddress.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: byteCount
        )

        self.byteCount = byteCount
        self.accessCapabilities = .readWrite
        self.lease = CVPixelBufferMemoryLease(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: .readWrite,
            coordinator: accessCoordinator
        ) { baseAddress, _ in
            baseAddress.deallocate()
        }
    }

    public func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try lease.withReadAccess(body)
    }

    public func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try lease.withWriteAccess(body)
    }
}

extension CVOwnedPixelBufferStorage
where Coordinator == CVNoOpPixelBufferAccessCoordinator {
    public convenience init(
        byteCount: Int,
        alignment: Int = 64
    ) throws(CVPixelBufferError) {
        try self.init(
            byteCount: byteCount,
            alignment: alignment,
            accessCoordinator: CVNoOpPixelBufferAccessCoordinator()
        )
    }
}
