import OpenCoreVideo
import Synchronization

@main
private enum OpenCoreVideoRuntimeSmoke {
    static func main() {
        verifyHostClock()
        verifyOwnedStorage()
        verifyBlockPackedBuffer()

        let attachments = CVBufferAttachments()
        let key = CVAttachmentKey(rawValue: "runtime-smoke")
        let attachment = CVBufferAttachment(
            value: .integer(42),
            mode: .shouldPropagate
        )
        let replacement = CVBufferAttachment(
            value: .integer(84),
            mode: .shouldPropagate
        )
        let copiedKey = CVAttachmentKey(rawValue: "runtime-smoke-copied")

        attachments.setAttachment(attachment, for: key)
        guard attachments.attachment(for: key) == attachment else {
            fatalError("Attachment mutation failed")
        }

        attachments.setAttachment(replacement, for: key)
        guard attachments.attachment(for: key) == replacement else {
            fatalError("Attachment replacement failed")
        }

        print("OpenCoreVideo runtime smoke: single mutation PASS")
        let singleSnapshot = attachments.attachments(
            for: .shouldPropagate
        )
        guard singleSnapshot[key] == .integer(84) else {
            fatalError("Single attachment snapshot failed")
        }
        print("OpenCoreVideo runtime smoke: single snapshot PASS")
        let copiedAttachments = attachmentInput(
            key: copiedKey,
            value: .string("copied")
        )
        print("OpenCoreVideo runtime smoke: batch input PASS")
        attachments.setAttachments(
            copiedAttachments,
            mode: .shouldPropagate
        )
        print("OpenCoreVideo runtime smoke: batch mutation PASS")
        let propagated = attachments.attachments(
            for: .shouldPropagate
        )
        print("OpenCoreVideo runtime smoke: snapshot materialization PASS")
        guard propagated[key] == .integer(84),
              propagated[copiedKey] == .string("copied") else {
            fatalError("Attachment snapshot failed")
        }

        attachments.removeAttachment(for: key)
        guard attachments.attachment(for: key) == nil else {
            fatalError("Attachment removal failed")
        }

        attachments.removeAllAttachments()
        guard attachments.attachment(for: copiedKey) == nil,
              attachments.attachments(for: .shouldPropagate).isEmpty else {
            fatalError("Attachment remove-all failed")
        }

        print("OpenCoreVideo runtime smoke: PASS")
    }

    private static func verifyOwnedStorage() {
        do {
            let coordinator = RuntimeAccessCoordinator()
            do {
                let storage = try CVOwnedPixelBufferStorage(
                    byteCount: 4,
                    alignment: 16,
                    accessCoordinator: coordinator
                )
                try storage.withWriteAccess { bytes in
                    bytes[0] = 41
                }
                try storage.withReadAccess { bytes in
                    guard bytes[0] == 41 else {
                        fatalError("Owned storage round trip failed")
                    }
                }
            }
            guard coordinator.counts == (locks: 2, unlocks: 2) else {
                fatalError("Owned storage coordinator became unbalanced")
            }
            print("OpenCoreVideo runtime smoke: owned storage PASS")

            let releaseCounter = RuntimeReleaseCounter()
            let baseAddress = UnsafeMutableRawPointer.allocate(
                byteCount: 4,
                alignment: 4
            )
            baseAddress.initializeMemory(
                as: UInt8.self,
                repeating: 0,
                count: 4
            )
            do {
                let storage = try CVExternalPixelBufferStorage(
                    baseAddress: baseAddress,
                    byteCount: 4,
                    accessCapabilities: .readWrite,
                    accessCoordinator: coordinator
                ) { baseAddress, _ in
                    baseAddress.deallocate()
                    releaseCounter.increment()
                }
                try storage.withWriteAccess { bytes in
                    bytes[3] = 73
                }
                try storage.withReadAccess { bytes in
                    guard bytes[3] == 73 else {
                        fatalError("External storage round trip failed")
                    }
                }
            }
            guard releaseCounter.value == 1 else {
                fatalError("External storage release was not exactly once")
            }
            print("OpenCoreVideo runtime smoke: external storage PASS")

            let dimensions = try CVPixelDimensions(width: 1, height: 1)
            let layout = try CVPackedPixelBufferLayout(
                dimensions: dimensions,
                pixelFormat: .bgra32,
                bytesPerPixel: 4,
                bytesPerRow: 4
            )
            let customStorage = try RuntimePackedStorage(byteCount: 4)
            let customBuffer = try CVPackedPixelBuffer(
                layout: layout,
                storage: customStorage
            )
            try customBuffer.withWriteBytes { bytes in
                bytes[1] = 29
            }
            try customBuffer.withReadBytes { bytes in
                guard bytes[1] == 29 else {
                    fatalError("Custom packed storage round trip failed")
                }
            }
            print("OpenCoreVideo runtime smoke: custom packed storage PASS")
        } catch {
            fatalError("Owned storage setup failed: \(error)")
        }
    }

