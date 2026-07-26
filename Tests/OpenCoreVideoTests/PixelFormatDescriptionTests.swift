import OpenCoreVideo
import Testing

@Suite("Pixel format descriptions")
struct PixelFormatDescriptionTests {
    @Test("Standard formats expose real component and plane layouts")
    func standardDescriptions() throws {
        let bgra = try #require(
            CVPixelFormatDescriptionCreateWithPixelFormatType(.bgra32)
        )
        #expect(bgra.name == "32BGRA")
        #expect(bgra.components == [.rgb, .alpha])
        #expect(bgra.componentRange == .full)
        guard case .nonPlanar(let bgraLayout) = bgra.planeConfiguration else {
            Issue.record("BGRA must be non-planar")
            return
        }
        #expect(bgraLayout.bitsPerBlock == 32)
        #expect(bgraLayout.bitsPerComponent == 8)
        #expect(bgraLayout.blackBlock == [0, 0, 0, 255])

        let videoRange = try #require(
            CVPixelFormatDescriptionCreateWithPixelFormatType(
                .yCbCr420BiPlanarVideoRange
            )
        )
        #expect(videoRange.components == [.yCbCr])
        #expect(videoRange.componentRange == .video)
        guard case .planar(let planes) = videoRange.planeConfiguration else {
            Issue.record("NV12 must be planar")
            return
        }
        #expect(planes.count == 2)
        #expect(planes[0].blackBlock == [16])
        #expect(planes[1].bitsPerBlock == 16)
        #expect(
            planes[1].subsampling
                == CVPixelFormatDescription.Dimensions(
                    horizontal: 2,
                    vertical: 2
                )
        )
        #expect(planes[1].blackBlock == [128, 128])
    }

    @Test("Registry replaces a description with the same format identifier")
    func replacement() throws {
        let registry = CVPixelFormatDescription.Registry()
        let first = try makeDescription(rawValue: 0x54535431, name: "First")
        let second = try makeDescription(rawValue: 0x54535431, name: "Second")

        registry.register(first)
        registry.register(second)

        #expect(registry.formatDescriptions.count == 1)
        #expect(registry[first.pixelFormatType]?.name == "Second")
    }

    @Test("Concurrent registration preserves every distinct format")
    func concurrentRegistration() async throws {
        let registry = CVPixelFormatDescription.Registry()
        let descriptions = try (0..<32).map { index in
            try makeDescription(
                rawValue: 0x7000_0000 + UInt32(index),
                name: "Format-\(index)"
            )
        }

        await withTaskGroup(of: Void.self) { group in
            for description in descriptions {
                group.addTask {
                    registry.register(description)
                }
            }
        }

        #expect(registry.formatDescriptions.count == descriptions.count)
        for description in descriptions {
            #expect(registry[description.pixelFormatType] == description)
        }
    }

    @Test("Invalid descriptions and mismatched registration fail")
    func failures() throws {
        #expect(throws: CVPixelFormatDescriptionError.invalidBitsPerBlock(0)) {
            try CVPixelFormatDescription.PixelLayout(bitsPerBlock: 0)
        }

        let description = try makeDescription(
            rawValue: 0x54535431,
            name: "Custom"
        )
        #expect(
            throws: CVPixelFormatDescriptionError.pixelFormatMismatch(
                description: description.pixelFormatType,
                registration: CVPixelFormatType(rawValue: 0x54535432)
            )
        ) {
            try CVPixelFormatDescriptionRegisterDescriptionWithPixelFormatType(
                description,
                CVPixelFormatType(rawValue: 0x54535432)
            )
        }
    }

    @Test("Known pixel formats reject semantically incompatible layouts")
    func layoutValidation() throws {
        let dimensions = try CVPixelDimensions(width: 4, height: 4)
        #expect(
            throws: CVPixelBufferError.pixelFormatBytesPerPixelMismatch(
                format: .bgra32,
                expected: 4,
                actual: 1
            )
        ) {
            try CVPackedPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .bgra32,
                bytesPerPixel: 1,
                bytesPerRow: 4
            )
        }

        #expect(
            throws: CVPixelBufferError.pixelFormatRequiresPlanarLayout(
                .yCbCr420BiPlanarVideoRange
            )
        ) {
            try CVPackedPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .yCbCr420BiPlanarVideoRange,
                bytesPerPixel: 1,
                bytesPerRow: 4
            )
        }

        let fullSizePlane = try CVPixelBufferPlaneLayout(
            dimensions: dimensions,
            bytesPerElement: 1,
            bytesPerRow: 4
        )
        #expect(
            throws: CVPixelBufferError.pixelFormatPlaneLayoutMismatch(
                format: .yCbCr420BiPlanarVideoRange,
                plane: 1
            )
        ) {
            try CVPlanarPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .yCbCr420BiPlanarVideoRange,
                planes: [fullSizePlane, fullSizePlane]
            )
        }
    }

    private func makeDescription(
        rawValue: UInt32,
        name: String
    ) throws -> CVPixelFormatDescription {
        try CVPixelFormatDescription(
            pixelFormatType: CVPixelFormatType(rawValue: rawValue),
            name: name,
            components: [.grayscale],
            componentRange: .full,
            planeConfiguration: .nonPlanar(
                CVPixelFormatDescription.PixelLayout(
                    bitsPerBlock: 8,
                    bitsPerComponent: 8
                )
            )
        )
    }
}
