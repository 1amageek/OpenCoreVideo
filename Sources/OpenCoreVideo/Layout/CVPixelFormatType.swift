public struct CVPixelFormatType: RawRepresentable, Sendable, Hashable {
    public let rawValue: UInt32

    public init(rawValue: UInt32) {
        self.rawValue = rawValue
    }

    public static let monochrome1 = Self(rawValue: 0x00000001)
    public static let indexed2 = Self(rawValue: 0x00000002)
    public static let indexed4 = Self(rawValue: 0x00000004)
    public static let indexed8 = Self(rawValue: 0x00000008)
    public static let indexedGrayWhiteIsZero1 = Self(rawValue: 0x00000021)
    public static let indexedGrayWhiteIsZero2 = Self(rawValue: 0x00000022)
    public static let indexedGrayWhiteIsZero4 = Self(rawValue: 0x00000024)
    public static let indexedGrayWhiteIsZero8 = Self(rawValue: 0x00000028)

    public static let rgb555BigEndian = Self(rawValue: 0x00000010)
    public static let rgb555LittleEndian = Self(rawValue: 0x4C353535)
    public static let rgb5551LittleEndian = Self(rawValue: 0x35353531)
    public static let rgb565BigEndian = Self(rawValue: 0x42353635)
    public static let rgb565LittleEndian = Self(rawValue: 0x4C353635)

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
    public static let rgb30BigEndian = Self(rawValue: 0x5231306B)
    public static let rgb30BigEndianVideoRange = Self(rawValue: 0x72323130)

    public static let yCbCr422Packed8 = Self(rawValue: 0x32767579)
    public static let yCbCr4444AlphaPacked8 = Self(rawValue: 0x76343038)
    public static let yCbCr4444AlphaRenderingPacked8 = Self(
        rawValue: 0x72343038
    )
    public static let alphaYCbCr4444Packed8 = Self(rawValue: 0x79343038)
    public static let alphaYCbCr4444Packed16 = Self(rawValue: 0x79343136)
    public static let alphaYCbCr4444PackedFloat = Self(
        rawValue: 0x7234666C
    )
    public static let yCbCr444Packed8 = Self(rawValue: 0x76333038)
    public static let yCbCr422Packed16 = Self(rawValue: 0x76323136)
    public static let yCbCr422Packed10 = Self(rawValue: 0x76323130)
    public static let yCbCr444Packed10 = Self(rawValue: 0x76343130)
    public static let yCbCr420PlanarVideoRange = Self(rawValue: 0x79343230)
    public static let yCbCr420PlanarFullRange = Self(rawValue: 0x66343230)
    public static let yCbCr422WithAlphaBiPlanar = Self(rawValue: 0x61327679)
    public static let yCbCr422Packed8YUY2 = Self(rawValue: 0x79757673)
    public static let yCbCr422Packed8FullRange = Self(rawValue: 0x79757666)

    public static let oneComponent8 = Self(rawValue: 0x4C303038)
    public static let grayscale8 = oneComponent8
    public static let twoComponent8 = Self(rawValue: 0x32433038)
    public static let rgb30LittleEndianWideGamut = Self(
        rawValue: 0x77333072
    )
    public static let argb2101010LittleEndian = Self(rawValue: 0x6C313072)
    public static let argb40LittleEndianWideGamut = Self(
        rawValue: 0x77343061
    )
    public static let argb40LittleEndianWideGamutPremultiplied = Self(
        rawValue: 0x7734306D
    )
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

    public static let bayer14GRBG = Self(rawValue: 0x67726234)
    public static let bayer14RGGB = Self(rawValue: 0x72676734)
    public static let bayer14BGGR = Self(rawValue: 0x62676734)
    public static let bayer14GBRG = Self(rawValue: 0x67627234)

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
    public static let versatileBayer16 = Self(rawValue: 0x62703136)
    public static let versatileBayerPacked12 = Self(rawValue: 0x62747032)
    public static let rgba64DownscaledProResRAW = Self(rawValue: 0x62703634)
    public static let yCbCr444VideoRangeWithAlphaTriPlanar16 = Self(
        rawValue: 0x73346173
    )
    public static let rgb30WideGamutWithAlphaBiPlanar = Self(
        rawValue: 0x62336138
    )
}
