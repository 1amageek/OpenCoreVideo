#if canImport(CoreVideo) && canImport(Foundation)
import CoreVideo
import Foundation
import OpenCoreVideo
import Testing

@Suite("Apple pixel buffer differential")
struct PixelBufferAppleDifferentialTests {
    @Test("Packed metadata and scoped mutation match Core Video")
    func packedBufferBehavior() throws {
        let apple = try makeApplePixelBuffer(
            width: 3,
            height: 2,
            pixelFormat: kCVPixelFormatType_32BGRA
        )
        let appleBytesPerRow = CoreVideo.CVPixelBufferGetBytesPerRow(
            apple
        )
        let portable = try CVPackedPixelBuffer(
            dimensions: CVPixelDimensions(width: 3, height: 2),
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: appleBytesPerRow
        )

        #expect(
            CoreVideo.CVPixelBufferGetWidth(apple)
                == portable.dimensions.width
        )
        #expect(
            CoreVideo.CVPixelBufferGetHeight(apple)
                == portable.dimensions.height
        )
        #expect(
            CoreVideo.CVPixelBufferGetPixelFormatType(apple)
                == portable.pixelFormat.rawValue
        )
        #expect(appleBytesPerRow == portable.bytesPerRow)

        let lockStatus = CoreVideo.CVPixelBufferLockBaseAddress(
            apple,
            []
        )
        guard
            lockStatus == CoreVideo.kCVReturnSuccess,
            let appleAddress =
                CoreVideo.CVPixelBufferGetBaseAddress(apple)
        else {
            throw ApplePixelBufferFixtureError.lock(lockStatus)
        }
        appleAddress.storeBytes(
            of: UInt8(47),
            toByteOffset: 1,
            as: UInt8.self
        )
        let unlockStatus = CoreVideo.CVPixelBufferUnlockBaseAddress(
            apple,
            []
        )
        guard unlockStatus == CoreVideo.kCVReturnSuccess else {
            throw ApplePixelBufferFixtureError.unlock(unlockStatus)
        }

        try portable.withWriteBytes { bytes in
            bytes[1] = 47
        }
        var portableValue: UInt8 = 0
        try portable.withReadBytes { bytes in
            portableValue = bytes[1]
        }
        #expect(portableValue == 47)
    }

    @Test("Bi-planar metadata matches Core Video")
    func planarMetadata() throws {
        let apple = try makeApplePixelBuffer(
            width: 4,
            height: 4,
            pixelFormat:
                kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange
        )
        let imageDimensions = try CVPixelDimensions(
            width: 4,
            height: 4
        )
        let portableLayout = try CVPlanarPixelBufferLayout(
            dimensions: imageDimensions,
            pixelFormat: .yCbCr420BiPlanarVideoRange,
            planes: [
                CVPixelBufferPlaneLayout(
                    dimensions: imageDimensions,
                    bytesPerElement: 1,
                    bytesPerRow:
                        CoreVideo.CVPixelBufferGetBytesPerRowOfPlane(
                            apple,
                            0
                        )
                ),
                CVPixelBufferPlaneLayout(
                    dimensions: CVPixelDimensions(width: 2, height: 2),
                    bytesPerElement: 2,
                    bytesPerRow:
                        CoreVideo.CVPixelBufferGetBytesPerRowOfPlane(
                            apple,
                            1
                        )
                ),
            ]
        )
        let portable = try CVPlanarPixelBuffer(
            layout: portableLayout
        )

        #expect(
            CoreVideo.CVPixelBufferGetPlaneCount(apple)
                == CVPixelBufferGetPlaneCount(portable)
        )
        for index in 0..<portable.planeCount {
            let portableDimensions = try portable.dimensionsOfPlane(
                at: index
            )
            let portableBytesPerRow =
                try portable.bytesPerRowOfPlane(at: index)
            #expect(
                CoreVideo.CVPixelBufferGetWidthOfPlane(apple, index)
                    == portableDimensions.width
            )
            #expect(
                CoreVideo.CVPixelBufferGetHeightOfPlane(apple, index)
                    == portableDimensions.height
            )
            #expect(
                CoreVideo.CVPixelBufferGetBytesPerRowOfPlane(
                    apple,
                    index
                ) == portableBytesPerRow
            )
        }
    }

    @Test("Allocation threshold and reuse match Core Video")
    func poolThreshold() throws {
        #expect(
            CoreVideo.CVPixelBufferPoolFlushFlags.excessBuffers.rawValue
                == OpenCoreVideo.CVPixelBufferPoolFlushFlags
                .excessBuffers.rawValue
        )
        let applePool = try makeApplePool()
        let auxiliaryAttributes = [
            kCVPixelBufferPoolAllocationThresholdKey: 1
        ] as CFDictionary

        var appleFirst: CoreVideo.CVPixelBuffer?
        let firstStatus =
            CoreVideo.CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
                nil,
                applePool,
                auxiliaryAttributes,
                &appleFirst
            )
        #expect(firstStatus == CoreVideo.kCVReturnSuccess)
        #expect(appleFirst != nil)

        var appleBlocked: CoreVideo.CVPixelBuffer?
        let blockedStatus =
            CoreVideo.CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
                nil,
                applePool,
                auxiliaryAttributes,
                &appleBlocked
            )
        #expect(
            blockedStatus
                == CoreVideo.kCVReturnWouldExceedAllocationThreshold
        )
        #expect(appleBlocked == nil)

        appleFirst = nil
        var appleReused: CoreVideo.CVPixelBuffer?
        let reusedStatus =
            CoreVideo.CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
                nil,
                applePool,
                auxiliaryAttributes,
                &appleReused
            )
        #expect(reusedStatus == CoreVideo.kCVReturnSuccess)
        #expect(appleReused != nil)

        let portablePool = try CVPixelBufferPool(
            layout: CVPackedPixelBufferLayout(
                dimensions: CVPixelDimensions(width: 2, height: 1),
                pixelFormat: .bgra32,
                bytesPerPixel: 4,
                bytesPerRow: 8
            )
        )
        var portableFirst: CVPackedPixelBuffer? =
            try portablePool.makePixelBuffer(allocationThreshold: 1)
        #expect(portableFirst != nil)
        #expect(throws: CVPixelBufferError
            .wouldExceedAllocationThreshold(1)) {
            _ = try portablePool.makePixelBuffer(
                allocationThreshold: 1
            )
        }
        portableFirst = nil
        _ = try
            OpenCoreVideo
            .CVPixelBufferPoolCreatePixelBufferWithAuxAttributes(
                portablePool,
                allocationThreshold: 1
            )
    }

    private func makeApplePixelBuffer(
        width: Int,
        height: Int,
        pixelFormat: OSType
    ) throws -> CoreVideo.CVPixelBuffer {
        var buffer: CoreVideo.CVPixelBuffer?
        let status = CoreVideo.CVPixelBufferCreate(
            nil,
            width,
            height,
            pixelFormat,
            nil,
            &buffer
        )
        guard status == CoreVideo.kCVReturnSuccess, let buffer else {
            throw ApplePixelBufferFixtureError.creation(status)
        }
        return buffer
    }

    private func makeApplePool() throws -> CoreVideo.CVPixelBufferPool {
        let pixelBufferAttributes = [
            kCVPixelBufferWidthKey: 2,
            kCVPixelBufferHeightKey: 1,
            kCVPixelBufferPixelFormatTypeKey:
                kCVPixelFormatType_32BGRA,
        ] as CFDictionary
        var pool: CoreVideo.CVPixelBufferPool?
        let status = CoreVideo.CVPixelBufferPoolCreate(
            nil,
            nil,
            pixelBufferAttributes,
            &pool
        )
        guard status == CoreVideo.kCVReturnSuccess, let pool else {
            throw ApplePixelBufferFixtureError.poolCreation(status)
        }
        return pool
    }
}

private enum ApplePixelBufferFixtureError: Error {
    case creation(CVReturn)
    case lock(CVReturn)
    case unlock(CVReturn)
    case poolCreation(CVReturn)
}
#endif
