public struct CVPixelBufferBlockLayout: Sendable, Hashable {
    public let blockSize: CVImageSize
    public let bytesPerBlock: Int
    public let blockAlignment: CVPixelFormatDescription.Dimensions

    public var byteAlignedBytesPerPixel: Int? {
        guard blockSize == CVImageSize(width: 1, height: 1) else {
            return nil
        }
        return bytesPerBlock
    }

    public init(
        blockSize: CVImageSize,
        bytesPerBlock: Int,
        blockAlignment: CVPixelFormatDescription.Dimensions = .init(
            horizontal: 1,
            vertical: 1
        )
    ) throws(CVPixelBufferError) {
        guard blockSize.width > 0, blockSize.height > 0 else {
            throw .invalidBlockSize(blockSize)
        }
        guard bytesPerBlock > 0 else {
            throw .invalidBytesPerBlock(bytesPerBlock)
        }
        guard blockAlignment.horizontal > 0,
              blockAlignment.vertical > 0 else {
            throw .invalidBlockAlignment(blockAlignment)
        }

        self.blockSize = blockSize
        self.bytesPerBlock = bytesPerBlock
        self.blockAlignment = blockAlignment
    }

    public func minimumBytesPerRow(
        for dimensions: CVPixelDimensions
    ) throws(CVPixelBufferError) -> Int {
        let horizontalBlocks = try roundedUpQuotient(
            dimensions.width,
            blockSize.width
        )
        let alignedBlocks = try roundedUpMultiple(
            horizontalBlocks,
            blockAlignment.horizontal
        )
        let byteCount = alignedBlocks.multipliedReportingOverflow(
            by: bytesPerBlock
        )
        guard !byteCount.overflow else {
            throw .layoutOverflow
        }
        return byteCount.partialValue
    }

    public func storageRowCount(
        for dimensions: CVPixelDimensions
    ) throws(CVPixelBufferError) -> Int {
        let verticalBlocks = try roundedUpQuotient(
            dimensions.height,
            blockSize.height
        )
        return try roundedUpMultiple(
            verticalBlocks,
            blockAlignment.vertical
        )
    }

    private func roundedUpQuotient(
        _ value: Int,
        _ divisor: Int
    ) throws(CVPixelBufferError) -> Int {
        let adjusted = value.addingReportingOverflow(divisor - 1)
        guard !adjusted.overflow else {
            throw .layoutOverflow
        }
        return adjusted.partialValue / divisor
    }

    private func roundedUpMultiple(
        _ value: Int,
        _ multiple: Int
    ) throws(CVPixelBufferError) -> Int {
        let quotient = try roundedUpQuotient(value, multiple)
        let result = quotient.multipliedReportingOverflow(by: multiple)
        guard !result.overflow else {
            throw .layoutOverflow
        }
        return result.partialValue
    }
}
