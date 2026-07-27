import OpenCoreVideo
import Testing

@Suite("Image buffer geometry")
struct ImageBufferGeometryTests {
    @Test("Default geometry uses encoded dimensions and top-left origin")
    func defaultGeometry() throws {
        let buffer = try makeBuffer()

        #expect(
            CVImageBufferGetEncodedSize(buffer)
                == CVImageSize(width: 720, height: 480)
        )
        #expect(
            try CVImageBufferGetCleanRect(buffer)
                == CVImageRect(
                    x: 0,
                    y: 0,
                    width: 720,
                    height: 480
                )
        )
        #expect(
            try CVImageBufferGetDisplaySize(buffer)
                == CVImageFloatSize(width: 720, height: 480)
        )
        #expect(CVImageBufferIsFlipped(buffer))
    }

    @Test("Clean aperture and aspect ratio derive display geometry")
    func derivedGeometry() throws {
        let buffer = try makeBuffer()
        try CVImageBufferSetCleanAperture(
            buffer,
            CVImageCleanAperture(
                width: 704,
                height: 470,
                horizontalOffset: 8,
                verticalOffset: 3
            )
        )
        try CVImageBufferSetPixelAspectRatio(
            buffer,
            CVImagePixelAspectRatio(
                horizontalSpacing: 10,
                verticalSpacing: 11
            )
        )

        #expect(
            try CVImageBufferGetCleanRect(buffer)
                == CVImageRect(
                    x: 16,
                    y: 2,
                    width: 704,
                    height: 470
                )
        )
        #expect(
            try CVImageBufferGetDisplaySize(buffer)
                == CVImageFloatSize(width: 640, height: 470)
        )
    }

    @Test("Explicit display dimensions override derived dimensions")
    func explicitDisplaySize() throws {
        let buffer = try makeBuffer()
        try CVImageBufferSetPixelAspectRatio(
            buffer,
            CVImagePixelAspectRatio(
                horizontalSpacing: 10,
                verticalSpacing: 11
            )
        )
        try CVImageBufferSetDisplaySize(
            buffer,
            CVImageFloatSize(width: 123, height: 456)
        )

        #expect(
            try CVImageBufferGetDisplaySize(buffer)
                == CVImageFloatSize(width: 123, height: 456)
        )
    }

    @Test("Malformed geometry attachments fail explicitly")
    func malformedGeometry() throws {
        let buffer = try makeBuffer()
        CVBufferSetAttachment(
            buffer,
            kCVImageBufferCleanApertureKey,
            .dictionary([
                kCVImageBufferCleanApertureWidthKey: .floatingPoint(704)
            ]),
            .shouldPropagate
        )

        #expect(
            throws: CVPixelBufferError.malformedImageBufferAttachment(
                kCVImageBufferCleanApertureKey
            )
        ) {
            try CVImageBufferGetCleanRect(buffer)
        }
    }

    private func makeBuffer() throws -> CVPackedPixelBuffer {
        try CVPackedPixelBuffer(
            dimensions: CVPixelDimensions(width: 720, height: 480),
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 2_880
        )
    }
}
