public protocol CVBuffer:
    AnyObject,
    CVPlatformConcurrencyContract
{
    associatedtype AttachmentStorage: CVBufferAttachmentStorage

    var attachments: AttachmentStorage { get }
}
