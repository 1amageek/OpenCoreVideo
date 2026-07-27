public final class CVPlanarPixelBuffer<
    Storage: CVPixelBufferStorage,
    Attachments: CVBufferAttachmentStorage
>: CVPixelBuffer {
    public typealias AttachmentStorage = Attachments

    private struct AccessState: Sendable {
        var readerCount = 0
        var isWriting = false
    }

    public let layout: CVPlanarPixelBufferLayout
    public let attachments: Attachments

    private let planeStorages: [Storage]
    private let accessState = CVStateLock(AccessState())

    public var dimensions: CVPixelDimensions {
        layout.dimensions
    }

    public var pixelFormat: CVPixelFormatType {
        layout.pixelFormat
    }

    /// Matches Core Video's covering-row concept for a planar buffer.
    public var bytesPerRow: Int {
        layout.coveringBytesPerRow
    }

    public var byteCount: Int {
        layout.byteCount
    }

    public var accessCapabilities: CVPixelBufferAccessCapabilities {
        var capabilities = CVPixelBufferAccessCapabilities.readWrite
        for storage in planeStorages {
            capabilities.formIntersection(storage.accessCapabilities)
        }
        return capabilities
    }

    public var isPlanar: Bool {
        true
    }

    public var planeCount: Int {
        layout.planes.count
    }

    public init(
        layout: CVPlanarPixelBufferLayout,
        planeStorages: [Storage],
        attachments: Attachments
    ) throws(CVPixelBufferError) {
        guard planeStorages.count == layout.planes.count else {
            throw .planeCountMismatch(
                expected: layout.planes.count,
                actual: planeStorages.count
            )
        }

        for index in layout.planes.indices {
            let required = layout.planes[index].byteCount
            let actual = planeStorages[index].byteCount
            guard actual >= required else {
                throw .planeStorageTooSmall(
                    plane: index,
                    required: required,
                    actual: actual
                )
            }
        }

        self.layout = layout
        self.planeStorages = planeStorages
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
        let storage = try validatedStorage(at: index)
        try acquire(.read)
        defer {
            finish(.read)
        }
        try storage.withReadAccess(body)
    }

    public func withWriteBytes(
        ofPlane index: Int,
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        let storage = try validatedStorage(at: index)
        try acquire(.write)
        defer {
            finish(.write)
        }
        try storage.withWriteAccess(body)
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

    private func validatedStorage(
        at index: Int
    ) throws(CVPixelBufferError) -> Storage {
        guard planeStorages.indices.contains(index) else {
            throw .invalidPlaneIndex(
                index: index,
                planeCount: planeStorages.count
            )
        }
        return planeStorages[index]
    }

    private func acquire(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) {
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

extension CVPlanarPixelBuffer
where Attachments == CVBufferAttachments {
    public convenience init(
        layout: CVPlanarPixelBufferLayout,
        planeStorages: [Storage]
    ) throws(CVPixelBufferError) {
        try self.init(
            layout: layout,
            planeStorages: planeStorages,
            attachments: CVBufferAttachments()
        )
    }
}

extension CVPlanarPixelBuffer
where
    Storage == CVOwnedPixelBufferStorage,
    Attachments == CVBufferAttachments
{
    public convenience init(
        layout: CVPlanarPixelBufferLayout,
        alignment: Int = 64
    ) throws(CVPixelBufferError) {
        var storages: [Storage] = []
        storages.reserveCapacity(layout.planes.count)
        for plane in layout.planes {
            storages.append(
                try Storage(
                    byteCount: plane.byteCount,
                    alignment: alignment
                )
            )
        }
        try self.init(layout: layout, planeStorages: storages)
    }
}

extension CVPlanarPixelBuffer
where
    Storage == CVExternalPixelBufferStorage,
    Attachments == CVBufferAttachments
{
    /// Creates independent zero-copy plane leases over caller-provided memory.
    ///
    /// Ownership transfers only after validation succeeds. The release handler
    /// is called exactly once for every plane lease.
    public convenience init(
        layout: CVPlanarPixelBufferLayout,
        planeBaseAddresses: [UnsafeMutableRawPointer],
        accessCapabilities: CVPixelBufferAccessCapabilities,
        releasePlaneHandler:
            @escaping @Sendable (
                Int,
                UnsafeMutableRawPointer,
                Int
            ) -> Void
    ) throws(CVPixelBufferError) {
        guard !accessCapabilities.isEmpty else {
            throw .unsupportedAccess(.read)
        }
        try Self.validateExternalPlaneRanges(
            layout: layout,
            planeBaseAddresses: planeBaseAddresses
        )

        var storages: [Storage] = []
        storages.reserveCapacity(layout.planes.count)
        for index in layout.planes.indices {
            let byteCount = layout.planes[index].byteCount
            storages.append(
                try Storage(
                    baseAddress: planeBaseAddresses[index],
                    byteCount: byteCount,
                    accessCapabilities: accessCapabilities
                ) { baseAddress, releasedByteCount in
                    releasePlaneHandler(
                        index,
                        baseAddress,
                        releasedByteCount
                    )
                }
            )
        }

        try self.init(layout: layout, planeStorages: storages)
    }

    private static func validateExternalPlaneRanges(
        layout: CVPlanarPixelBufferLayout,
        planeBaseAddresses: [UnsafeMutableRawPointer]
    ) throws(CVPixelBufferError) {
        guard planeBaseAddresses.count == layout.planes.count else {
            throw .planeCountMismatch(
                expected: layout.planes.count,
                actual: planeBaseAddresses.count
            )
        }

        var ranges: [(start: UInt, end: UInt)] = []
        ranges.reserveCapacity(layout.planes.count)

        for index in layout.planes.indices {
            let start = UInt(bitPattern: planeBaseAddresses[index])
            let byteCount = UInt(layout.planes[index].byteCount)
            let end = start.addingReportingOverflow(byteCount)
            guard !end.overflow else {
                throw .planeAddressRangeOverflow(plane: index)
            }
            ranges.append((start: start, end: end.partialValue))
        }

        for first in ranges.indices {
            for second in ranges.indices where second > first {
                let overlaps =
                    ranges[first].start < ranges[second].end
                    && ranges[second].start < ranges[first].end
                guard !overlaps else {
                    throw .overlappingPlaneStorage(
                        first: first,
                        second: second
                    )
                }
            }
        }
    }
}
