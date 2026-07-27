public final class CVExternalPixelBufferStorage:
    CVPixelBufferStorage
{
    public let byteCount: Int
    public let accessCapabilities: CVPixelBufferAccessCapabilities

    private let owner: CVPixelBufferMemoryOwner
    // Keep the class layout independent of Coordinator without boxing a protocol
    // existential in the pinned Swift 6.4 regular-WASI runtime.
    private let coordinator: CVPixelBufferAccessCoordinatorAdapter

    internal var operations: CVPixelBufferStorageOperations {
        CVPixelBufferStorageOperations(
            owner: owner,
            coordinator: coordinator
        )
    }

    /// Creates a lease over caller-provided memory without copying its bytes.
    ///
    /// Ownership transfers only after this initializer succeeds. The release
    /// handler is invoked exactly once when the final storage lease is released.
    public convenience init<Coordinator: CVPixelBufferAccessCoordinator>(
        baseAddress: UnsafeMutableRawPointer,
        byteCount: Int,
        accessCapabilities: CVPixelBufferAccessCapabilities,
        accessCoordinator: Coordinator,
        releaseHandler:
            @escaping @Sendable (UnsafeMutableRawPointer, Int) -> Void
    ) throws(CVPixelBufferError) {
        try self.init(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: accessCapabilities,
            coordinator: CVPixelBufferAccessCoordinatorAdapter(
                accessCoordinator
            ),
            releaseHandler: releaseHandler
        )
    }

    private init(
        baseAddress: UnsafeMutableRawPointer,
        byteCount: Int,
        accessCapabilities: CVPixelBufferAccessCapabilities,
        coordinator: CVPixelBufferAccessCoordinatorAdapter,
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
        self.owner = CVPixelBufferMemoryOwner(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: accessCapabilities,
            releaseOperation: .custom(releaseHandler)
        )
        self.coordinator = coordinator
    }

    public func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try owner.withReadAccess(coordinator: coordinator, body)
    }

    public func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try owner.withWriteAccess(coordinator: coordinator, body)
    }
}

extension CVExternalPixelBufferStorage {
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
            coordinator: CVPixelBufferAccessCoordinatorAdapter(),
            releaseHandler: releaseHandler
        )
    }
}
