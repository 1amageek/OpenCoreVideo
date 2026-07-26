extension CVPixelFormatDescription {
    internal static var standardDescriptions: [CVPixelFormatDescription] {
        makeStandardPixelFormatDescriptions()
    }

    internal static func standardDescription(
        for pixelFormat: CVPixelFormatType
    ) -> CVPixelFormatDescription? {
        makeStandardPixelFormatDescription(for: pixelFormat)
    }
}

private func makeStandardPixelFormatDescriptions()
    -> [CVPixelFormatDescription]
{
    [
        makeBGRA32Description(),
        makeRGBA32Description(),
        makeGrayscale8Description(),
        makeYpCbCr420BiPlanarDescription(
            pixelFormat: .yCbCr420BiPlanarVideoRange,
            name: "420YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            lumaBlack: 16
        ),
        makeYpCbCr420BiPlanarDescription(
            pixelFormat: .yCbCr420BiPlanarFullRange,
            name: "420YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            lumaBlack: 0
        )
    ]
}

private func makeStandardPixelFormatDescription(
    for pixelFormat: CVPixelFormatType
) -> CVPixelFormatDescription? {
    switch pixelFormat {
    case .bgra32:
        return makeBGRA32Description()
    case .rgba32:
        return makeRGBA32Description()
    case .grayscale8:
        return makeGrayscale8Description()
    case .yCbCr420BiPlanarVideoRange:
        return makeYpCbCr420BiPlanarDescription(
            pixelFormat: pixelFormat,
            name: "420YpCbCr8BiPlanarVideoRange",
            componentRange: .video,
            lumaBlack: 16
        )
    case .yCbCr420BiPlanarFullRange:
        return makeYpCbCr420BiPlanarDescription(
            pixelFormat: pixelFormat,
            name: "420YpCbCr8BiPlanarFullRange",
            componentRange: .full,
            lumaBlack: 0
        )
    default:
        return nil
    }
}

private func makeBGRA32Description() -> CVPixelFormatDescription {
    CVPixelFormatDescription(
        validatedPixelFormatType: .bgra32,
        name: "32BGRA",
        components: [.rgb, .alpha],
        componentRange: .full,
        planeConfiguration: .nonPlanar(makePacked32Layout())
    )
}

private func makeRGBA32Description() -> CVPixelFormatDescription {
    CVPixelFormatDescription(
        validatedPixelFormatType: .rgba32,
        name: "32RGBA",
        components: [.rgb, .alpha],
        componentRange: .full,
        planeConfiguration: .nonPlanar(makePacked32Layout())
    )
}

private func makeGrayscale8Description() -> CVPixelFormatDescription {
    CVPixelFormatDescription(
        validatedPixelFormatType: .grayscale8,
        name: "OneComponent8",
        components: [.grayscale],
        componentRange: .full,
        planeConfiguration: .nonPlanar(
            CVPixelFormatDescription.PixelLayout(
                validatedBlockSize: CVImageSize(width: 1, height: 1),
                bitsPerBlock: 8,
                bitsPerComponent: 8,
                blockAlignment: unitDimensions(),
                subsampling: unitDimensions(),
                blackBlock: [0],
                compatibility: [
                    .cgBitmapContext,
                    .cgImage,
                    .metalTexture
                ]
            )
        )
    )
}

private func makePacked32Layout()
    -> CVPixelFormatDescription.PixelLayout
{
    CVPixelFormatDescription.PixelLayout(
        validatedBlockSize: CVImageSize(width: 1, height: 1),
        bitsPerBlock: 32,
        bitsPerComponent: 8,
        blockAlignment: unitDimensions(),
        subsampling: unitDimensions(),
        blackBlock: [0, 0, 0, 255],
        compatibility: [
            .cgBitmapContext,
            .cgImage,
            .ioSurfaceCoreAnimation,
            .metalTexture
        ]
    )
}

private func makeYpCbCr420BiPlanarDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    componentRange: CVPixelFormatDescription.ComponentRange,
    lumaBlack: UInt8
) -> CVPixelFormatDescription {
    let luma = CVPixelFormatDescription.PixelLayout(
        validatedBlockSize: CVImageSize(width: 1, height: 1),
        bitsPerBlock: 8,
        bitsPerComponent: 8,
        blockAlignment: unitDimensions(),
        subsampling: unitDimensions(),
        blackBlock: [lumaBlack],
        compatibility: [.ioSurfaceCoreAnimation, .metalTexture]
    )
    let chroma = CVPixelFormatDescription.PixelLayout(
        validatedBlockSize: CVImageSize(width: 1, height: 1),
        bitsPerBlock: 16,
        bitsPerComponent: 8,
        blockAlignment: unitDimensions(),
        subsampling: CVPixelFormatDescription.Dimensions(
            horizontal: 2,
            vertical: 2
        ),
        blackBlock: [128, 128],
        compatibility: [.ioSurfaceCoreAnimation, .metalTexture]
    )
    return CVPixelFormatDescription(
        validatedPixelFormatType: pixelFormat,
        name: name,
        components: [.yCbCr],
        componentRange: componentRange,
        planeConfiguration: .planar([luma, chroma])
    )
}

private func unitDimensions() -> CVPixelFormatDescription.Dimensions {
    CVPixelFormatDescription.Dimensions(horizontal: 1, vertical: 1)
}
