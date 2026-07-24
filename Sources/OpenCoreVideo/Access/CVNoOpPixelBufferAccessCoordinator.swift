public struct CVNoOpPixelBufferAccessCoordinator:
    CVPixelBufferAccessCoordinator
{
    public init() {}

    public func lock(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) {}

    public func unlock(_ mode: CVPixelBufferAccessMode) {}
}
