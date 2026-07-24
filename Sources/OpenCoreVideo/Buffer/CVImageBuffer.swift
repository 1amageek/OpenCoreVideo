public protocol CVImageBuffer:
    AnyObject,
    CVPlatformConcurrencyContract
{
    associatedtype AttachmentStorage: CVBufferAttachmentStorage

    var dimensions: CVPixelDimensions { get }
    var attachments: AttachmentStorage { get }
}
