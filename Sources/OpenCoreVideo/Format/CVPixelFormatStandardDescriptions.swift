extension CVPixelFormatDescription {
    internal static var standardDescriptions: [CVPixelFormatDescription] {
        makePackedStandardPixelFormatDescriptions()
            + makePlanarStandardPixelFormatDescriptions()
    }

    internal static func standardDescription(
        for pixelFormat: CVPixelFormatType
    ) -> CVPixelFormatDescription? {
        if let packed = makePackedStandardPixelFormatDescription(
            for: pixelFormat
        ) {
            return packed
        }
        return makePlanarStandardPixelFormatDescription(
            for: pixelFormat
        )
    }
}
