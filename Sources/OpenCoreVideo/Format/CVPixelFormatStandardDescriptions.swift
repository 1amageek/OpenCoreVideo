extension CVPixelFormatDescription {
    internal static var standardDescriptions: [CVPixelFormatDescription] {
        makePackedStandardPixelFormatDescriptions()
            + makeBlockPackedStandardPixelFormatDescriptions()
            + makePlanarStandardPixelFormatDescriptions()
            + makeLegacyPlanarStandardPixelFormatDescriptions()
    }

    internal static func standardDescription(
        for pixelFormat: CVPixelFormatType
    ) -> CVPixelFormatDescription? {
        if let packed = makePackedStandardPixelFormatDescription(
            for: pixelFormat
        ) {
            return packed
        }
        if let blockPacked = makeBlockPackedStandardPixelFormatDescription(
            for: pixelFormat
        ) {
            return blockPacked
        }
        if let planar = makePlanarStandardPixelFormatDescription(
            for: pixelFormat
        ) {
            return planar
        }
        return makeLegacyPlanarStandardPixelFormatDescription(
            for: pixelFormat
        )
    }
}
