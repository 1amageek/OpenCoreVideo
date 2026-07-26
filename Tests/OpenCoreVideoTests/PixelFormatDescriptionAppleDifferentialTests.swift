#if canImport(CoreVideo) && canImport(Foundation)
import CoreVideo
import Foundation
import OpenCoreVideo
import Testing

@Suite("Apple pixel format description differential")
struct PixelFormatDescriptionAppleDifferentialTests {
    @Test("BGRA and NV12 descriptions match Core Video")
    func standardDescriptions() throws {
        try compare(
            appleType: kCVPixelFormatType_32BGRA,
            portableType: .bgra32
        )
        try compare(
            appleType: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            portableType: .yCbCr420BiPlanarVideoRange
        )
    }

    private func compare(
        appleType: OSType,
        portableType: OpenCoreVideo.CVPixelFormatType
    ) throws {
        let appleDictionary = try #require(
            CoreVideo.CVPixelFormatDescriptionCreateWithPixelFormatType(
                nil,
                appleType
            ) as? [String: Any]
        )
        let portableCandidate =
            OpenCoreVideo.CVPixelFormatDescriptionCreateWithPixelFormatType(
                portableType
            )
        guard let portable = portableCandidate else {
            Issue.record(
                "The portable registry must contain the standard format"
            )
            return
        }

        #expect(
            appleDictionary["PixelFormat"] as? UInt32
                == portable.pixelFormatType.rawValue
        )
        #expect(
            appleDictionary["ContainsAlpha"] as? Bool
                == portable.components.contains(.alpha)
        )
        #expect(
            appleDictionary["ContainsRGB"] as? Bool
                == portable.components.contains(.rgb)
        )
        #expect(
            appleDictionary["ContainsYCbCr"] as? Bool
                == portable.components.contains(.yCbCr)
        )

        if let applePlanes = appleDictionary["Planes"] as? [[String: Any]] {
            guard case .planar(let portablePlanes) = portable.planeConfiguration else {
                Issue.record("Apple planar format must be portable planar")
                return
            }
            #expect(applePlanes.count == portablePlanes.count)
            for index in applePlanes.indices {
                #expect(
                    applePlanes[index]["BitsPerBlock"] as? Int
                        == portablePlanes[index].bitsPerBlock
                )
            }
        } else {
            guard case .nonPlanar(let portableLayout) = portable.planeConfiguration else {
                Issue.record("Apple packed format must be portable packed")
                return
            }
            #expect(
                appleDictionary["BitsPerBlock"] as? Int
                    == portableLayout.bitsPerBlock
            )
        }
    }
}
#endif
