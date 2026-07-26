public struct CVPixelFormatType: RawRepresentable, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let rgb24 = Self(rawValue: 0x00000018)
    public static let bgr24 = Self(rawValue: 0x32344247)
    public static let argb32 = Self(rawValue: 0x00000020)
    public static let bgra32 = Self(rawValue: 0x42475241)
    public static let abgr32 = Self(rawValue: 0x41424752)
    public static let rgba32 = Self(rawValue: 0x52474241)
    public static let argb64BigEndian = Self(rawValue: 0x62363461)
    public static let rgba64LittleEndian = Self(rawValue: 0x6C363472)
    public static let rgb48BigEndian = Self(rawValue: 0x62343872)
    public static let alphaGray32BigEndian = Self(rawValue: 0x62333261)
    public static let gray16BigEndian = Self(rawValue: 0x62313667)

    public static let oneComponent8 = Self(rawValue: 0x4C303038)
    public static let grayscale8 = oneComponent8
    public static let twoComponent8 = Self(rawValue: 0x32433038)
    public static let oneComponent10 = Self(rawValue: 0x4C303130)
    public static let oneComponent12 = Self(rawValue: 0x4C303132)
    public static let oneComponent16 = Self(rawValue: 0x4C303136)
    public static let twoComponent16 = Self(rawValue: 0x32433136)
    public static let oneComponent16Half = Self(rawValue: 0x4C303068)
    public static let oneComponent32Float = Self(rawValue: 0x4C303066)
    public static let twoComponent16Half = Self(rawValue: 0x32433068)
    public static let twoComponent32Float = Self(rawValue: 0x32433066)
    public static let rgba64Half = Self(rawValue: 0x52476841)
    public static let rgba128Float = Self(rawValue: 0x52476641)

    public static let disparity16Half = Self(rawValue: 0x68646973)
    public static let disparity32Float = Self(rawValue: 0x66646973)
    public static let depth16Half = Self(rawValue: 0x68646570)
    public static let depth32Float = Self(rawValue: 0x66646570)

    public static let yCbCr420BiPlanarVideoRange = Self(
        rawValue: 0x34323076
    )
    public static let yCbCr420BiPlanarFullRange = Self(
        rawValue: 0x34323066
    )
    public static let yCbCr422BiPlanarVideoRange = Self(
        rawValue: 0x34323276
    )
    public static let yCbCr422BiPlanarFullRange = Self(
        rawValue: 0x34323266
    )
    public static let yCbCr444BiPlanarVideoRange = Self(
        rawValue: 0x34343476
    )
    public static let yCbCr444BiPlanarFullRange = Self(
        rawValue: 0x34343466
    )

    public static let yCbCr420BiPlanar10VideoRange = Self(
        rawValue: 0x78343230
    )
    public static let yCbCr422BiPlanar10VideoRange = Self(
        rawValue: 0x78343232
    )
    public static let yCbCr444BiPlanar10VideoRange = Self(
        rawValue: 0x78343434
    )
    public static let yCbCr420BiPlanar10FullRange = Self(
        rawValue: 0x78663230
    )
    public static let yCbCr422BiPlanar10FullRange = Self(
        rawValue: 0x78663232
    )
    public static let yCbCr444BiPlanar10FullRange = Self(
        rawValue: 0x78663434
    )

    public static let yCbCr422BiPlanar16VideoRange = Self(
        rawValue: 0x73763232
    )
    public static let yCbCr444BiPlanar16VideoRange = Self(
        rawValue: 0x73763434
    )
    public static let yCbCr420VideoRangeWithAlphaTriPlanar = Self(
        rawValue: 0x76306138
    )
    public static let yCbCr444VideoRangeWithAlphaTriPlanar16 = Self(
        rawValue: 0x73346173
    )
    public static let rgb30WideGamutWithAlphaBiPlanar = Self(
        rawValue: 0x62336138
    )
}
