public struct CVPixelDimensions: Sendable, Hashable {
    public let width: Int
    public let height: Int

    public init(
        width: Int,
        height: Int
    ) throws(CVPixelBufferError) {
        guard width > 0, height > 0 else {
            throw .invalidDimensions(width: width, height: height)
        }

        self.width = width
        self.height = height
    }
}
