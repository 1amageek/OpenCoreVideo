#if canImport(CoreVideo)
import CoreVideo
#endif
import OpenCoreVideo
import Testing

@Suite("Core Video result codes")
struct CVReturnTests {
    @Test("Constants match the Core Video ABI")
    func constants() {
        #expect(OpenCoreVideo.kCVReturnSuccess == 0)
        #expect(OpenCoreVideo.kCVReturnFirst == -6_660)
        #expect(OpenCoreVideo.kCVReturnInvalidArgument == -6_661)
        #expect(OpenCoreVideo.kCVReturnAllocationFailed == -6_662)
        #expect(OpenCoreVideo.kCVReturnUnsupported == -6_663)
        #expect(OpenCoreVideo.kCVReturnInvalidPixelFormat == -6_680)
        #expect(OpenCoreVideo.kCVReturnInvalidSize == -6_681)
        #expect(
            OpenCoreVideo.kCVReturnInvalidPixelBufferAttributes == -6_682
        )
        #expect(
            OpenCoreVideo.kCVReturnWouldExceedAllocationThreshold == -6_689
        )
        #expect(OpenCoreVideo.kCVReturnPoolAllocationFailed == -6_690)
        #expect(OpenCoreVideo.kCVReturnInvalidPoolAttributes == -6_691)
        #expect(OpenCoreVideo.kCVReturnRetry == -6_692)
        #expect(OpenCoreVideo.kCVReturnLast == -6_699)

        #if canImport(CoreVideo)
        #expect(
            OpenCoreVideo.kCVReturnWouldExceedAllocationThreshold
                == CoreVideo.kCVReturnWouldExceedAllocationThreshold
        )
        #expect(
            OpenCoreVideo.kCVReturnInvalidPixelBufferAttributes
                == CoreVideo.kCVReturnInvalidPixelBufferAttributes
        )
        #endif
    }

    @Test("Typed failures map to stable ABI categories")
    func mapping() {
        #expect(
            CVReturnForPixelBufferError(.invalidPixelFormat(0))
                == OpenCoreVideo.kCVReturnInvalidPixelFormat
        )
        #expect(
            CVReturnForPixelBufferError(
                .invalidDimensions(width: 0, height: 1)
            ) == OpenCoreVideo.kCVReturnInvalidSize
        )
        #expect(
            CVReturnForPixelBufferError(.invalidBytesPerRow(
                minimum: 8,
                actual: 4
            )) == OpenCoreVideo.kCVReturnInvalidPixelBufferAttributes
        )
        #expect(
            CVReturnForPixelBufferError(.invalidBytesPerBlock(0))
                == OpenCoreVideo.kCVReturnInvalidPixelBufferAttributes
        )
        #expect(
            CVReturnForPixelBufferError(.invalidMinimumBufferCount(-1))
                == OpenCoreVideo.kCVReturnInvalidPoolAttributes
        )
        #expect(
            CVReturnForPixelBufferError(
                .wouldExceedAllocationThreshold(1)
            ) == OpenCoreVideo.kCVReturnWouldExceedAllocationThreshold
        )
        #expect(
            CVReturnForPixelBufferError(.accessConflict(.write))
                == OpenCoreVideo.kCVReturnRetry
        )
        #expect(
            CVReturnForPixelBufferError(.unsupportedAccess(.read))
                == OpenCoreVideo.kCVReturnUnsupported
        )
        #expect(
            CVReturnForPixelBufferError(.platformAccessFailure(code: 91))
                == OpenCoreVideo.kCVReturnError
        )
    }
}
