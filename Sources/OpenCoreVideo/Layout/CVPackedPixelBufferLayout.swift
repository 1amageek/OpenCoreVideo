public struct CVPackedPixelBufferLayout: Sendable, Hashable {
    public let dimensions: CVPixelDimensions
    public let pixelFormat: CVPixelFormatType
    public let bytesPerPixel: Int
    public let bytesPerRow: Int
    public let byteCount: Int

    public init(
        dimensions: CVPixelDimensions,
        pixelFormat: CVPixelFormatType,
        bytesPerPixel: Int,
        bytesPerRow: Int
    ) throws(CVPixelBufferError) {
        guard pixelFormat.rawValue != 0 else {
            throw .invalidPixelFormat(pixelFormat.rawValue)
        }
        guard bytesPerPixel > 0 else {
            throw .invalidBytesPerPixel(bytesPerPixel)
        }
        if let description = CVPixelFormatDescription.standardDescription(
            for: pixelFormat
        ) {
            guard case .nonPlanar(let pixelLayout) =
                    description.planeConfiguration else {
                throw .pixelFormatRequiresPlanarLayout(pixelFormat)
            }
            let bitsPerByte = 8
            guard pixelLayout.blockSize == CVImageSize(width: 1, height: 1),
                  pixelLayout.bitsPerBlock.isMultiple(of: bitsPerByte) else {
                throw .pixelFormatPlaneLayoutMismatch(
                    format: pixelFormat,
                    plane: 0
                )
            }
            let expectedBytesPerPixel =
                pixelLayout.bitsPerBlock / bitsPerByte
            guard bytesPerPixel == expectedBytesPerPixel else {
                throw .pixelFormatBytesPerPixelMismatch(
                    format: pixelFormat,
                    expected: expectedBytesPerPixel,
                    actual: bytesPerPixel
                )
            }
        }

        let minimumRowResult = dimensions.width.multipliedReportingOverflow(
            by: bytesPerPixel
        )
        guard !minimumRowResult.overflow else {
            throw .layoutOverflow
        }
        guard bytesPerRow >= minimumRowResult.partialValue else {
            throw .invalidBytesPerRow(
                minimum: minimumRowResult.partialValue,
                actual: bytesPerRow
            )
        }

        let byteCountResult = bytesPerRow.multipliedReportingOverflow(
            by: dimensions.height
        )
        guard !byteCountResult.overflow else {
            throw .layoutOverflow
        }

        self.dimensions = dimensions
        self.pixelFormat = pixelFormat
        self.bytesPerPixel = bytesPerPixel
        self.bytesPerRow = bytesPerRow
        self.byteCount = byteCountResult.partialValue
    }
}
