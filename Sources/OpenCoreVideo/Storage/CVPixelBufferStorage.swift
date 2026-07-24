public protocol CVPixelBufferStorage:
    AnyObject,
    CVPlatformConcurrencyContract
{
    var byteCount: Int { get }
    var accessCapabilities: CVPixelBufferAccessCapabilities { get }

    func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError)

    func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError)
}
