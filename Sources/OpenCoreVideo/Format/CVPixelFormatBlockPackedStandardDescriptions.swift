internal func makeBlockPackedStandardPixelFormatDescriptions()
    -> [CVPixelFormatDescription]
{
    let pixelFormats = blockPackedStandardPixelFormatTypes()
    var descriptions: [CVPixelFormatDescription] = []
    descriptions.reserveCapacity(pixelFormats.count)
    for pixelFormat in pixelFormats {
        guard let description =
                makeBlockPackedStandardPixelFormatDescription(
                    for: pixelFormat
                ) else {
            preconditionFailure("Missing standard pixel format description")
        }
        descriptions.append(description)
    }
    return descriptions
}

internal func makeBlockPackedStandardPixelFormatDescription(
    for pixelFormat: CVPixelFormatType
) -> CVPixelFormatDescription? {
    switch pixelFormat {
    case .indexedGrayWhiteIsZero8:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "8IndexedGrayWhiteIsZero",
            components: [.grayscale],
            bitsPerBlock: 8,
            bitsPerComponent: 8,
            blackBlock: [255]
        )
    case .rgb555BigEndian:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "16BE555",
            components: [.rgb, .alpha],
            bitsPerBlock: 16,
            bitsPerComponent: 5,
            blackBlock: [128, 0]
        )
    case .rgb30BigEndian:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "30RGB",
            components: [.rgb],
            componentRange: .full,
            bitsPerBlock: 32,
            bitsPerComponent: 10
        )
    case .rgb30BigEndianVideoRange:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "30RGB_r210",
            components: [.rgb],
            componentRange: .video,
            bitsPerBlock: 32,
            bitsPerComponent: 10
        )
    case .rgb30LittleEndianWideGamut:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "30RGBLEPackedWideGamut",
            components: [.rgb],
            componentRange: .wide,
            bitsPerBlock: 32,
            bitsPerComponent: 10,
            blackBlock: [128, 1, 6, 24],
            compatibility: [.ioSurfaceCoreAnimation]
        )
    case .argb2101010LittleEndian:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "ARGB2101010LEPacked",
            components: [.rgb, .alpha],
            componentRange: .full,
            bitsPerBlock: 32,
            bitsPerComponent: 10,
            blackBlock: [0, 0, 0, 192]
        )
    case .argb40LittleEndianWideGamut:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "40ARGBLEWideGamut",
            components: [.rgb, .alpha],
            bitsPerBlock: 64,
            bitsPerComponent: 10,
            blackBlock: [128, 1, 128, 1, 128, 1, 128, 1]
        )
    case .argb40LittleEndianWideGamutPremultiplied:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "40ARGBLEWideGamutPremultiplied",
            components: [.rgb, .alpha],
            componentRange: .wide,
            bitsPerBlock: 64,
            bitsPerComponent: 10,
            blackBlock: [128, 1, 128, 1, 128, 1, 128, 1]
        )
    case .bayer14GRBG:
        return makeBayer14Description(pixelFormat, name: "14Bayer_GRBG")
    case .bayer14RGGB:
        return makeBayer14Description(pixelFormat, name: "14Bayer_RGGB")
    case .bayer14BGGR:
        return makeBayer14Description(pixelFormat, name: "14Bayer_BGGR")
    case .bayer14GBRG:
        return makeBayer14Description(pixelFormat, name: "14Bayer_GBRG")
    case .versatileBayer16:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "16VersatileBayer",
            components: [.senselArray],
            componentRange: .full,
            bitsPerBlock: 16,
            bitsPerComponent: 16
        )
    case .versatileBayerPacked12:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "96VersatileBayerPacked12",
            components: [.senselArray],
            blockSize: CVImageSize(width: 8, height: 1),
            bitsPerBlock: 96,
            bitsPerComponent: 12
        )
    case .rgba64DownscaledProResRAW:
        return standardPackedDescription(
            pixelFormat: pixelFormat,
            name: "64RGBA_DownscaledProResRAW",
            components: [.rgb],
            componentRange: .full,
            bitsPerBlock: 64,
            bitsPerComponent: 64,
            blackBlock: [0, 0, 0, 0, 0, 0, 255, 255]
        )
    case .yCbCr422Packed8:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "422YpCbCr8",
            componentRange: .video,
            blockSize: CVImageSize(width: 2, height: 1),
            bitsPerBlock: 32,
            bitsPerComponent: 8,
            subsampling: .init(horizontal: 2, vertical: 1),
            blackBlock: [128, 16, 128, 16],
            compatibility: [.ioSurfaceCoreAnimation]
        )
    case .yCbCr4444AlphaPacked8:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "4444YpCbCrA8",
            components: [.yCbCr, .alpha],
            componentRange: .video,
            bitsPerBlock: 32,
            bitsPerComponent: 8,
            blackBlock: [128, 16, 128, 235]
        )
    case .yCbCr4444AlphaRenderingPacked8:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "4444YpCbCrA8R",
            components: [.yCbCr, .alpha],
            bitsPerBlock: 32,
            bitsPerComponent: 8,
            blackBlock: [255, 0, 128, 128]
        )
    case .alphaYCbCr4444Packed8:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "4444AYpCbCr8",
            components: [.yCbCr, .alpha],
            componentRange: .video,
            bitsPerBlock: 32,
            bitsPerComponent: 8,
            blackBlock: [255, 16, 128, 128]
        )
    case .alphaYCbCr4444Packed16:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "4444AYpCbCr16",
            components: [.yCbCr, .alpha],
            componentRange: .video,
            bitsPerBlock: 64,
            bitsPerComponent: 16,
            blackBlock: [255, 255, 0, 16, 0, 128, 0, 128],
            compatibility: [.ioSurfaceCoreAnimation]
        )
    case .alphaYCbCr4444PackedFloat:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "4444AYpCbCrFloat",
            components: [.yCbCr, .alpha],
            bitsPerBlock: 128,
            bitsPerComponent: 32,
            blackBlock: [
                0, 0, 128, 63,
                0, 0, 0, 0,
                129, 128, 0, 63,
                129, 128, 0, 63
            ]
        )
    case .yCbCr444Packed8:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "444YpCbCr8",
            componentRange: .video,
            bitsPerBlock: 24,
            bitsPerComponent: 8,
            blackBlock: [128, 16, 128]
        )
    case .yCbCr422Packed16:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "422YpCbCr16",
            componentRange: .video,
            blockSize: CVImageSize(width: 2, height: 1),
            bitsPerBlock: 64,
            bitsPerComponent: 16,
            subsampling: .init(horizontal: 2, vertical: 1),
            blackBlock: [0, 128, 0, 16, 0, 128, 0, 16],
            compatibility: [.ioSurfaceCoreAnimation]
        )
    case .yCbCr422Packed10:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "422YpCbCr10",
            componentRange: .video,
            blockSize: CVImageSize(width: 6, height: 1),
            bitsPerBlock: 128,
            bitsPerComponent: 10,
            blockAlignment: .init(horizontal: 8, vertical: 1),
            subsampling: .init(horizontal: 2, vertical: 1),
            blackBlock: [
                0, 2, 1, 32, 64, 0, 8, 4,
                0, 2, 1, 32, 64, 0, 8, 4
            ]
        )
    case .yCbCr444Packed10:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "444YpCbCr10",
            componentRange: .video,
            bitsPerBlock: 32,
            bitsPerComponent: 10,
            blackBlock: [0, 8, 4, 128]
        )
    case .yCbCr422Packed8YUY2:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "422YpCbCr8_yuvs",
            componentRange: .video,
            blockSize: CVImageSize(width: 2, height: 1),
            bitsPerBlock: 32,
            bitsPerComponent: 8,
            subsampling: .init(horizontal: 2, vertical: 1),
            blackBlock: [16, 128, 16, 128],
            compatibility: [.ioSurfaceCoreAnimation]
        )
    case .yCbCr422Packed8FullRange:
        return makePackedYCbCrDescription(
            pixelFormat: pixelFormat,
            name: "422YpCbCr8FullRange",
            componentRange: .full,
            blockSize: CVImageSize(width: 2, height: 1),
            bitsPerBlock: 32,
            bitsPerComponent: 8,
            subsampling: .init(horizontal: 2, vertical: 1),
            blackBlock: [0, 128, 0, 128],
            compatibility: [.ioSurfaceCoreAnimation]
        )
    default:
        return nil
    }
}

