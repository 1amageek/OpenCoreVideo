public struct CVPixelBufferPlaneLayout: Sendable, Hashable {
    public let dimensions: CVPixelDimensions
    public let blockLayout: CVPixelBufferBlockLayout
    public let bytesPerRow: Int
    public let byteCount: Int

    public var bytesPerElement: Int? {
        blockLayout.byteAlignedBytesPerPixel
    }

    public init(
        dimensions: CVPixelDimensions,
        bytesPerElement: Int,
        bytesPerRow: Int
    ) throws(CVPixelBufferError) {
        guard bytesPerElement > 0 else {
            throw .invalidBytesPerPixel(bytesPerElement)
        }

        let blockLayout = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 1, height: 1),
            bytesPerBlock: bytesPerElement
        )
        try self.init(
            dimensions: dimensions,
            blockLayout: blockLayout,
            bytesPerRow: bytesPerRow
        )
    }

    public init(
        dimensions: CVPixelDimensions,
        blockLayout: CVPixelBufferBlockLayout,
        bytesPerRow: Int
    ) throws(CVPixelBufferError) {
        let minimumRow = try blockLayout.minimumBytesPerRow(
            for: dimensions
        )

        guard bytesPerRow >= minimumRow else {
            throw .invalidBytesPerRow(
                minimum: minimumRow,
                actual: bytesPerRow
            )
        }

        let storageRowCount = try blockLayout.storageRowCount(
            for: dimensions
        )
        let byteCount = bytesPerRow.multipliedReportingOverflow(
            by: storageRowCount
        )
        guard !byteCount.overflow else {
            throw .layoutOverflow
        }

        self.dimensions = dimensions
        self.blockLayout = blockLayout
        self.bytesPerRow = bytesPerRow
        self.byteCount = byteCount.partialValue
    }
}
