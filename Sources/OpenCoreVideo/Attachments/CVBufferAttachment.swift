public struct CVBufferAttachment: Sendable, Equatable {
    public let value: CVAttachmentValue
    public let mode: CVAttachmentMode

    public init(
        value: CVAttachmentValue,
        mode: CVAttachmentMode
    ) {
        self.value = value
        self.mode = mode
    }
}
