public protocol CVPixelBufferPoolAllocator:
    CVPlatformConcurrencyContract
{
    associatedtype Storage: CVPixelBufferStorage

    func storage(
        byteCount: Int
    ) throws(CVPixelBufferError) -> Storage
}
