public struct CVPixelBufferPoolConfiguration: Sendable, Hashable {
    public static let `default` = Self(
        validatedMinimumBufferCount: 0,
        maximumBufferAgeNanoseconds: nil
    )

    public let minimumBufferCount: Int
    public let maximumBufferAgeNanoseconds: UInt64?

    public init(
        minimumBufferCount: Int = 0,
        maximumBufferAgeNanoseconds: UInt64? = nil
    ) throws(CVPixelBufferError) {
        guard minimumBufferCount >= 0 else {
            throw .invalidMinimumBufferCount(minimumBufferCount)
        }
        self.minimumBufferCount = minimumBufferCount
        self.maximumBufferAgeNanoseconds = maximumBufferAgeNanoseconds
    }

    private init(
        validatedMinimumBufferCount: Int,
        maximumBufferAgeNanoseconds: UInt64?
    ) {
        self.minimumBufferCount = validatedMinimumBufferCount
        self.maximumBufferAgeNanoseconds = maximumBufferAgeNanoseconds
    }
}
