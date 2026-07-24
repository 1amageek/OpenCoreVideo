public protocol CVPixelBufferAccessCoordinator:
    CVPlatformConcurrencyContract
{
    func lock(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError)

    func unlock(_ mode: CVPixelBufferAccessMode)
}
