public final class CVLeasedPlanarPixelBuffer<
    StorageLease: CVPlanarStorageLease,
    Attachments: CVBufferAttachmentStorage
>: CVPixelBuffer {
    public typealias AttachmentStorage = Attachments

    private struct AccessState: Sendable {
        var readerCount = 0
        var isWriting = false
    }

    public let layout: CVPlanarPixelBufferLayout
    public let attachments: Attachments

    private let storageLease: StorageLease
    private let accessState = CVStateLock(AccessState())

    public var dimensions: CVPixelDimensions {
        layout.dimensions
    }

    public var pixelFormat: CVPixelFormatType {
        layout.pixelFormat
    }

    public var bytesPerRow: Int {
        layout.coveringBytesPerRow
    }

    public var byteCount: Int {
        layout.byteCount
    }

    public var accessCapabilities: CVPixelBufferAccessCapabilities {
        storageLease.accessCapabilities
    }

    public var isPlanar: Bool {
        true
    }

    public var planeCount: Int {
        layout.planes.count
    }

    public init(
        layout: CVPlanarPixelBufferLayout,
        storageLease: StorageLease,
        attachments: Attachments
    ) throws(CVPixelBufferError) {
        guard storageLease.planeCount == layout.planes.count else {
            throw .planeCountMismatch(
                expected: layout.planes.count,
                actual: storageLease.planeCount
            )
        }

        for index in layout.planes.indices {
            let required = layout.planes[index].byteCount
            let actual = try storageLease.byteCount(ofPlane: index)
            guard actual >= required else {
                throw .planeStorageTooSmall(
                    plane: index,
                    required: required,
                    actual: actual
                )
            }
        }

        self.layout = layout
        self.storageLease = storageLease
        self.attachments = attachments
    }

    public func dimensionsOfPlane(
        at index: Int
    ) throws(CVPixelBufferError) -> CVPixelDimensions {
        try validatedPlane(at: index).dimensions
    }

    public func bytesPerRowOfPlane(
        at index: Int
    ) throws(CVPixelBufferError) -> Int {
        try validatedPlane(at: index).bytesPerRow
    }

    public func withReadBytes(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        throw .planarBufferRequiresPlaneAccess
    }

    public func withWriteBytes(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        throw .planarBufferRequiresPlaneAccess
    }

    public func withReadBytes(
        ofPlane index: Int,
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        _ = try validatedPlane(at: index)
        try acquire(.read)
        defer {
            finish(.read)
        }
        try storageLease.withReadBytes(ofPlane: index, body)
    }

    public func withWriteBytes(
        ofPlane index: Int,
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        _ = try validatedPlane(at: index)
        try acquire(.write)
        defer {
            finish(.write)
        }
        try storageLease.withWriteBytes(ofPlane: index, body)
    }

    private func validatedPlane(
        at index: Int
    ) throws(CVPixelBufferError) -> CVPixelBufferPlaneLayout {
        guard layout.planes.indices.contains(index) else {
            throw .invalidPlaneIndex(
                index: index,
                planeCount: layout.planes.count
            )
        }
        return layout.planes[index]
    }

    private func acquire(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) {
        let requiredCapability: CVPixelBufferAccessCapabilities
        switch mode {
        case .read:
            requiredCapability = .read
        case .write:
            requiredCapability = .write
        }
        guard storageLease.accessCapabilities.contains(requiredCapability)
        else {
            throw .unsupportedAccess(mode)
        }

        try accessState.withLock { state throws(CVPixelBufferError) in
            switch mode {
            case .read:
                guard !state.isWriting else {
                    throw .accessConflict(.read)
                }
                state.readerCount += 1

            case .write:
                guard !state.isWriting, state.readerCount == 0 else {
                    throw .accessConflict(.write)
                }
                state.isWriting = true
            }
        }
    }

    private func finish(_ mode: CVPixelBufferAccessMode) {
        accessState.withLock { state in
            switch mode {
            case .read:
                precondition(state.readerCount > 0)
                state.readerCount -= 1
            case .write:
                precondition(state.isWriting)
                state.isWriting = false
            }
        }
    }
}

extension CVLeasedPlanarPixelBuffer
where Attachments == CVBufferAttachments {
    public convenience init(
        layout: CVPlanarPixelBufferLayout,
        storageLease: StorageLease
    ) throws(CVPixelBufferError) {
        try self.init(
            layout: layout,
            storageLease: storageLease,
            attachments: CVBufferAttachments()
        )
    }
}
