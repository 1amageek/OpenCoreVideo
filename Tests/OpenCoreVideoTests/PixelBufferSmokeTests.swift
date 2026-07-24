import OpenCoreVideo
import Synchronization
import Testing

@Suite("Packed pixel buffer smoke")
struct PixelBufferSmokeTests {
    @Test("Owned packed storage preserves layout and supports zero-copy mutation")
    func ownedPackedStorageRoundTrip() throws {
        let dimensions = try CVPixelDimensions(width: 4, height: 2)
        let buffer = try CVPackedPixelBuffer(
            dimensions: dimensions,
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 16
        )

        #expect(buffer.dimensions == dimensions)
        #expect(buffer.pixelFormat == .bgra32)
        #expect(buffer.bytesPerRow == 16)
        #expect(buffer.byteCount == 32)

        var writeAddress: UInt?
        try buffer.withWriteBytes { bytes in
            bytes[0] = 17
            bytes[31] = 99
            writeAddress = bytes.withUnsafeMutableBufferPointer { buffer in
                buffer.baseAddress.map { UInt(bitPattern: $0) }
            }
        }

        var values: (UInt8, UInt8) = (0, 0)
        var readAddress: UInt?
        try buffer.withReadBytes { bytes in
            values = (bytes[0], bytes[31])
            readAddress = bytes.withUnsafeBufferPointer { buffer in
                buffer.baseAddress.map { UInt(bitPattern: $0) }
            }
        }
        #expect(values.0 == 17)
        #expect(values.1 == 99)
        #expect(readAddress == writeAddress)
    }

