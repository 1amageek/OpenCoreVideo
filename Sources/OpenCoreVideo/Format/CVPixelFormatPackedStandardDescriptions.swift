internal func makePackedStandardPixelFormatDescriptions()
    -> [CVPixelFormatDescription]
{
    [
        makeRGB24Description(),
        makeBGR24Description(),
        makeARGB32Description(),
        makeBGRA32Description(),
        makeABGR32Description(),
        makeRGBA32Description(),
        makeARGB64BigEndianDescription(),
        makeRGBA64LittleEndianDescription(),
        makeRGB48BigEndianDescription(),
        makeAlphaGray32BigEndianDescription(),
        makeGray16BigEndianDescription(),
        makeOneComponent8Description(),
        makeTwoComponent8Description(),
        makeOneComponent10Description(),
        makeOneComponent12Description(),
        makeOneComponent16Description(),
        makeTwoComponent16Description(),
        makeOneComponent16HalfDescription(),
        makeOneComponent32FloatDescription(),
        makeTwoComponent16HalfDescription(),
        makeTwoComponent32FloatDescription(),
        makeRGBA64HalfDescription(),
        makeRGBA128FloatDescription(),
        makeDisparity16HalfDescription(),
        makeDisparity32FloatDescription(),
        makeDepth16HalfDescription(),
        makeDepth32FloatDescription()
    ]
}

internal func makePackedStandardPixelFormatDescription(
    for pixelFormat: CVPixelFormatType
) -> CVPixelFormatDescription? {
    switch pixelFormat {
    case .rgb24: return makeRGB24Description()
    case .bgr24: return makeBGR24Description()
    case .argb32: return makeARGB32Description()
    case .bgra32: return makeBGRA32Description()
    case .abgr32: return makeABGR32Description()
    case .rgba32: return makeRGBA32Description()
    case .argb64BigEndian: return makeARGB64BigEndianDescription()
    case .rgba64LittleEndian: return makeRGBA64LittleEndianDescription()
    case .rgb48BigEndian: return makeRGB48BigEndianDescription()
    case .alphaGray32BigEndian: return makeAlphaGray32BigEndianDescription()
    case .gray16BigEndian: return makeGray16BigEndianDescription()
    case .oneComponent8: return makeOneComponent8Description()
    case .twoComponent8: return makeTwoComponent8Description()
    case .oneComponent10: return makeOneComponent10Description()
    case .oneComponent12: return makeOneComponent12Description()
    case .oneComponent16: return makeOneComponent16Description()
    case .twoComponent16: return makeTwoComponent16Description()
    case .oneComponent16Half: return makeOneComponent16HalfDescription()
    case .oneComponent32Float: return makeOneComponent32FloatDescription()
    case .twoComponent16Half: return makeTwoComponent16HalfDescription()
    case .twoComponent32Float: return makeTwoComponent32FloatDescription()
    case .rgba64Half: return makeRGBA64HalfDescription()
    case .rgba128Float: return makeRGBA128FloatDescription()
    case .disparity16Half: return makeDisparity16HalfDescription()
    case .disparity32Float: return makeDisparity32FloatDescription()
    case .depth16Half: return makeDepth16HalfDescription()
    case .depth32Float: return makeDepth32FloatDescription()
    default: return nil
    }
}

private func makeRGB24Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .rgb24,
        name: "24RGB",
        components: [.rgb],
        componentRange: nil,
        bitsPerBlock: 24,
        bitsPerComponent: 8,
        blackBlock: nil,
        compatibility: [.cgImage]
    )
}

private func makeBGR24Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .bgr24,
        name: "24BGR",
        components: [.rgb],
        componentRange: .full,
        bitsPerBlock: 24,
        bitsPerComponent: 8,
        blackBlock: [0, 0, 0],
        compatibility: []
    )
}

private func makeARGB32Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .argb32,
        name: "32ARGB",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 32,
        bitsPerComponent: 8,
        blackBlock: [255, 0, 0, 0],
        compatibility: [.cgBitmapContext, .cgImage]
    )
}

private func makeBGRA32Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .bgra32,
        name: "32BGRA",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 32,
        bitsPerComponent: 8,
        blackBlock: [0, 0, 0, 255],
        compatibility: [
            .cgBitmapContext,
            .cgImage,
            .ioSurfaceCoreAnimation,
            .metalTexture
        ]
    )
}

