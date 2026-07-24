import Testing
@testable import OpenCoreVideo

struct AttachmentPropagationTests {
    @Test("Attachment replacement changes value and propagation mode")
    func replacement() throws {
        let buffer = try makeBuffer()
        let key = CVAttachmentKey(rawValue: "color-space")

        CVBufferSetAttachment(
            buffer,
            key,
            .string("display-p3"),
            .shouldPropagate
        )
        CVBufferSetAttachment(
            buffer,
            key,
            .string("srgb"),
            .shouldNotPropagate
        )

        #expect(
            CVBufferCopyAttachment(buffer, key)
                == CVBufferAttachment(
                    value: .string("srgb"),
                    mode: .shouldNotPropagate
                )
        )
        #expect(
            CVBufferCopyAttachments(buffer, .shouldPropagate) == nil
        )
        #expect(
            CVBufferCopyAttachments(buffer, .shouldNotPropagate)
                == [key: .string("srgb")]
        )
    }

    @Test("Propagation copies only propagatable metadata")
    func propagation() throws {
        let source = try makeBuffer()
        let destination = try makeBuffer()
        let colorKey = CVAttachmentKey(rawValue: "color-space")
        let privateKey = CVAttachmentKey(rawValue: "capture-private")
        let destinationKey = CVAttachmentKey(rawValue: "destination")

        CVBufferSetAttachment(
            source,
            colorKey,
            .string("display-p3"),
            .shouldPropagate
        )
        CVBufferSetAttachment(
            source,
            privateKey,
            .boolean(true),
            .shouldNotPropagate
        )
        CVBufferSetAttachment(
            destination,
            destinationKey,
            .integer(7),
            .shouldNotPropagate
        )

        CVBufferPropagateAttachments(source, destination)

        #expect(
            CVBufferCopyAttachment(destination, colorKey)
                == CVBufferAttachment(
                    value: .string("display-p3"),
                    mode: .shouldPropagate
                )
        )
        #expect(
            CVBufferCopyAttachment(destination, privateKey) == nil
        )
        #expect(
            CVBufferCopyAttachment(destination, destinationKey)
                == CVBufferAttachment(
                    value: .integer(7),
                    mode: .shouldNotPropagate
                )
        )
    }

    @Test("Batch operations and remove all preserve mode filtering")
    func batchAndRemoveAll() throws {
        let buffer = try makeBuffer()
        let first = CVAttachmentKey(rawValue: "first")
        let second = CVAttachmentKey(rawValue: "second")

        CVBufferSetAttachments(
            buffer,
            [
                first: .integer(1),
                second: .integer(2),
            ],
            .shouldPropagate
        )

        #expect(
            CVBufferCopyAttachments(buffer, .shouldPropagate)
                == [
                    first: .integer(1),
                    second: .integer(2),
                ]
        )

        CVBufferRemoveAllAttachments(buffer)

        #expect(!CVBufferHasAttachment(buffer, first))
        #expect(!CVBufferHasAttachment(buffer, second))
    }

    private func makeBuffer() throws -> CVPackedPixelBuffer<
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
}
