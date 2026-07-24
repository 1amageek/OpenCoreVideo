public protocol CVPlanarStorageLease:
    AnyObject,
    CVPlatformConcurrencyContract
{
    var planeCount: Int { get }
    var accessCapabilities: CVPixelBufferAccessCapabilities { get }

    func byteCount(
        ofPlane index: Int
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