private func blockPackedStandardPixelFormatTypes() -> [CVPixelFormatType] {
    [
        .indexedGrayWhiteIsZero8,
        .rgb555BigEndian,
        .rgb30BigEndian,
        .rgb30BigEndianVideoRange,
        .rgb30LittleEndianWideGamut,
        .argb2101010LittleEndian,
        .argb40LittleEndianWideGamut,
        .argb40LittleEndianWideGamutPremultiplied,
        .bayer14GRBG,
        .bayer14RGGB,
        .bayer14BGGR,
        .bayer14GBRG,
        .versatileBayer16,
        .versatileBayerPacked12,
        .rgba64DownscaledProResRAW,
        .yCbCr422Packed8,
        .yCbCr4444AlphaPacked8,
        .yCbCr4444AlphaRenderingPacked8,
        .alphaYCbCr4444Packed8,
        .alphaYCbCr4444Packed16,
        .alphaYCbCr4444PackedFloat,
        .yCbCr444Packed8,
        .yCbCr422Packed16,
        .yCbCr422Packed10,
        .yCbCr444Packed10,
        .yCbCr422Packed8YUY2,
        .yCbCr422Packed8FullRange
    ]
}

private func makeBayer14Description(
    _ pixelFormat: CVPixelFormatType,
    name: String
) -> CVPixelFormatDescription {
    standardPackedDescription(
        pixelFormat: pixelFormat,
        name: name,
        components: [.senselArray],
        bitsPerBlock: 16,
        bitsPerComponent: 14
    )
}