private func makeABGR32Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .abgr32,
        name: "32ABGR",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 32,
        bitsPerComponent: 8,
        blackBlock: [255, 0, 0, 0],
        compatibility: [.metalTexture]
    )
}

private func makeRGBA32Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .rgba32,
        name: "32RGBA",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 32,
        bitsPerComponent: 8,
        blackBlock: [0, 0, 0, 255],
        compatibility: [.metalTexture]
    )
}

private func makeARGB64BigEndianDescription() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .argb64BigEndian,
        name: "64ARGB",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 64,
        bitsPerComponent: 16,
        blackBlock: [255, 255, 0, 0, 0, 0, 0, 0],
        compatibility: []
    )
}

private func makeRGBA64LittleEndianDescription() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .rgba64LittleEndian,
        name: "64RGBALE",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 64,
        bitsPerComponent: 16,
        blackBlock: [0, 0, 0, 0, 0, 0, 255, 255],
        compatibility: [.metalTexture]
    )
}

private func makeRGB48BigEndianDescription() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .rgb48BigEndian,
        name: "48RGB",
        components: [.rgb],
        componentRange: .full,
        bitsPerBlock: 48,
        bitsPerComponent: 16,
        blackBlock: nil,
        compatibility: []
    )
}

private func makeAlphaGray32BigEndianDescription()
    -> CVPixelFormatDescription
{
    makePackedDescription(
        pixelFormat: .alphaGray32BigEndian,
        name: "32AlphaGray",
        components: [.alpha, .grayscale],
        componentRange: .full,
        bitsPerBlock: 32,
        bitsPerComponent: 16,
        blackBlock: [255, 255, 0, 0],
        compatibility: []
    )
}

private func makeGray16BigEndianDescription() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .gray16BigEndian,
        name: "16Gray",
        components: [.grayscale],
        componentRange: .full,
        bitsPerBlock: 16,
        bitsPerComponent: 16,
        blackBlock: nil,
        compatibility: []
    )
}

private func makeOneComponent8Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .oneComponent8,
        name: "OneComponent8",
        components: [.grayscale],
        componentRange: .full,
        bitsPerBlock: 8,
        bitsPerComponent: 8,
        blackBlock: nil,
        compatibility: [.cgBitmapContext, .cgImage, .metalTexture]
    )
}

private func makeTwoComponent8Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .twoComponent8,
        name: "TwoComponent8",
        components: [.generic],
        componentRange: nil,
        bitsPerBlock: 16,
        bitsPerComponent: 8,
        blackBlock: nil,
        compatibility: [.metalTexture]
    )
}

private func makeOneComponent10Description() -> CVPixelFormatDescription {
    makeOneComponentIntegerDescription(
        pixelFormat: .oneComponent10,
        name: "OneComponent10",
        bitsPerComponent: 10
    )
}

private func makeOneComponent12Description() -> CVPixelFormatDescription {
    makeOneComponentIntegerDescription(
        pixelFormat: .oneComponent12,
        name: "OneComponent12",
        bitsPerComponent: 12
    )
}

private func makeOneComponent16Description() -> CVPixelFormatDescription {
    makeOneComponentIntegerDescription(
        pixelFormat: .oneComponent16,
        name: "OneComponent16",
        bitsPerComponent: 16
    )
}

private func makeOneComponentIntegerDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    bitsPerComponent: Int
) -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: pixelFormat,
        name: name,
        components: [.grayscale],
        componentRange: .full,
        bitsPerBlock: 16,
        bitsPerComponent: bitsPerComponent,
        blackBlock: nil,
        compatibility: [.metalTexture]
    )
}

private func makeTwoComponent16Description() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .twoComponent16,
        name: "TwoComponent16",
        components: [.generic],
        componentRange: nil,
        bitsPerBlock: 32,
        bitsPerComponent: 16,
        blackBlock: nil,
        compatibility: [.metalTexture]
    )
}

private func makeOneComponent16HalfDescription()
    -> CVPixelFormatDescription
{
    makePackedDescription(
        pixelFormat: .oneComponent16Half,
        name: "OneComponent16Half",
        components: [.grayscale],
        componentRange: .full,
        bitsPerBlock: 16,
        bitsPerComponent: 16,
        blackBlock: nil,
        compatibility: [.metalTexture]
    )
}

