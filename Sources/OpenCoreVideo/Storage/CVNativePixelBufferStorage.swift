/// A storage lease that can lend a platform resource without copying it.
///
/// The handle is valid only while `withNativeHandle` is executing. Concrete
/// adapters own synchronization and must retain the underlying platform
/// resource for the complete lifetime of the storage lease.
public protocol CVNativePixelBufferStorage:
    AnyObject,
    CVPlatformConcurrencyContract
{
    associatedtype NativeHandle

    var storageIdentity: CVPixelBufferStorageIdentity { get }

    func withNativeHandle<Result>(
        _ body: (borrowing NativeHandle) -> Result
    ) throws(CVPixelBufferError) -> Result
}
