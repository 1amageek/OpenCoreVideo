#if canImport(CoreVideo) && canImport(Foundation)
import CoreVideo
import Foundation
import OpenCoreVideo
import Testing

@Suite("Apple image geometry differential")
struct ImageBufferGeometryAppleDifferentialTests {
    @Test("Clean rect and display size match Core Video")
    func geometry() throws {
        var appleBuffer: CoreVideo.CVPixelBuffer?
        let status = CoreVideo.CVPixelBufferCreate(
            nil,
            720,
            480,
            kCVPixelFormatType_32BGRA,
            nil,
            &appleBuffer
        )
        guard status == CoreVideo.kCVReturnSuccess, let appleBuffer else {
            throw ImageBufferGeometryFixtureError.creation(status)
        }
        let portable = try makePortableBuffer()

        CoreVideo.CVBufferSetAttachment(
            appleBuffer,
            CoreVideo.kCVImageBufferCleanApertureKey,
            [
                CoreVideo.kCVImageBufferCleanApertureWidthKey: 704.0,
                CoreVideo.kCVImageBufferCleanApertureHeightKey: 470.0,
                CoreVideo.kCVImageBufferCleanApertureHorizontalOffsetKey: 8.0,
                CoreVideo.kCVImageBufferCleanApertureVerticalOffsetKey: 3.0
            ] as CFDictionary,
            .shouldPropagate
        )
        CoreVideo.CVBufferSetAttachment(
            appleBuffer,
            CoreVideo.kCVImageBufferPixelAspectRatioKey,
            [
                CoreVideo.kCVImageBufferPixelAspectRatioHorizontalSpacingKey: 10,
                CoreVideo.kCVImageBufferPixelAspectRatioVerticalSpacingKey: 11
            ] as CFDictionary,
            .shouldPropagate
        )
        try OpenCoreVideo.CVImageBufferSetCleanAperture(
            portable,
            OpenCoreVideo.CVImageCleanAperture(
                width: 704,
                height: 470,
                horizontalOffset: 8,
                verticalOffset: 3
            )
        )
        try OpenCoreVideo.CVImageBufferSetPixelAspectRatio(
            portable,
            OpenCoreVideo.CVImagePixelAspectRatio(
                horizontalSpacing: 10,
                verticalSpacing: 11
            )
        )

        let appleCleanRect = CoreVideo.CVImageBufferGetCleanRect(
            appleBuffer
        )
        let portableCleanRect = try OpenCoreVideo.CVImageBufferGetCleanRect(
            portable
        )
        #expect(Double(appleCleanRect.origin.x) == portableCleanRect.x)
        #expect(Double(appleCleanRect.origin.y) == portableCleanRect.y)
        #expect(Double(appleCleanRect.width) == portableCleanRect.width)
        #expect(Double(appleCleanRect.height) == portableCleanRect.height)

        let appleDisplaySize = CoreVideo.CVImageBufferGetDisplaySize(
            appleBuffer
        )
        let portableDisplaySize = try OpenCoreVideo.CVImageBufferGetDisplaySize(
            portable
        )
        #expect(Double(appleDisplaySize.width) == portableDisplaySize.width)
        #expect(Double(appleDisplaySize.height) == portableDisplaySize.height)
        #expect(
            CoreVideo.CVImageBufferIsFlipped(appleBuffer)
                == OpenCoreVideo.CVImageBufferIsFlipped(portable)
        )
    }

    private func makePortableBuffer() throws -> CVPackedPixelBuffer<
        CVOwnedPixelBufferStorage<CVNoOpPixelBufferAccessCoordinator>,
        CVBufferAttachments
    > {
        try CVPackedPixelBuffer(
            dimensions: CVPixelDimensions(width: 720, height: 480),
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 2_880
        )
    }
}

private enum ImageBufferGeometryFixtureError: Error {
    case creation(CVReturn)
}
#endif
