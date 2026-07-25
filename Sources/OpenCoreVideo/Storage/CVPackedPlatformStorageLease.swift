/// A packed pixel storage lease backed by a platform-native resource.
///
/// DMA-BUF, mapped V4L2 memory, browser frames, and GPU-backed allocations can
/// conform in integration packages without introducing their SDKs here.
public protocol CVPackedPlatformStorageLease:
    CVPixelBufferStorage,
    CVNativePixelBufferStorage
{}
