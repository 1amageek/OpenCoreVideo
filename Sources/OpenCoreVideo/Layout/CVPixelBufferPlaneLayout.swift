public struct CVPixelBufferPlaneLayout: Sendable, Hashable {
    public let dimensions: CVPixelDimensions
    public let bytesPerElement: Int
    public let bytesPerRow: Int
    public let byteCount: Int

    public init(
        dimensions: CVPixelDimensions,
        bytesPerElement: Int,
        bytesPerRow: Int
    ) throws(CVPixelBufferError) {
        guard bytesPerElement > 0 else {
            throw .invalidBytesPerPixel(bytesPerElement)
        }

        let minimumRow = dimensions.width.multipliedReportingOverflow(
            by: bytesPerElement
        )
        guard !minimumRow.overflow else {
            throw .layoutOverflow
        }
        guard bytesPerRow >= minimumRow.partialValue else {
            throw .invalidBytesPerRow(
                minimum: minimumRow.partialValue,
                actual: bytesPerRow
            )
        }

        let byteCount = bytesPerRow.multipliedReportingOverflow(
            by: dimensions.height
        )
        guard !byteCount.overflow else {
            throw .layoutOverflow
        }

        self.dimensions = dimensions
        self.bytesPerElement = bytesPerElement
        self.bytesPerRow = bytesPerRow
        self.byteCount = byteCount.partialValue
    }
}
