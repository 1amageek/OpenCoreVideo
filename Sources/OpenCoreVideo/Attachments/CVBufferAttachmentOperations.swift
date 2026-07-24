public func CVBufferHasAttachment<Buffer: CVBuffer>(
    _ buffer: borrowing Buffer,
    _ key: CVAttachmentKey
) -> Bool {
    buffer.attachments.attachment(for: key) != nil
}

public func CVBufferCopyAttachment<Buffer: CVBuffer>(
    _ buffer: borrowing Buffer,
    _ key: CVAttachmentKey
) -> CVBufferAttachment? {
    buffer.attachments.attachment(for: key)
}

public func CVBufferCopyAttachments<Buffer: CVBuffer>(
    _ buffer: borrowing Buffer,
    _ mode: CVAttachmentMode
) -> [CVAttachmentKey: CVAttachmentValue]? {
    let values = buffer.attachments.attachments(for: mode)
    return values.isEmpty ? nil : values
}

public func CVBufferSetAttachment<Buffer: CVBuffer>(
    _ buffer: borrowing Buffer,
    _ key: CVAttachmentKey,
    _ value: CVAttachmentValue,
    _ mode: CVAttachmentMode
) {
    buffer.attachments.setAttachment(
        CVBufferAttachment(value: value, mode: mode),
        for: key
    )
}

public func CVBufferSetAttachments<Buffer: CVBuffer>(
    _ buffer: borrowing Buffer,
    _ values: [CVAttachmentKey: CVAttachmentValue],
    _ mode: CVAttachmentMode
) {
    buffer.attachments.setAttachments(values, mode: mode)
}

public func CVBufferRemoveAttachment<Buffer: CVBuffer>(
    _ buffer: borrowing Buffer,
    _ key: CVAttachmentKey
) {
    buffer.attachments.removeAttachment(for: key)
}

public func CVBufferRemoveAllAttachments<Buffer: CVBuffer>(
    _ buffer: borrowing Buffer
) {
    buffer.attachments.removeAllAttachments()
}

public func CVBufferPropagateAttachments<
    Source: CVBuffer,
    Destination: CVBuffer
>(
    _ source: borrowing Source,
    _ destination: borrowing Destination
) {
    let propagated = source.attachments.attachments(
        for: .shouldPropagate
    )
    destination.attachments.setAttachments(
        propagated,
        mode: .shouldPropagate
    )
}
