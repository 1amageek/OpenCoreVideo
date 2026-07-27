internal func makeLegacyPlanarStandardPixelFormatDescriptions()
    -> [CVPixelFormatDescription]
{
    [
        makeYCbCr420PlanarDescription(
            pixelFormat: .yCbCr420PlanarVideoRange,
            name: "420YpCbCr8Planar",
            componentRange: .video,
            lumaBlack: [16]
        ),
        makeYCbCr420PlanarDescription(
            pixelFormat: .yCbCr420PlanarFullRange,
            name: "420YpCbCr8PlanarFullRange",
            componentRange: .full,
            lumaBlack: [0]
        ),
        makeYCbCr422AlphaBiPlanarDescription()
    ]
}

internal func makeLegacyPlanarStandardPixelFormatDescription(
    for pixelFormat: CVPixelFormatType
) -> CVPixelFormatDescription? {
    switch pixelFormat {
    case .yCbCr420PlanarVideoRange:
        return makeYCbCr420PlanarDescription(
            pixelFormat: pixelFormat,
            name: "420YpCbCr8Planar",
            componentRange: .video,
            lumaBlack: [16]
        )
    case .yCbCr420PlanarFullRange:
        return makeYCbCr420PlanarDescription(
            pixelFormat: pixelFormat,
            name: "420YpCbCr8PlanarFullRange",
            componentRange: .full,
            lumaBlack: [0]
        )
    case .yCbCr422WithAlphaBiPlanar:
        return makeYCbCr422AlphaBiPlanarDescription()
    default:
        return nil
    }
}

private func makeYCbCr420PlanarDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    componentRange: CVPixelFormatDescription.ComponentRange,
    lumaBlack: [UInt8]
) -> CVPixelFormatDescription {
    CVPixelFormatDescription(
        validatedPixelFormatType: pixelFormat,
        name: name,
        components: [.yCbCr],
        componentRange: componentRange,
        planeConfiguration: .planar([
            makeLegacyPlaneLayout(
                subsampling: unitPixelFormatDimensions(),
                blackBlock: lumaBlack
            ),
            makeLegacyPlaneLayout(
                subsampling: .init(horizontal: 2, vertical: 2),
                blackBlock: [128]
            ),
            makeLegacyPlaneLayout(
                subsampling: .init(horizontal: 2, vertical: 2),
                blackBlock: [128]
            )
        ])
    )
}

private func makeYCbCr422AlphaBiPlanarDescription()
    -> CVPixelFormatDescription
{
    CVPixelFormatDescription(
        validatedPixelFormatType: .yCbCr422WithAlphaBiPlanar,
        name: "422YpCbCr_4A_8BiPlanar",
        components: [.yCbCr, .alpha],
        componentRange: .video,
        componentSubsampling: .init(horizontal: 2, vertical: 1),
        planeConfiguration: .planar([
            makePlaneLayout(
                blockSize: CVImageSize(width: 2, height: 1),
                bitsPerBlock: 32,
                bitsPerComponent: 8,
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [128, 16, 128, 16],
                compatibility: []
            ),
            makeLegacyPlaneLayout(
                subsampling: unitPixelFormatDimensions(),
                blackBlock: [255]
            )
        ])
    )
}

private func makeLegacyPlaneLayout(
    subsampling: CVPixelFormatDescription.Dimensions,
    blackBlock: [UInt8]
) -> CVPixelFormatDescription.PixelLayout {
    makePlaneLayout(
        bitsPerBlock: 8,
        bitsPerComponent: 8,
        subsampling: subsampling,
        blackBlock: blackBlock,
        compatibility: []
    )
}
