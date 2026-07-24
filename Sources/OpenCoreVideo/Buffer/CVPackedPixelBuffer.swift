public final class CVPackedPixelBuffer<
    Storage: CVPixelBufferStorage,
    Attachments: CVBufferAttachmentStorage
>: CVPixelBuffer {
    public typealias AttachmentStorage = Attachments

    public let layout: CVPackedPixelBufferLayout
    public let attachments: Attachments

    private let storage: Storage

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

    public init(
        layout: CVPackedPixelBufferLayout,
        storage: Storage,
        attachments: Attachments
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

extension CVPackedPixelBuffer
where Attachments == CVBufferAttachments {
    public convenience init(
        layout: CVPackedPixelBufferLayout,
        storage: Storage
    ) throws(CVPixelBufferError) {
        try self.init(
            layout: layout,
            storage: storage,
            attachments: CVBufferAttachments()
        )
    }
}

extension CVPackedPixelBuffer
where
    Storage ==
        CVOwnedPixelBufferStorage<
            CVNoOpPixelBufferAccessCoordinator
        >,
    Attachments == CVBufferAttachments
{
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
        let storage = try CVOwnedPixelBufferStorage(
            byteCount: layout.byteCount,
            alignment: alignment
        )
        try self.init(
            layout: layout,
            storage: storage,
            attachments: CVBufferAttachments()
        )
    }
}
