import OpenCoreVideo
import Synchronization
import Testing

@Suite("Binary attachments")
struct BinaryAttachmentTests {
    @Test("Empty binary attachment lends an empty span")
    func emptyBinaryAttachment() throws {
        let attachment = CVBinaryAttachment()
        var observedCount = -1

        try attachment.withReadBytes { bytes in
            observedCount = bytes.count
        }

        #expect(attachment.byteCount == 0)
        #expect(observedCount == 0)
    }

    @Test("Binary bytes retain their original storage without copying")
    func zeroCopyBorrow() throws {
        let releaseCount = Mutex(0)
        let baseAddress = UnsafeMutableRawPointer.allocate(
            byteCount: 8,
            alignment: 8
        )
        baseAddress.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: 8
        )
        baseAddress.storeBytes(
            of: UInt8(73),
            toByteOffset: 3,
            as: UInt8.self
        )
        let expectedAddress = UInt(bitPattern: baseAddress)

        do {
            let binary = try CVBinaryAttachment(
                baseAddress: baseAddress,
                byteCount: 8
            ) { baseAddress, _ in
                releaseCount.withLock { $0 += 1 }
                baseAddress.deallocate()
            }

            var borrowedAddress: UInt?
            var value: UInt8 = 0
            try binary.withReadBytes { bytes in
                borrowedAddress =
                    bytes.withUnsafeBufferPointer { pointer in
                        pointer.baseAddress.map { UInt(bitPattern: $0) }
                    }
                value = bytes[3]
            }
            #expect(borrowedAddress == expectedAddress)
            #expect(value == 73)
            #expect(releaseCount.withLock { $0 } == 0)
        }

        #expect(releaseCount.withLock { $0 } == 1)
    }

    @Test("Attachment propagation shares one retained binary owner")
    func propagationRetainsOwner() throws {
        let releaseCount = Mutex(0)
        let baseAddress = UnsafeMutableRawPointer.allocate(
            byteCount: 4,
            alignment: 4
        )
        var binary: CVBinaryAttachment? = try CVBinaryAttachment(
            baseAddress: baseAddress,
            byteCount: 4
        ) { baseAddress, _ in
            releaseCount.withLock { $0 += 1 }
            baseAddress.deallocate()
        }
        let key = CVAttachmentKey(rawValue: "calibration")

        do {
            let source = try makeBuffer()
            let destination = try makeBuffer()
            CVBufferSetAttachment(
                source,
                key,
                .binary(try #require(binary)),
                .shouldPropagate
            )
            CVBufferPropagateAttachments(source, destination)
            binary = nil

            guard
                case let .binary(propagated)? =
                    CVBufferCopyAttachment(destination, key)?.value
            else {
                Issue.record("Expected a propagated binary attachment")
                return
            }
            guard
                case let .binary(sourceBinary)? =
                    CVBufferCopyAttachment(source, key)?.value
            else {
                Issue.record("Expected a source binary attachment")
                return
            }
            #expect(propagated === sourceBinary)
            #expect(releaseCount.withLock { $0 } == 0)
        }

        #expect(releaseCount.withLock { $0 } == 1)
    }

    private func makeBuffer() throws -> CVPackedPixelBuffer<
        CVOwnedPixelBufferStorage<
            CVNoOpPixelBufferAccessCoordinator
        >,
        CVBufferAttachments
    > {
        try CVPackedPixelBuffer(
            dimensions: CVPixelDimensions(width: 1, height: 1),
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 4
        )
    }
}
