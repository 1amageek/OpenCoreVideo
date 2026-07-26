public typealias CVReturn = Int32

public let kCVReturnSuccess: CVReturn = 0
public let kCVReturnFirst: CVReturn = -6_660
public let kCVReturnError: CVReturn = kCVReturnFirst
public let kCVReturnInvalidArgument: CVReturn = -6_661
public let kCVReturnAllocationFailed: CVReturn = -6_662
public let kCVReturnUnsupported: CVReturn = -6_663
public let kCVReturnInvalidDisplay: CVReturn = -6_670
public let kCVReturnDisplayLinkAlreadyRunning: CVReturn = -6_671
public let kCVReturnDisplayLinkNotRunning: CVReturn = -6_672
public let kCVReturnDisplayLinkCallbacksNotSet: CVReturn = -6_673
public let kCVReturnInvalidPixelFormat: CVReturn = -6_680
public let kCVReturnInvalidSize: CVReturn = -6_681
public let kCVReturnInvalidPixelBufferAttributes: CVReturn = -6_682
public let kCVReturnPixelBufferNotOpenGLCompatible: CVReturn = -6_683
public let kCVReturnPixelBufferNotMetalCompatible: CVReturn = -6_684
public let kCVReturnWouldExceedAllocationThreshold: CVReturn = -6_689
public let kCVReturnPoolAllocationFailed: CVReturn = -6_690
public let kCVReturnInvalidPoolAttributes: CVReturn = -6_691
public let kCVReturnRetry: CVReturn = -6_692
public let kCVReturnLast: CVReturn = -6_699

public func CVReturnForPixelBufferError(
    _ error: borrowing CVPixelBufferError
) -> CVReturn {
    switch error {
    case .invalidPixelFormat,
         .pixelFormatBytesPerPixelMismatch,
         .pixelFormatRequiresPackedLayout,
         .pixelFormatRequiresPlanarLayout,
         .pixelFormatPlaneLayoutMismatch:
        return kCVReturnInvalidPixelFormat

    case .invalidDimensions,
         .layoutOverflow,
         .storageTooSmall,
         .planeStorageTooSmall,
         .planeAddressRangeOverflow:
        return kCVReturnInvalidSize

    case .invalidBytesPerPixel,
         .invalidBytesPerRow,
         .invalidStorageSize,
         .invalidAlignment,
         .invalidPlaneCount,
         .planeCountMismatch,
         .invalidPlaneIndex,
         .planeDimensionsExceedImage,
         .overlappingPlaneStorage,
         .planarBufferRequiresPlaneAccess,
         .malformedImageBufferAttachment,
         .invalidCleanAperture,
         .invalidPixelAspectRatio,
         .invalidDisplaySize:
        return kCVReturnInvalidPixelBufferAttributes

    case .invalidMinimumBufferCount:
        return kCVReturnInvalidPoolAttributes

    case .invalidAllocationThreshold,
         .storageReleased:
        return kCVReturnInvalidArgument

    case .wouldExceedAllocationThreshold:
        return kCVReturnWouldExceedAllocationThreshold

    case .poolShutdown,
         .unsupportedAccess:
        return kCVReturnUnsupported

    case .accessConflict:
        return kCVReturnRetry

    case .platformAccessFailure:
        return kCVReturnError
    }
}
