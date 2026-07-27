public final class CVOwnedPixelBufferStorage:
    CVPixelBufferStorage
{
    public let byteCount: Int
    public let accessCapabilities: CVPixelBufferAccessCapabilities

    private let owner: CVPixelBufferMemoryOwner
    // Fixed-layout operations avoid the pinned Swift 6.4 regular-WASI generic
    // stored-property and boxed-existential runtime defects.
    private let coordinator: CVPixelBufferAccessCoordinatorAdapter

    internal var operations: CVPixelBufferStorageOperations {
        CVPixelBufferStorageOperations(
            owner: owner,
            coordinator: coordinator
        )
    }

    public convenience init<Coordinator: CVPixelBufferAccessCoordinator>(
        byteCount: Int,
        alignment: Int = 64,
        accessCoordinator: Coordinator
    ) throws(CVPixelBufferError) {
        try self.init(
            byteCount: byteCount,
            alignment: alignment,
            coordinator: CVPixelBufferAccessCoordinatorAdapter(
                accessCoordinator
            )
        )
    }

    private init(
        byteCount: Int,
        alignment: Int,
        coordinator: CVPixelBufferAccessCoordinatorAdapter
    ) throws(CVPixelBufferError) {
        guard byteCount > 0 else {
            throw .invalidStorageSize(byteCount)
        }
        guard alignment > 0, alignment.nonzeroBitCount == 1 else {
            throw .invalidAlignment(alignment)
        }

        let baseAddress = allocateOwnedPixelBufferMemory(
            byteCount: byteCount,
            alignment: alignment
        )

        self.byteCount = byteCount
        self.accessCapabilities = .readWrite
        self.owner = CVPixelBufferMemoryOwner(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: .readWrite,
            releaseOperation: .deallocate
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

// The returned allocation is initialized for its complete byte range. Ownership
// transfers to CVPixelBufferMemoryOwner immediately after this function returns,
// and that owner performs exactly one matching deallocation after all borrows end.
// The non-generic boundary keeps raw allocation and initialization independent
// from the storage coordinator specialization.
@inline(never)
internal func allocateOwnedPixelBufferMemory(
    byteCount: Int,
    alignment: Int
) -> UnsafeMutableRawPointer {
    let baseAddress = UnsafeMutableRawPointer.allocate(
        byteCount: byteCount,
        alignment: alignment
    )
    baseAddress.initializeMemory(
        as: UInt8.self,
        repeating: 0,
        count: byteCount
    )
    return baseAddress
}

extension CVOwnedPixelBufferStorage {
    public convenience init(
        byteCount: Int,
        alignment: Int = 64
    ) throws(CVPixelBufferError) {
        try self.init(
            byteCount: byteCount,
            alignment: alignment,
            coordinator: CVPixelBufferAccessCoordinatorAdapter()
        )
    }
}
