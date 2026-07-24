public protocol CVPixelBuffer: CVImageBuffer {
    var pixelFormat: CVPixelFormatType { get }
    var bytesPerRow: Int { get }
    var byteCount: Int { get }
    var accessCapabilities: CVPixelBufferAccessCapabilities { get }
    var isPlanar: Bool { get }
    var planeCount: Int { get }

    func withReadBytes(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError)

    func withWriteBytes(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError)

    func dimensionsOfPlane(
        at index: Int
    ) throws(CVPixelBufferError) -> CVPixelDimensions

    func bytesPerRowOfPlane(
        at index: Int
    ) throws(CVPixelBufferError) -> Int

    func withReadBytes(
        ofPlane index: Int,
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError)

    func withWriteBytes(
        ofPlane index: Int,
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError)
}

extension CVPixelBuffer {
    public var isPlanar: Bool {
        false
    }

    public var planeCount: Int {
        0
    }

    public func dimensionsOfPlane(
        at index: Int
    ) throws(CVPixelBufferError) -> CVPixelDimensions {
        throw .invalidPlaneIndex(index: index, planeCount: 0)
    }

    public func bytesPerRowOfPlane(
        at index: Int
    ) throws(CVPixelBufferError) -> Int {
        throw .invalidPlaneIndex(index: index, planeCount: 0)
    }

    public func withReadBytes(
        ofPlane index: Int,
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        throw .invalidPlaneIndex(index: index, planeCount: 0)
    }

    public func withWriteBytes(
        ofPlane index: Int,
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        throw .invalidPlaneIndex(index: index, planeCount: 0)
    }
}
