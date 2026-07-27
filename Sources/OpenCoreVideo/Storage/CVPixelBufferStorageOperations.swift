internal struct CVPixelBufferStorageOperations: Sendable {
    private enum Backend: Sendable {
        case memory(
            owner: CVPixelBufferMemoryOwner,
            coordinator: CVPixelBufferAccessCoordinatorAdapter
        )
        case custom(
            read: @Sendable ((borrowing Span<UInt8>) -> Void)
                throws(CVPixelBufferError) -> Void,
            write: @Sendable ((inout MutableSpan<UInt8>) -> Void)
                throws(CVPixelBufferError) -> Void
        )
    }

    internal let byteCount: Int
    internal let accessCapabilities: CVPixelBufferAccessCapabilities

    private let backend: Backend

    internal init(
        ownedByteCount byteCount: Int,
        alignment: Int
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
        let owner = CVPixelBufferMemoryOwner(
            baseAddress: baseAddress,
            byteCount: byteCount,
            accessCapabilities: .readWrite,
            releaseOperation: .deallocate
        )
        let coordinator = CVPixelBufferAccessCoordinatorAdapter()

        self.byteCount = byteCount
        self.accessCapabilities = .readWrite
        self.backend = .memory(
            owner: owner,
            coordinator: coordinator
        )
    }

    internal init(
        owner: CVPixelBufferMemoryOwner,
        coordinator: CVPixelBufferAccessCoordinatorAdapter
    ) {
        byteCount = owner.byteCount
        accessCapabilities = owner.accessCapabilities
        backend = .memory(owner: owner, coordinator: coordinator)
    }

    internal init<Storage: CVPixelBufferStorage>(_ storage: Storage) {
        byteCount = storage.byteCount
        accessCapabilities = storage.accessCapabilities
        backend = .custom(
            read: {
                (body: (borrowing Span<UInt8>) -> Void)
                    throws(CVPixelBufferError) in
                try storage.withReadAccess(body)
            },
            write: {
                (body: (inout MutableSpan<UInt8>) -> Void)
                    throws(CVPixelBufferError) in
                try storage.withWriteAccess(body)
            }
        )
    }

    internal func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        switch backend {
        case .memory(let owner, let coordinator):
            try owner.withReadAccess(coordinator: coordinator, body)
        case .custom(let read, _):
            try read(body)
        }
    }

    internal func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        switch backend {
        case .memory(let owner, let coordinator):
            try owner.withWriteAccess(coordinator: coordinator, body)
        case .custom(_, let write):
            try write(body)
        }
    }
}
