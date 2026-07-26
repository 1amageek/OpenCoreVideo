#if canImport(CoreVideo) && canImport(Foundation)
import CoreVideo
import Foundation
import OpenCoreVideo
import Testing

@Suite("Apple pixel format description differential")
struct PixelFormatDescriptionAppleDifferentialTests {
    @Test("Packed and planar descriptions match Core Video")
    func standardDescriptions() throws {
        try compare(
            appleType: kCVPixelFormatType_24RGB,
            portableType: .rgb24
        )
        try compare(
            appleType: kCVPixelFormatType_32ARGB,
            portableType: .argb32
        )
        try compare(
            appleType: kCVPixelFormatType_32BGRA,
            portableType: .bgra32
        )
        try compare(
            appleType: kCVPixelFormatType_64RGBAHalf,
            portableType: .rgba64Half
        )
        try compare(
            appleType: kCVPixelFormatType_128RGBAFloat,
            portableType: .rgba128Float
        )
        try compare(
            appleType: kCVPixelFormatType_OneComponent10,
            portableType: .oneComponent10
        )
        try compare(
            appleType: kCVPixelFormatType_OneComponent32Float,
            portableType: .oneComponent32Float
        )
        try compare(
            appleType: kCVPixelFormatType_DepthFloat32,
            portableType: .depth32Float
        )
        try compare(
            appleType: kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange,
            portableType: .yCbCr420BiPlanarVideoRange
        )
        try compare(
            appleType: kCVPixelFormatType_422YpCbCr8BiPlanarFullRange,
            portableType: .yCbCr422BiPlanarFullRange
        )
        try compare(
            appleType: kCVPixelFormatType_420YpCbCr10BiPlanarVideoRange,
            portableType: .yCbCr420BiPlanar10VideoRange
        )
        try compare(
            appleType: kCVPixelFormatType_444YpCbCr10BiPlanarFullRange,
            portableType: .yCbCr444BiPlanar10FullRange
        )
        try compare(
            appleType: kCVPixelFormatType_444YpCbCr16BiPlanarVideoRange,
            portableType: .yCbCr444BiPlanar16VideoRange
        )
        try compare(
            appleType:
                kCVPixelFormatType_420YpCbCr8VideoRange_8A_TriPlanar,
            portableType: .yCbCr420VideoRangeWithAlphaTriPlanar
        )
        try compare(
            appleType:
                kCVPixelFormatType_444YpCbCr16VideoRange_16A_TriPlanar,
            portableType: .yCbCr444VideoRangeWithAlphaTriPlanar16
        )
        try compare(
            appleType: kCVPixelFormatType_30RGBLE_8A_BiPlanar,
            portableType: .rgb30WideGamutWithAlphaBiPlanar
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
        #expect(
            appleDictionary["ComponentRange"] as? String
                == componentRangeName(portable.componentRange)
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
                #expect(
                    ((applePlanes[index]["HorizontalSubsampling"] as? Int)
                        ?? 1)
                        == portablePlanes[index].subsampling.horizontal
                )
                #expect(
                    ((applePlanes[index]["VerticalSubsampling"] as? Int)
                        ?? 1)
                        == portablePlanes[index].subsampling.vertical
                )
                compareBlackBlock(
                    applePlanes[index]["BlackBlock"] as? Data,
                    portablePlanes[index].blackBlock
                )
            }
            #expect(
                appleDictionary["BitsPerComponent"] as? Int
                    == portablePlanes.first?.bitsPerComponent
            )
        } else {
            guard case .nonPlanar(let portableLayout) = portable.planeConfiguration else {
                Issue.record("Apple packed format must be portable packed")
                return
            }
            #expect(
                appleDictionary["BitsPerBlock"] as? Int
                    == portableLayout.bitsPerBlock
            )
            #expect(
                appleDictionary["BitsPerComponent"] as? Int
                    == portableLayout.bitsPerComponent
            )
            compareBlackBlock(
                appleDictionary["BlackBlock"] as? Data,
                portableLayout.blackBlock
            )
        }
    }

    private func componentRangeName(
        _ range: OpenCoreVideo.CVPixelFormatDescription.ComponentRange?
    ) -> String? {
        switch range {
        case .full: return "FullRange"
        case .video: return "VideoRange"
        case .wide: return "WideRange"
        case nil: return nil
        }
    }

    private func compareBlackBlock(
        _ apple: Data?,
        _ portable: [UInt8]?
    ) {
        guard let apple else {
            #expect(portable == nil)
            return
        }
        #expect(Array(apple) == portable)
    }
}
#endif
