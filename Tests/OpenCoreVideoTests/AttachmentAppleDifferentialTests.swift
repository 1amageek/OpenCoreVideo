#if canImport(CoreFoundation) && canImport(CoreVideo)
import CoreFoundation
import CoreVideo
import Testing
@testable import OpenCoreVideo

struct AttachmentAppleDifferentialTests {
    @Test("Attachment replacement and propagation match Apple Core Video")
    func replacementAndPropagation() throws {
        let appleSource = try makeAppleBuffer()
        let appleDestination = try makeAppleBuffer()
        let portableSource = try makePortableBuffer()
        let portableDestination = try makePortableBuffer()
        let appleKey = try makeString("color-space")
        let firstAppleValue = try makeString("display-p3")
        let secondAppleValue = try makeString("srgb")
        let portableKey = CVAttachmentKey(rawValue: "color-space")
        let propagatedAppleKey = try makeString("transfer-function")
        let propagatedAppleValue = try makeString("linear")
        let propagatedPortableKey = CVAttachmentKey(
            rawValue: "transfer-function"
        )

        CoreVideo.CVBufferSetAttachment(
            appleSource,
            appleKey,
            firstAppleValue,
            .shouldPropagate
        )
        CoreVideo.CVBufferSetAttachment(
            appleSource,
            appleKey,
            secondAppleValue,
            .shouldNotPropagate
        )
        CVBufferSetAttachment(
            portableSource,
            portableKey,
            .string("display-p3"),
            .shouldPropagate
        )
        CVBufferSetAttachment(
            portableSource,
            portableKey,
            .string("srgb"),
            .shouldNotPropagate
        )
        CoreVideo.CVBufferSetAttachment(
            appleSource,
            propagatedAppleKey,
            propagatedAppleValue,
            .shouldPropagate
        )
        CVBufferSetAttachment(
            portableSource,
            propagatedPortableKey,
            .string("linear"),
            .shouldPropagate
        )

        var appleMode = CoreVideo.CVAttachmentMode.shouldPropagate
        let appleValue = CoreVideo.CVBufferCopyAttachment(
            appleSource,
            appleKey,
            &appleMode
        )
        let portableValue = CVBufferCopyAttachment(
            portableSource,
            portableKey
        )

        #expect(appleMode == .shouldNotPropagate)
        #expect(
            appleValue.map { CFEqual($0, secondAppleValue) } == true
        )
        #expect(
            portableValue
                == CVBufferAttachment(
                    value: .string("srgb"),
                    mode: .shouldNotPropagate
                )
        )

        CoreVideo.CVBufferPropagateAttachments(
            appleSource,
            appleDestination
        )
        CVBufferPropagateAttachments(
            portableSource,
            portableDestination
        )

        #expect(
            CoreVideo.CVBufferHasAttachment(
                appleDestination,
                appleKey
            ) == false
        )
        #expect(
            CVBufferHasAttachment(
                portableDestination,
                portableKey
            ) == false
        )

        var propagatedAppleMode =
            CoreVideo.CVAttachmentMode.shouldNotPropagate
        let propagatedDestinationValue =
            CoreVideo.CVBufferCopyAttachment(
                appleDestination,
                propagatedAppleKey,
                &propagatedAppleMode
            )
        #expect(propagatedAppleMode == .shouldPropagate)
        #expect(
            propagatedDestinationValue.map {
                CFEqual($0, propagatedAppleValue)
            } == true
        )
        #expect(
            CVBufferCopyAttachment(
                portableDestination,
                propagatedPortableKey
            )
                == CVBufferAttachment(
                    value: .string("linear"),
                    mode: .shouldPropagate
                )
        )
    }

    private func makeAppleBuffer() throws -> CoreVideo.CVPixelBuffer {
        var buffer: CoreVideo.CVPixelBuffer?
        let status = CoreVideo.CVPixelBufferCreate(
            nil,
            1,
            1,
            kCVPixelFormatType_32BGRA,
            nil,
            &buffer
        )
        guard status == kCVReturnSuccess, let buffer else {
            throw AppleAttachmentFixtureError.pixelBufferCreation(status)
        }
        return buffer
    }

    private func makePortableBuffer() throws -> CVPackedPixelBuffer<
        CVOwnedPixelBufferStorage<
            CVNoOpPixelBufferAccessCoordinator
        >,
        CVBufferAttachments
    > {
        let dimensions = try CVPixelDimensions(width: 1, height: 1)
        let layout = try CVPackedPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 4
        )
        return try CVPackedPixelBuffer(
            layout: layout,
            storage: try CVOwnedPixelBufferStorage(byteCount: 4)
        )
    }

    private func makeString(_ value: StaticString) throws -> CFString {
        guard
            let string = CFStringCreateWithCString(
                nil,
                value.utf8Start,
                CFStringBuiltInEncodings.UTF8.rawValue
            )
        else {
            throw AppleAttachmentFixtureError.stringCreation
        }
        return string
    }
}

private enum AppleAttachmentFixtureError: Error {
    case pixelBufferCreation(CVReturn)
    case stringCreation
}
#endif
