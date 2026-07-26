public protocol CVImageBuffer:
    CVBuffer
{
    var dimensions: CVPixelDimensions { get }
    var originPosition: CVImageBufferOriginPosition { get }
}

extension CVImageBuffer {
    public var originPosition: CVImageBufferOriginPosition {
        .topLeft
    }
}
