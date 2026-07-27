public final class CVPackedPixelBuffer: CVPixelBuffer {
    public typealias AttachmentStorage = CVBufferAttachments

    public let layout: CVPackedPixelBufferLayout
    public let attachments: CVBufferAttachments

    private let storage: CVPixelBufferStorageOperations

    public var dimensions: CVPixelDimensions {
        layout.dimensions
    }

    public var pixelFormat: CVPixelFormatType {
        layout.pixelFormat
    }

    public var bytesPerRow: Int {
        layout.bytesPerRow
    }

    public var byteCount: Int {
        layout.byteCount
    }

    public var accessCapabilities: CVPixelBufferAccessCapabilities {
        storage.accessCapabilities
    }

    public convenience init<Storage: CVPixelBufferStorage>(
        layout: CVPackedPixelBufferLayout,
        storage: Storage,
        attachments: CVBufferAttachments
    ) throws(CVPixelBufferError) {
        let storageOperations = CVPixelBufferStorageOperations(storage)
        try self.init(
            layout: layout,
            storage: storageOperations,
            attachments: attachments
        )
    }

    public convenience init<Storage: CVPixelBufferStorage>(
        layout: CVPackedPixelBufferLayout,
        storage: Storage
    ) throws(CVPixelBufferError) {
        try self.init(
            layout: layout,
            storage: storage,
            attachments: CVBufferAttachments()
        )
    }

    private init(
        layout: CVPackedPixelBufferLayout,
        storage: CVPixelBufferStorageOperations,
        attachments: CVBufferAttachments
    ) throws(CVPixelBufferError) {
        guard storage.byteCount >= layout.byteCount else {
            throw .storageTooSmall(
                required: layout.byteCount,
                actual: storage.byteCount
            )
        }

        self.layout = layout
        self.storage = storage
        self.attachments = attachments
    }

    public convenience init(
        dimensions: CVPixelDimensions,
        pixelFormat: CVPixelFormatType,
        bytesPerPixel: Int,
        bytesPerRow: Int,
        alignment: Int = 64
    ) throws(CVPixelBufferError) {
        let layout = try CVPackedPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: pixelFormat,
            bytesPerPixel: bytesPerPixel,
            bytesPerRow: bytesPerRow
        )
        let storage = try CVPixelBufferStorageOperations(
            ownedByteCount: layout.byteCount,
            alignment: alignment
        )
        try self.init(
            layout: layout,
            storage: storage,
            attachments: CVBufferAttachments()
        )
    }

    public convenience init(
        dimensions: CVPixelDimensions,
        pixelFormat: CVPixelFormatType,
        blockLayout: CVPixelBufferBlockLayout,
        bytesPerRow: Int,
        alignment: Int = 64
    ) throws(CVPixelBufferError) {
        let layout = try CVPackedPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: pixelFormat,
            blockLayout: blockLayout,
            bytesPerRow: bytesPerRow
        )
        let storage = try CVPixelBufferStorageOperations(
            ownedByteCount: layout.byteCount,
            alignment: alignment
        )
        try self.init(
            layout: layout,
            storage: storage,
            attachments: CVBufferAttachments()
        )
    }

    public func withReadBytes(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withReadAccess(body)
    }

    public func withWriteBytes(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withWriteAccess(body)
    }
}
