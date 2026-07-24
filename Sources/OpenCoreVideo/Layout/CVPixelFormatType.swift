public struct CVPixelFormatType: RawRepresentable, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let bgra32 = Self(rawValue: 0x42475241)
    public static let rgba32 = Self(rawValue: 0x52474241)
    public static let grayscale8 = Self(rawValue: 0x4C303038)
    public static let yCbCr420BiPlanarVideoRange = Self(
        rawValue: 0x34323076
    )
    public static let yCbCr420BiPlanarFullRange = Self(
        rawValue: 0x34323066
    )
}
