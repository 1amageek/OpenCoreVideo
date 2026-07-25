public final class CVBufferAttachments {
    private struct Entry: Sendable {
        let key: CVAttachmentKey
        var attachment: CVBufferAttachment
    }

    private struct State: Sendable {
        var generation: UInt64 = 0
        var entries: [Entry] = []
    }

    private struct Snapshot: Sendable {
        let generation: UInt64
        let entries: [Entry]
    }

    private let state: CVStateLock<State>

    public init() {
        self.state = CVStateLock(State())
    }

    public func attachment(
        for key: CVAttachmentKey
    ) -> CVBufferAttachment? {
        let entries = snapshot().entries
        for entry in entries where entry.key == key {
            return entry.attachment
        }
        return nil
    }

    public func attachments(
        for mode: CVAttachmentMode
    ) -> [CVAttachmentKey: CVAttachmentValue] {
        let entries = snapshot().entries
        var matching: [(CVAttachmentKey, CVAttachmentValue)] = []
        matching.reserveCapacity(entries.count)
        for entry in entries where entry.attachment.mode == mode {
            matching.append(
                (entry.key, entry.attachment.value)
            )
        }
        // Attachment dictionaries are small metadata snapshots. The tuple
        // array avoids the regular-WASI Dictionary subscript metadata bug;
        // this conversion never touches pixel or binary attachment bytes.
        return Self.materializeDictionary(matching)
    }

    public func setAttachment(
        _ attachment: CVBufferAttachment,
        for key: CVAttachmentKey
    ) {
        replaceEntries { entries in
            Self.setAttachment(
                attachment,
                for: key,
                in: &entries
            )
        }
    }

    public func setAttachments(
        _ attachments: [CVAttachmentKey: CVAttachmentValue],
        mode: CVAttachmentMode
    ) {
        var updates: [Entry] = []
        updates.reserveCapacity(attachments.count)
        var attachmentIndex = attachments.startIndex
        while attachmentIndex != attachments.endIndex {
            let (key, value) = attachments[attachmentIndex]
            updates.append(
                Entry(
                    key: key,
                    attachment: CVBufferAttachment(
                        value: value,
                        mode: mode
                    )
                )
            )
            attachments.formIndex(after: &attachmentIndex)
        }

        replaceEntries { entries in
            for update in updates {
                Self.setAttachment(
                    update.attachment,
                    for: update.key,
                    in: &entries
                )
            }
        }
    }

    public func removeAttachment(for key: CVAttachmentKey) {
        replaceEntries { entries in
            for index in entries.indices where entries[index].key == key {
                entries.remove(at: index)
                return
            }
        }
    }

    public func removeAllAttachments() {
        replaceEntries { entries in
            entries.removeAll(keepingCapacity: true)
        }
    }

    private func snapshot() -> Snapshot {
        state.withLock { state in
            Snapshot(
                generation: state.generation,
                entries: state.entries
            )
        }
    }

    private func replaceEntries(
        _ mutation: ([Entry]) -> [Entry]
    ) {
        while true {
            let snapshot = snapshot()
            let replacement = mutation(snapshot.entries)
            let didReplace = state.withLock { state in
                guard state.generation == snapshot.generation else {
                    return false
                }
                state.entries = replacement
                state.generation &+= 1
                return true
            }
            if didReplace {
                return
            }
        }
    }

    private func replaceEntries(
        _ mutation: (inout [Entry]) -> Void
    ) {
        replaceEntries { entries in
            var replacement = entries
            mutation(&replacement)
            return replacement
        }
    }

    private static func setAttachment(
        _ attachment: CVBufferAttachment,
        for key: CVAttachmentKey,
        in entries: inout [Entry]
    ) {
        for index in entries.indices where entries[index].key == key {
            entries[index].attachment = attachment
            return
        }
        entries.append(Entry(key: key, attachment: attachment))
    }

    // The pinned Swift 6.4 regular-WASI optimizer miscompiles this exact
    // Dictionary storage allocation. Keep only the metadata materialization
    // boundary unoptimized; attachment lookup and pixel paths remain optimized.
    @_optimize(none)
    private static func materializeDictionary(
        _ entries: [(CVAttachmentKey, CVAttachmentValue)]
    ) -> [CVAttachmentKey: CVAttachmentValue] {
        Dictionary(uniqueKeysWithValues: entries)
    }
}

/// Exports the conformance used by downstream Embedded generic specializations.
@export(interface)
extension CVBufferAttachments: CVBufferAttachmentStorage {}
