public final class CVBufferAttachments:
    CVBufferAttachmentStorage
{
    private let values: CVStateLock<
        [CVAttachmentKey: CVAttachmentValue]
    >

    public init() {
        self.values = CVStateLock([:])
    }

    public func value(
        for key: CVAttachmentKey
    ) -> CVAttachmentValue? {
        values.withLock { values in
            values[key]
        }
    }

    public func setValue(
        _ value: CVAttachmentValue,
        for key: CVAttachmentKey
    ) {
        values.withLock { values in
            values[key] = value
        }
    }

    public func removeValue(for key: CVAttachmentKey) {
        _ = values.withLock { values in
            values.removeValue(forKey: key)
        }
    }
}
