internal func makePlanarStandardPixelFormatDescriptions()
    -> [CVPixelFormatDescription]
{
    [
        makeYCbCrBiPlanar8Description(
            pixelFormat: .yCbCr420BiPlanarVideoRange,
            name: "420YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        ),
        makeYCbCrBiPlanar8Description(
            pixelFormat: .yCbCr420BiPlanarFullRange,
            name: "420YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        ),
        makeYCbCrBiPlanar8Description(
            pixelFormat: .yCbCr422BiPlanarVideoRange,
            name: "422YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        ),
        makeYCbCrBiPlanar8Description(
            pixelFormat: .yCbCr422BiPlanarFullRange,
            name: "422YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        ),
        makeYCbCrBiPlanar8Description(
            pixelFormat: .yCbCr444BiPlanarVideoRange,
            name: "444YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            subsampling: unitPixelFormatDimensions()
        ),
        makeYCbCrBiPlanar8Description(
            pixelFormat: .yCbCr444BiPlanarFullRange,
            name: "444YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            subsampling: unitPixelFormatDimensions()
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr420BiPlanar10VideoRange,
            name: "420YpCbCr10BiPlanarVideoRange",
            bitsPerComponent: 10,
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr420BiPlanar10FullRange,
            name: "420YpCbCr10BiPlanarFullRange",
            bitsPerComponent: 10,
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr422BiPlanar10VideoRange,
            name: "422YpCbCr10BiPlanarVideoRange",
            bitsPerComponent: 10,
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr422BiPlanar10FullRange,
            name: "422YpCbCr10BiPlanarFullRange",
            bitsPerComponent: 10,
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr444BiPlanar10VideoRange,
            name: "444YpCbCr10BiPlanarVideoRange",
            bitsPerComponent: 10,
            componentRange: .video,
            subsampling: unitPixelFormatDimensions()
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr444BiPlanar10FullRange,
            name: "444YpCbCr10BiPlanarFullRange",
            bitsPerComponent: 10,
            componentRange: .full,
            subsampling: unitPixelFormatDimensions()
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr422BiPlanar16VideoRange,
            name: "422YpCbCr16BiPlanarVideoRange",
            bitsPerComponent: 16,
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        ),
        makeYCbCrBiPlanarHighBitDepthDescription(
            pixelFormat: .yCbCr444BiPlanar16VideoRange,
            name: "444YpCbCr16BiPlanarVideoRange",
            bitsPerComponent: 16,
            componentRange: .video,
            subsampling: unitPixelFormatDimensions()
        ),
        makeYCbCr420AlphaTriPlanarDescription(),
        makeYCbCr444AlphaTriPlanar16Description(),
        makeRGB30AlphaBiPlanarDescription()
    ]
}

internal func makePlanarStandardPixelFormatDescription(
    for pixelFormat: CVPixelFormatType
) -> CVPixelFormatDescription? {
    switch pixelFormat {
    case .yCbCr420BiPlanarVideoRange:
        return makeYCbCrBiPlanar8Description(
            pixelFormat: pixelFormat,
            name: "420YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        )
    case .yCbCr420BiPlanarFullRange:
        return makeYCbCrBiPlanar8Description(
            pixelFormat: pixelFormat,
            name: "420YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        )
    case .yCbCr422BiPlanarVideoRange:
        return makeYCbCrBiPlanar8Description(
            pixelFormat: pixelFormat,
            name: "422YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        )
    case .yCbCr422BiPlanarFullRange:
        return makeYCbCrBiPlanar8Description(
            pixelFormat: pixelFormat,
            name: "422YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        )
    case .yCbCr444BiPlanarVideoRange:
        return makeYCbCrBiPlanar8Description(
            pixelFormat: pixelFormat,
            name: "444YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            subsampling: unitPixelFormatDimensions()
        )
    case .yCbCr444BiPlanarFullRange:
        return makeYCbCrBiPlanar8Description(
            pixelFormat: pixelFormat,
            name: "444YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            subsampling: unitPixelFormatDimensions()
        )
    case .yCbCr420BiPlanar10VideoRange:
        return makeYCbCrBiPlanar10Description(
            pixelFormat: pixelFormat,
            name: "420YpCbCr10BiPlanarVideoRange",
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        )
    case .yCbCr420BiPlanar10FullRange:
        return makeYCbCrBiPlanar10Description(
            pixelFormat: pixelFormat,
            name: "420YpCbCr10BiPlanarFullRange",
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 2)
        )
    case .yCbCr422BiPlanar10VideoRange:
        return makeYCbCrBiPlanar10Description(
            pixelFormat: pixelFormat,
            name: "422YpCbCr10BiPlanarVideoRange",
            componentRange: .video,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        )
    case .yCbCr422BiPlanar10FullRange:
        return makeYCbCrBiPlanar10Description(
            pixelFormat: pixelFormat,
            name: "422YpCbCr10BiPlanarFullRange",
            componentRange: .full,
            subsampling: subsampling(horizontal: 2, vertical: 1)
        )
    case .yCbCr444BiPlanar10VideoRange:
        return makeYCbCrBiPlanar10Description(
            pixelFormat: pixelFormat,
            name: "444YpCbCr10BiPlanarVideoRange",
            componentRange: .video,
            subsampling: unitPixelFormatDimensions()
        )
    case .yCbCr444BiPlanar10FullRange:
        return makeYCbCrBiPlanar10Description(
            pixelFormat: pixelFormat,
            name: "444YpCbCr10BiPlanarFullRange",
            componentRange: .full,
            subsampling: unitPixelFormatDimensions()
        )
    case .yCbCr422BiPlanar16VideoRange:
        return makeYCbCrBiPlanar16Description(
            pixelFormat: pixelFormat,
            name: "422YpCbCr16BiPlanarVideoRange",
            subsampling: subsampling(horizontal: 2, vertical: 1)
        )
    case .yCbCr444BiPlanar16VideoRange:
        return makeYCbCrBiPlanar16Description(
            pixelFormat: pixelFormat,
            name: "444YpCbCr16BiPlanarVideoRange",
            subsampling: unitPixelFormatDimensions()
        )
    case .yCbCr420VideoRangeWithAlphaTriPlanar:
        return makeYCbCr420AlphaTriPlanarDescription()
    case .yCbCr444VideoRangeWithAlphaTriPlanar16:
        return makeYCbCr444AlphaTriPlanar16Description()
    case .rgb30WideGamutWithAlphaBiPlanar:
        return makeRGB30AlphaBiPlanarDescription()
    default:
        return nil
    }
}

private func makeYCbCrBiPlanar8Description(
    pixelFormat: CVPixelFormatType,
    name: String,
    componentRange: CVPixelFormatDescription.ComponentRange,
    subsampling: CVPixelFormatDescription.Dimensions
) -> CVPixelFormatDescription {
    makeYCbCrBiPlanarDescription(
        pixelFormat: pixelFormat,
        name: name,
        bitsPerComponent: 8,
        componentRange: componentRange,
        subsampling: subsampling,
        lumaBlack: componentRange == .video ? [16] : [0],
        chromaBlack: [128, 128]
    )
}

private func makeYCbCrBiPlanar10Description(
    pixelFormat: CVPixelFormatType,
    name: String,
    componentRange: CVPixelFormatDescription.ComponentRange,
    subsampling: CVPixelFormatDescription.Dimensions
) -> CVPixelFormatDescription {
    makeYCbCrBiPlanarHighBitDepthDescription(
        pixelFormat: pixelFormat,
        name: name,
        bitsPerComponent: 10,
        componentRange: componentRange,
        subsampling: subsampling
    )
}

private func makeYCbCrBiPlanar16Description(
    pixelFormat: CVPixelFormatType,
    name: String,
    subsampling: CVPixelFormatDescription.Dimensions
) -> CVPixelFormatDescription {
    makeYCbCrBiPlanarHighBitDepthDescription(
        pixelFormat: pixelFormat,
        name: name,
        bitsPerComponent: 16,
        componentRange: .video,
        subsampling: subsampling
    )
}

private func makeYCbCrBiPlanarHighBitDepthDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    bitsPerComponent: Int,
    componentRange: CVPixelFormatDescription.ComponentRange,
    subsampling: CVPixelFormatDescription.Dimensions
) -> CVPixelFormatDescription {
    makeYCbCrBiPlanarDescription(
        pixelFormat: pixelFormat,
        name: name,
        bitsPerComponent: bitsPerComponent,
        componentRange: componentRange,
        subsampling: subsampling,
        lumaBlack: componentRange == .video ? [0, 16] : nil,
        chromaBlack: [0, 128, 0, 128]
    )
}

private func makeYCbCrBiPlanarDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    bitsPerComponent: Int,
    componentRange: CVPixelFormatDescription.ComponentRange,
    subsampling: CVPixelFormatDescription.Dimensions,
    lumaBlack: [UInt8]?,
    chromaBlack: [UInt8]
) -> CVPixelFormatDescription {
    let bytesPerComponent = bitsPerComponent == 8 ? 1 : 2
    let luma = makePlaneLayout(
        bitsPerBlock: bytesPerComponent * 8,
        bitsPerComponent: bitsPerComponent,
        subsampling: unitPixelFormatDimensions(),
        blackBlock: lumaBlack
    )
    let chroma = makePlaneLayout(
        bitsPerBlock: bytesPerComponent * 16,
        bitsPerComponent: bitsPerComponent,
        subsampling: subsampling,
        blackBlock: chromaBlack
    )
    return CVPixelFormatDescription(
        validatedPixelFormatType: pixelFormat,
        name: name,
        components: [.yCbCr],
        componentRange: componentRange,
        planeConfiguration: .planar([luma, chroma])
    )
}

private func makeYCbCr420AlphaTriPlanarDescription()
    -> CVPixelFormatDescription
{
    CVPixelFormatDescription(
        validatedPixelFormatType: .yCbCr420VideoRangeWithAlphaTriPlanar,
        name: "420YpCbCr8VideoRange8AlphaTriPlanar",
        components: [.yCbCr, .alpha],
        componentRange: .video,
        planeConfiguration: .planar([
            makePlaneLayout(
                bitsPerBlock: 8,
                bitsPerComponent: 8,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [16]
            ),
            makePlaneLayout(
                bitsPerBlock: 16,
                bitsPerComponent: 8,
                subsampling: subsampling(horizontal: 2, vertical: 2),
                blackBlock: [128, 128]
            ),
            makePlaneLayout(
                bitsPerBlock: 8,
                bitsPerComponent: 8,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [16]
            )
        ])
    )
}

private func makeYCbCr444AlphaTriPlanar16Description()
    -> CVPixelFormatDescription
{
    CVPixelFormatDescription(
        validatedPixelFormatType:
            .yCbCr444VideoRangeWithAlphaTriPlanar16,
        name: "444YpCbCr16VideoRange16AlphaTriPlanar",
        components: [.yCbCr, .alpha],
        componentRange: .video,
        planeConfiguration: .planar([
            makePlaneLayout(
                bitsPerBlock: 16,
                bitsPerComponent: 16,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [0, 16]
            ),
            makePlaneLayout(
                bitsPerBlock: 32,
                bitsPerComponent: 16,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [0, 128, 0, 128]
            ),
            makePlaneLayout(
                bitsPerBlock: 16,
                bitsPerComponent: 16,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [255, 255]
            )
        ])
    )
}

private func makeRGB30AlphaBiPlanarDescription()
    -> CVPixelFormatDescription
{
    CVPixelFormatDescription(
        validatedPixelFormatType: .rgb30WideGamutWithAlphaBiPlanar,
        name: "30RGBLE8AlphaBiPlanar",
        components: [.rgb, .alpha],
        componentRange: .wide,
        planeConfiguration: .planar([
            makePlaneLayout(
                bitsPerBlock: 32,
                bitsPerComponent: 10,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: nil
            ),
            makePlaneLayout(
                bitsPerBlock: 8,
                bitsPerComponent: 8,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [255]
            )
        ])
    )
}

private func makePlaneLayout(
    bitsPerBlock: Int,
    bitsPerComponent: Int,
    subsampling: CVPixelFormatDescription.Dimensions,
    blackBlock: [UInt8]?
) -> CVPixelFormatDescription.PixelLayout {
    CVPixelFormatDescription.PixelLayout(
        validatedBlockSize: CVImageSize(width: 1, height: 1),
        bitsPerBlock: bitsPerBlock,
        bitsPerComponent: bitsPerComponent,
        blockAlignment: unitPixelFormatDimensions(),
        subsampling: subsampling,
        blackBlock: blackBlock,
        compatibility: [.ioSurfaceCoreAnimation, .metalTexture]
    )
}

private func subsampling(
    horizontal: Int,
    vertical: Int
) -> CVPixelFormatDescription.Dimensions {
    CVPixelFormatDescription.Dimensions(
        horizontal: horizontal,
        vertical: vertical
    )
}
