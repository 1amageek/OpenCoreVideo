public struct CVPixelBufferAccessCapabilities: OptionSet, Sendable {
    public let rawValue: UInt8

    public init(rawValue: UInt8) {
        self.rawValue = rawValue
    }

    public static let read = Self(rawValue: 1 << 0)
    public static let write = Self(rawValue: 1 << 1)
    public static let readWrite: Self = [.read, .write]
}
