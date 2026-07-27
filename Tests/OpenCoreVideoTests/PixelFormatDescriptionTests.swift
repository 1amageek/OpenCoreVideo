import OpenCoreVideo
import Testing

@Suite("Pixel format descriptions")
struct PixelFormatDescriptionTests {
    @Test("Standard formats expose real component and plane layouts")
    func standardDescriptions() throws {
        let registeredTypes =
            CVPixelFormatDescriptionArrayCreateWithAllPixelFormatTypes()
        #expect(registeredTypes.count == 74)
        #expect(Set(registeredTypes).count == registeredTypes.count)

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

        let rgbaFloat = try #require(
            CVPixelFormatDescriptionCreateWithPixelFormatType(.rgba128Float)
        )
        guard case .nonPlanar(let rgbaFloatLayout) =
                rgbaFloat.planeConfiguration else {
            Issue.record("RGBA float must be non-planar")
            return
        }
        #expect(rgbaFloatLayout.bitsPerBlock == 128)
        #expect(rgbaFloatLayout.bitsPerComponent == 32)
        #expect(
            rgbaFloatLayout.blackBlock
                == [
                    0, 0, 0, 0,
                    0, 0, 0, 0,
                    0, 0, 0, 0,
                    0, 0, 128, 63
                ]
        )

        let alphaPlanar = try #require(
            CVPixelFormatDescriptionCreateWithPixelFormatType(
                .yCbCr444VideoRangeWithAlphaTriPlanar16
            )
        )
        guard case .planar(let alphaPlanes) =
                alphaPlanar.planeConfiguration else {
            Issue.record("YCbCr alpha format must be planar")
            return
        }
        #expect(alphaPlanes.count == 3)
        #expect(alphaPlanes[2].blackBlock == [255, 255])

        let v210 = try #require(
            CVPixelFormatDescriptionCreateWithPixelFormatType(
                .yCbCr422Packed10
            )
        )
        guard case .nonPlanar(let v210Layout) =
                v210.planeConfiguration else {
            Issue.record("v210 must be non-planar")
            return
        }
        #expect(v210Layout.blockSize == CVImageSize(width: 6, height: 1))
        #expect(v210Layout.bitsPerBlock == 128)
        #expect(v210Layout.blockAlignment.horizontal == 8)
        #expect(v210Layout.subsampling.horizontal == 2)

        let packedBayer = try #require(
            CVPixelFormatDescriptionCreateWithPixelFormatType(
                .versatileBayerPacked12
            )
        )
        #expect(packedBayer.components == [.senselArray])
        guard case .nonPlanar(let bayerLayout) =
                packedBayer.planeConfiguration else {
            Issue.record("Packed Bayer must be non-planar")
            return
        }
        #expect(bayerLayout.blockSize == CVImageSize(width: 8, height: 1))
        #expect(bayerLayout.bitsPerBlock == 96)
        #expect(bayerLayout.bitsPerComponent == 12)
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
        #expect(
            throws: CVPixelFormatDescriptionError
                .bitsPerBlockNotByteAligned(1)
        ) {
            try CVPixelFormatDescription.PixelLayout(
                blockSize: CVImageSize(width: 8, height: 1),
                bitsPerBlock: 1
            )
        }
        #expect(
            throws: CVPixelFormatDescriptionError.invalidBlackBlockByteCount(
                expected: 2,
                actual: 1
            )
        ) {
            try CVPixelFormatDescription.PixelLayout(
                bitsPerBlock: 16,
                blackBlock: [0]
            )
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

    @Test("Block layouts preserve fractional pixels and row alignment")
    func blockLayout() throws {
        let v210Dimensions = try CVPixelDimensions(width: 13, height: 2)
        let v210Block = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 6, height: 1),
            bytesPerBlock: 16,
            blockAlignment: .init(horizontal: 8, vertical: 1)
        )
        let v210 = try CVPackedPixelBufferLayout(
            dimensions: v210Dimensions,
            pixelFormat: .yCbCr422Packed10,
            blockLayout: v210Block,
            bytesPerRow: 128
        )
        #expect(v210.bytesPerPixel == nil)
        #expect(v210.byteCount == 256)

        let bayerDimensions = try CVPixelDimensions(width: 9, height: 3)
        let bayerBlock = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 8, height: 1),
            bytesPerBlock: 12
        )
        let bayer = try CVPackedPixelBufferLayout(
            dimensions: bayerDimensions,
            pixelFormat: .versatileBayerPacked12,
            blockLayout: bayerBlock,
            bytesPerRow: 24
        )
        #expect(bayer.byteCount == 72)

        let subByte = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 8, height: 1),
            bytesPerBlock: 1
        )
        #expect(try subByte.minimumBytesPerRow(for: bayerDimensions) == 2)

        let twoDimensionalBlock = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 2, height: 2),
            bytesPerBlock: 3,
            blockAlignment: .init(horizontal: 4, vertical: 2)
        )
        let smallDimensions = try CVPixelDimensions(width: 3, height: 3)
        #expect(
            try twoDimensionalBlock.minimumBytesPerRow(
                for: smallDimensions
            ) == 12
        )
        #expect(
            try twoDimensionalBlock.storageRowCount(
                for: smallDimensions
            ) == 2
        )
    }

    @Test("Block layout failures remain typed")
    func blockLayoutFailures() throws {
        #expect(
            throws: CVPixelBufferError.invalidBlockSize(.zero)
        ) {
            try CVPixelBufferBlockLayout(
                blockSize: .zero,
                bytesPerBlock: 1
            )
        }
        #expect(
            throws: CVPixelBufferError.invalidBytesPerBlock(0)
        ) {
            try CVPixelBufferBlockLayout(
                blockSize: CVImageSize(width: 1, height: 1),
                bytesPerBlock: 0
            )
        }
        #expect(
            throws: CVPixelBufferError.invalidBlockAlignment(
                .init(horizontal: 0, vertical: 1)
            )
        ) {
            try CVPixelBufferBlockLayout(
                blockSize: CVImageSize(width: 1, height: 1),
                bytesPerBlock: 1,
                blockAlignment: .init(horizontal: 0, vertical: 1)
            )
        }

        let dimensions = try CVPixelDimensions(width: 13, height: 1)
        let wrongV210Block = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 1, height: 1),
            bytesPerBlock: 4
        )
        #expect(
            throws: CVPixelBufferError.pixelFormatPlaneLayoutMismatch(
                format: .yCbCr422Packed10,
                plane: 0
            )
        ) {
            try CVPackedPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .yCbCr422Packed10,
                blockLayout: wrongV210Block,
                bytesPerRow: 52
            )
        }

        let v210Block = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 6, height: 1),
            bytesPerBlock: 16,
            blockAlignment: .init(horizontal: 8, vertical: 1)
        )
        #expect(
            throws: CVPixelBufferError.invalidBytesPerRow(
                minimum: 128,
                actual: 127
            )
        ) {
            try CVPackedPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .yCbCr422Packed10,
                blockLayout: v210Block,
                bytesPerRow: 127
            )
        }

        let overflowingBlock = try CVPixelBufferBlockLayout(
            blockSize: CVImageSize(width: 1, height: 1),
            bytesPerBlock: .max
        )
        let overflowingDimensions = try CVPixelDimensions(
            width: 2,
            height: 1
        )
        #expect(throws: CVPixelBufferError.layoutOverflow) {
            try overflowingBlock.minimumBytesPerRow(
                for: overflowingDimensions
            )
        }
    }

    @Test("Block-packed planes validate against planar format descriptions")
    func blockPackedPlane() throws {
        let dimensions = try CVPixelDimensions(width: 5, height: 2)
        let packedYCbCr = try CVPixelBufferPlaneLayout(
            dimensions: dimensions,
            blockLayout: CVPixelBufferBlockLayout(
                blockSize: CVImageSize(width: 2, height: 1),
                bytesPerBlock: 4
            ),
            bytesPerRow: 12
        )
        let alpha = try CVPixelBufferPlaneLayout(
            dimensions: dimensions,
            bytesPerElement: 1,
            bytesPerRow: 5
        )
        let layout = try CVPlanarPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: .yCbCr422WithAlphaBiPlanar,
            planes: [packedYCbCr, alpha]
        )

        #expect(layout.byteCount == 34)
        #expect(layout.planes[0].bytesPerElement == nil)
        #expect(layout.planes[1].bytesPerElement == 1)
    }

    @Test("Pixel format identifiers use printable FourCC representations")
    func fourCharacterCode() {
        #expect(
            OpenCoreVideo.CVPixelFormatTypeCopyFourCharCodeString(.bgra32)
                == "BGRA"
        )
        #expect(
            OpenCoreVideo.CVPixelFormatTypeCopyFourCharCodeString(.rgb24)
                == "24"
        )
        #expect(
            OpenCoreVideo.CVPixelFormatTypeCopyFourCharCodeString(
                OpenCoreVideo.CVPixelFormatType(rawValue: 0x4142_2720)
            ) == "AB' "
        )
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

        let oneComponent10 = try CVPackedPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: .oneComponent10,
            bytesPerPixel: 2,
            bytesPerRow: 8
        )
        #expect(oneComponent10.byteCount == 32)

        let oddDimensions = try CVPixelDimensions(width: 5, height: 3)
        let luma10 = try CVPixelBufferPlaneLayout(
            dimensions: oddDimensions,
            bytesPerElement: 2,
            bytesPerRow: 10
        )
        let chroma10 = try CVPixelBufferPlaneLayout(
            dimensions: CVPixelDimensions(width: 3, height: 2),
            bytesPerElement: 4,
            bytesPerRow: 12
        )
        let p010 = try CVPlanarPixelBufferLayout(
            dimensions: oddDimensions,
            pixelFormat: .yCbCr420BiPlanar10VideoRange,
            planes: [luma10, chroma10]
        )
        #expect(p010.byteCount == 54)

        let invalidChroma10 = try CVPixelBufferPlaneLayout(
            dimensions: CVPixelDimensions(width: 3, height: 2),
            bytesPerElement: 2,
            bytesPerRow: 6
        )
        #expect(
            throws: CVPixelBufferError.pixelFormatPlaneLayoutMismatch(
                format: .yCbCr420BiPlanar10VideoRange,
                plane: 1
            )
        ) {
            try CVPlanarPixelBufferLayout(
                dimensions: oddDimensions,
                pixelFormat: .yCbCr420BiPlanar10VideoRange,
                planes: [luma10, invalidChroma10]
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
