import Testing
@testable import OpenCoreVideo

struct AttachmentPropagationTests {
    @Test("Recursive property-list attachment values preserve structure")
    func recursivePropertyListValues() {
        let value = CVAttachmentValue.dictionary([
            "nested": .array([
                .boolean(true),
                .integer(7),
                .string("camera"),
            ])
        ])

        #expect(
            value == .dictionary([
                "nested": .array([
                    .boolean(true),
                    .integer(7),
                    .string("camera"),
                ])
            ])
        )
    }

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

    @Test("Concurrent attachment updates preserve distinct keys")
    func concurrentUpdates() async {
        let attachments = CVBufferAttachments()
        let updateCount = 64

        await withTaskGroup(of: Void.self) { group in
            for index in 0..<updateCount {
                group.addTask {
                    attachments.setAttachment(
                        CVBufferAttachment(
                            value: .integer(Int64(index)),
                            mode: .shouldPropagate
                        ),
                        for: CVAttachmentKey(
                            rawValue: "concurrent-\(index)"
                        )
                    )
                }
            }
        }

        let snapshot = attachments.attachments(
            for: .shouldPropagate
        )
        #expect(snapshot.count == updateCount)
        for index in 0..<updateCount {
            #expect(
                snapshot[
                    CVAttachmentKey(rawValue: "concurrent-\(index)")
                ] == .integer(Int64(index))
            )
        }
    }

    private func makeBuffer() throws -> CVPackedPixelBuffer {
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
