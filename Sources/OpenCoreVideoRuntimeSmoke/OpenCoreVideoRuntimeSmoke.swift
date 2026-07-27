import OpenCoreVideo
import Synchronization

@main
private enum OpenCoreVideoRuntimeSmoke {
    static func main() {
        verifyHostClock()

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
