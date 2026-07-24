public protocol CVBufferAttachmentStorage:
    CVPlatformConcurrencyContract
{
    func value(for key: CVAttachmentKey) -> CVAttachmentValue?
    func setValue(
        _ value: CVAttachmentValue,
        for key: CVAttachmentKey
    )
    func removeValue(for key: CVAttachmentKey)
}