private func makePackedYCbCrDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    components: CVPixelFormatDescription.Components = [.yCbCr],
    componentRange: CVPixelFormatDescription.ComponentRange? = nil,
    blockSize: CVImageSize = CVImageSize(width: 1, height: 1),
    bitsPerBlock: Int,
    bitsPerComponent: Int,
    blockAlignment: CVPixelFormatDescription.Dimensions =
        unitPixelFormatDimensions(),
    subsampling: CVPixelFormatDescription.Dimensions =
        unitPixelFormatDimensions(),
    blackBlock: [UInt8],
    compatibility: CVPixelFormatDescription.Compatibility = []
) -> CVPixelFormatDescription {
    standardPackedDescription(
        pixelFormat: pixelFormat,
        name: name,
        components: components,
        componentRange: componentRange,
        blockSize: blockSize,
        bitsPerBlock: bitsPerBlock,
        bitsPerComponent: bitsPerComponent,
        blockAlignment: blockAlignment,
        subsampling: subsampling,
        blackBlock: blackBlock,
        compatibility: compatibility
    )
}

private func standardPackedDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    components: CVPixelFormatDescription.Components,
    componentRange: CVPixelFormatDescription.ComponentRange? = nil,
    blockSize: CVImageSize = CVImageSize(width: 1, height: 1),
    bitsPerBlock: Int,
    bitsPerComponent: Int,
    blockAlignment: CVPixelFormatDescription.Dimensions =
        unitPixelFormatDimensions(),
    subsampling: CVPixelFormatDescription.Dimensions =
        unitPixelFormatDimensions(),
    blackBlock: [UInt8]? = nil,
    compatibility: CVPixelFormatDescription.Compatibility = []
) -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: pixelFormat,
        name: name,
        components: components,
        componentRange: componentRange,
        blockSize: blockSize,
        bitsPerBlock: bitsPerBlock,
        bitsPerComponent: bitsPerComponent,
        blockAlignment: blockAlignment,
        subsampling: subsampling,
        blackBlock: blackBlock,
        compatibility: compatibility
    )
}
