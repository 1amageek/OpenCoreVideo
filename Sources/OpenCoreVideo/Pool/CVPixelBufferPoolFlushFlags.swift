public struct CVPixelBufferPoolFlushFlags: OptionSet, Sendable {
    public let rawValue: UInt64

    public init(rawValue: UInt64) {
        self.rawValue = rawValue
    }

    public static let excessBuffers = Self(rawValue: 1)
}
