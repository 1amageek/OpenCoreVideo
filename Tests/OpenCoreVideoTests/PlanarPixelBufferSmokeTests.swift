import OpenCoreVideo
import Synchronization
import Testing

@Suite("Planar pixel buffer smoke")
struct PlanarPixelBufferSmokeTests {
    typealias OwnedBuffer = CVPlanarPixelBuffer<
        CVOwnedPixelBufferStorage<
            CVNoOpPixelBufferAccessCoordinator
        >,
        CVBufferAttachments
    >

    typealias ExternalBuffer = CVPlanarPixelBuffer<
        CVExternalPixelBufferStorage<
            CVNoOpPixelBufferAccessCoordinator
        >,
        CVBufferAttachments
    >

    @Test("Owned planar storage exposes independent zero-copy planes")
    func ownedPlanarStorageRoundTrip() throws {
        let layout = try makeBiPlanarLayout()
        let buffer = try OwnedBuffer(layout: layout)

        #expect(buffer.isPlanar)
        #expect(buffer.planeCount == 2)
        #expect(buffer.byteCount == 24)
        #expect(buffer.bytesPerRow == 6)
        #expect(CVPixelBufferGetPlaneCount(buffer) == 2)
        #expect(try CVPixelBufferGetWidthOfPlane(buffer, 0) == 4)
        #expect(try CVPixelBufferGetHeightOfPlane(buffer, 1) == 2)
        #expect(
            try CVPixelBufferGetBytesPerRowOfPlane(buffer, 1) == 4
        )
        #expect(
            try buffer.dimensionsOfPlane(at: 0)
                == CVPixelDimensions(width: 4, height: 4)
        )
        #expect(try buffer.bytesPerRowOfPlane(at: 1) == 4)

        var writeAddress: UInt?
        try buffer.withWriteBytes(ofPlane: 1) { bytes in
            bytes[0] = 41
            bytes[7] = 99
            writeAddress = bytes.withUnsafeMutableBufferPointer { buffer in
                buffer.baseAddress.map { UInt(bitPattern: $0) }
            }
        }

        var readAddress: UInt?
        var values: (UInt8, UInt8) = (0, 0)
        try buffer.withReadBytes(ofPlane: 1) { bytes in
            values = (bytes[0], bytes[7])
            readAddress = bytes.withUnsafeBufferPointer { buffer in
                buffer.baseAddress.map { UInt(bitPattern: $0) }
            }
        }

        #expect(writeAddress == readAddress)
        #expect(values.0 == 41)
        #expect(values.1 == 99)
    }

    @Test("External plane addresses are preserved and released once each")
    func externalPlanarStorageIsZeroCopy() throws {
        let layout = try makeBiPlanarLayout()
        let lumaAddress = UnsafeMutableRawPointer.allocate(
            byteCount: 16,
            alignment: 8
        )
        let chromaAddress = UnsafeMutableRawPointer.allocate(
            byteCount: 8,
            alignment: 8
        )
        lumaAddress.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: 16
        )
        chromaAddress.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: 8
        )

        let expectedLumaAddress = UInt(bitPattern: lumaAddress)
        let expectedChromaAddress = UInt(bitPattern: chromaAddress)
        let releaseCounts = Mutex([0, 0])

        do {
            let buffer = try ExternalBuffer(
                layout: layout,
                planeBaseAddresses: [lumaAddress, chromaAddress],
                accessCapabilities: .readWrite
            ) { index, baseAddress, _ in
                releaseCounts.withLock { counts in
                    counts[index] += 1
                }
                baseAddress.deallocate()
            }

            var borrowedLumaAddress: UInt?
            try buffer.withWriteBytes(ofPlane: 0) { bytes in
                bytes[3] = 27
                borrowedLumaAddress =
                    bytes.withUnsafeMutableBufferPointer { buffer in
                        buffer.baseAddress.map { UInt(bitPattern: $0) }
                    }
            }
            #expect(borrowedLumaAddress == expectedLumaAddress)
            #expect(
                lumaAddress.load(
                    fromByteOffset: 3,
                    as: UInt8.self
                ) == 27
            )

            chromaAddress.storeBytes(
                of: UInt8(73),
                toByteOffset: 2,
                as: UInt8.self
            )
            var borrowedChromaAddress: UInt?
            var chromaValue: UInt8 = 0
            try buffer.withReadBytes(ofPlane: 1) { bytes in
                borrowedChromaAddress =
                    bytes.withUnsafeBufferPointer { buffer in
                        buffer.baseAddress.map { UInt(bitPattern: $0) }
                    }
                chromaValue = bytes[2]
            }
            #expect(borrowedChromaAddress == expectedChromaAddress)
            #expect(chromaValue == 73)
        }

        #expect(releaseCounts.withLock { $0 } == [1, 1])
    }

    @Test("Planar layout rejects overflow and oversized planes")
    func planarLayoutValidation() throws {
        let imageDimensions = try CVPixelDimensions(width: 4, height: 2)
        let oversizedDimensions = try CVPixelDimensions(
            width: 5,
            height: 2
        )
        let oversizedPlane = try CVPixelBufferPlaneLayout(
            dimensions: oversizedDimensions,
            bytesPerElement: 1,
            bytesPerRow: 5
        )

        #expect(throws: CVPixelBufferError.planeDimensionsExceedImage(
            plane: oversizedDimensions,
            image: imageDimensions
        )) {
            _ = try CVPlanarPixelBufferLayout(
                dimensions: imageDimensions,
                pixelFormat: .yCbCr420BiPlanarVideoRange,
                planes: [oversizedPlane]
            )
        }

        let tallDimensions = try CVPixelDimensions(width: 1, height: 2)
        #expect(throws: CVPixelBufferError.layoutOverflow) {
            _ = try CVPixelBufferPlaneLayout(
                dimensions: tallDimensions,
                bytesPerElement: 1,
                bytesPerRow: .max
            )
        }
    }

    @Test("Invalid plane range and insufficient storage are typed failures")
    func planeRangeAndStorageValidation() throws {
        let layout = try makeSinglePlaneLayout()
        let storage = try CVOwnedPixelBufferStorage<
            CVNoOpPixelBufferAccessCoordinator
        >(byteCount: 4)

        #expect(throws: CVPixelBufferError.planeStorageTooSmall(
            plane: 0,
            required: 8,
            actual: 4
        )) {
            _ = try OwnedBuffer(
                layout: layout,
                planeStorages: [storage]
            )
        }

        let validBuffer = try OwnedBuffer(layout: layout)
        #expect(throws: CVPixelBufferError.invalidPlaneIndex(
            index: 1,
            planeCount: 1
        )) {
            _ = try validBuffer.dimensionsOfPlane(at: 1)
        }
        #expect(throws: CVPixelBufferError.planarBufferRequiresPlaneAccess) {
            try validBuffer.withReadBytes { _ in }
        }

        let packedBuffer = try CVPackedPixelBuffer(
            dimensions: CVPixelDimensions(width: 2, height: 1),
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 8
        )
        #expect(CVPixelBufferGetPlaneCount(packedBuffer) == 0)
    }

    @Test("External planes reject overlapping and overflowing ranges")
    func externalPlaneRangeValidation() throws {
        let layout = try makeOverlappingRangeLayout()
        let baseAddress = UnsafeMutableRawPointer.allocate(
            byteCount: 16,
            alignment: 8
        )

        #expect(throws: CVPixelBufferError.overlappingPlaneStorage(
            first: 0,
            second: 1
        )) {
            _ = try ExternalBuffer(
                layout: layout,
                planeBaseAddresses: [
                    baseAddress,
                    baseAddress.advanced(by: 4),
                ],
                accessCapabilities: .readWrite
            ) { _, _, _ in
                Issue.record("Ownership must not transfer after validation failure")
            }
        }
        baseAddress.deallocate()

        guard
            let overflowingAddress = UnsafeMutableRawPointer(
                bitPattern: UInt.max - 3
            )
        else {
            Issue.record("Could not form an address for range validation")
            return
        }

        let singlePlaneLayout = try makeSinglePlaneLayout()
        #expect(throws: CVPixelBufferError.planeAddressRangeOverflow(
            plane: 0
        )) {
            _ = try ExternalBuffer(
                layout: singlePlaneLayout,
                planeBaseAddresses: [overflowingAddress],
                accessCapabilities: .readWrite
            ) { _, _, _ in
                Issue.record("Ownership must not transfer after validation failure")
            }
        }
    }

    @Test("Buffer-wide access state prevents cross-plane write conflicts")
    func crossPlaneAccessConflict() throws {
        let buffer = try OwnedBuffer(layout: makeBiPlanarLayout())

        try buffer.withReadBytes(ofPlane: 0) { _ in
            #expect(throws: CVPixelBufferError.accessConflict(.write)) {
                try buffer.withWriteBytes(ofPlane: 1) { _ in }
            }
        }

        try buffer.withWriteBytes(ofPlane: 1) { bytes in
            bytes[0] = 5
        }
    }

    private func makeBiPlanarLayout()
        throws -> CVPlanarPixelBufferLayout
    {
        let imageDimensions = try CVPixelDimensions(width: 4, height: 4)
        let luma = try CVPixelBufferPlaneLayout(
            dimensions: imageDimensions,
            bytesPerElement: 1,
            bytesPerRow: 4
        )
        let chroma = try CVPixelBufferPlaneLayout(
            dimensions: CVPixelDimensions(width: 2, height: 2),
            bytesPerElement: 2,
            bytesPerRow: 4
        )
        return try CVPlanarPixelBufferLayout(
            dimensions: imageDimensions,
            pixelFormat: .yCbCr420BiPlanarVideoRange,
            planes: [luma, chroma]
        )
    }

    private func makeSinglePlaneLayout()
        throws -> CVPlanarPixelBufferLayout
    {
        let dimensions = try CVPixelDimensions(width: 4, height: 2)
        let plane = try CVPixelBufferPlaneLayout(
            dimensions: dimensions,
            bytesPerElement: 1,
            bytesPerRow: 4
        )
        return try CVPlanarPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: CVPixelFormatType(rawValue: 0x5030_3031),
            planes: [plane]
        )
    }

    private func makeOverlappingRangeLayout()
        throws -> CVPlanarPixelBufferLayout
    {
        let dimensions = try CVPixelDimensions(width: 4, height: 2)
        let plane = try CVPixelBufferPlaneLayout(
            dimensions: dimensions,
            bytesPerElement: 1,
            bytesPerRow: 4
        )
        return try CVPlanarPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: CVPixelFormatType(rawValue: 0x5030_3032),
            planes: [plane, plane]
        )
    }
}
