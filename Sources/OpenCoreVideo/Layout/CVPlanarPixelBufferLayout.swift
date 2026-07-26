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

        if let description = CVPixelFormatDescription.standardDescription(
            for: pixelFormat
        ) {
            guard case .planar(let pixelLayouts) =
                    description.planeConfiguration else {
                throw .pixelFormatRequiresPackedLayout(pixelFormat)
            }
            guard pixelLayouts.count == planes.count else {
                throw .planeCountMismatch(
                    expected: pixelLayouts.count,
                    actual: planes.count
                )
            }
            for index in planes.indices {
                let pixelLayout = pixelLayouts[index]
                let expectedWidth = try Self.roundedUpQuotient(
                    dimensions.width,
                    pixelLayout.subsampling.horizontal
                )
                let expectedHeight = try Self.roundedUpQuotient(
                    dimensions.height,
                    pixelLayout.subsampling.vertical
                )
                let bitsPerByte = 8
                guard pixelLayout.blockSize
                        == CVImageSize(width: 1, height: 1),
                      pixelLayout.bitsPerBlock.isMultiple(
                        of: bitsPerByte
                      ),
                      planes[index].dimensions.width == expectedWidth,
                      planes[index].dimensions.height == expectedHeight,
                      planes[index].bytesPerElement
                        == pixelLayout.bitsPerBlock / bitsPerByte else {
                    throw .pixelFormatPlaneLayoutMismatch(
                        format: pixelFormat,
                        plane: index
                    )
                }
            }
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

    private static func roundedUpQuotient(
        _ value: Int,
        _ divisor: Int
    ) throws(CVPixelBufferError) -> Int {
        let adjusted = value.addingReportingOverflow(divisor - 1)
        guard !adjusted.overflow else {
            throw .layoutOverflow
        }
        return adjusted.partialValue / divisor
    }
}
