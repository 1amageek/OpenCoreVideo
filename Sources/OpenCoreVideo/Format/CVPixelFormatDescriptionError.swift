public enum CVPixelFormatDescriptionError: Error, Sendable, Equatable {
    case invalidName
    case invalidPixelFormat(UInt32)
    case emptyComponents
    case invalidBlockSize(CVImageSize)
    case invalidBitsPerBlock(Int)
    case invalidBitsPerComponent(Int)
    case invalidBlockAlignment(
        CVPixelFormatDescription.Dimensions
    )
    case invalidSubsampling(
        CVPixelFormatDescription.Dimensions
    )
    case invalidPlaneCount(Int)
    case pixelFormatMismatch(
        description: CVPixelFormatType,
        registration: CVPixelFormatType
    )
}
