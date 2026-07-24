#if hasFeature(Embedded)
public protocol CVPlatformConcurrencyContract {}
#else
public protocol CVPlatformConcurrencyContract: Sendable {}
#endif
