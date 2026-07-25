/// A planar pixel storage lease backed by one platform-native resource.
///
/// One lease owns the complete resource and lends individual planes through
/// `CVPlanarStorageLease`. Native handles remain scoped independently.
public protocol CVPlanarPlatformStorageLease:
    CVPlanarStorageLease,
    CVNativePixelBufferStorage
{}
