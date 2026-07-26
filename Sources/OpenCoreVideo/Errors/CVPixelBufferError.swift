public enum CVPixelBufferError: Error, Sendable, Equatable {
    case invalidDimensions(width: Int, height: Int)
    case invalidPixelFormat(UInt32)
    case invalidBytesPerPixel(Int)
    case pixelFormatBytesPerPixelMismatch(
        format: CVPixelFormatType,
        expected: Int,
        actual: Int
    )
    case pixelFormatRequiresPackedLayout(CVPixelFormatType)
    case pixelFormatRequiresPlanarLayout(CVPixelFormatType)
    case pixelFormatPlaneLayoutMismatch(
        format: CVPixelFormatType,
        plane: Int
    )
    case invalidBytesPerRow(minimum: Int, actual: Int)
    case invalidStorageSize(Int)
    case invalidAlignment(Int)
    case layoutOverflow
    case storageTooSmall(required: Int, actual: Int)
    case invalidPlaneCount(Int)
    case planeCountMismatch(expected: Int, actual: Int)
    case invalidPlaneIndex(index: Int, planeCount: Int)
    case planeDimensionsExceedImage(
        plane: CVPixelDimensions,
        image: CVPixelDimensions
    )
    case planeStorageTooSmall(
        plane: Int,
        required: Int,
        actual: Int
    )
    case planeAddressRangeOverflow(plane: Int)
    case overlappingPlaneStorage(first: Int, second: Int)
    case planarBufferRequiresPlaneAccess
    case malformedImageBufferAttachment(CVAttachmentKey)
    case invalidCleanAperture
    case invalidPixelAspectRatio(
        horizontalSpacing: Double,
        verticalSpacing: Double
    )
    case invalidDisplaySize(width: Double, height: Double)
    case invalidMinimumBufferCount(Int)
    case invalidAllocationThreshold(Int)
    case wouldExceedAllocationThreshold(Int)
    case poolShutdown
    case unsupportedAccess(CVPixelBufferAccessMode)
    case accessConflict(CVPixelBufferAccessMode)
    case platformAccessFailure(code: Int32)
    case storageReleased
}
