public protocol CVBufferAttachmentStorage:
    CVPlatformConcurrencyContract
{
    func attachment(
        for key: CVAttachmentKey
    ) -> CVBufferAttachment?
    func attachments(
        for mode: CVAttachmentMode
    ) -> [CVAttachmentKey: CVAttachmentValue]
    func setAttachment(
        _ attachment: CVBufferAttachment,
        for key: CVAttachmentKey
    )
    func setAttachments(
        _ attachments: [CVAttachmentKey: CVAttachmentValue],
        mode: CVAttachmentMode
    )
    func removeAttachment(for key: CVAttachmentKey)
    func removeAllAttachments()
}
