public struct CVOwnedPixelBufferPoolAllocator<
    Coordinator: CVPixelBufferAccessCoordinator
>: CVPixelBufferPoolAllocator {
    public let alignment: Int
    private let accessCoordinator:
        @Sendable () -> Coordinator

    public init(
        alignment: Int = 64,
        accessCoordinator:
            @escaping @Sendable () -> Coordinator
    ) throws(CVPixelBufferError) {
        guard alignment > 0, alignment.nonzeroBitCount == 1 else {
            throw .invalidAlignment(alignment)
        }
        self.alignment = alignment
        self.accessCoordinator = accessCoordinator
    }

    public func storage(
        byteCount: Int
    ) throws(CVPixelBufferError) -> CVOwnedPixelBufferStorage {
        try CVOwnedPixelBufferStorage(
            byteCount: byteCount,
            alignment: alignment,
            accessCoordinator: accessCoordinator()
        )
    }
}

extension CVOwnedPixelBufferPoolAllocator
where Coordinator == CVNoOpPixelBufferAccessCoordinator {
    public init(
        alignment: Int = 64
    ) throws(CVPixelBufferError) {
        try self.init(
            alignment: alignment,
            accessCoordinator: {
                CVNoOpPixelBufferAccessCoordinator()
            }
        )
    }
}
