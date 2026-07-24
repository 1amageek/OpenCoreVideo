public final class CVExternalPixelBufferStorage<
    Coordinator: CVPixelBufferAccessCoordinator
>:
    CVPixelBufferStorage
{
    public let byteCount: Int
    public let accessCapabilities: CVPixelBufferAccessCapabilities

    private let lease: CVPixelBufferMemoryLease<Coordinator>

    /// Creates a lease over caller-provided memory without copying its bytes.
    ///
    /// Ownership transfers only after this initializer succeeds. The release
    /// handler is invoked exactly once when the final storage lease is released.
    public init(
        baseAddress: UnsafeMutableRawPointer,
        byteCount: Int,
        accessCapabilities: CVPixelBufferAccessCapabilities,
        accessCoordinator: Coordinator,
        releaseHandler:
            @escaping @Sendable (UnsafeMutableRawPointer, Int) -> Void
    ) throws(CVPixelBufferError) {
        guard byteCount > 0 else {
            throw .invalidStorageSize(byteCount)
        }
        guard !accessCapabilities.isEmpty else {
            throw .unsupportedAccess(.read)
        }

        self.byteCount = byteCount
        self.accessCapabilities = accessCapabilities
        self.lease = CVPixelBufferMemoryLease(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: accessCapabilities,
            coordinator: accessCoordinator,
            releaseHandler: releaseHandler
        )
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

extension CVExternalPixelBufferStorage
where Coordinator == CVNoOpPixelBufferAccessCoordinator {
    public convenience init(
        baseAddress: UnsafeMutableRawPointer,
        byteCount: Int,
        accessCapabilities: CVPixelBufferAccessCapabilities,
        releaseHandler:
            @escaping @Sendable (UnsafeMutableRawPointer, Int) -> Void
    ) throws(CVPixelBufferError) {
        try self.init(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: accessCapabilities,
            accessCoordinator: CVNoOpPixelBufferAccessCoordinator(),
            releaseHandler: releaseHandler
        )
    }
}