    @Test("Invalid dimensions and packed layouts are typed failures")
    func invalidLayoutFailures() throws {
        #expect(throws: CVPixelBufferError.invalidDimensions(
            width: 0,
            height: 10
        )) {
            _ = try CVPixelDimensions(width: 0, height: 10)
        }

        let dimensions = try CVPixelDimensions(width: 4, height: 2)

        #expect(throws: CVPixelBufferError.invalidBytesPerRow(
            minimum: 16,
            actual: 15
        )) {
            _ = try CVPackedPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .bgra32,
                bytesPerPixel: 4,
                bytesPerRow: 15
            )
        }

        #expect(throws: CVPixelBufferError.invalidStorageSize(0)) {
            _ = try CVOwnedPixelBufferStorage<
                CVNoOpPixelBufferAccessCoordinator
            >(byteCount: 0)
        }
    }

    @Test("Read-only external storage rejects write access")
    func unsupportedWriteAccess() throws {
        let baseAddress = UnsafeMutableRawPointer.allocate(
            byteCount: 8,
            alignment: 8
        )
        let storage = try CVExternalPixelBufferStorage(
            baseAddress: baseAddress,
            byteCount: 8,
            accessCapabilities: [.read]
        ) { baseAddress, _ in
            baseAddress.deallocate()
        }
        let dimensions = try CVPixelDimensions(width: 2, height: 1)
        let layout = try CVPackedPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 8
        )
        let buffer = try CVPackedPixelBuffer(
            layout: layout,
            storage: storage
        )

        #expect(throws: CVPixelBufferError.unsupportedAccess(.write)) {
            try buffer.withWriteBytes { bytes in
                bytes[0] = 1
            }
        }
    }

    @Test("External storage identity is preserved across read and write")
    func externalStorageIsZeroCopy() throws {
        let baseAddress = UnsafeMutableRawPointer.allocate(
            byteCount: 8,
            alignment: 8
        )
        baseAddress.initializeMemory(
            as: UInt8.self,
            repeating: 0,
            count: 8
        )
        let expectedAddress = UInt(bitPattern: baseAddress)
        let storage = try CVExternalPixelBufferStorage(
            baseAddress: baseAddress,
            byteCount: 8,
            accessCapabilities: .readWrite
        ) { baseAddress, _ in
            baseAddress.deallocate()
        }
        let dimensions = try CVPixelDimensions(width: 2, height: 1)
        let layout = try CVPackedPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 8
        )
        let buffer = try CVPackedPixelBuffer(
            layout: layout,
            storage: storage
        )

        var writeAddress: UInt?
        try buffer.withWriteBytes { bytes in
            bytes[1] = 42
            writeAddress = bytes.withUnsafeMutableBufferPointer { buffer in
                buffer.baseAddress.map { UInt(bitPattern: $0) }
            }
        }
        #expect(writeAddress == expectedAddress)
        #expect(
            baseAddress.load(
                fromByteOffset: 1,
                as: UInt8.self
            ) == 42
        )

        baseAddress.storeBytes(
            of: UInt8(77),
            toByteOffset: 2,
            as: UInt8.self
        )
        var readAddress: UInt?
        var readValue: UInt8 = 0
        try buffer.withReadBytes { bytes in
            let address = bytes.withUnsafeBufferPointer { buffer in
                buffer.baseAddress.map { UInt(bitPattern: $0) }
            }
            readAddress = address
            readValue = bytes[2]
        }
        #expect(readAddress == expectedAddress)
        #expect(readValue == 77)
    }

    @Test("Access coordinator balances scopes and recovers after lock failure")
    func balancedAccessScopes() throws {
        let coordinator = AccessCoordinatorProbe()
        let dimensions = try CVPixelDimensions(width: 2, height: 1)
        let layout = try CVPackedPixelBufferLayout(
            dimensions: dimensions,
            pixelFormat: .bgra32,
            bytesPerPixel: 4,
            bytesPerRow: 8
        )
        let storage = try CVOwnedPixelBufferStorage(
            byteCount: layout.byteCount,
            accessCoordinator: coordinator
        )
        let buffer = try CVPackedPixelBuffer(
            layout: layout,
            storage: storage
        )

        try buffer.withReadBytes { _ in }

        try buffer.withReadBytes { _ in
            #expect(throws: CVPixelBufferError.accessConflict(.write)) {
                try buffer.withWriteBytes { _ in }
            }
        }

        coordinator.failNextLock = .write
        #expect(throws: CVPixelBufferError.accessConflict(.write)) {
            try buffer.withWriteBytes { _ in }
        }

        #expect(coordinator.events == [
            .lock(.read),
            .unlock(.read),
            .lock(.read),
            .unlock(.read),
            .lock(.write),
        ])

        try buffer.withWriteBytes { bytes in
            bytes[0] = 7
        }
        #expect(coordinator.events.suffix(2) == [
            .lock(.write),
            .unlock(.write),
        ])
    }

    @Test("External storage release handler runs exactly once")
    func externalReleaseRunsOnce() throws {
        let releaseCount = Mutex(0)

        do {
            let baseAddress = UnsafeMutableRawPointer.allocate(
                byteCount: 8,
                alignment: 8
            )
            let storage = try CVExternalPixelBufferStorage(
                baseAddress: baseAddress,
                byteCount: 8,
                accessCapabilities: .readWrite
            ) { baseAddress, _ in
                releaseCount.withLock { count in
                    count += 1
                }
                baseAddress.deallocate()
            }
            let dimensions = try CVPixelDimensions(width: 2, height: 1)
            let layout = try CVPackedPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .bgra32,
                bytesPerPixel: 4,
                bytesPerRow: 8
            )
            let buffer = try CVPackedPixelBuffer(
                layout: layout,
                storage: storage
            )

            try buffer.withWriteBytes { bytes in
                bytes[0] = 1
            }
        }

        #expect(releaseCount.withLock { $0 } == 1)
    }

    @Test("Attachments are stored independently from pixel bytes")
    func attachmentRoundTrip() {
        let attachments = CVBufferAttachments()
        let key = CVAttachmentKey(rawValue: "color-space")

        attachments.setValue(.string("display-p3"), for: key)
        #expect(attachments.value(for: key) == .string("display-p3"))

        attachments.removeValue(for: key)
        #expect(attachments.value(for: key) == nil)
    }
}

private enum AccessEvent: Sendable, Equatable {
    case lock(CVPixelBufferAccessMode)
    case unlock(CVPixelBufferAccessMode)
}

private final class AccessCoordinatorProbe:
    CVPixelBufferAccessCoordinator
{
    private struct State: Sendable {
        var events: [AccessEvent] = []
        var failNextLock: CVPixelBufferAccessMode?
    }

    private let state = Mutex(State())

    var events: [AccessEvent] {
        state.withLock { state in
            state.events
        }
    }

    var failNextLock: CVPixelBufferAccessMode? {
        get {
            state.withLock { state in
                state.failNextLock
            }
        }
        set {
            state.withLock { state in
                state.failNextLock = newValue
            }
        }
    }

    func lock(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) {
        let shouldFail = state.withLock { state in
            state.events.append(.lock(mode))
            if state.failNextLock == mode {
                state.failNextLock = nil
                return true
            }
            return false
        }
        if shouldFail {
            throw .accessConflict(mode)
        }
    }

    func unlock(_ mode: CVPixelBufferAccessMode) {
        state.withLock { state in
            state.events.append(.unlock(mode))
        }
    }
}
