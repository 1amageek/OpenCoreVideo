public final class CVBufferAttachments {
    private let values: CVStateLock<
        [CVAttachmentKey: CVBufferAttachment]
    >

    public init() {
        self.values = CVStateLock([:])
    }

    public func attachment(
        for key: CVAttachmentKey
    ) -> CVBufferAttachment? {
        values.withLock { values in
            values[key]
        }
    }

    public func attachments(
        for mode: CVAttachmentMode
    ) -> [CVAttachmentKey: CVAttachmentValue] {
        values.withLock { values in
            var matching: [CVAttachmentKey: CVAttachmentValue] = [:]
            matching.reserveCapacity(values.count)
            for (key, attachment) in values
            where attachment.mode == mode {
                matching[key] = attachment.value
            }
            return matching
        }
    }

    public func setAttachment(
        _ attachment: CVBufferAttachment,
        for key: CVAttachmentKey
    ) {
        values.withLock { values in
            values[key] = attachment
        }
    }

    public func setAttachments(
        _ attachments: [CVAttachmentKey: CVAttachmentValue],
        mode: CVAttachmentMode
    ) {
        values.withLock { values in
            for (key, value) in attachments {
                values[key] = CVBufferAttachment(
                    value: value,
                    mode: mode
                )
            }
        }
    }

    public func removeAttachment(for key: CVAttachmentKey) {
        _ = values.withLock { values in
            values.removeValue(forKey: key)
        }
    }

    public func removeAllAttachments() {
        values.withLock { values in
            values.removeAll(keepingCapacity: true)
        }
    }
}

/// Exports the conformance used by downstream Embedded generic specializations.
@export(interface)
extension CVBufferAttachments: CVBufferAttachmentStorage {}