    private static func verifyBlockPackedBuffer() {
        do {
            let dimensions = try CVPixelDimensions(width: 13, height: 2)
            let blockLayout = try CVPixelBufferBlockLayout(
                blockSize: CVImageSize(width: 6, height: 1),
                bytesPerBlock: 16,
                blockAlignment: .init(horizontal: 8, vertical: 1)
            )
            let buffer = try CVPackedPixelBuffer(
                dimensions: dimensions,
                pixelFormat: .yCbCr422Packed10,
                blockLayout: blockLayout,
                bytesPerRow: 128
            )
            print("OpenCoreVideo runtime smoke: block-packed construction PASS")

            guard buffer.byteCount == 256 else {
                fatalError("Block-packed byte count is incorrect")
            }
            try buffer.withWriteBytes { bytes in
                bytes[0] = 17
                bytes[255] = 99
            }
            print("OpenCoreVideo runtime smoke: block-packed write PASS")

            var endpoints: (UInt8, UInt8) = (0, 0)
            try buffer.withReadBytes { bytes in
                endpoints = (bytes[0], bytes[255])
            }
            print("OpenCoreVideo runtime smoke: block-packed read PASS")
            guard endpoints == (17, 99) else {
                fatalError("Block-packed zero-copy round trip failed")
            }

            print("OpenCoreVideo runtime smoke: block-packed buffer PASS")
        } catch {
            fatalError("Block-packed buffer setup failed: \(error)")
        }
    }

    private static func verifyHostClock() {
        #if hasFeature(Embedded)
        do {
            try CVHostClockProvider.system.install(RuntimeSmokeHostClock())
        } catch {
            fatalError("Embedded host clock installation failed: \(error)")
        }
        #endif

        let first = CVGetCurrentHostTime()
        let second = CVGetCurrentHostTime()

        guard second >= first else {
            fatalError("Host time moved backwards")
        }
        guard CVGetHostClockFrequency() == 1_000_000_000 else {
            fatalError("Host clock frequency does not match its timebase")
        }
        guard CVGetHostClockMinimumTimeDelta() == 1 else {
            fatalError("Host clock minimum time delta is invalid")
        }

        print("OpenCoreVideo runtime smoke: host clock PASS")
    }

    // The pinned Swift 6.4 regular-WASI optimizer miscompiles construction of
    // this exact public Dictionary input before OpenCoreVideo receives it.
    @_optimize(none)
    private static func attachmentInput(
        key: CVAttachmentKey,
        value: CVAttachmentValue
    ) -> [CVAttachmentKey: CVAttachmentValue] {
        Dictionary(uniqueKeysWithValues: [(key, value)])
    }
}

private final class RuntimePackedStorage: CVPixelBufferStorage {
    let byteCount: Int
    let accessCapabilities: CVPixelBufferAccessCapabilities = .readWrite

    private let storage: CVOwnedPixelBufferStorage

    init(byteCount: Int) throws(CVPixelBufferError) {
        storage = try CVOwnedPixelBufferStorage(byteCount: byteCount)
        self.byteCount = byteCount
    }

    func withReadAccess(
        _ body: (borrowing Span<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withReadAccess(body)
    }

    func withWriteAccess(
        _ body: (inout MutableSpan<UInt8>) -> Void
    ) throws(CVPixelBufferError) {
        try storage.withWriteAccess(body)
    }
}

private final class RuntimeReleaseCounter: Sendable {
    private let count = Mutex(0)

    var value: Int {
        count.withLock { $0 }
    }

    func increment() {
        count.withLock { count in
            count += 1
        }
    }
}

private final class RuntimeAccessCoordinator:
    CVPixelBufferAccessCoordinator
{
    private struct State: Sendable {
        var locks = 0
        var unlocks = 0
    }

    private let state = Mutex(State())

    var counts: (locks: Int, unlocks: Int) {
        state.withLock { state in
            (locks: state.locks, unlocks: state.unlocks)
        }
    }

    func lock(
        _ mode: CVPixelBufferAccessMode
    ) throws(CVPixelBufferError) {
        state.withLock { state in
            state.locks += 1
        }
    }

    func unlock(_ mode: CVPixelBufferAccessMode) {
        state.withLock { state in
            state.unlocks += 1
        }
    }
}

#if hasFeature(Embedded)
private final class RuntimeSmokeHostClock: CVHostClock, Sendable {
    let frequency: Double = 1_000_000_000
    let minimumTimeDelta: UInt32 = 1

    private let time = Mutex<UInt64>(0)

    func currentHostTime() -> UInt64 {
        time.withLock { time in
            time += 1
            return time
        }
    }
}
#endif
