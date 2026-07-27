public struct CVPackedPixelBufferLayout: Sendable, Hashable {
    public let dimensions: CVPixelDimensions
    public let pixelFormat: CVPixelFormatType
    public let blockLayout: CVPixelBufferBlockLayout
    public let bytesPerRow: Int
    public let byteCount: Int

    public var bytesPerPixel: Int? {
        blockLayout.byteAlignedBytesPerPixel
    }

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

        let blockLayout = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 1, height: 1),
            bytesPerBlock: bytesPerPixel
        )
        try self.init(
            dimensions: dimensions,
            pixelFormat: pixelFormat,
            blockLayout: blockLayout,
            bytesPerRow: bytesPerRow
        )
    }

    public init(
        dimensions: CVPixelDimensions,
        pixelFormat: CVPixelFormatType,
        blockLayout: CVPixelBufferBlockLayout,
        bytesPerRow: Int
    ) throws(CVPixelBufferError) {
        guard pixelFormat.rawValue != 0 else {
            throw .invalidPixelFormat(pixelFormat.rawValue)
        }

        if let description = CVPixelFormatDescription.standardDescription(
            for: pixelFormat
        ) {
            guard case .nonPlanar(let pixelLayout) =
                    description.planeConfiguration else {
                throw .pixelFormatRequiresPlanarLayout(pixelFormat)
            }
            guard pixelLayout.bitsPerBlock.isMultiple(of: 8),
                  blockLayout.blockSize == pixelLayout.blockSize,
                  blockLayout.bytesPerBlock == pixelLayout.bitsPerBlock / 8,
                  blockLayout.blockAlignment
                    == pixelLayout.blockAlignment else {
                throw .pixelFormatPlaneLayoutMismatch(
                    format: pixelFormat,
                    plane: 0
                )
            }
        }

        let minimumBytesPerRow = try blockLayout.minimumBytesPerRow(
            for: dimensions
        )
        guard bytesPerRow >= minimumBytesPerRow else {
            throw .invalidBytesPerRow(
                minimum: minimumBytesPerRow,
                actual: bytesPerRow
            )
        }

        let storageRowCount = try blockLayout.storageRowCount(
            for: dimensions
        )
        let byteCountResult = bytesPerRow.multipliedReportingOverflow(
            by: storageRowCount
        )
        guard !byteCountResult.overflow else {
            throw .layoutOverflow
        }

        self.dimensions = dimensions
        self.pixelFormat = pixelFormat
        self.blockLayout = blockLayout
        self.bytesPerRow = bytesPerRow
        self.byteCount = byteCountResult.partialValue
    }
}