private func makeOneComponent32FloatDescription()
    -> CVPixelFormatDescription
{
    makePackedDescription(
        pixelFormat: .oneComponent32Float,
        name: "OneComponent32Float",
        components: [.grayscale],
        componentRange: .full,
        bitsPerBlock: 32,
        bitsPerComponent: 32,
        blackBlock: nil,
        compatibility: [.cgBitmapContext, .cgImage, .metalTexture]
    )
}

private func makeTwoComponent16HalfDescription()
    -> CVPixelFormatDescription
{
    makePackedDescription(
        pixelFormat: .twoComponent16Half,
        name: "TwoComponent16Half",
        components: [.generic],
        componentRange: .full,
        bitsPerBlock: 32,
        bitsPerComponent: 16,
        blackBlock: nil,
        compatibility: [.metalTexture]
    )
}

private func makeTwoComponent32FloatDescription()
    -> CVPixelFormatDescription
{
    makePackedDescription(
        pixelFormat: .twoComponent32Float,
        name: "TwoComponent32Float",
        components: [.generic],
        componentRange: .full,
        bitsPerBlock: 64,
        bitsPerComponent: 32,
        blackBlock: nil,
        compatibility: [.metalTexture]
    )
}

private func makeRGBA64HalfDescription() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .rgba64Half,
        name: "64RGBAHalf",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 64,
        bitsPerComponent: 16,
        blackBlock: [0, 0, 0, 0, 0, 0, 0, 60],
        compatibility: [.ioSurfaceCoreAnimation, .metalTexture]
    )
}

private func makeRGBA128FloatDescription() -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: .rgba128Float,
        name: "128RGBAFloat",
        components: [.rgb, .alpha],
        componentRange: .full,
        bitsPerBlock: 128,
        bitsPerComponent: 32,
        blackBlock: [
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 0, 0,
            0, 0, 128, 63
        ],
        compatibility: [
            .cgBitmapContext,
            .cgImage,
            .ioSurfaceCoreAnimation,
            .metalTexture
        ]
    )
}

private func makeDisparity16HalfDescription() -> CVPixelFormatDescription {
    makeGenericScalarDescription(
        pixelFormat: .disparity16Half,
        name: "DisparityFloat16",
        bits: 16
    )
}

private func makeDisparity32FloatDescription() -> CVPixelFormatDescription {
    makeGenericScalarDescription(
        pixelFormat: .disparity32Float,
        name: "DisparityFloat32",
        bits: 32
    )
}

private func makeDepth16HalfDescription() -> CVPixelFormatDescription {
    makeGenericScalarDescription(
        pixelFormat: .depth16Half,
        name: "DepthFloat16",
        bits: 16
    )
}

private func makeDepth32FloatDescription() -> CVPixelFormatDescription {
    makeGenericScalarDescription(
        pixelFormat: .depth32Float,
        name: "DepthFloat32",
        bits: 32
    )
}

private func makeGenericScalarDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    bits: Int
) -> CVPixelFormatDescription {
    makePackedDescription(
        pixelFormat: pixelFormat,
        name: name,
        components: [.generic],
        componentRange: .full,
        bitsPerBlock: bits,
        bitsPerComponent: bits,
        blackBlock: nil,
        compatibility: [.metalTexture]
    )
}

private func makePackedDescription(
    pixelFormat: CVPixelFormatType,
    name: String,
    components: CVPixelFormatDescription.Components,
    componentRange: CVPixelFormatDescription.ComponentRange?,
    bitsPerBlock: Int,
    bitsPerComponent: Int,
    blackBlock: [UInt8]?,
    compatibility: CVPixelFormatDescription.Compatibility
) -> CVPixelFormatDescription {
    CVPixelFormatDescription(
        validatedPixelFormatType: pixelFormat,
        name: name,
        components: components,
        componentRange: componentRange,
        planeConfiguration: .nonPlanar(
            CVPixelFormatDescription.PixelLayout(
                validatedBlockSize: CVImageSize(width: 1, height: 1),
                bitsPerBlock: bitsPerBlock,
                bitsPerComponent: bitsPerComponent,
                blockAlignment: unitPixelFormatDimensions(),
                subsampling: unitPixelFormatDimensions(),
                blackBlock: blackBlock,
                compatibility: compatibility
            )
        )
    )
}

internal func unitPixelFormatDimensions()
    -> CVPixelFormatDescription.Dimensions
{
    CVPixelFormatDescription.Dimensions(horizontal: 1, vertical: 1)
}
