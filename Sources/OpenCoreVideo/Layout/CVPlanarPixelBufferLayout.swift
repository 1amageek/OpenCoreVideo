public struct CVPlanarPixelBufferLayout: Sendable, Hashable {
    public let dimensions: CVPixelDimensions
    public let pixelFormat: CVPixelFormatType
    public let planes: [CVPixelBufferPlaneLayout]
    public let byteCount: Int
    public let coveringBytesPerRow: Int

    public init(
        dimensions: CVPixelDimensions,
        pixelFormat: CVPixelFormatType,
        planes: [CVPixelBufferPlaneLayout]
    ) throws(CVPixelBufferError) {
        guard pixelFormat.rawValue != 0 else {
            throw .invalidPixelFormat(pixelFormat.rawValue)
        }
        guard !planes.isEmpty else {
            throw .invalidPlaneCount(planes.count)
        }

        var byteCount = 0
        for plane in planes {
            guard
                plane.dimensions.width <= dimensions.width,
                plane.dimensions.height <= dimensions.height
            else {
                throw .planeDimensionsExceedImage(
                    plane: plane.dimensions,
                    image: dimensions
                )
            }

            let total = byteCount.addingReportingOverflow(plane.byteCount)
            guard !total.overflow else {
                throw .layoutOverflow
            }
            byteCount = total.partialValue
        }

        let quotient = byteCount / dimensions.height
        let remainder = byteCount % dimensions.height
        let coveringBytesPerRow = quotient + (remainder == 0 ? 0 : 1)

        self.dimensions = dimensions
        self.pixelFormat = pixelFormat
        self.planes = planes
        self.byteCount = byteCount
        self.coveringBytesPerRow = coveringBytesPerRow
    }
}
